#!/bin/bash

echo "Preparing, Please wait..."
if ! ubiattach -p /dev/mtd10 > /tmp/ubiattach_output.txt 2>&1; then
    echo "ubiattach failed, abort!"
    exit 1
fi

ubi_device=$(grep 'UBI device number' /tmp/ubiattach_output.txt | awk '{print $4}' | tr -d ',')
if [[ -z "$ubi_device" ]]; then
    ubidetach -p /dev/mtd10
    echo "ubiattach failed, abort!"
    exit 1
fi

mkdir -p /tmp/editnvram
if ! mount -t ubifs "ubi${ubi_device}_0" /tmp/editnvram; then
    ubidetach -p /dev/mtd10
    echo "Mount failed, abort!"
    exit 1
fi

if [[ ! -f /tmp/editnvram/nvram.nvm ]]; then
    umount /tmp/editnvram
    ubidetach -p /dev/mtd10
    echo "FACTORY NVRAM file not found, abort!"
    exit 1
fi

territory_code=$(grep -oE 'territory_code=[A-Z]{2}/[0-9]{2}' /tmp/editnvram/nvram.nvm | cut -d'=' -f2)
sleep 1

if [[ "$territory_code" != "CN/01" ]]; then
    cp /tmp/editnvram/nvram.nvm /jffs/nvram.nvm.backup
    read -p "Backup has been done. Activate ASSASSIN MODE now? (Y/n): " response
    if [[ "$response" != "Y" && "$response" != "y" ]]; then
        umount /tmp/editnvram
        ubidetach -p /dev/mtd10
        echo "User canceled, abort!"
        exit 1
    fi
    sed -i 's/territory_code=[^ ]*/territory_code=CN\/01/' /tmp/editnvram/nvram.nvm
    sleep 1
    if  grep -q 'territory_code=CN/01' /tmp/editnvram/nvram.nvm; then
        umount /tmp/editnvram
        nvram set location_code=XX
        nvram commit
        echo "ASSASSIN MODE Activated. Please reboot now."
    else
        cp /jffs/nvram.nvm.backup /tmp/editnvram/nvram.nvm
        chmod 775 /tmp/editnvram/nvram.nvm
        umount /tmp/editnvram
        echo "Process failed. Backup restored successfully. Please reboot now."
    fi
else
    if [[ ! -f /jffs/nvram.nvm.backup ]]; then
        umount /tmp/editnvram
        ubidetach -p /dev/mtd10
        echo "Backup file not found, restore not possible, abort!"
        exit 1
    fi
    read -p "Restore to original? (Y/n): " response
    if [[ "$response" != "Y" && "$response" != "y" ]]; then
        umount /tmp/editnvram
        ubidetach -p /dev/mtd10
        echo "User canceled, abort!"
        exit 1
    fi
    cp /jffs/nvram.nvm.backup /tmp/editnvram/nvram.nvm
    chmod 775 /tmp/editnvram/nvram.nvm
    umount /tmp/editnvram
    sleep 1
    echo "Restore to original success. Please reboot now."
fi
