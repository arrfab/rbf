umount /tmp/temp/boot
umount /tmp/temp/proc
umount -l /tmp/temp/dev/
sleep 2
umount /tmp/temp
[ -b /dev/loop0 ] && losetup -d /dev/loop0 &>> rbf.log
exit 0
