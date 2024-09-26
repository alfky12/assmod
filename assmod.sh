#!/bin/bash

# Function to attach UBI device
attach_ubi() {
    ubiattach -p /dev/mtd10
}

# Function to get UBI device number
get_ubi_device() {
    dmesg | grep -oP 'UBI device number \K\d+'
}

# Function to mount UBI filesystem
mount_ubi() {
    local ubi_device="$1"
    mkdir -p /tmp/editnvram
    mount -t ubifs "ubi${ubi_device}_0" /tmp/editnvram
}

# Function to check for nvram.nvm file
check_nvram_file() {
    if [ ! -f /tmp/editnvram/nvram.nvm ]; then
        umount /tmp/editnvram
        echo "nvram.nvm file not found, exit now"
        exit 1
    fi
}

# Function to get territory_code
get_territory_code() {
    grep -oP 'territory_code=\K.*' /tmp/editnvram/nvram.nvm
}

# Function to backup nvram.nvm file
backup_nvram() {
    cp /tmp/editnvram/nvram.nvm /jffs/nvram.nvm.backup
}

# Function to prompt user for changes
prompt_user_change() {
    local current_code="$1"
    echo "Found territory_code: $current_code. Change to CN/01? (Y/n)"
    read -r user_input
    if [[ "$user_input" =~ ^[Nn]$ ]]; then
        umount /tmp/editnvram
        echo "user canceled, exit now"
        exit 1
    fi
}

# Function to update territory_code in nvram.nvm
update_territory_code() {
    sed -i 's/territory_code=.*$/territory_code=CN\/01/' /tmp/editnvram/nvram.nvm
}

# Function to restore nvram.nvm.backup file
restore_backup() {
    if [ -f /jffs/nvram.nvm.backup ]; then
        echo "Restore nvram.nvm.backup? (Y/n)"
        read -r restore_input
        if [[ "$restore_input" =~ ^[Nn]$ ]]; then
            umount /tmp/editnvram
            echo "user canceled, exit now"
            exit 1
        fi
        [ -f /tmp/editnvram/nvram.nvm ] && rm /tmp/editnvram/nvram.nvm
        cp /jffs/nvram.nvm.backup /tmp/editnvram/nvram.nvm
        chmod 775 /tmp/editnvram/nvram.nvm
    fi
}

# Main script execution
attach_ubi
UBI_DEV=$(get_ubi_device)
mount_ubi "$UBI_DEV"
check_nvram_file
TERRITORY_CODE=$(get_territory_code)

if [[ "$TERRITORY_CODE" != "CN/01" ]]; then
    backup_nvram
fi

prompt_user_change "$TERRITORY_CODE"
update_territory_code
umount /tmp/editnvram
echo "Region successfully changed to CN/01 (China). Please reboot now."

if [[ "$TERRITORY_CODE" == "CN/01" ]]; then
    restore_backup
    umount /tmp/editnvram
    echo "nvram.nvm successfully restored. Please reboot now."
fi
