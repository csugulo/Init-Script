#!/bin/bash

COMMON_SOFTWARE_LIST="git vim tmux zsh cmake curl wget htop golang gdbserver valgrind google-perftools libgoogle-perftools-dev libgtest-dev"

RASPBIAN_SOFTWARE_LIST="libopencv-dev python-opencv libboost-all-dev libeigen3-dev"

UBUNTU_SOFTWARE_LIST=""

DEBIAN_SOFTWARE_LIST=""

DATE=`date "+%Y%m%d%H%M%S"`

OS=
VERSION=
ARCHITECTURE=
USE_TUNA_SOURCE=False

log(){
    green_text="\033[0;32m$1\033[0m"
    echo -e "$green_text";
}

err(){
    red_text="\033[0;31m$1\033[0m"
    echo -e "$red_text";
    exit 1
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

raspbian_use_tuna_source(){
    VERSION_NAME=
    if [[ $VERSION == "7" ]]; then
        VERSION_NAME="wheezy"
    elif [ $VERSION == "8" ]; then
        VERSION_NAME="jessie"
    elif [ $VERSION == "9" ]; then
        VERSION_NAME="stretch"
    elif [ $VERSION == "10" ]; then
        VERSION_NAME="buster"
    else
        err "Unsupported Raspbian version: $VERSION"
    fi

    log "$OS $VERSION $VERSION_NAME use TUNA source..."
    sudo rm -f /etc/apt/sources.list
    echo "deb http://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ $VERSION_NAME main non-free contrib" | sudo tee -a /etc/apt/sources.list
    echo "deb-src http://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ $VERSION_NAME main non-free contrib" | sudo tee -a /etc/apt/sources.list
    sudo rm -f /etc/apt/sources.list.d/raspi.list
    echo "deb http://mirrors.tuna.tsinghua.edu.cn/raspberrypi/ $VERSION_NAME main ui" | sudo tee -a /etc/apt/sources.list.d/raspi.list
}

init_raspbian(){
    if [[ $USE_TUNA_SOURCE == True ]]; then
        raspbian_use_tuna_source
    fi
    log "apt update list of available packages"
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install $COMMON_SOFTWARE_LIST $RASPBIAN_SOFTWARE_LIST -y

    # disable swapfile
    sudo dphys-swapfile swapoff
    sudo systemctl disable dphys-swapfile.service

    REVISION=($(cat /proc/cpuinfo | grep Revision))
    REVISION=${REVISION[2]}
    log "Raspberry Pi revision: $REVISION"

    # Pi 2 Model B
    if [[ $REVISION == *"a01041"* ]] || [[ $REVISION == *"a21041"* ]]; then
        # split 16MB memory for GPU
        log "Minimize GPU memory..."
        if [[ $(cat /boot/config.txt | grep gpu_mem=16) != "gpu_mem=16" ]]; then
            echo "gpu_mem=16" | sudo tee -a /boot/config.txt
        fi

        # overclock to 1GHz
        log "Overclock to 1GHz..."
        if [[ $(cat /boot/config.txt | grep arm_freq=1000) != "arm_freq=1000" ]]; then
            echo "arm_freq=1000" | sudo tee -a /boot/config.txt
        fi
        if [[ $(cat /boot/config.txt | grep core_freq=450) != "core_freq=450" ]]; then
            echo "core_freq=450" | sudo tee -a /boot/config.txt
        fi
        if [[ $(cat /boot/config.txt | grep sdram_freq=450) != "sdram_freq=450" ]]; then
            echo "sdram_freq=450" | sudo tee -a /boot/config.txt
        fi
        if [[ $(cat /boot/config.txt | grep over_voltage=2) != "over_voltage=2" ]]; then
            echo "over_voltage=2" | sudo tee -a /boot/config.txt
        fi
    fi

}

ubuntu_use_tuna_source(){
    VERSION_NAME=
    if [[ $VERSION == "12"* ]]; then
        VERSION_NAME="precise"
    elif [[ $VERSION == "14"* ]]; then
        VERSION_NAME="trusty"
    elif [[ $VERSION == "16"* ]]; then
        VERSION_NAME="xenial"
    elif [[ $VERSION == "18"* ]]; then
        VERSION_NAME="bionic"
    else
        err "Unsupported Ubuntu version: $VERSION"
    fi

    log "$OS $VERSION $VERSION_NAME use TUNA source..."
    sudo rm -f /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $VERSION_NAME main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $VERSION_NAME-updates main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $VERSION_NAME-backports main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $VERSION_NAME-security main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list
}

init_ubuntu(){
    if [[ $USE_TUNA_SOURCE == True ]]; then
        ubuntu_use_tuna_source
    fi
    log "apt update list of available packages"
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install $COMMON_SOFTWARE_LIST $UBUNTU_SOFTWARE_LIST -y
}

debian_use_tuna_source(){
    VERSION_NAME=
    if [[ $VERSION == "11"* ]]; then
        VERSION_NAME="bullseye"
    elif [[ $VERSION == "10"* ]]; then
        VERSION_NAME="buster"
    elif [[ $VERSION == "9"* ]]; then
        VERSION_NAME="stretch"
    elif [[ $VERSION == "8"* ]]; then
        VERSION_NAME="jessie"
    else
        err "Unsupported Ubuntu version: $VERSION"
    fi

    log "$OS $VERSION $VERSION_NAME use TUNA source..."
    sudo rm -f /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $VERSION_NAME main contrib non-free" | sudo tee -a /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $VERSION_NAME-updates main contrib non-free" | sudo tee -a /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $VERSION_NAME-backports main contrib non-free" | sudo tee -a /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian-security $VERSION_NAME/updates main contrib non-free" | sudo tee -a /etc/apt/sources.list
}

init_debian(){
    if [[ $USE_TUNA_SOURCE == True ]]; then
        debian_use_tuna_source
    fi
    log "apt update list of available packages"
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install $COMMON_SOFTWARE_LIST $DEBIAN_SOFTWARE_LIST -y
}



init_darwin(){
    return 0
}

config(){

    sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    wget https://raw.githubusercontent.com/csugulo/Init-Script/master/.zshrc -O $HOME/.zshrc -nc
    wget https://raw.githubusercontent.com/csugulo/Init-Script/master/.tmux.conf -O $HOME/.tmux.conf -nc
    wget https://raw.githubusercontent.com/csugulo/Init-Script/master/.vimrc -O $HOME/.vimrc -nc

    if [ ! -d "$HOME/bin" ]; then
        mkdir $HOME/bin
    fi
}

init(){
    if [[ $OS == "Raspbian"* ]]; then
        init_raspbian
    elif [[ $OS == "Debian"* ]]; then
        init_debian
    elif [[ $OS == "Ubuntu"* ]]; then
        init_ubuntu
    elif [[ $OS == "Darwin"* ]]; then
        init_dawrin
    else
        err "Unsupported OS: $OS"
    fi
}

parse_args(){
    for i in $@
    do
        if [ $i == use-tuna-source ];then
                USE_TUNA_SOURCE=True
        fi
    done
}


parse_args $@
detect
init
config
