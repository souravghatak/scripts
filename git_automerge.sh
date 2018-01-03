#!/bin/bash
branch_count=`head -1 automerge.conf | tr '|' '\n' | wc -l`
for (( j=1; j<=$((branch_count-1)); j++ ))
do
    branch=`awk -v var=$j -v var2=$((j+1)) 'BEGIN {FS = "|"}; {print $var"|"$var2}' automerge.conf`
    for (( i=1; i<=2; i++ ));
    do
        branch_name=`echo $branch | awk -v I=$i 'BEGIN {FS = "|"}; {print $I}'`
        if [[ $i == 1 ]]
          then
            awk -v var1=$branch_name 'BEGIN {FS = "|"}; {OFS = "|"}; {if (FNR == 2) {$3 = var1}; { print }}' merge.conf > merge1.conf
        elif [[ $i == 2 ]]
          then
            awk -v var1=$branch_name 'BEGIN {FS = "|"}; {OFS = "|"}; {if (FNR == 2) {$2 = var1}; { print }}' merge1.conf > merge2.conf
        fi
    done
    mv merge2.conf merge.conf &> /dev/null
    rm merge1.conf
    ./git_merge.sh
done
