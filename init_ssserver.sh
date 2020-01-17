#!/bin/bash

OS=
VERSION=
ARCHITECTURE=
PACKAGE_MANAGER=

log(){
    green_text="\033[0;32m$1\033[0m"
    echo -e "$green_text";
}

err(){
    red_text="\033[0;31m$1\033[0m"
    echo -e "$red_text";
    exit 1
}

superuserdo(){
    if [ `whoami` == 'root' ];then
        $@
    else
        sudo $@
    fi
}

detect(){
    # detecting os
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VERSION=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VERSION=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VERSION=$(cat /etc/debian_version)
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        VERSION=$(uname -r)
    fi

    # detection architecture
    ARCHITECTURE=`uname -m`
    log "Detecting Architecture:"
    log "OS:$OS"
    log "Version:$VERSION"
    log "Architecture:$ARCHITECTURE"

    if [[ $OS == "Raspbian"* ]]; then
        PACKAGE_MANAGER="apt"
        SOFTWARE_LIST="$SOFTWARE_LIST $RASPBIAN_SOFTWARE_LIST"
    elif [[ $OS == "Debian"* ]]; then
        PACKAGE_MANAGER="apt"
        SOFTWARE_LIST="$SOFTWARE_LIST $DEBIAN_SOFTWARE_LIST"
    elif [[ $OS == "Ubuntu"* ]]; then
        PACKAGE_MANAGER="apt"
        SOFTWARE_LIST="$SOFTWARE_LIST $UBUNTU_SOFTWARE_LIST"
    elif [[ $OS == "Darwin"* ]]; then
        PACKAGE_MANAGER="brew"
        SOFTWARE_LIST="$SOFTWARE_LIST $DARWIN_SOFTWARE_LIST"
    else
        err "Unsupported OS: $OS"
    fi
}

log "Using BBR."
echo "net.core.default_qdisc=fq" | superuserdo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | superuserdo tee -a /etc/sysctl.conf
sysctl -p

log "Installing shadowsocks."
superuserdo $PACKAGE_MANAGER update
superuserdo $PACKAGE_MANAGER install python-pip -y
pip install git+https://github.com/shadowsocks/shadowsocks.git@master

superuserdo mkdir -p /etc/shadowsocks
superuserdo cp -p ./shadowsocks/server.json /etc/shadowsocks/server.json
superuserdo ssserver -c /etc/shadowsocks/server.json -d start

