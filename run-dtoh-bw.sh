
bandwidthTest="/usr/local/cuda/samples/1_Utilities/bandwidthTest/bandwidthTest"

for device in $(seq 0 7); do
    CUDA_VISIBLE_DEVICES=$device numactl -m $(( $device / 2 )) -N $(( $device / 2 )) $bandwidthTest --memory=pinned --mode=range --start=1073741824 --end=1073741824 --increment=1 --dtoh
done
