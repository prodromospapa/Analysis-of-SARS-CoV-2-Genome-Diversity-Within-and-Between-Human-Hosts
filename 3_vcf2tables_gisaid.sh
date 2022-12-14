country=$(less country.txt) 
ram=$(grep MemTotal /proc/meminfo | awk '{print $2}')
cpu_opt=$((ram/16000000))

if [ $cpu_opt == 0 ]
then
    cpu_opt=1
fi
vcfs=$country/vcf_gisaid/*

items_per_thread=1
while [ $(echo $vcfs | wc -w) -gt $(($items_per_thread*$cpu_opt)) ]
do
    items_per_thread=$((items_per_thread+1))
done

counter=0
samples=0
total=0
command=""

for i in $vcfs
do 
    total=$(($total + $(sed '4q;d' $i | grep -o hCoV-19 | wc -l) - 1 ))
done

while [ $counter -lt $(echo $vcfs | wc -w) ]
do
    vcf2tables=""
    samples=$(($samples+1))
    for i in $(seq 1 $items_per_thread)
    do
        counter=$(($counter+1))
        new=$(echo $vcfs | cut -d ' ' -f $counter)
        if [ ! $new == "" ]
        then
          vcf2tables="$vcf2tables $new"
        fi
    done
    if [ ! "$vcf2tables" == "" ]
    then
        echo 0 > tables_progress_$samples.txt
        command="$command python3 vcf2tables_gisaid.py $vcf2tables $samples &"
    fi
done

eval " $command bash progress.sh $total 'paste -d+ tables_progress_*.txt| bc'"
wait

python3 merge_samples.py $counter
rm $country/tables_gisaid/samples_*.pickle

rm tables_progress_*.txt
echo all done 
