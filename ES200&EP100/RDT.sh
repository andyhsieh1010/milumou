#!/bin/bash
#Project : All Linux System
#Version :2020/8/6
#ipmitool raw 0x3e 0x02 0xa1 0x01 100
clear
#Parameter
i=0
Mem="`free -m|grep -i "Mem:"|awk '{print$4*0.6}'`"
time=`date +%Y-%m-%d_%H-%M`

script=$0
script=`readlink -f $script`
script_path=${script%/*}
realpath=$(readlink -f $script_path)

mkdir "$realpath"/"$time"
log_dir=""$realpath"/"$time""

err_key="error\|Error\|fatal\|Fatal\|critical\|Critical\|panic\|fail\|Fail\|warning\|Warning"
_ask="`echo -e "Test time : $1 Seconds\nType Y start stress\nType N break stress\nYour Choise? (Y/N) : "`"


#Function
os_check(){	
	os="`lsblk|grep -i "boot\|centos"|egrep -o 'nvme[0-9]{1,2}n1'|uniq`"
	target=(`lsblk|awk '{print$1}'|egrep -o  'sd[a-z]|nvme[0-9]{1,2}n1'|uniq |grep -v ${os}`)
}

log_check () {
	ipmitool sdr elist > "$log_dir"/sdr_elist.log
	ipmitool sensor > "$log_dir"/sensor.log
	ipmitool sel list > "$log_dir"/sel_"$1".log
	ipmitool sel elist > "$log_dir"/sel_"$1".log
    ipmitool sel list -vvv > "$log_dir"/sel_"$1"_-vvv.log 2>&1
	ipmiutil sel > "$log_dir"/sel_util_"$1".log
	(date +%Y-%m-%D\ %H:%M ;ipmitool sdr) > "$log_dir"/sdr_"$1".log
	(date +%Y-%m-%D\ %H:%M ;ipmitool sdr elist) > "$log_dir"/sdr_elist_"$1".log
	(date +%Y-%m-%D\ %H:%M ;ipmitool sensor) > "$log_dir"/sdr_sensor_"$1".log
	lspci -vvv > "$log_dir"/pci_"$1".log
	lspci -vt > "$log_dir"/pci_-vt_"$1".log
	dmidecode  > "$log_dir"/dmi_"$1".log
	dmesg > "$log_dir"/dmesg_"$1".log
	lsblk > "$log_dir"/lsblk_"$1".log
	nvme list > "$log_dir"/nvme_list_"$1".log
	cat /var/log/messages > "$log_dir"/varlog_"$1".log
	cat /var/log/mcelog > "$log_dir"/mcelog_"$1".log
	mkdir "$log_dir"/"$1"_var
	cp /var/log/*messages* "$log_dir"/"$1"_var
	rm -f /var/log/*messages*
	echo "" > /var/log/messages
}
check_config () {
	echo -n "CPU's Qty: " >> "$log_dir"/$1_Config.txt
	dmidecode -t 4 |grep "Socket Designation: " -c >> "$log_dir"/$1_Config.txt
	echo -n "DIMM's Qty: " >> "$log_dir"/$1_Config.txt
	dmidecode -t 17 |grep "Manufacturer: Samsung\|Manufacturer: SK Hynix" -c >> "$log_dir"/$1_Config.txt
	echo -n "NVMe SSD Count: " >> "$log_dir"/$1_Config.txt
	nvme list |grep "/dev" -c >> "$log_dir"/$1_Config.txt
	echo "" >> "$log_dir"/$1_Config.txt
	
	fuck="`lspci -vvv |grep -i "Mellanox Technologies MT27800" |awk '{print$1}'`"
	for i in $fuck;do
	lspci -s $i -vvv >> "$log_dir"/$1_Config.txt
	done	


	check=`diff "$realpath"/GoldenConfig.txt "$log_dir"/$1_Config.txt`

	if [[ -z $check ]];then
        	echo "$1 config check Result : PASS" |tee -a "$log_dir"/Summary.log
	else
        	echo "$1 config check Result : FAIL" |tee -a "$log_dir"/Summary.log
	fi

}

#Check test time
	if [ -z $1 ];then
		echo "Please input time by seconds before stress.sh
		function_check Usage: 
		./function_check.sh <Number of seconds>
		Exsample : ./stress.sh 60"
		exit 0
	fi

# Confirm your test time
#	until [ $i = 3 ];do
#	read -p "${_ask}" ch
#	case $ch in
#		Y|y)
#		echo "Start stress"
#		break
#		;;
#		N|n)
#		echo "EXIT SCRIPT"
#		exit
#		;;
#		*)
#		i=$(($i+1))
#		clear
#		echo "Please type y or n (Error type : $i/3 )"
#		echo ""
#		sleep 3
#		;;
#	esac
#	done	

#Before test log
    echo "Sorting log berfore function stress."
	#mkdir /root/Function/"$time"
	echo "Clear old log"
	ipmitool sel elist >> "$log_dir"/sel_elist_backup.log
	ipmitool sel list -vvv >> "$log_dir"/sel_-vvv_backup.log
	ipmiutil sel >> "$log_dir"/sel_util_backup.log
	ipmitool sel clear
	
	echo "#############################################"
	echo "#             Dump pre test log             #"
	echo "#############################################"
	log_check Bf
	check_config Bf
	echo ""
	echo "#############################################"
	echo "#              Finish dump log              #"
	echo "#############################################"
	
	cycle=(`ls -l "$realpath"/ |grep "drwxr" -c`)
#Main test  
	echo "#############################################"
	echo "      Start RDT stressing cycle: $cycle      "
	echo "#############################################"
	sh "$realpath"/sdr_collect.sh "$1" "$log_dir" "$realpath" &
	
	echo "Start test $time full stress : $1 Seconds" |tee -a ""$log_dir"/Summary.log"
	
	iperf_t=$(($1+$1/10+30))
	iperf -s -i 5 -t $iperf_t |tee -a ""$log_dir"/iperf_s.log" &
#	iperf -c 192.168.0.1 -i 5 -P 5 -t $1 |tee -a ""$log_dir"/iperf.log" &

	os_check
    for i in "${target[@]}";do
		smartctl -a /dev/${i} >> "$log_dir"/${i}_smart.log
		nvme smart-log /dev/"$i" >> "$log_dir"/"${i}"_smart_bf.log
        fio --filename=/dev/$i -direct=1 -iodepth=64 -ioengine=libaio -rw=rw -bs=4k -numjobs=4 -runtime=$1 -group_reporting -name=stress -time_based --log_avg_msec=1000 --write_iops_log="$log_dir"/"${i}"_IOpsDiag.txt >> "$log_dir"/"${i}".log &
		
    done
    	stressapptest -s $1 --pause_delay $1 -M "${Mem}" -W -f stress.tmp -l stress.outfile -i 2 >> "$log_dir"/Stressapp.log  &
	#ptugen -y -ct 2 -cp 80 -t $1 >> "$log_dir"/ptugne.log &
	#ptumon  -i 1000 -t $1 >> "$log_dir"/ptumon.log &
	#ptu -y -b 1 -ct 1 -mp 50 -t $1 -log -q &
	
	sleep $1
    wait
	echo "#############################################"
	echo "#               End stressing               #"
	echo "#############################################"

#After test log
	echo "Now sorting log after test."
	log_check Af
	check_config Af
	
	for i in "${target[@]}";do
		nvme smart-log /dev/$i >> "$log_dir"/"${i}"_smart_af.log
    done
#Compare bf & af log

	echo "Compare log and output result"
	diff "$log_dir"/sel_Bf.log "$log_dir"/sel_Af.log > "$log_dir"/sel_fail 2>&1
    diff "$log_dir"/sel_Bf_-vvv.log "$log_dir"/sel_Af_-vvv.log > "$log_dir"/sel_-vvv_fail 2&>1
	diff "$log_dir"/pci_Bf.log "$log_dir"/pci_Af.log > "$log_dir"/pci_fail 2>&1
	diff "$log_dir"/dmi_Bf.log "$log_dir"/dmi_Af.log > "$log_dir"/dmi_fail 2>&1+
    diff "$log_dir"/nvme_list_Bf.log "$log_dir"/nvme_list_Af.log > "$log_dir"/nvme_list_fail 2>&1
	diff "$log_dir"/lsblk_Bf.log "$log_dir"/lsblk_Af.log > "$log_dir"/lsblk_fail 2>&1
    


#Check all result
	echo "Start function check at ${time} "
	echo "Stress Time : ${1} Seconds" |tee -a "$log_dir"/Summary.log
	list=(`ls "$log_dir"/*_fail`)
	for c in ${list[@]};do
		if [ -z `cat $c|grep -i "${err_key}"|grep -v "$BYPASS"` ];then
			echo "$c Not found error
Result : PASS" |tee -a "$log_dir"/Summary.log
		else	
			echo "$c Found something error
Result : FAIL
===========Fail infomation==========
`cat $c|grep -i ${err_key}`"|tee -a "$log_dir"/Summary.log
		fi
	done
	
	if [[ "`cat "$log_dir"/Stressapp.log |grep -i -o "PASS"`" = "PASS" ]];then
		echo "stressapptest Result : PASS" >> "$log_dir"/Summary.log
	else
		echo "stressapptest Result : Fail" >> "$log_dir"/Summary.log
	fi
	list_fio=(`ls "$log_dir"/nvme*n1.log`)
	for f in ${list_fio[@]};do
		if [[ -z `cat $f|grep -i "${err_key}"` ]];then
			echo "FIO ${f} Result : PASS" >> "$log_dir"/Summary.log
		else
			echo "FIO ${f} Result : FAIL" >> "$log_dir"/Summary.log
		fi
	done
	if [[ -z `cat "$log_dir"/Summary.log|grep -i "Result : FAIL"` ]];then
		echo "Test : ${time} Summary is PASS" >> "$log_dir"/Summary.log
		echo "Test Cycle $cycle is Pass (Test time is $time)" >> "$realpath"/Test_Summary_1.txt
	else
		echo "Test  ${time} Summary is Fail" >> "$log_dir"/Summary.log
		echo "Test cycle $cycle is Fail (Test time is $time)" >> "$realpath"/Test_Summary_1.txt
	fi

#Sorting All log
	#cd /root/Function/
    mv "$realpath"/stress.* "$log_dir"
    #mv Bf_Config.txt Af_Config.txt "$log_dir"
    #mv /root/ptu/log "$log_dir"
	#sleep 10
    clear
	cat ""$log_dir"/Summary.log"
	end_time=`date +%Y-%m-%d_%H-%M` 
	echo "Test Complete at $end_time" |tee -a ""$log_dir"/Summary.log"
	echo "NIC Status: " |tee -a ""$log_dir"/Summary.log"
	cat ""$log_dir"/iperf_s.log" |tail -n 6 |tee -a ""$log_dir"/Summary.log"
	cat ""$log_dir"/iperf.log" |tail -n 6 |tee -a ""$log_dir"/Summary.log"
	ipmitool sel clear
	#rm -f /root/Function/1
#sshpass -p 111111 scp /root/Function/Test_Summary_1.txt root@[192.169.0.10]:/root/JC_RDT_Result/
#sleep 300
#init 0
