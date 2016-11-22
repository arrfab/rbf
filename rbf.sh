echo [INFO ]   $0 Detaching Loopback Device: /dev/loop0
[ -b /dev/loop0 ] && losetup -d /dev/loop0 &>> rbf.log
echo [INFO ]    $0 Creating CentOS-Userland-7-armv7hl-Minimal-YM-Cubieboard.img
dd if=/dev/zero of="CentOS-Userland-7-armv7hl-Minimal-YM-Cubieboard.img" bs=1M count=0 seek=3072 &>> rbf.log 
if [ $? != 0 ]; then exit 200; fi

losetup /dev/loop0 "CentOS-Userland-7-armv7hl-Minimal-YM-Cubieboard.img" &>> rbf.log
if [ $? != 0 ]; then exit 220; fi

echo [INFO ]   $0 Creating Parititons
parted /dev/loop0 --align optimal -s mklabel msdos mkpart primary ext3 2048s 1026047s mkpart primary linux-swap 1026048s 2074623s mkpart primary ext4 2074624s 6268927s  &>> rbf.log 
if [ $? != 0 ]; then exit 201; fi

partprobe /dev/loop0 &>> rbf.log
if [ $? != 0 ]; then exit 221; fi

[ -b /dev/loop0p1 ] && echo [INFO ]   $0 Creating Filesystem ext3 on partition 1 || exit 203
mkfs.ext3 -U 1d9324c0-a688-4ee5-8fa7-4f4020129ccc /dev/loop0p1 &>> rbf.log 
[ -b /dev/loop0p2 ] && echo [INFO ]   $0 Creating Filesystem swap on partition 2 || exit 203
mkswap -U 99ca1a07-8ed8-4ce1-a133-d840f1ecd0ac /dev/loop0p2 &>> rbf.log 
[ -b /dev/loop0p3 ] && echo [INFO ]   $0 Creating Filesystem ext4 on partition 3 || exit 203
mkfs.ext4 -U 10df37ab-ff7b-44bc-a623-e4c88c11e6da /dev/loop0p3 &>> rbf.log 
mkdir -p /tmp/temp
if [ $? != 0 ]; then exit 222; fi

echo [INFO ]   $0 Mouting Parititon 3 on /
mount /dev/loop0p3 /tmp/temp/
if [ $? != 0 ]; then exit 204; fi

mkdir -p /tmp/temp//boot
echo [INFO ]   $0 Mouting Parititon 1 on /boot
mount /dev/loop0p1 /tmp/temp/boot
if [ $? != 0 ]; then exit 204; fi

mkdir /tmp/temp/proc /tmp/temp/sys /tmp/temp/dev
mount -t proc proc /tmp/temp/proc
mount --bind /dev /tmp/temp/dev
rm -rf /tmp/temp/etc/yum.repos.d
mkdir -p /tmp/temp/etc/yum.repos.d
cat > /tmp/temp/etc/yum.repos.d/centos-base_rbf.repo << EOF
[centos-base_rbf]
name=centos-base_rbf
baseurl=http://armv7.dev.centos.org/repos/7/os/armhfp/
gpgcheck=0
enabled=1
EOF
if [ $? != 0 ]; then exit 205; fi

cat > /tmp/temp/etc/yum.repos.d/centos-extras_rbf.repo << EOF
[centos-extras_rbf]
name=centos-extras_rbf
baseurl=http://armv7.dev.centos.org/repos/7/extras/armhfp/
gpgcheck=0
enabled=1
EOF
if [ $? != 0 ]; then exit 205; fi

cat > /tmp/temp/etc/yum.repos.d/centos-updates_rbf.repo << EOF
[centos-updates_rbf]
name=centos-updates_rbf
baseurl=http://armv7.dev.centos.org/repos/7/updates/armhfp/
gpgcheck=0
enabled=1
EOF
if [ $? != 0 ]; then exit 205; fi

cat > /tmp/temp/etc/yum.repos.d/centos-arm-kernels_rbf.repo << EOF
[centos-arm-kernels_rbf]
name=centos-arm-kernels_rbf
baseurl=http://armv7.dev.centos.org/repodir/arm-kernels/4.4.34-201/
gpgcheck=0
enabled=1
EOF
if [ $? != 0 ]; then exit 205; fi

cat > /tmp/temp/etc/yum.repos.d/centos-cr_rbf.repo << EOF
[centos-cr_rbf]
name=centos-cr_rbf
baseurl=http://armv7.dev.centos.org/repodir/c71611-pass-1
gpgcheck=0
enabled=1
EOF
if [ $? != 0 ]; then exit 205; fi

rpm --root /tmp/temp --initdb
if [ $? != 0 ]; then exit 208; fi

echo [INFO ]  $0 Installing Package Groups. Please Wait
yum --disablerepo=* --enablerepo=centos-base_rbf --enablerepo=centos-extras_rbf --enablerepo=centos-updates_rbf --enablerepo=centos-arm-kernels_rbf --enablerepo=centos-cr_rbf  --installroot=/tmp/temp --releasever=7 groupinstall -y core 2>> rbf.log
if [ $? != 0 ]; then echo [INFO ]  GROUP_INSTALL_ERROR: Error Installing Some Package Groups; read -p "Press Enter To Continue"; fi

echo [INFO ]  $0 Installing Packages. Please Wait
yum --disablerepo=* --enablerepo=centos-base_rbf --enablerepo=centos-extras_rbf --enablerepo=centos-updates_rbf --enablerepo=centos-arm-kernels_rbf --enablerepo=centos-cr_rbf  --installroot=/tmp/temp --releasever=7 install -y chrony cloud-utils-growpart net-tools 2>> rbf.log
if [ $? != 0 ]; then echo [INFO ]  PACKAGE_INSTALL_ERROR: Error Installing Some Packages; read -p "Press Enter To Continue"; fi

echo [INFO ]  $0 Installing Kernel Packages. Please Wait
yum --disablerepo=* --enablerepo=centos-base_rbf --enablerepo=centos-extras_rbf --enablerepo=centos-updates_rbf --enablerepo=centos-arm-kernels_rbf --enablerepo=centos-cr_rbf  --installroot=/tmp/temp --releasever=7 install -y kernel dracut-config-generic 2>> rbf.log
if [ $? != 0 ]; then echo [INFO ]  KERNEL_PACKAGE_INSTALL_ERROR: Error installing Kernel Packages; read -p "Press Enter To Continue"; fi

cp kernelup.d/rbfcubieboard.sh /tmp/temp/usr/sbin/
if [ $? != 0 ]; then echo [INFO ]  KERNELUP_ERROR: Could not copy kernel upgrade script; read -p "Press Enter To Continue"; fi

cp -rpv ./etc/* /tmp/temp/etc/ &>> rbf.log 
if [ $? != 0 ]; then exit 211; fi

echo "root:centos" | chpasswd --root /tmp/temp &>> rbf.log
if [ $? != 0 ]; then echo [INFO ]  ROOT_PASS_ERROR: Could Not Set Root Pass; read -p "Press Enter To Continue"; fi

sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /tmp/temp/etc/selinux/config  &>> rbf.log 
if [ $? != 0 ]; then echo [INFO ]  SELINUX_ERROR: Could Not Set SELINUX Status; read -p "Press Enter To Continue"; fi

exit 0
