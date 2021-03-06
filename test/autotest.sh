#!/bin/bash

TFTP_EXEC_DIR="$(pwd)/build/test"
TFTP_WORK_DIR="${TFTP_EXEC_DIR}/tmp"
TFTP_WORK_SUBDIR="${TFTP_WORK_DIR}/subdir"
TFTP_WORK_FILE="test.img"

function tftp_setup() {
	dd if=/dev/urandom bs=1000 count=10 of=${1}/$TFTP_WORK_FILE
}

function tftp_cleanup() {
	echo CLEANUP
	pwd;ls
	killall picoapp.elf
	rm -rf $TFTP_WORK_DIR
	if [ $1 ]; then
		exit $1
	fi
}


sh ./test/vde_sock_start_user.sh
rm -f /tmp/pico-mem-report-*
sleep 2
ulimit -c unlimited
killall picoapp.elf &> /dev/null
killall picoapp6.elf &> /dev/null


echo "IPV6 tests!"
echo "PING6 LOCALHOST"
./build/test/picoapp6.elf --loop -a ping,::1,, || exit 1

echo "PING6 TEST"
(./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,aaaa::1,ffff::,,,,) &
./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,aaaa::2,ffff::,,, -a ping,aaaa::1,, || exit 1
killall picoapp6.elf

echo "PING6 TEST (aborted in 4 seconds...)"
(./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,aaaa::1,ffff::,,,,) &
(./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,aaaa::2,ffff::,,, -a ping,aaaa::1,4,) &
sleep 7
killall picoapp6.elf

echo "TCP6 TEST"
(./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,aaaa::1,ffff::,,, -a tcpbench,r,6667,,) &
time (./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,aaaa::2,ffff::,,, -a tcpbench,t,aaaa::1,6667,, || exit 1)
killall picoapp6.elf

echo "TCP6 TEST (with 2% packet loss on both directions)"
(./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,aaaa::1,ffff::,,2,2, -a tcpbench,r,6667,,) &
time (./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,aaaa::2,ffff::,,, -a tcpbench,t,aaaa::1,6667,, || exit 1)
killall picoapp6.elf

echo "TCP6 TEST (nagle)"
(./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,aaaa::1,ffff::,,, -a tcpbench,r,6667,n,) &
time (./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,aaaa::2,ffff::,,, -a tcpbench,t,aaaa::1,6667,n, || exit 1)
killall picoapp6.elf

echo "UDP6 TEST"
(./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,aaaa::1,ffff::,,, -a udpecho,::0,6667,) &
./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,aaaa::2,ffff::,,, -a udpclient,aaaa::1,6667,6667,1400,100,10, || exit 1
wait || exit 1
wait
killall picoapp6.elf

echo
echo
echo
echo "IPV6 FWD TCP TEST"
(./build/test/picoapp6.elf --vde pic0,/tmp/pic1.ctl,2001:aabb::2,ffff:ffff::,2001:aabb::ff,, -a tcpbench,r,6667,,) &
(./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,2001:aaaa::ff,ffff:ffff::,,, --vde pic1,/tmp/pic1.ctl,2001:aabb::ff,ffff:ffff::,,, -a noop,) &
./build/test/picoapp6.elf --vde pic0,/tmp/pic0.ctl,2001:aaaa::1,ffff:ffff::,2001:aaaa::ff,, -a tcpbench,t,2001:aabb::2,6667,, || exit 1
sleep 2
killall picoapp6.elf


echo "MULTICAST TEST"
(./build/test/picoapp.elf --vde pic1:/tmp/pic0.ctl:10.40.0.3:255.255.0.0: -a mcastreceive:10.40.0.3:224.7.7.7:6667:6667) &
(./build/test/picoapp.elf --vde pic2:/tmp/pic0.ctl:10.40.0.4:255.255.0.0: -a mcastreceive:10.40.0.4:224.7.7.7:6667:6667) &
(./build/test/picoapp.elf --vde pic3:/tmp/pic0.ctl:10.40.0.5:255.255.0.0: -a mcastreceive:10.40.0.5:224.7.7.7:6667:6667) &
sleep 2
./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.2:255.255.0.0: -a mcastsend:10.40.0.2:224.7.7.7:6667:6667 || exit 1
(wait && wait && wait) || exit 1

echo
echo
echo
echo
echo

echo "IPV4 tests!"

echo "PING LOCALHOST"
./build/test/picoapp.elf --loop -a ping:127.0.0.1: || exit 1

echo "PING TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.8:255.255.0.0:::) &
./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0::: -a ping:10.40.0.8:: || exit 1
killall picoapp.elf

echo "PING TEST -- Aborted in 4 seconds"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.8:255.255.0.0:::) &
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0::: -a ping:10.40.0.8:4:) &
sleep 7
killall picoapp.elf

echo "TCP TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.8:255.255.0.0:::: -a tcpbench:r:6667::) &
time (./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0::: -a tcpbench:t:10.40.0.8:6667:: || exit 1)
killall picoapp.elf

echo "TCP TEST (with 2% packet loss on both directions)"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.8:255.255.0.0::2:2: -a tcpbench:r:6667::) &
time (./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0::: -a tcpbench:t:10.40.0.8:6667:: || exit 1)
killall picoapp.elf

echo "TCP TEST (nagle)"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.8:255.255.0.0::: -a tcpbench:r:6667:n:) &
time (./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0::: -a tcpbench:t:10.40.0.8:6667:n: || exit 1)
killall picoapp.elf

echo "UDP TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.8:255.255.0.0::: -a udpecho:10.40.0.8:6667) &
./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0::: -a udpclient:10.40.0.8:6667:6667:1400:100:10 || exit 1
wait || exit 1
wait

echo "UDP TEST with fragmentation"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.8:255.255.0.0::: -a udpecho:10.40.0.8:6667) &
./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0::: -a udpclient:10.40.0.8:6667:6667:4500:100:10 || exit 1
wait || exit 1
wait

echo "NAT TCP TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.10:255.255.0.0::: --vde pic1:/tmp/pic1.ctl:10.50.0.10:255.255.0.0: -a natbox:10.50.0.10) &
sleep 2
(./build/test/picoapp.elf --vde pic0:/tmp/pic1.ctl:10.50.0.8:255.255.0.0::: -a tcpbench:r:6667) &
sleep 2
./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0:10.40.0.10::: -a tcpbench:t:10.50.0.8:6667: || exit 1
killall picoapp.elf

echo "NAT UDP TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.10:255.255.0.0::: --vde pic1:/tmp/pic1.ctl:10.50.0.10:255.255.0.0::: -a natbox:10.50.0.10) &
(./build/test/picoapp.elf --vde pic0:/tmp/pic1.ctl:10.50.0.8:255.255.0.0::: -a udpecho:10.50.0.8:6667) &
./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.9:255.255.0.0:10.40.0.10::: -a udpclient:10.50.0.8:6667:6667:1400:100:10 || exit 1
#sometimes udpecho finishes before reaching wait %2
#wait %2

killall picoapp.elf

echo "MULTICAST TEST"
(./build/test/picoapp.elf --vde pic1:/tmp/pic0.ctl:10.40.0.3:255.255.0.0::: -a mcastreceive:10.40.0.3:224.7.7.7:6667:6667) &
(./build/test/picoapp.elf --vde pic2:/tmp/pic0.ctl:10.40.0.4:255.255.0.0::: -a mcastreceive:10.40.0.4:224.7.7.7:6667:6667) &
(./build/test/picoapp.elf --vde pic3:/tmp/pic0.ctl:10.40.0.5:255.255.0.0::: -a mcastreceive:10.40.0.5:224.7.7.7:6667:6667) &
sleep 2
./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.2:255.255.0.0::: -a mcastsend:10.40.0.2:224.7.7.7:6667:6667 || exit 1
(wait && wait && wait) || exit 1

killall picoapp.elf

echo "DHCP TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.1:255.255.0.0::: -a dhcpserver:pic0:10.40.0.1:255.255.255.0:64:128:) &
./build/test/picoapp.elf --barevde pic0:/tmp/pic0.ctl: -a dhcpclient:pic0 || exit 1
killall picoapp.elf

echo "DHCP DUAL TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.2:255.255.0.0::: -a dhcpserver:pic0:10.40.0.2:255.255.255.0:64:128:) &
(./build/test/picoapp.elf --vde pic1:/tmp/pic1.ctl:10.50.0.2:255.255.0.0::: -a dhcpserver:pic1:10.50.0.2:255.255.255.0:64:128:) &
./build/test/picoapp.elf --barevde pic0:/tmp/pic0.ctl: --barevde pic1:/tmp/pic1.ctl: -a dhcpclient:pic0:pic1 || exit 1
killall picoapp.elf

#TO DO: the ping address 169.254.22.5 is hardcoded in the slaacv4 test. Nice to pass that by parameter
echo "SLAACV4 TEST"
(./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:169.254.22.5:255.255.0.0:::) &
./build/test/picoapp.elf --barevde pic0:/tmp/pic0.ctl: -a slaacv4:pic0 || exit 1
killall picoapp.elf


./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.2:255.255.0.0:10.40.0.1::: -a udpdnsclient:www.google.be:173.194.67.94:: &
./build/test/picoapp.elf --vde pic0:/tmp/pic0.ctl:10.40.0.2:255.255.0.0:10.40.0.1::: -a udpdnsclient:ipv6.google.be:doesntmatter:ipv6: &
./build/test/picoapp.elf  --vde pic0:/tmp/pic0.ctl:10.50.0.2:255.255.0.0:10.50.0.1::: -a sntp:ntp.nasa.gov &
sleep 20
killall picoapp.elf


echo "MDNS TEST"
#retrieve a local mdns host name from the host
(./build/test/picoapp.elf  --vde pic0:/tmp/pic0.ctl:10.50.0.2:255.255.255.0:10.50.0.1: --app mdns:hostfoo.local:hostbar.local:) &
(./build/test/picoapp.elf  --vde pic0:/tmp/pic0.ctl:10.50.0.3:255.255.255.0:10.50.0.1: --app mdns:hostbar.local:hostfoo.local:) &
(./build/test/picoapp.elf  --vde pic0:/tmp/pic0.ctl:10.50.0.2:255.255.255.0:10.50.0.1: --app mdns:hostfoobar.local:nonexisting.local:) &
sleep 10
killall picoapp.elf

sleep 1
sync


# TFTP TEST BEGINS...

if [ ! -d $TFTP_WORK_DIR ]; then
        mkdir $TFTP_WORK_DIR || exit 1
fi
if [ ! -d ${TFTP_WORK_SUBDIR}/server ]; then
        mkdir $TFTP_WORK_SUBDIR || exit 1
fi

pushd $TFTP_WORK_DIR

echo "TFTP GET TEST"
tftp_setup $TFTP_WORK_DIR
(${TFTP_EXEC_DIR}/picoapp.elf  --vde pic0:/tmp/pic0.ctl:10.50.0.2:255.255.255.0:10.50.0.1: --app tftp:S) &
cd $TFTP_WORK_SUBDIR
sleep 2
${TFTP_EXEC_DIR}/picoapp.elf  --vde pic0:/tmp/pic0.ctl:10.50.0.3:255.255.255.0:10.50.0.1: --app tftp:R:${TFTP_WORK_FILE}:10.50.0.2 || tftp_cleanup 1
sleep 3
killall picoapp.elf

sleep 1

rm $TFTP_WORK_FILE

echo "TFTP PUT TEST"
(${TFTP_EXEC_DIR}/picoapp.elf  --vde pic0:/tmp/pic0.ctl:10.50.0.2:255.255.255.0:10.50.0.1: --app tftp:S) &
cd $TFTP_WORK_DIR
tftp_setup $TFTP_WORK_DIR
sleep 2
${TFTP_EXEC_DIR}/picoapp.elf  --vde pic0:/tmp/pic0.ctl:10.50.0.3:255.255.255.0:10.50.0.1: --app tftp:T:${TFTP_WORK_FILE}:10.50.0.2 || tftp_cleanup 1
sleep 3

tftp_cleanup
popd
# TFTP TEST ENDS.

MAXMEM=`cat /tmp/pico-mem-report-* | sort -r -n |head -1`
echo
echo
echo
echo "MAX memory used: $MAXMEM"
rm -f /tmp/pico-mem-report-*

echo "SUCCESS!" && exit 0
