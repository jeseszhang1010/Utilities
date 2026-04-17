#!/bin/bash

HOSTNAME_IPS=$1
NUM_RACKS=$2
SERVERTOBT0_NDT=${SERVERTOBT0_NDT:-"/home/NetBench/fw_mke03_servertobt0.csv"}
MIN_NODES_PER_RACK=16
#BAD_RACK_ARR=("F01C02C016-CR2028" "F01C02C015-AT2031" "F01C02C015-AY2017" "F01C02C015-AT2017" "F01C02C015-AT2029" "F01C02C015-AT2030" "F01C02C015-AY2031" "F01C02C015-BD2031")

ls $HOSTNAME_IPS
ndt_lines=$(grep -if <(awk -F, '{print $1}' $HOSTNAME_IPS) $SERVERTOBT0_NDT  | grep -F A1.PORT1 | tr -d '\r')

all_ct_rack=$(echo "$ndt_lines" | awk -F, '{print $NF}' | sed 's/\"//g' | sort | uniq -c | sort -r )
echo "$all_ct_rack" > all_ct_rack
all_ct_arr=$(echo "$all_ct_rack" | awk '{print $1}')
all_rack_arr=$(echo "$all_ct_rack" | awk '{print $2}')

ct_rack=$(echo "$ndt_lines" | awk -F, '{print $NF}' | sed 's/\"//g' | sort | uniq -c | sort -r \
    | awk -v val=$MIN_NODES_PER_RACK '$1 >= val')
echo "$ct_rack" > ct_rack
ct_arr=$(echo "$ct_rack" | awk '{print $1}')
rack_arr=$(echo "$ct_rack" | awk '{print $2}')

rack_arr=($(printf "%s\n" "${rack_arr[@]}" | sort))
max_num_racks="${#rack_arr[@]}"

#for rack in "${BAD_RACK_ARR[@]}"; do
#    echo "Removing rack $rack"
#    for ((i=0;i<$max_num_racks;i++)); do
#        if [[ "${rack_arr[i]}" == "$rack" ]]; then
#            unset 'rack_arr[i]'
#            unset 'all_rack_arr[i]'
#        fi
#    done
#done
#rack_arr=("${rack_arr[@]//}")
#all_rack_arr=("${all_rack_arr[@]//}")

max_num_racks="${#rack_arr[@]}"
echo "Max available NVL64 racks $max_num_racks, requested racks $NUM_RACKS"


# Prepare racknames and hostfiles.
rm -f hostnames-*
rm -f hostfile-*

for rack in ${all_rack_arr[@]}; do
    echo "Preparing IPs for $rack"
    hostfile=hostfile-$rack
    hostnamesfile=hostnames-$rack
    rm -f $hostfile $hostnames
    hostnames=$(echo "$ndt_lines" | grep -F "$rack" | awk -F, '{print $1}' | sed 's/\"//g' | tr '[:lower:]' '[:upper:]' )
    rack_hostnames_ips=$(grep -f <(echo "$hostnames") $HOSTNAME_IPS) 
    
    count=$(echo "$rack_hostnames_ips" | wc -l)
    if [[ $count -ge $MIN_NODES_PER_RACK ]]; then
        rack_hostnames_ips_nvl64=$(grep -f <(echo "$hostnames") $HOSTNAME_IPS | head -n $MIN_NODES_PER_RACK) 
        echo "$rack_hostnames_ips_nvl64" | awk -F, '{print $1}' > "$hostnamesfile-nvl64"
        echo "$rack_hostnames_ips_nvl64" | awk -F, '{print $2}' > "$hostfile-nvl64"
    fi

    echo "$rack_hostnames_ips" | awk -F, '{print $1}' > "$hostnamesfile"
    echo "$rack_hostnames_ips" | awk -F, '{print $2}' > "$hostfile"
done

# Restart imex service, if needed.
config_file=/tmp/nodes_config.cfg
for rack in ${all_rack_arr[@]}; do

    hostfile=hostfile-$rack
    num_nodes_with_active_imex=$(parallel-ssh -h "$hostfile" -X "-o ConnectTimeout=10" -x "-o StrictHostKeyChecking=no" -t 180 -i \
        "sudo systemctl is-active nvidia-imex" | grep "^active$" | wc -l)

    count=$(cat $hostfile | wc -l)
    if [ "$num_nodes_with_active_imex" -ne $count ]; then
        echo "Restarting IMEX on $rack"
        hostfile=hostfile-$rack
        parallel-scp -h $hostfile -x "-o ConnectTimeout=10" -x" -o StrictHostKeyChecking=no" -t 180 $hostfile $config_file
        parallel-ssh -h $hostfile -i -X "-o ConnectTimeout=10 " -x"-o StrictHostKeyChecking=no" -t 30 \
            "sudo install -m 644 -D $config_file /etc/nvidia-imex/nodes_config.cfg && rm -f $config_file"
        parallel-ssh -h "$hostfile" -X "-o ConnectTimeout=10 " -x"-o StrictHostKeyChecking=no" -t 180 -i \
            "sudo systemctl stop nvidia-imex;sudo systemctl enable --now nvidia-imex && sudo systemctl restart nvidia-imex" &
    else
        echo "Rack $rack already has imex active on all the nodes needed"
    fi

done


wait

# Check if imex service is active and MRC service is active.
echo "Checking if IMEX and MRC are active"
racks_active=()
all_racks_active=()
for rack in ${all_rack_arr[@]}; do
    hostfile=hostfile-$rack
    num_nodes_with_active_imex=$(parallel-ssh -h "$hostfile" -X "-o ConnectTimeout=10" -x "-o StrictHostKeyChecking=no" -t 180 -i \
        "sudo systemctl is-active nvidia-imex" | grep "^active$" | wc -l)
    is_imex_active=0
    count=$(cat $hostfile | wc -l)
    if [ "$num_nodes_with_active_imex" -ne $count ]; then
        echo "One or more nodes in $rack failed to start imex" 
    else
        is_imex_active=1
    fi

    num_nodes_with_active_mrc=$(parallel-ssh -h "$hostfile" -X "-o ConnectTimeout=10" -x "-o StrictHostKeyChecking=no" -t 180 -i \
        "sudo systemctl is-active mrc-config" | grep "^active$" | wc -l)

    is_mrc_active=0
    if [ "$num_nodes_with_active_mrc" -ne $count ]; then
        echo "One or more nodes in $rack failed to start MRC" 
    else
        is_mrc_active=1
    fi

    if [[ "$is_imex_active" -eq 1 && "$is_mrc_active" -eq 1 ]]; then
        all_racks_active+=("$rack")
	if [ $count -ge "$MIN_NODES_PER_RACK" ]; then
            racks_active+=("$rack")
	fi
    fi
done

echo "Racks with active IMEX and MRC in NVL64:"
printf "%s\n" "${racks_active[@]}"

echo "THIS IS FINAL_IP_FILE: $FINAL_IP_FILE"
FINAL_IP_FILE=${FINAL_IP_FILE:-"ips-for-nccl-$HOSTNAME_IPS"}
rm -f $FINAL_IP_FILE-*

for rack in "${racks_active[@]}"; do
    hostfile="hostfile-$rack-nvl64"
    cat "$hostfile" >> "$FINAL_IP_FILE-nvl64"
done

echo "Racks with active IMEX and MRC:"
printf "%s\n" "${all_racks_active[@]}"

for rack in "${all_racks_active[@]}"; do
    hostfile=hostfile-$rack
    cat "$hostfile" >> "$FINAL_IP_FILE-all"
done

echo "IPs of NVL64 for NCCL written to $FINAL_IP_FILE-nvl64"
echo "All IPs for NCCL written to $FINAL_IP_FILE-all"

