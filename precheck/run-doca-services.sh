#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <cluster; cluster can be canary, pilot or prod"
  exit 1
fi
CLUSTER=$1

# Source common functions.
source "$(dirname "$0")/common.sh"
check_cluster "$CLUSTER"

# Set the configuration file.
MRC_CONFIG_FILE=${MRC_CONFIG_FILE:-"$PWD/mrc-config-file.txt"}
check_file_existence "$MRC_CONFIG_FILE"
NPLANES=${NPLANES:-8}
NPLANESM1=$(( NPLANES-1 ))
SRV6_GRPC_BASE_PORT=${SRV6_GRPC_BASE_PORT:-30000}
PSMA_GRPC_BASE_PORT=${PSMA_GRPC_BASE_PORT:-31000}
PRDMA_PROV_GRPC_BASE_PORT=${PRDMA_PROV_GRPC_BASE_PORT:-29000}
DYNAMIC_DEBUG_GRPC_ADDR_BASE_PORT=${DYNAMIC_DEBUG_GRPC_ADDR_BASE_PORT:-29700}
PSMA_DB=${PSMA_DB:-"$PWD/psma-db"}
STAT_TIME_INTERVAL=${STAT_TIME_INTERVAL:-20}
METHOD_TYPE=${METHOD_TYPE:-"both"}
PS_TYPE=${PS_TYPE:-"encode-plane"}
SLEEP_TIME=${SLEEP_TIME:-5}
CONFIG_ADDR_JSON=${CONFIG_ADDR_JSON:-"config_addr.json"}
PLANE_OFFSET_BITS=${PLANE_OFFSET_BITS:-4}
LOG_DIR=${LOG_DIR:-"/var/log/doca"}
PSS_CPU_LISTS=${PSS_CPU_LISTS:-"71,70 67,66 143,142 139,138"}
PRDMA_CPU_LISTS=${PRDMA_CPU_LISTS:-"69,70 65,64 141,140 137,136"}

mkdir -p $LOG_DIR

mapfile -t DEVICE_PCI_ADDR_LIST < <(parse_list "$MRC_CONFIG_FILE" DEVICE_PCI_ADDR_LIST)
mapfile -t VF_PCI_ADDR_LIST < <(parse_list "$MRC_CONFIG_FILE" VF_PCI_ADDR_LIST)
mapfile -t PF_PCI_ADDR_LIST < <(parse_list "$MRC_CONFIG_FILE" PF_PCI_ADDR_LIST)
mapfile -t VF_IP_ADDR_LIST < <(parse_list "$MRC_CONFIG_FILE" VF_IP_ADDR_LIST)
mapfile -t PF_SWITCH_DMAC_LIST < <(parse_list "$MRC_CONFIG_FILE" PF_SWITCH_DMAC_LIST)

read -r -a PSS_CORE_LIST_ARR   <<< "$PSS_CPU_LISTS"
read -r -a PRDMA_CORE_LIST_ARR <<< "$PRDMA_CPU_LISTS"

mrc_config_print "Creating config_addr.json for PSS"

# Create the single mac addr json file.
python3 gen_addr_json.py --device_pci $(join_arr , "${DEVICE_PCI_ADDR_LIST[@]}") \
	--num_pfs_per_device $NPLANES \
	--pf_switch_dmac $(join_arr , "${PF_SWITCH_DMAC_LIST[@]}") \
	--srv6_grpc_base_port $SRV6_GRPC_BASE_PORT \
	--dynamic_debug_grpc_addr_base_port $DYNAMIC_DEBUG_GRPC_ADDR_BASE_PORT \
	--output_filename $CONFIG_ADDR_JSON

SRV6_GRPC_ADDRESS_LIST=()
VF_GLOBAL_IPV6_LIST=()
PSMA_GRPC_ADDRESS_LIST=()
PRDMA_PROV_ADDRESS_LIST=()
DYNAMIC_DEBUG_GRPC_ADDRESS_LIST=()

i=0
for DEVICE_PCI_ADDR in "${DEVICE_PCI_ADDR_LIST[@]}"; do
	SRV6_GRPC_ADDRESS_LIST+=("localhost:$(( SRV6_GRPC_BASE_PORT+i ))")
	VF_GLOBAL_IPV6=$(echo ${VF_IP_ADDR_LIST[i]} | cut -d'/' -f1)
	VF_GLOBAL_IPV6_LIST+=("$VF_GLOBAL_IPV6")
	PSMA_GRPC_ADDRESS_LIST+=("localhost:$(( PSMA_GRPC_BASE_PORT+i ))")
	PRDMA_PROV_ADDRESS_LIST+=("localhost:$(( PRDMA_PROV_GRPC_BASE_PORT+i ))")
	DYNAMIC_DEBUG_GRPC_ADDRESS_LIST+=("localhost:$(( DYNAMIC_DEBUG_GRPC_ADDR_BASE_PORT+i ))")
	i=$(( i + 1 ))
done

mrc_config_print "Checking if ports needed for DOCA services are available"

check_if_ports_avail "${SRV6_GRPC_ADDRESS_LIST[@]}"
check_if_ports_avail "${DYNAMIC_DEBUG_GRPC_ADDRESS_LIST[@]}"
check_if_ports_avail "${PSMA_GRPC_ADDRESS_LIST[@]}"
check_if_ports_avail "${PRDMA_PROV_ADDRESS_LIST[@]}"

mrc_config_print "Starting DOCA Path Selector Switching service"

# DOCA PATH SELECTOR SWITCHING
PSS_ADDITIONAL_ARGS=""

i=0
for DEVICE_PCI_ADDR in "${DEVICE_PCI_ADDR_LIST[@]}"; do
  VF_NETDEV=$(ls /sys/bus/pci/devices/"${VF_PCI_ADDR_LIST[i]}"/net | grep 'v[0-9]*$')

  PSS_CPULIST=${PSS_CORE_LIST_ARR[i]}
  PSS_LCORE=${PSS_CPULIST%%,*}

  set -x	
  /opt/mellanox/doca/services/doca_path_selector_switching -l "$PSS_LCORE" --file-prefix "$i" -- --pci "$DEVICE_PCI_ADDR" \
	-r "pf[0-$NPLANESM1]vf[0]" -c "$CONFIG_ADDR_JSON" -t "$STAT_TIME_INTERVAL" -mt "$METHOD_TYPE" \
	-ps "$PS_TYPE" -o "$PLANE_OFFSET_BITS" -vf "$VF_NETDEV" $PSS_ADDITIONAL_ARGS \
	> "${LOG_DIR}/doca_path_selector_switching_${VF_NETDEV}_stdout.log" \
	2> "${LOG_DIR}/doca_path_selector_switching_${VF_NETDEV}_stderr.log" &
  PSS_PID=$!
  sleep 0.5 # Need a small delay to make sure the service starts properly before setting affinity.
  taskset -acp "$PSS_CPULIST" "$PSS_PID"
  set +x

  i=$(( i + 1 ))
done

mrc_config_print "Checking if ports opened by DOCA Path Selector Switching service are up"

check_all_ports_up "${SRV6_GRPC_ADDRESS_LIST[@]}"
check_all_ports_up "${DYNAMIC_DEBUG_GRPC_ADDRESS_LIST[@]}"

mrc_config_print "Starting DOCA PRDMA Provider service"

# DOCA PRDMA PROVIDER
PRDMA_ADDITIONAL_ARGS="--no-sack  --telemetry-psls --telemetry-steering"

i=0
for DEVICE_PCI_ADDR in "${DEVICE_PCI_ADDR_LIST[@]}"; do
	
  VF_NETDEV=$(ls /sys/bus/pci/devices/"${VF_PCI_ADDR_LIST[i]}"/net | grep 'v[0-9]*$')
  VF_GLOBAL_IPV6=$(echo "${VF_IP_ADDR_LIST[i]}" | cut -d'/' -f1)
  PF0_NETDEV_NAME=$(ls /sys/bus/pci/devices/"$DEVICE_PCI_ADDR"/net | grep -E 'be[0-9]+p0$' | head -n 1)
  VF_REP_NAME=$(devlink port show | grep "$DEVICE_PCI_ADDR" | grep "flavour pcivf" | grep "pfnum 0" | grep "vfnum 0" | awk '{for(n=1;n<=NF;n++) if($n=="netdev") print $(n+1)}')

  REPR="$VF_REP_NAME,$VF_GLOBAL_IPV6"
  VF_MAC_ADDR=$(cat /sys/class/net/"${VF_NETDEV}"/address)
  REPR+=",$VF_MAC_ADDR"

  PRDMA_CPULIST=${PRDMA_CORE_LIST_ARR[i]}
  PRDMA_LCORE=${PRDMA_CPULIST%%,*}

  set -x	
  /opt/mellanox/doca/services/doca_prdma_provider -l "$PRDMA_LCORE" -- -p "$PF0_NETDEV_NAME" -r "$REPR" \
 	--mode switch --ps-plane-num "$NPLANES" --psma-addr "${PSMA_GRPC_ADDRESS_LIST[i]}" --ps-plane-shift "$PLANE_OFFSET_BITS" \
	--grpc-listening-address "${PRDMA_PROV_ADDRESS_LIST[i]}" $PRDMA_ADDITIONAL_ARGS \
	> "${LOG_DIR}/doca_prdma_provider_${VF_NETDEV}_stdout.log" \
	2> "${LOG_DIR}/doca_prdma_provider_${VF_NETDEV}_stderr.log" &
  PRDMA_PID=$!
  sleep 0.5 # Need a small delay to make sure the service starts properly before setting affinity.
  taskset -acp "$PRDMA_CPULIST" "$PRDMA_PID"
  set +x

  i=$(( i + 1 ))
done

mrc_config_print "Checking if ports opened by DOCA PRDMA Provider service are up"

check_all_ports_up "${PRDMA_PROV_ADDRESS_LIST[@]}"

mrc_config_print "Starting DOCA Path Selector Manager service"

# DOCA PATH SELECTOR MANAGER SERVICE
PSMA_ADDITIONAL_ARGS="--pss_request_deadline_milliseconds 10000"

i=0
for DEVICE_PCI_ADDR in "${DEVICE_PCI_ADDR_LIST[@]}"; do

	VF_NETDEV=$(ls /sys/bus/pci/devices/"${VF_PCI_ADDR_LIST[i]}"/net | grep 'v[0-9]*$' )

	PLANE_MAPPING=()
	for ((j=0; j<8; j++)); do
		k=$((j+8*i))
		PF_NETDEV=$(ls /sys/bus/pci/devices/"${PF_PCI_ADDR_LIST[k]}"/net | grep -E 'be[0-9]+p[0-9]+$')
		PLANE_MAPPING+=("$PF_NETDEV=$j")
	done

	set -x	
	/opt/mellanox/doca/services/doca_ps_manager_server \
		--encoding_plugin_name "libev_struct_encoding_plugin_lib.so" --encoding_plugin_args "$PWD/cluster/$CLUSTER/encoding.json,$PWD/cluster/$CLUSTER/path_template.json" \
		--grpc_address "${PSMA_GRPC_ADDRESS_LIST[i]}" \
		--pss_service_addresses "${SRV6_GRPC_ADDRESS_LIST[i]}" \
		--pss_served_ips "${VF_GLOBAL_IPV6_LIST[i]}" \
		--functions_per_pss_instance 1 \
		--prdma_prov_addr "${PRDMA_PROV_ADDRESS_LIST[i]}" \
		--plane_mapping $(join_arr , "${PLANE_MAPPING[@]}") $PSMA_ADDITIONAL_ARGS > ${LOG_DIR}/doca_ps_manager_server_${VF_NETDEV}_stdout.log 2> ${LOG_DIR}/doca_ps_manager_server_${VF_NETDEV}_stderr.log &
	set +x
	sleep 1.2 # This is needed so that the internal file (based on seconds) gets created properly.
	i=$((i+1))
done

mrc_config_print "Checking if ports opened by DOCA Path Selector Manager service are up"

check_all_ports_up "${PSMA_GRPC_ADDRESS_LIST[@]}"

mrc_config_print "Checking if PCC host status ACTIVE is present in DOCA PRDMA Provider service logs"

# Wait until the 'PCC host status ACTIVE' string appears on the stdout log of PRDMA provider.
i=0
for DEVICE_PCI_ADDR in "${DEVICE_PCI_ADDR_LIST[@]}"; do
	
	VF_NETDEV=$(ls /sys/bus/pci/devices/"${VF_PCI_ADDR_LIST[i]}"/net | grep 'v[0-9]*$' )
	check_if_string_in_file 'PCC host status ACTIVE' "${LOG_DIR}/doca_prdma_provider_${VF_NETDEV}_stdout.log"

	i=$(( i + 1 ))
done
