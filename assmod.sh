#!/bin/bash

# Attach UBI device and check for errors
if ! ubiattach -p /dev/mtd10 > /tmp/ubiattach_output.txt 2>&1; then
    echo "ubiattach failed, exit now."
    exit 1
fi

# Get UBI device number
ubi_device=$(grep 'UBI device number' /tmp/ubiattach_output.txt | awk '{print $4}' | tr -d ',')
if [[ -z "$ubi_device" ]]; then
    echo "ubiattach failed, exit now."
    exit 1
fi

# Prepare mount point and mount UBI filesystem
mkdir -p /tmp/editnvram
if ! mount -t ubifs "ubi${ubi_device}_0" /tmp/editnvram; then
    echo "Mount failed, exit now."
    exit 1
fi

# Check for nvram.nvm file
if [[ ! -f /tmp/editnvram/nvram.nvm ]]; then
    umount /tmp/editnvram
    echo "CFE file not found, exit now."
    exit 1
fi

# Check and process territory_code
territory_code=$(grep -oE 'territory_code=[A-Z]{2}/[0-9]{2}' /tmp/editnvram/nvram.nvm | cut -d'=' -f2)

if [[ "$territory_code" != "CN/01" ]]; then
    cp /tmp/editnvram/nvram.nvm /jffs/nvram.nvm.backup
    read -p "Found territory_code: $territory_code. Change CFE Region to China (CN/01)? (Y/n): " response
    if [[ "$response" != "Y" && "$response" != "y" ]]; then
        umount /tmp/editnvram
        echo "User canceled, exit now."
        exit 1
    fi
    sed -i 's/territory_code=[^ ]*/territory_code=CN\/01/' /tmp/editnvram/nvram.nvm
    if  grep -q 'territory_code=CN/01' /tmp/editnvram/nvram.nvm; then
        umount /tmp/editnvram
        echo "CFE Region successfully changed to China (CN/01). Please reboot now."
    else
        echo "Edit process failed, restoring original CFE."
        cp /jffs/nvram.nvm.backup /tmp/editnvram/nvram.nvm
        chmod 775 /tmp/editnvram/nvram.nvm
        umount /tmp/editnvram
        echo "Original CFE restored successfully, please reboot now."
    fi
else
    if [[ ! -f /jffs/nvram.nvm.backup ]]; then
        umount /tmp/editnvram
        echo "Current CFE Region is China (CN/01)."
        echo "But original CFE backup file not found, exit now."
        exit 1
    fi
    read -p "Current CFE Region is China (CN/01). Restore original CFE file? (Y/n): " response
    if [[ "$response" != "Y" && "$response" != "y" ]]; then
        umount /tmp/editnvram
        echo "User canceled, exit now."
        exit 1
    fi
    cp /jffs/nvram.nvm.backup /tmp/editnvram/nvram.nvm
    chmod 775 /tmp/editnvram/nvram.nvm
    umount /tmp/editnvram
    echo "Original CFE restored successfully, please reboot now."
fi
