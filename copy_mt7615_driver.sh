#!/bin/bash
cd /home/shutdown/src/padavan

# Create target directory
mkdir -p trunk/linux-3.4.x/drivers/net/wireless/ralink/mt7615

# Copy all files from nilabsent's proprietary mt7615 directory
echo "Copying MT7615 driver source from nilabsent..."
for file in $(git ls-tree -r nilabsent/master:trunk/proprietary/rt_wifi/rtpci/5.0.4.0/mt7615/ | awk '{print $4}'); do
    src="trunk/proprietary/rt_wifi/rtpci/5.0.4.0/mt7615/$file"
    dst="trunk/linux-3.4.x/drivers/net/wireless/ralink/mt7615/$file"
    mkdir -p "$(dirname "$dst")"
    git show nilabsent/master:"$src" > "$dst"
done

echo "Done copying MT7615 driver source"

# Also copy the mt7615_ap Kconfig and Makefile to the kernel wireless ralink directory
echo "Updating mt7615_ap Kconfig and Makefile..."
git show nilabsent/master:trunk/linux-3.4.x/drivers/net/wireless/ralink/mt7615_ap/Kconfig > trunk/linux-3.4.x/drivers/net/wireless/ralink/mt7615_ap/Kconfig
git show nilabsent/master:trunk/linux-3.4.x/drivers/net/wireless/ralink/mt7615_ap/Makefile > trunk/linux-3.4.x/drivers/net/wireless/ralink/mt7615_ap/Makefile

echo "Done!"