# Filename: Check_Stress.sh
# Author: Structure
# Version: 2021/03/22


### Stress Option ###
Stress_CPU="Y"          #Option for stressing CPU: Y/N
Stress_DIMM="Y"         #Option for stressing DIMM: Y/N
Stress_Disk="Y"         #Option for stressing Drive: Y/N
Stress_NIC="Y"          #Option for stressing NIC: Y/N

Still_Stress="Y"        #

### Server/Clinent ###
Server_Client="S"       #Server is "S" or "s"; Clinet is "C" or "c"
Server_ip=192.168.19.101  #Server IP

### System Information & Configuration ###
PN_CPU="Intel|AMD"
PN_DIMM="Hynix|Micron|Skhynix|Samsung"
PN_M2="KXG60ZNV256G"
PN_SSDnvme="WUS4BB096D7P3E1"
PN_SSDsd="Intel|Samsung"
PN_HDD="Seagate"
PN_NIC="Mellanox|Broadcom"
# PN_VGA="Radeon HD 5000/6000/7350/8350 Series"

NCPU_GS=1               #CPU
NDIMM_GS=8              #DIMM
NM2_GS=1                #M.2 NVMe
NSSD_nvme_GS=2          #SSD NVMe
NSSD_sd_GS=0            #SSD sd
NHDD_GS=0               #HDD
NFan_GS=6               #Fan

Fan_spec=1000
CPU_spec=85

de_time=30 # Stress Time between HDD and CPU/DIMM (second)


### Color Code ###
rest="\e[0m"
red="\e[31;1m"
green="\e[32;1m"
yellow="\e[33;1m"
blue="\e[34;1m"
skyblue="\e[36;1m"
whitebg="\e[47;30m"

### Input Interface ###
clear
read -p "Please key in the test item(e.g., nonop_vib_x or op_shock_y): " test_item
test_item=$(echo -e "$test_item" | tr ' ' '_')
# clear
echo -e "${whitebg}==== Checking System Configuration Before Test... ====${rest}"


### Create Test Folder ###
findcounter=$(ls |grep counter -c)
if [ "$findcounter" -ne 0 ]; then
    count=$(sed -n '1p' counter)
    count=$(($count+1))
    mkdir ${count}_$(date +"%m%d")_${test_item}
    folder=${count}_$(date +"%m%d")_${test_item}
    sleep 1
else
    count=1
    mkdir ${count}_$(date +"%m%d")_${test_item}
    folder=${count}_$(date +"%m%d")_${test_item}
    sleep 1
fi
echo -e $count'\n'$test_item'\n'$folder'\n'StressSystem.sh: Not yet been executed > counter

###Get System Information before Test###
#Clear BMC Log
ipmitool sel time get >> $folder/BMC_sel_bef.log
ipmitool sel elist >> $folder/BMC_sel_bef.log
ipmitool sel clear >> $folder/BMC_sel_bef.log

#CPU Information
lscpu >> $folder/CPU_info_bef.log
sleep 1

#DIMM Information
dmidecode -t memory >> $folder/DIMM_All_bef.csv
dmidecode -t 17 |grep -iE $PN_DIMM >> $folder/DIMM_info_bef.csv
sleep 1

#Drive Information
lsblk >> $folder/Disk_list_bef.csv
sleep 1
nvme list >> $folder/Disk_info_bef.csv
sleep 1
#sg_map -i >> $folder/Disk_info_bef.csv
#sleep 1

#List all PCI Devices
lspci -vt >> $folder/PCI_info_bef.log
sleep 1

#Fan Information
ipmitool sdr >> $folder/Fan_All_bef.csv

###Show the Key Information###
# clear
echo -e " === System Configuration Before Test === "
echo -e "  Number of CPU($NCPU_GS): \c" >> $folder/KeyInfo.log
NCPU=$(cat $folder/CPU_info_bef.log |grep 'Socket'|awk '{print $2}')
if [ $NCPU -ne $NCPU_GS ]; then
  echo -e "${red}$NCPU${rest}" >> $folder/KeyInfo.log;
else
  echo -e "${green}$NCPU${rest}" >> $folder/KeyInfo.log;
fi

echo -e "  Number of DIMM($NDIMM_GS): \c" >> $folder/KeyInfo.log
NDIMM=$(cat $folder/DIMM_info_bef.csv |wc -l)
if [ "$NDIMM" -ne "$NDIMM_GS" ]; then
    echo -e "${red}$NDIMM${rest}" >> $folder/KeyInfo.log;
else
    echo -e "${green}$NDIMM${rest}" >> $folder/KeyInfo.log;
fi

Nd_GS=$(($NM2_GS+$NSSD_nvme_GS+$NSSD_sd_GS+$NHDD_GS))
if [ $Nd_GS -gt 1 ]; then
  if [ $NM2_GS -ne 0 ]; then
    echo -e "  Number of M.2($NM2_GS): \c" >> $folder/KeyInfo.log
	NM2=$(cat $folder/Disk_info_bef.csv |grep -icE $PN_M2)
	if [ "$NM2" -ne "$NM2_GS" ]; then
      echo -e "${red}$NM2${rest}" >> $folder/KeyInfo.log;
    else
      echo -e "${green}$NM2${rest}" >> $folder/KeyInfo.log;
    fi
  fi
  if [ $NSSD_nvme_GS -ne 0 ]; then
    echo -e "  Number of NVMe SSD($NSSD_nvme_GS): \c" >> $folder/KeyInfo.log
	NSSD_nvme=$(cat $folder/Disk_info_bef.csv |grep -icE $PN_SSDnvme)
	if [ "$NSSD_nvme" -ne "$NSSD_nvme_GS" ]; then
      echo -e "${red}$NSSD_nvme${rest}" >> $folder/KeyInfo.log;
    else
      echo -e "${green}$NSSD_nvme${rest}" >> $folder/KeyInfo.log;
    fi
  fi
  if [ $NSSD_sd_GS -ne 0 ]; then
    echo -e "  Number of SSD($NSSD_sd_GS): \c" >> $folder/KeyInfo.log
	NSSD_sd=$(cat $folder/Disk_info_bef.csv |grep -icE $PN_SSDsd)
	if [ "$NSSD_sd" -ne "$NSSD_sd_GS" ]; then
      echo -e "${red}$NSSD_sd${rest}" >> $folder/KeyInfo.log;
    else
      echo -e "${green}$NSSD_sd${rest}" >> $folder/KeyInfo.log;
    fi
  fi
  if [ $NHDD_GS -ne 0 ]; then
    echo -e "  Number of HDD($NHDD_GS): \c" >> $folder/KeyInfo.log
	NHDD=$(cat $folder/Disk_info_bef.csv |grep -icE $PN_HDD)
	if [ "$NHDD" -ne "$NHDD_GS" ]; then
      echo -e "${red}$NHDD${rest}" >> $folder/KeyInfo.log;
    else
      echo -e "${green}$NHDD${rest}" >> $folder/KeyInfo.log;
    fi
  fi
fi

Nfan=0
for (( i=1 ; i<=$NFan_GS ; i++)); do
  Fan_speed=$(cat $folder/Fan_All_bef.csv|grep "SYS_FAN" |awk '{print $3}'|sed -n $i'p')
  Fan_speed=${Fan_speed/*[:alpha:]*/1}
  if [ $Fan_speed -gt $Fan_spec ] ; then
    Nfan=$(($Nfan+1))
  fi
done

echo -e "  Number of Fan($NFan_GS): \c" >> $folder/KeyInfo.log
if [ "$Nfan" -ne "$NFan_GS" ]; then
  echo -e "${red}$Nfan${rest}" >> $folder/KeyInfo.log;
else
  echo -e "${green}$Nfan${rest}" >> $folder/KeyInfo.log;
fi

echo -e "  NIC Card: \c" >> $folder/KeyInfo.log
NIC=$(cat $folder/PCI_info_bef.log |grep -icE "$PN_NIC" )
if [ "$NIC" -ne 0 ]; then
    echo -e "${green}NIC Card is detected${rest}" >> $folder/KeyInfo.log;
else
    echo -e "${red}NIC Card is NOT detected${rest}" >> $folder/KeyInfo.log;
fi

#echo -e "  PCIe VGA Card: \c"
#VGA=$(cat $folder/PCI_info_bef.log |grep -icE "$Brand_VGA")
#if [ "$VGA" -ne 0 ]; then
#    echo -e "${green}VGA Card is detected${rest}";
#else
#    echo -e "${red}VGA Card is NOT detected${rest}";
#fi

echo "$(cat $folder/KeyInfo.log)"
sleep 3

count=$(sed -n '1p' counter)
test_item=$(sed -n '2p' counter)
folder=$(sed -n '3p' counter)

cat /etc/os-release | sed 's/^/OS: &/g' >> $folder/System_config.txt
ipmitool mc info | grep "Firmware Revision" | sed 's/^.*: //g' | sed 's/^/BMC: &/g' >> $folder/System_config.txt 
dmidecode -s bios-version | sed 's/^/BIOS: &/g' >> $folder/System_config.txt

echo -e "\nCPU:" >> $folder/System_config.txt
lscpu >> $folder/System_config.txt

echo -e "\nSSD & HDD:" >> $folder/System_config.txt
echo -e "NVMe list:" >> $folder/System_config.txt
nvme list >> $folder/System_config.txt
echo -e "Block device list:" >> $folder/System_config.txt
lsblk >> $folder/System_config.txt

echo -e "\nDIMM:" >> $folder/System_config.txt
dmidecode -t 17 >> $folder/System_config.txt


### Input Interface ###
echo -e ""
read -p "Please press <Y/N> to continue/stop the stress script: " run_stress
until echo $run_stress | grep -iqwE "y|yes|n|no"
    do
        read -p "Please press (Y/N) to continue/stop the stress script: " run_stress
    done
    if echo $run_stress | grep -iqwE "n|no" ; then
        exit 0
    fi


read -p "Please input the run time(s) for the $test_item <Must be longer than 180(s)>:" run_time

checkfolder=$(sed -n '4p' counter | awk '{print $2}')
if [ x$checkfolder = x'Have' ]; then
    echo " You have executed StressSystem for the test item($test_item)"
    until echo $choice | grep -iqwE "y|yes|n|no"
    do
        read -p " Continue (y/n)?" choice
    done
    if echo $choice | grep -iqwE "n|no" ; then
        exit 0
    fi
fi
echo -e $count"\n"$test_item"\n"$folder"\n"Stress.sh: Have been executed > counter

# clear
echo -e "${whitebg}==== Runing the Stress Script... ====${rest}"


### Catch diff log & clear system log ###
# if [ $count -eq "1" ] ; then
  # rm -rf diff_log
  # mkdir diff_log
  # lsblk > diff_log/lsblk.log
  # lsblk | wc -l > diff_log/lsblk_count.log
  # nvme list | grep "/dev/nvme" | awk '{print $1,$2,$3,$4}' >> diff_log/nvme-list.log
  # dmidecode -t memory | grep -A16 "Memory Device" | grep "Size" > diff_log/dimm.log
  # ifconfig -a | grep "flags" | awk 'NR==1{print $1}' >> diff_log/ifconfig.log
  # ifconfig -a | grep "netmask" | awk 'NR==1{print $2}' >> diff_log/ifconfig.log
  # echo -e "${yellow} remove diff log & catch new diff log ${rest}"
# fi 
 
MemoryFree=$(cat /proc/meminfo | grep -i "MemFree" | awk '{print $2}')
MemoryTest=$(($MemoryFree/1024*3/5))
echo -e " Test Memory Size: ${yellow}$MemoryTest${rest} MB"


### Catch before log ###
mkdir $folder/log

ipmitool sel elist >> $folder/log/before_sel.log
dmesg |grep -iE "error|fail|critical|warning" >> $folder/log/before_dmesg.log
cat /var/log/messages |grep -iE "error|fail|critical|warning" >> $folder/log/before_messages.log
# cat /var/log/mcelog |grep -iE "error|fail|critical|warning" >> $folder/log/before_mcelog.log
lsblk >> $folder/log/before_lsblk.log
lsblk | wc -l >> $folder/log/before_lsblk_count.log
nvme list | grep "/dev/nvme" | awk '{print $1,$2,$3,$4}' >> $folder/log/before_nvme-list.log
dmidecode -t memory | grep -A16 "Memory Device" | grep "Size" >> $folder/log/before_dimm.log
ifconfig -a | grep "flags" | awk 'NR==1{print $1}' >> $folder/log/before_ifconfig.log
ifconfig -a | grep "netmask" | awk 'NR==1{print $2}' >> $folder/log/before_ifconfig.log

disklist=($(lsblk | grep "disk" | awk '{print$1}'))
for disk in ${disklist[@]}; do
 smartctl -a /dev/$disk >> $folder/log/before_$disk.log
done

echo -e "${blue} catch before log finish${rest}"


### Compare before system log ###
#echo -e "${blue} compare system log ...${rest}"
# clear
#echo -e " === Before Test Summary === " >> $folder/log/summary_before.log
#sudo timedatectl | grep "RTC time" | sed 's/^.*R/  R/g' >> $folder/log/summary_before.log

#diff $folder/log/before_dimm.log diff_log/dimm.log
#if [ $? = 0 ]; then
#  echo -e "  check dimm      ${green} PASS ${rest}" >> $folder/log/summary_before.log
#else
#  echo -e "  check dimm      ${red} Fail ${rest}" >> $folder/log/summary_before.log
#fi

#diff $folder/log/before_nvme-list.log diff_log/nvme-list.log
#if [ $? = 0 ]; then
#  echo -e "  check NVMe      ${green} PASS ${rest}" >> $folder/log/summary_before.log
#else
#  echo -e "  check NVMe      ${red} Fail ${rest}" >> $folder/log/summary_before.log
#fi

#diff $folder/log/before_lsblk_count.log diff_log/lsblk_count.log
#if [ $? = 0 ]; then
#  echo -e "  check lsblk     ${green} PASS ${rest}" >> $folder/log/summary_before.log
#else
#  echo -e "  check lsblk     ${red} Fail ${rest}" >> $folder/log/summary_before.log
#fi

#diff $folder/log/before_ifconfig.log diff_log/ifconfig.log
#if [ $? = 0 ]; then
#  echo -e "  check ifconfig  ${green} PASS ${rest}" >> $folder/log/summary_before.log
#else
#  echo -e "  check ifconfig  ${red} Fail ${rest}" >> $folder/log/summary_before.log
#fi

#if [ $(cat $folder/log/summary_before.log | grep -c "Fail") -ne 0 ] ; then
#  echo  -e " ***  ${red} Stress Pause Please Check system Config ${rest} *** "  
#  cat $folder/log/summary_before.log
#  if echo $Still_Stress | grep -iqwE "n|no" ; then
#    exit 0
#  fi
#fi

#if [ $(cat $folder/log/summary_before.log | grep -c "Fail") -eq 0 ] ; then
#  cat $folder/log/summary_before.log
#fi


### Stress System ###
echo -e " === Stressing System === "
time_HDD=$(($run_time+$de_time))        # Time for stressing HDD (second)
time_CPU_DIMM=$run_time                 # Time for stressing CPU/DIMM (second)


if echo $Stress_CPU | grep -iqwE "y|yes" ; then
  echo " >> Start CPU stress"
  if [ $(lscpu | grep -ciw "Intel") -ne 0 ] ; then
    ./ptumon -t $(($run_time+5)) >> $folder/CPU_ptumon.txt&
    ./ptugen -ct 2 -cp 80 -t $time_CPU_DIMM -y >> $folder/CPU_ptugen.txt&
	# ./ptugen -mp 50 -mt 3 -t $time_CPU_DIMM > $folder/CPU_ptugen.txt&
	echo " "
  elif [ $(lscpu | grep -ciw "AMD") -ne 0 ] ; then
    #echo -e "AMDSST --NoGui --ServerMode False --AutoStart True --modules --processor.enable True --Memory.enable True --LogPath=$folder/ --RunTime $time_CPU_DIMM >> $folder/CPU_AMDSST.txt" > CPU_AMDSST.sh
    # AMDSST --NoGui True --ServerMode False --AutoStart True --Modules --Processor.Fpu.Enable=true --LogPath=$folder/ --RunTime $time_CPU_DIMM&
    echo -e "./../AMD/SystemStressTest/AMDSST --NoGui --Modules --Processor.enable=True --Runtime $time_CPU_DIMM --ServerMode=false --LogPath=$folder/ >> $folder/CPU_AMDSST.txt" > CPU_AMDSST.sh
    screen -dm sh CPU_AMDSST.sh
  else
	echo -e "${red}Can't identify CPU brand${rest}"
  fi
fi

if echo $Stress_DIMM | grep -iqwE "y|yes" ; then
  echo " >> Start DIMM stress"
  stressapptest --cc_test -s $time_CPU_DIMM -M $MemoryTest -m 48 -W -f stress.tmp -l $folder/stressapp_DIMM.log -i 2 > $folder/stressapp.log&
  sleep 10
fi

disk_boot=$(lsblk |grep -B3 "/boot/" |sed -n '1p' |awk '{print $1}')
if echo $Stress_Disk | grep -iqwE "y|yes" ; then
  echo " >> Start Drive stress"
  disk_stress=($(lsblk |grep "disk" |grep -v $disk_boot |awk '{print $1}'))
  iostat -dm 1 $(($time_HDD+5)) > $folder/Disk_iostat.log&  # Monitor the HDD IO
  for disk in ${disk_stress[@]}; do
    fio --filename=/dev/"$disk" -direct=1 -iodepth=64 -ioengine=libaio -rw=rw -bs=128k -numjobs=1 -runtime=$time_HDD -group_reporting -name=stress -time_based -output=$folder/fio_"$disk".log > $folder/fio"$disk".csv&
	# echo $disk
  done 
fi

if echo $Stress_NIC | grep -iqwE "y|yes" ; then
  echo " >> Start Network stress"
  rm -rf $folder/Network.log
  
  if echo $Server_Client | grep -iqwE "c|client" ; then
    # ifconfig eth0 192.168.19.102
    # sleep 1
    time_Network=$(($time_HDD+5))
    run_Network=$(($time_Network/5))
    sleep 20
    for i in $(seq 1 $run_Network);
    do
      echo $i
      # iperf -c $Server_ip -t 5 -w 256K -P 8 -p 501 | grep "SUM" | tee -a $folder/Network.log
	  iperf -c $Server_ip -t 5 -w 256K -p 501 >> $folder/Network.log
	  cat $folder/Network.log | tail -n 1
    done
    # iperf -c $Server_ip -t 10 -w 256K -P 8 -p 501 > $folder/Network_10s.log
	iperf -c $Server_ip -t 10 -w 256K -p 501 > $folder/Network_10s.log
	
  elif echo $Server_Client | grep -iqwE "s|server"; then
    time_Network=$(($time_HDD+75))
    iperf -s -p 501 | tee -a $folder/Network.log&
    for i in $(seq 1 $time_Network);
    do
      echo $i
      sleep 1
    done
    killall iperf
  fi
else
  time_Network=$(($time_HDD+5))
  for i in $(seq 1 $time_Network);
  do
    echo -e " Process: $i / $time_Network \r\c"
    sleep 1
  done
fi

echo -e "${blue} checking system configuration ... ${rest}"
rm -rf CPU_AMDSST.sh
rm -rf $folder/fio*.csv


### COLLECT SYSTEM STATUS & BMC LOG ###

#Get System Log after Test

ipmitool sdr >> $folder/Status.log
sleep 1
ipmitool sel time get >> $folder/BMC_sel_aft.log
ipmitool sel elist >> $folder/BMC_sel_aft.log
sleep 1

#CPU Information
lscpu >> $folder/CPU_info_aft.log
sleep 1

#DIMM Information
dmidecode -t memory >> $folder/DIMM_All_aft.csv
dmidecode -t 17 | grep -iE $PN_DIMM >> $folder/DIMM_info_aft.csv
sleep 1

#Drive Information
lsblk >> $folder/Disk_list_aft.csv
sleep 1
nvme list >> $folder/Disk_info_aft.csv
sleep 1
#sg_map -i >> $folder/Disk_info_aft.csv
#sleep 1

#Fan Information
ipmitool sdr >> $folder/Fan_All_aft.csv

#List all PCI Devices
lspci -vt >> $folder/PCI_info_aft.log
sleep 1


### Show the Key Information ###
echo -e " ==== System Configuration After Test ==== "
echo -e "  Number of CPU($NCPU_GS): \c" >> $folder/TestResult.log
NCPU=$(cat $folder/CPU_info_aft.log |grep 'Socket'|awk '{print $2}')
if [ $NCPU -ne $NCPU_GS ]; then
  echo -e "${red}$NCPU${rest}" >> $folder/TestResult.log;
else
  echo -e "${green}$NCPU${rest}" >> $folder/TestResult.log;
fi

echo -e "  Number of DIMM($NDIMM_GS): \c" >> $folder/TestResult.log
NDIMM=$(cat $folder/DIMM_info_aft.csv |wc -l)
if [ $NDIMM -ne $NDIMM_GS ]; then
  echo -e "${red}$NDIMM${rest}" >> $folder/TestResult.log;
else
  echo -e "${green}$NDIMM${rest}" >> $folder/TestResult.log;
fi

Nd_GS=$(($NM2_GS+$NSSD_nvme_GS+$NSSD_sd_GS+$NHDD_GS))
if [ $Nd_GS -gt 1 ]; then
  if [ $NM2_GS -ne 0 ]; then
    echo -e "  Number of M.2($NM2_GS): \c" >> $folder/TestResult.log
	NM2=$(cat $folder/Disk_info_aft.csv |grep -icE $PN_M2)
	if [ "$NM2" -ne "$NM2_GS" ]; then
      echo -e "${red}$NM2${rest}" >> $folder/TestResult.log;
    else
      echo -e "${green}$NM2${rest}" >> $folder/TestResult.log;
    fi
  fi
  if [ $NSSD_nvme_GS -ne 0 ]; then
    echo -e "  Number of NVMe SSD($NSSD_nvme_GS): \c" >> $folder/TestResult.log
	NSSD_nvme=$(cat $folder/Disk_info_aft.csv |grep -icE $PN_SSDnvme)
	if [ "$NSSD_nvme" -ne "$NSSD_nvme_GS" ]; then
      echo -e "${red}$NSSD_nvme${rest}" >> $folder/TestResult.log;
    else
      echo -e "${green}$NSSD_nvme${rest}" >> $folder/TestResult.log;
    fi
  fi
  if [ $NSSD_sd_GS -ne 0 ]; then
    echo -e "  Number of SSD($NSSD_sd_GS): \c" >> $folder/TestResult.log
	NSSD_sd=$(cat $folder/Disk_info_aft.csv |grep -icE $PN_SSDsd)
	if [ "$NSSD_sd" -ne "$NSSD_sd_GS" ]; then
      echo -e "${red}$NSSD_sd${rest}" >> $folder/TestResult.log;
    else
      echo -e "${green}$NSSD_sd${rest}" >> $folder/TestResult.log;
    fi
  fi
  if [ $NHDD_GS -ne 0 ]; then
    echo -e "  Number of HDD($NHDD_GS): \c" >> $folder/TestResult.log
	NHDD=$(cat $folder/Disk_info_aft.csv |grep -icE $PN_HDD)
	if [ "$NHDD" -ne "$NHDD_GS" ]; then
      echo -e "${red}$NHDD${rest}" >> $folder/TestResult.log;
    else
      echo -e "${green}$NHDD${rest}" >> $folder/TestResult.log;
    fi
  fi
fi

Nfan=0
for (( i=1 ; i<=$NFan_GS ; i++)); do
  # Fan_speed=$(cat $folder/Fan_All_aft.csv|grep "SYS FAN" | sed -n 's/.*'FAN............'//p'|sed -n 's/'" .*$"'//p'|sed -n $i'p') 
  Fan_speed=$(cat $folder/Fan_All_aft.csv|grep "SYS_FAN" |awk '{print $3}'|sed -n $i'p')
  Fan_speed=${Fan_speed/*[:alpha:]*/1}
  if [ $Fan_speed -gt $Fan_spec ] ; then
	Nfan=$(($Nfan+1))
  fi
done

echo -e "  Number of Fan($NFan_GS): \c" >> $folder/TestResult.log
if [ $Nfan -ne $NFan_GS ]; then
  echo -e "${red}$Nfan${rest}" >> $folder/TestResult.log;
else
  echo -e "${green}$Nfan${rest}" >> $folder/TestResult.log;
fi

echo -e "  NIC Card: \c" >> $folder/TestResult.log;
if [ "$NIC" -ne 0 ]; then
    echo -e "${green}NIC Card is detected${rest}" >> $folder/TestResult.log;
else
    echo -e "${red}NIC Card is NOT detected${rest}" >> $folder/TestResult.log;
fi

if echo $Stress_CPU | grep -iqwE "y|yes" ; then
  echo -e "  CPU Stress Result: \c" >> $folder/TestResult.log
  if [ $(lscpu | grep -ciw "Intel") -ne 0 ] ; then
    cpu_check=0
    cpu_W=($(cat $folder/CPU_ptugen.txt |grep "CPU.*100" |awk '{print $16}' |sed 's/^.*=//g' |sed 's/W.*$//g' |head -n -5 |tail -n +5))
	cpu_W_floor=$(echo "scale=2; $CPU_spec*1.05" |bc)
	cpu_W_bottom=$(echo "scale=2; $CPU_spec*0.95" |bc)
    for i in ${cpu_W[@]}; do
      if [ $(echo "$i < $cpu_W_bottom" |bc) -eq 1 ] || [ $(echo "$i > $cpu_W_floor" |bc) -eq 1 ]; then
        cpu_check=$(($cpu_check+1))
      fi
    done
    if [ $cpu_check -ne 0 ]; then
      echo -e "${red}FAIL${rest}" >> $folder/TestResult.log;
    else
      echo -e "${green}PASS${rest}" >> $folder/TestResult.log;
    fi
  elif [ $(lscpu | grep -ciw "AMD") -ne 0 ] ; then
	cpu_check=$(cat $folder/*.json |grep -iEA1 "Name.*StressModule" | sed -n '2p' | sed 's/[", ]//g' | sed 's/^.*://g')
	if [ x$cpu_check = x'PASS' ]; then
      echo -e "${green}PASS${rest}" >> $folder/TestResult.log;
    else
      echo -e "${red}FAIL${rest}" >> $folder/TestResult.log;
    fi
  else
	echo -e "${red}Can't identify CPU brand${rest}" >> $folder/TestResult.log;
  fi
fi

if echo $Stress_DIMM | grep -iqwE "y|yes" ; then
  echo -e "  DIMM Stress Result:" >> $folder/TestResult.log
  cat $folder/stressapp_DIMM.log |grep "Status" | sed -n 's/.*':'//p' >> $folder/TestResult.log
fi

if echo $Stress_Disk | grep -iqwE "y|yes" ; then
  echo -e "  Drive Performance:" >> $folder/TestResult.log
  for disk in ${disk_stress[@]}; do
    Pf_nvme_SR=$(cat $folder/fio_"$disk".log |grep "read" |grep "IOPS" | sed -n 's/.*'BW='//p'|sed -n 's/'" (.*$"'//p')
    Pf_nvme_SW=$(cat $folder/fio_"$disk".log |grep "write" |grep "IOPS" | sed -n 's/.*'BW='//p'|sed -n 's/'" (.*$"'//p')
    echo -e "   The performance ${skyblue}<Sequential Read;Write>${rest} for ${yellow}"$disk"${rest} is ${green}$Pf_nvme_SR;$Pf_nvme_SW${rest} " >> $folder/TestResult.log
  done 
fi

echo "$(cat $folder/TestResult.log)"

if echo $Stress_NIC | grep -iqwE "y|yes" ; then
  echo -e "  Network Stress Result:" >> $folder/TestResult_NIC.log
  cat $folder/Network.log | grep "SUM]  0" >> $folder/TestResult_NIC.log
  echo "$(cat $folder/TestResult_NIC.log | head -n -1 | tail -n 5)" 
fi

### Catch after log ###
ipmitool sel elist >> $folder/log/after_sel.log
dmesg |grep -iE "error|fail|critical|warning" >> $folder/log/after_dmesg.log
cat /var/log/messages |grep -iE "error|fail|critical|warning" >> $folder/log/after_messages.log
# cat /var/log/mcelog |grep -iE "error|fail|critical|warning" >> $folder/log/after_mcelog.log
lsblk >> $folder/log/after_lsblk.log
lsblk | wc -l >> $folder/log/after_lsblk_count.log
nvme list | grep "/dev/nvme" | awk '{print $1,$2,$3,$4}' >> $folder/log/after_nvme-list.log 
dmidecode -t memory | grep -A16 "Memory Device" | grep "Size" >> $folder/log/after_dimm.log
ifconfig -a | grep "flags" | awk 'NR==1{print $1}' >> $folder/log/after_ifconfig.log
ifconfig -a | grep "netmask" | awk 'NR==1{print $2}' >> $folder/log/after_ifconfig.log

disklist=($(lsblk | grep "disk" | awk '{print$1}'))
for disk in ${disklist[@]}; do
 smartctl -a /dev/$disk >> $folder/log/after_$disk.log
done

echo -e "${blue} catch after log finish ${rest}"


### Compare after test system log ###
#echo -e "${blue} compare system log ... ${rest}"
echo -e " === After Test Summary === " >> $folder/log/summary.log
#sudo timedatectl | grep "RTC time" | sed 's/^.*R/  R/g' >> $folder/log/summary.log

#diff $folder/log/after_nvme-list.log diff_log/nvme-list.log
#if [ $? = 0 ]; then
#  echo -e "  check NVMe      ${green} PASS ${rest}" >> $folder/log/summary.log
#else
#  echo -e "  check NVMe      ${red} Fail ${rest}" >> $folder/log/summary.log
#fi

#diff $folder/log/after_lsblk_count.log diff_log/lsblk_count.log
#if [ $? = 0 ]; then
#  echo -e "  check lsblk     ${green} PASS ${rest}" >> $folder/log/summary.log
#else
#  echo -e "  check lsblk     ${red} Fail ${rest}" >> $folder/log/summary.log
#fi 

#diff $folder/log/after_dimm.log diff_log/dimm.log
#if [ $? = 0 ]; then
#  echo -e "  check dimm      ${green} PASS ${rest}" >> $folder/log/summary.log
#else
#  echo -e "  check dimm      ${red} Fail ${rest}" >> $folder/log/summary.log
#fi 

#diff $folder/log/after_ifconfig.log diff_log/ifconfig.log
#if [ $? = 0 ]; then
#  echo -e "  check ifconfig  ${green} PASS ${rest}" >> $folder/log/summary.log
#else
#  echo -e "  check ifconfig  ${red} Fail ${rest}" >> $folder/log/summary.log
#fi 


  if [ $(lscpu | grep -ciw "Intel") -ne 0 ] ; then
    echo " ===PTUgen=== " >> $folder/log/summary.log
    if echo $Stress_CPU | grep -iqwE "y|yes" ; then
	  if [ $cpu_check -ne 0 ] ; then
        echo -e "${red}FAIL${rest}" >> $folder/log/summary.log
      else
        echo -e "${green}PASS${rest}" >> $folder/log/summary.log
      fi
	else
	  echo -e "  N/A" >> $folder/log/summary.log
	fi
  fi
  if [ $(lscpu | grep -ciw "AMD") -ne 0 ] ; then
    echo " ===AMDSST=== " >> $folder/log/summary.log
	if echo $Stress_CPU | grep -iqwE "y|yes" ; then
	  echo -e "  Processor Errors: \c" >> $folder/log/summary.log
	  cat $folder/*.json |grep -iwEA5 "Processor" |sed -n '6p' |sed 's/[[:alpha:][:punct:] ]//g' >> $folder/log/summary.log
	else
	  echo -e "  N/A" >> $folder/log/summary.log
	fi
  fi

echo " ===Stressapptest=== " >> $folder/log/summary.log
if echo $Stress_DIMM | grep -iqwE "y|yes" ; then
  tail -n 2 $folder/stressapp.log | sed 's/^/  &/g' >> $folder/log/summary.log
else
  echo -e "  N/A" >> $folder/log/summary.log
fi

echo " ===fio=== " >> $folder/log/summary.log
N_SSD_HDD=$(($NM2_GS+$NSSD_nvme_GS+$NHDD_GS+$Nsd_M2_GS+$NSSD_sd_GS))

if [ $N_SSD_HDD = 1 ] ; then
  echo -e "  N/A" >> $folder/log/summary.log
elif echo $Stress_Disk | grep -iqwE "y|yes" ; then
  for disk in ${disk_stress[@]}; do
    echo -e $disk" \c" | sed 's/^/  &/g' >> $folder/log/summary.log 
    cat $folder/fio_"$disk".log | grep err | awk '{print $4 $5 }' >> $folder/log/summary.log
  done
else
  echo -e "  N/A" >> $folder/log/summary.log
fi

cat $folder/log/summary.log

sleep 2
dmesg -c >> $folder/log/dmesg_c.log

cat /dev/null > /var/log/messages
# cat /dev/null > /var/log/mcelog
