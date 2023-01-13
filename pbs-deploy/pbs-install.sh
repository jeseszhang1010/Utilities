#!/bin/bash
set -e

function help_msg {
    echo "Usage: $0 <server/client> <server-hostname>"
    exit 1
}


SERVERCLIENT=$1
SERVERNAME=$2

# Check to see if pbs is already installed
if [ -f /etc/pbs.conf ];then
    echo "OpenPBS is already installed, nothing to do"
    exit 0
fi

if [ $# -ne 2 ]; then
    help_msg
fi
if [ $SERVERCLIENT != "server" ] && [ $SERVERCLIENT != "client" ]; then
    echo "Error: first argument has to be either server or client, exiting"
    help_msg
fi

# Check to see which OS this is running on.
os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
os_maj_ver=$(cat /etc/os-release | grep "^VERSION_ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
echo "OS Release: $os_release"
echo "OS Major Version: $os_maj_ver"

# Download OpenPBS tarball
if [ "$SERVERCLIENT" = "server" ]; then
    wget https://github.com/openpbs/openpbs/archive/refs/tags/v22.05.11.tar.gz
fi
tar xf v22.05.11.tar.gz
cd openpbs-22.05.11

if [ "$os_release" = "almalinux" ]; then
    # Enable necessary package repos
    sudo dnf config-manager --set-enabled powertools
    sudo dnf install -y dnf-plugins-core
    sudo dnf install -y gcc make rpm-build libtool hwloc-devel libX11-devel \
    		    libXt-devel libedit-devel libical-devel  ncurses-devel \
    		    perl postgresql-devel postgresql-contrib python3-devel tcl-devel  tk-devel \
    		    swig expat-devel openssl-devel libXext libXft  autoconf automake gcc-c++
    sudo dnf install -y expat libedit postgresql-server postgresql-contrib python3 sendmail sudo tcl tk libical

elif [ "$os_release" = "ubuntu" ] && [ "$os_maj_ver" = "20.04" ];then
    sudo apt install -y gcc make libtool libhwloc-dev libx11-dev \
          libxt-dev libedit-dev libical-dev ncurses-dev perl \
          postgresql-server-dev-all postgresql-contrib python3-dev tcl-dev tk-dev swig \
          libexpat-dev libssl-dev libxext-dev libxft-dev autoconf \
          automake g++
    sudo apt-get -y install expat libedit2 postgresql python3 postgresql-contrib sendmail-bin \
          sudo tcl tk libical3
fi

# build pbs
./autogen.sh && ./configure --prefix=/opt/pbs && make -j4 && sudo make install
sudo /opt/pbs/libexec/pbs_postinstall
# Some file permissions must be modified to add SUID privilege.
sudo chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp

# modify /etc/pbs.conf for client
if [ $SERVERCLIENT = "client" ]; then
    sudo sed -i "s/^PBS_SERVER=.*/PBS_SERVER=${SERVERNAME}/g" /etc/pbs.conf
    sudo sed -i "s/^PBS_START_SERVER=1.*/PBS_START_SERVER=0/g" /etc/pbs.conf
    sudo sed -i "s/^PBS_START_SCHED=1.*/PBS_START_SCHED=0/g" /etc/pbs.conf
    sudo sed -i "s/^PBS_START_COMM=1.*/PBS_START_COMM=0/g" /etc/pbs.conf
    sudo sed -i "s/^PBS_START_MOM=0.*/PBS_START_MOM=1/g" /etc/pbs.conf
fi

# start pbs service
#sudo /etc/init.d/pbs start
sudo systemctl enable pbs
sudo systemctl start  pbs
sudo systemctl status pbs

if ! systemctl list-units --type=service --state=running | grep pbs.service ; then
    echo "Error: OpenPBS service is not in running state, exiting"
    exit 1
fi

# All configured PBS services should now be running. Update your PATH and MANPATH
# variables by sourcing the appropriate PBS profile or logging out and back in.
. /etc/profile.d/pbs.sh

ssh ${SERVERNAME} "sudo /opt/pbs/bin/qmgr -c \"create node $(hostname)\""
pbsnodes $(hostname)
