#!/bin/bash

# Raspberry Pi disable swapfile and overclock

OS=
VERSION=
ARCHITECTURE=

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

    log "OS:$OS"
    log "Version:$VERSION"
    log "Architecture:$ARCHITECTURE"
}

disable_swap(){
    superuserdo dphys-swapfile swapoff
    superuserdo systemctl disable dphys-swapfile.service
}

overclock(){
    REVISION=($(cat /proc/cpuinfo | grep Revision))
    REVISION=${REVISION[2]}
    log "Raspberry Pi revision: $REVISION"

    # Pi 2 Model B
    if [[ $REVISION == *"a01041"* ]] || [[ $REVISION == *"a21041"* ]]; then
        # split 16MB memory for GPU
        log "Minimize GPU memory..."
        if [[ $(cat /boot/config.txt | grep gpu_mem=16) != "gpu_mem=16" ]]; then
            echo "gpu_mem=16" | superuserdo tee -a /boot/config.txt
        fi

        # overclock to 1GHz
        log "Overclock to 1GHz..."
        if [[ $(cat /boot/config.txt | grep arm_freq=1000) != "arm_freq=1000" ]]; then
            echo "arm_freq=1000" | superuserdo tee -a /boot/config.txt
        fi
        if [[ $(cat /boot/config.txt | grep core_freq=450) != "core_freq=450" ]]; then
            echo "core_freq=450" | superuserdo tee -a /boot/config.txt
        fi
        if [[ $(cat /boot/config.txt | grep sdram_freq=450) != "sdram_freq=450" ]]; then
            echo "sdram_freq=450" | superuserdo tee -a /boot/config.txt
        fi
        if [[ $(cat /boot/config.txt | grep over_voltage=2) != "over_voltage=2" ]]; then
            echo "over_voltage=2" | superuserdo tee -a /boot/config.txt
        fi
    else
        err "Unsupported Revision: $REVISION"
    fi
}

detect

if [[ $OS == "Raspbian"* ]]; then
        disable_swap
        overclock
else
    err "Unsupported OS: $OS"
fi

