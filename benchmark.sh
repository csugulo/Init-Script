#/bin/bash

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

test_cpu(){
    log "Testing CPU."
    g++ -O3 -fopenmp smallpt.cpp -o smallpt >> /dev/null 2>&1
    chmod a+x smallpt
    start_tm=`date +%s%N`;
    ./smallpt 50
    end_tm=`date +%s%N`;
    use_tm=`echo $end_tm $start_tm | awk '{ print ($1 - $2) / 1000000000}'`
    log "Path tracing cost $use_tm s."
}

test_bandwidth(){
    superuserdo pip install speedtest-cli >> /dev/null 2>&1
    log "Testing bandwidth."
    speedtest-cli --simple
}

test_disk_io(){
    log "Testing disk IO."

    log "Testing write with bs=64M."
    dd if=/dev/zero of=/tmp/test.img bs=64M count=16 oflag=dsync
    log "Testing write with bs=4K."
    dd if=/dev/zero of=/tmp/test.img bs=4K count=262144 oflag=dsync

    echo 3 | superuserdo tee /proc/sys/vm/drop_caches

    log "Testing read with bs=64M."
    dd if=/tmp/test.img of=/dev/null bs=64M
    log "Testing read with bs=4K."
    dd if=/tmp/test.img of=/dev/null bs=4K

    superuserdo rm -f /tmp/test.img
}

test_cpu
test_bandwidth
test_disk_io