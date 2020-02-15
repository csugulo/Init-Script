#!/bin/bash

# Usage: bash init.sh [use-tuna-source] [install-proxy]

SOFTWARE_LIST="git vim tmux zsh cmake curl wget htop build-essential python3-pip"

RASPBIAN_SOFTWARE_LIST=""

UBUNTU_SOFTWARE_LIST=""

DEBIAN_SOFTWARE_LIST=""

DATE=`date "+%Y%m%d%H%M%S"`

OS=
VERSION=
ARCHITECTURE=
PACKAGE_MANAGER=
USE_TUNA_SOURCE=False
INSTALL_PROXY=False

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

parse_args(){
    for i in $@
    do
        if [ $i == use-tuna-source ];then
            USE_TUNA_SOURCE=True
        fi
        if [ $i == install-proxy ];then
            INSTALL_PROXY=True    
        fi
    done
}

use_tuna_source(){
    log "$PACKAGE_MANAGER use tuna source."
    VERSION_NAME=
    # Raspbian
    if [[ $OS == "Raspbian"* ]]; then
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
        superuserdo rm -f /etc/apt/sources.list
        echo "deb http://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ $VERSION_NAME main non-free contrib" | superuserdo tee -a /etc/apt/sources.list
        echo "deb-src http://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ $VERSION_NAME main non-free contrib" | superuserdo tee -a /etc/apt/sources.list
        superuserdo rm -f /etc/apt/sources.list.d/raspi.list
        echo "deb http://mirrors.tuna.tsinghua.edu.cn/raspberrypi/ $VERSION_NAME main ui" | superuserdo tee -a /etc/apt/sources.list.d/raspi.list
    
    # Debian
    elif [[ $OS == "Debian"* ]]; then
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
        superuserdo rm -f /etc/apt/sources.list
        echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $VERSION_NAME main contrib non-free" | superuserdo tee -a /etc/apt/sources.list
        echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $VERSION_NAME-updates main contrib non-free" | superuserdo tee -a /etc/apt/sources.list
        echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $VERSION_NAME-backports main contrib non-free" | superuserdo tee -a /etc/apt/sources.list
        echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian-security $VERSION_NAME/updates main contrib non-free" | superuserdo tee -a /etc/apt/sources.list
    
    # Ubuntu
    elif [[ $OS == "Ubuntu"* ]]; then
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
        superuserdo rm -f /etc/apt/sources.list
        echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $VERSION_NAME main restricted universe multiverse" | superuserdo tee -a /etc/apt/sources.list
        echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $VERSION_NAME-updates main restricted universe multiverse" | superuserdo tee -a /etc/apt/sources.list
        echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $VERSION_NAME-backports main restricted universe multiverse" | superuserdo tee -a /etc/apt/sources.list
        echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $VERSION_NAME-security main restricted universe multiverse" | superuserdo tee -a /etc/apt/sources.list
    
    # Darwin
    elif [[ $OS == "Darwin"* ]]; then
        err "Unsupported OS: $OS"
    else
        err "Unsupported OS: $OS"
    fi
}

install_softwares(){
    log "Installing softwares."
    superuserdo $PACKAGE_MANAGER update
    superuserdo $PACKAGE_MANAGER install $SOFTWARE_LIST -y
    log "Install Ohmyzsh."
    sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

copy_config(){
    log "Coping config files."
    cp ./.zshrc $HOME/.zshrc -f
    cp ./.tmux.conf $HOME/.tmux.conf -f
    cp ./.vimrc $HOME/.vimrc -f
    if [ ! -d "$HOME/bin" ]; then
        mkdir $HOME/bin
    fi
}

install_proxy(){
    log "Installing proxy softwares."
    superuserdo $PACKAGE_MANAGER update -y
    superuserdo $PACKAGE_MANAGER install proxychains
    wget https://install.direct/go.sh
    superuserdo bash go.sh
    rm go.bash
    if [[ $OS == "Darwin"* ]]; then
        err "Unsupported OS: $OS"
        # brew update
    else
        superuserdo cp ./v2ray/config.json /etc/v2ray/config.json
        superuserdo cp ./proxychains.conf /etc/proxychains.conf
        superuserdo systemctl start v2ray
    fi
}

parse_args $@
detect
if [[ $USE_TUNA_SOURCE == True ]]; then
    use_tuna_source
fi
install_softwares
copy_config
if [[ $INSTALL_PROXY == True ]]; then
    install_proxy
fi

log "Done. Please Reboot Computer."
