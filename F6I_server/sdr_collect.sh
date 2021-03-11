cycle=$(($1/180))

echo -n "Time," >"$2"/temp.txt
ipmitool sdr |cut -d '|' -f 1 |xargs |tr " " "," >>"$2"/temp.txt
cat "$2"/temp.txt > "$2"/sdr.csv

if [[ -f "$3"/sdr_all.csv ]]
then
	echo ""
else
	cat "$2"/temp.txt > "$3"/sdr_all.csv
fi


for ((i=1;i<=${cycle};i++));
do
    time=`date +%Y-%m-%d\ %H:%M`
    echo -n ""$time"," > "$2"/temp.txt
    ipmitool sdr |cut -d '|' -f 2 |cut -d " " -f 2 |xargs |tr " " "," >> "$2"/temp.txt
    cat "$2"/temp.txt >> "$2"/sdr.csv
    cat "$2"/temp.txt >> "$3"/sdr_all.csv
    echo "$time" > "$3"/in_outlet.log
    ipmitool sdr |grep "Temp_Inlet\|Temp_Outlet" |tail -n 2 >> "$3"/in_outlet.log
#    sshpass -p "111111" scp /root/in_outlet_1.log root@[192.169.0.10]:/root/JC_RDT_Result/
    
    
    sleep 180
done
