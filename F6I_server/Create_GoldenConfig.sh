#!/bin/bash


rm -f ./GoldenConfig.txt
rm -f ./GoldenConfig_pci.txt
rm -f ./GoldenConfig_pci_vt.txt
echo -n "CPU's Qty: " >> ./GoldenConfig.txt
dmidecode -t 4 |grep "Socket Designation: " -c >> ./GoldenConfig.txt
echo -n "DIMM's Qty: " >>./GoldenConfig.txt
dmidecode -t 17 |grep "Manufacturer: Samsung\|Manufacturer: Hynix\|Manufacturer: Intel" -c >> ./GoldenConfig.txt
echo -n "NVMe SSD Count: " >> ./GoldenConfig.txt
nvme list |grep "/dev" -c >> ./GoldenConfig.txt
echo ""  >> ./GoldenConfig.txt
fuck="`lspci -vvv |grep -i "Mellanox Technologies MT27800 Family" |grep -v "Interrupt\|CESta" |awk '{print$1}'`"
        for i in $fuck;do
        lspci -s $i -vvv >> ./GoldenConfig.txt
        done




clear
echo "Golden Config Create complete!"
