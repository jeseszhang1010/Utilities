#!/usr/bin/env python3

import ipaddress
import subprocess
import sys
import re
import os

CONFIG_FILE = "/opt/microsoft/mrc/config/mrc-config-file.txt"
RT_TABLES_FILE = "/etc/iproute2/rt_tables"
NUM_NICS = 4
NUM_PLANES_PER_NIC = 8

def check_path_existence(path):
    if not os.path.exists(path):
        print(f"{path} does not exist")
        sys.exit(1)

def parse_list(filepath, sec_name):
    with open(filepath) as f:
        lines = f.readlines()

    vals = []
    in_section = False

    pattern = rf"^==\s*{re.escape(sec_name)}"
    for line in lines:
        line = line.strip()
        if re.match(pattern, line):
            in_section = True
            continue
        if line.startswith("=="):
            in_section = False
        if in_section and line and not line.startswith("#"):
            if "IP_ADDR" in sec_name:
                vals.append(line.split('/')[0])  # strip subnet if this is an IP address.
            else:
                vals.append(line)
    return vals

def get_netdev_from_pci_addr(pci_addr):
    try:
        netdev_path = f"/sys/bus/pci/devices/{pci_addr}/net/"
        output = subprocess.check_output(["ls", netdev_path], text=True, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError as e:
        print(f"Error running ls {netdev_path}: {e}", file=sys.stderr)
        sys.exit(1)
    # Match original names (enP...np0, enP...v0) or renamed (be0p0, be0v0)
    match = re.search(r'(en\S*(np|v)\d+|be\d+[pv]\d+)', output)
    if match:
        netdev_name = match.group(0)
    else:
        print(f'Unexpected netdevname in {output}. Exiting', file=sys.stderr)
        sys.exit(1)
    return netdev_name


def modify_rt_tables(filepath, vf_netdev_list):

    with open(filepath) as f:
        lines = f.readlines()

    new_lines = []
    for inic in range(NUM_NICS):
        pattern = rf"^{inic+1}\s+"
        vf_netdev = vf_netdev_list[inic]
        line_found = False
        for line in lines:
            if re.match(pattern, line):
                full_pattern = rf"^{inic+1}\s+{vf_netdev}_table"
                if re.match(full_pattern, line) == None:
                    print(f"We got a line that starts with {inic+1} but the name of the routing table is not nic{inic}")
                    sys.exit(1)
                line_found = True
                print(f"Routing table entry '{line.strip()}' is already present.")
                break
        if line_found == False:
            new_lines.append(f"{inic+1} {vf_netdev}_table" + "\n")
        else:
            continue

    with open(filepath, "a") as f:
        f.writelines(new_lines)

def modify_ip_rules(vf_ip_addr_list, vf_netdev_list):

    cmd = ['ip', '-6', 'rule', 'show']
    try:
        output = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True)
    except Exception as e:
        print(f"[ERROR] ip -6 rule show failed. Error is {str(e)}")
        sys.exit(1)

    # Check if any rule already exists for preferences 1...NUM_NICS followed by a colon.
    lines = output.splitlines()
    for inic in range(NUM_NICS):
        vf_netdev = vf_netdev_list[inic]
        ip_addr = ipaddress.IPv6Address(vf_ip_addr_list[inic]).compressed
        pattern = rf"^{inic+1}:"
        line_found = False
        for line in lines:
            if re.match(pattern, line):
                full_pattern = rf"^{inic+1}:\s+from\s+{ip_addr}\s+lookup\s+{vf_netdev}_table"
                if re.match(full_pattern, line) == None:
                    print(f"We got a rule with pref {inic+1} which is not associated with expected {vf_netdev_list[inic]} IPv6 address")
                    sys.exit(1)
                line_found = True
                print(f"Rule {line} is already configured")
                break
        if line_found == False:
            cmd = ['ip', '-6', 'rule', 'add', 'from', f'{ip_addr}', 'lookup', f'{inic+1}', 'pref', f'{inic+1}']
            result = subprocess.run(cmd, capture_output=True, text=True, check=False)
            if result.returncode != 0:
                print(f"Could not add ip rule: {cmd}. Output is: {result.stdout}")
                sys.exit(1)
        else:
            continue

    line_found = False
    for line in lines:
        pattern = rf"^0:\s+from\s+all\s+lookup\s+local"
        if re.match(pattern, line):
            line_found = True
            print(f"Deleting local lookup with pref 0")
            cmd = ['ip', '-6', 'rule', 'del', 'from', 'all', 'lookup', 'local', 'pref', '0']
            result = subprocess.run(cmd, capture_output=True, text=True, check=False)
            if result.returncode != 0:
                print(f"Could not delete ip rule: {cmd}. Output is: {result.stdout}")
                sys.exit(1)

    if line_found == False:
        print(f"Local loookup with pref 0 was not there. So, nothing to delete.")

    line_found = False
    for line in lines:
        pattern = rf"^{NUM_NICS+1}:\s+from\s+all\s+lookup\s+local"
        if re.match(pattern, line):
            line_found = True
            print(f"Config: '{line}' is already there. Not reconfiguring local lookup.")
            break

    if line_found == False:
        cmd = ['ip', '-6', 'rule', 'add', 'from', 'all', 'lookup', 'local', 'pref', f'{NUM_NICS+1}']
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        if result.returncode != 0:
            print(f"Could not add ip rule for local lookup with the new pref: {cmd}. Output is: {result.stdout}")
            sys.exit(1)


def modify_ip_routes(vf_ip_addr_list, vf_netdev_list, pf_netdev_list, next_hop_ip_list):


    for inic in range(NUM_NICS):

        cmd = ['ip', '-6', 'route', 'show', 'table', f'{inic+1}']
        try:
            output = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True)
        except Exception as e:
            print(f"[ERROR] ip -6 rule show failed. Error is {str(e)}")
            sys.exit(1)
        lines = output.splitlines()

        this_nic_ip = ipaddress.IPv6Address(vf_ip_addr_list[inic]).compressed
        other_nic_ip = ipaddress.IPv6Address(vf_ip_addr_list[(inic + 2) % NUM_NICS]).compressed

        pattern = rf"^{other_nic_ip}\s+via"
        line_found = False
        for line in lines:
            if re.match(pattern, line):
                line_found = True
                print(f"Found a route for the other NIC in table {inic+1}: {line}. Not configuring this route again.")
                break

        if line_found == False:
            cmd = ['ip', '-6', 'route', 'add', f'{other_nic_ip}/128', 'via', f'{next_hop_ip_list[NUM_PLANES_PER_NIC*inic]}', 'dev', f'{pf_netdev_list[NUM_PLANES_PER_NIC*inic]}', 'metric', '1024', 'table', f'{inic+1}']
            result = subprocess.run(cmd, capture_output=True, text=True, check=False)
            if result.returncode != 0:
                print(f"Could not add route for nic{(inic+2) % NUM_NICS} from nic{inic}: {cmd}. Output is: {result.stdout}")
                sys.exit(1)

        pattern = rf"^default\s+via"
        line_found = False
        for line in lines:
            if re.match(pattern, line):
                line_found = True
                print(f"Found a route for the other NIC in table {inic+1}: {line}. Not configuring this route again.")
                break

        if line_found == False:
            cmd = ['ip', '-6', 'route', 'add', f'default', 'via', f'{next_hop_ip_list[NUM_PLANES_PER_NIC*inic]}', 'dev', f'{pf_netdev_list[NUM_PLANES_PER_NIC*inic]}', 'metric', '1024', 'table', f'{inic+1}']
            result = subprocess.run(cmd, capture_output=True, text=True, check=False)
            if result.returncode != 0:
                print(f"Could not add default route from nic{inic}: {cmd}. Output is: {result.stdout}")
                sys.exit(1)


def main():

    check_path_existence(CONFIG_FILE)
    check_path_existence(RT_TABLES_FILE)
    vf_ip_addr_list = parse_list(CONFIG_FILE, "VF_IP_ADDR_LIST")
    pf_pci_addr_list = parse_list(CONFIG_FILE, "PF_PCI_ADDR_LIST")
    vf_pci_addr_list = parse_list(CONFIG_FILE, "VF_PCI_ADDR_LIST")
    next_hop_ip_list = parse_list(CONFIG_FILE, "NEXT_HOP_IP_ADDR_LIST")
    pf_netdev_list = []
    for pf_pci_addr in pf_pci_addr_list:
        pf_netdev_list.append(get_netdev_from_pci_addr(pf_pci_addr))
    vf_netdev_list = []
    for vf_pci_addr in vf_pci_addr_list:
        vf_netdev_list.append(get_netdev_from_pci_addr(vf_pci_addr))

    modify_rt_tables(RT_TABLES_FILE, vf_netdev_list)
    modify_ip_rules(vf_ip_addr_list, vf_netdev_list)
    modify_ip_routes(vf_ip_addr_list, vf_netdev_list, pf_netdev_list, next_hop_ip_list)

if __name__ == "__main__":
    main()

