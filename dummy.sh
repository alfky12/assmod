#!/bin/bash

# Simulasi: Set UBI device number
ubi_device=2  # Hardcode nilai untuk uji

# Prepare mount point and create dummy file
mkdir -p /tmp/editnvram
echo "territory_code=CN/01" > /tmp/editnvram/nvram.nvm

# Check for nvram.nvm file
if [[ ! -f /tmp/editnvram/nvram.nvm ]]; then
    echo "nvram.nvm file not found, exit now."
    exit 1
fi

# Check and process territory_code
territory_code=$(grep -oE 'territory_code=[A-Z]{2}/[0-9]{2}' /tmp/editnvram/nvram.nvm | cut -d'=' -f2)

if [[ "$territory_code" != "CN/01" ]]; then
    cp /tmp/editnvram/nvram.nvm /jffs/nvram.nvm.backup
    read -p "Found territory_code: $territory_code. Change to China Region (CN/01)? (Y/n): " response
    if [[ "$response" != "Y" && "$response" != "y" ]]; then
        echo "User canceled, exit now."
        exit 1
    fi
    sed -i 's/territory_code=[^ ]*/territory_code=CN\/01/' /tmp/editnvram/nvram.nvm
    if  grep -q 'territory_code=CN/01' /tmp/editnvram/nvram.nvm; then
        echo "CFE Region successfully changed to CN/01 (China). Please reboot now."
    else
        echo "Edit process failed, restoring original CFE."
        cp /jffs/nvram.nvm.backup /tmp/editnvram/nvram.nvm
        chmod 775 /tmp/editnvram/nvram.nvm
        echo "Original CFE restored successfully, please reboot now."
    fi
else
    if [[ ! -f /jffs/nvram.nvm.backup ]]; then
        echo "Original CFE backup file not found, exit now."
        exit 1
    fi
    read -p "Current CFE Region is China (CN/01). Restore original CFE file? (Y/n): " response
    if [[ "$response" != "Y" && "$response" != "y" ]]; then
        cp /jffs/nvram.nvm.backup /tmp/editnvram/nvram.nvm
        chmod 775 /tmp/editnvram/nvram.nvm
        echo "Original CFE restored successfully, please reboot now."
    fi
fi
