sudo /sbin/modprobe nvidia-uvm
D=`grep nvidia-uvm /proc/devices | awk '{print $1}'`
sudo mknod -m 666 /dev/nvidia-uvm c $D 0
