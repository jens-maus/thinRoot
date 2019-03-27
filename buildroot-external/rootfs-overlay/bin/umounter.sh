#!/bin/sh
for MNTPATH in `grep /mnt /proc/mounts | awk '{ print $2 }'`; do
  /bin/umount ${MNTPATH}
  if [ $? -eq 0 ] ;then 
    CHECK=`grep ${MNTPATH} /proc/mounts`
    if [ $? -ne 0 ] ;then
      rm -r ${MNTPATH}
    fi
  fi
done
