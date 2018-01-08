#!/bin/bash

cur_dir=`pwd`
#awk '{if(NR>1)print}' automerge.conf > temp_automerge.conf
branch_count=`head -1 $cur_dir/temp_automerge.conf | tr '|' '\n' | wc -l`
awk '{if(NR>1)print}' push.conf > temp_push.conf

while IFS="|"  read -r fDir ;
do
validate()
{
    git branch -r > $cur_dir/branches.txt
    awk '{gsub(/origin\//," ")}1' $cur_dir/branches.txt > $cur_dir/branches1.txt
    all_branches=`sed -e "/HEAD/d" $cur_dir/branches1.txt`
    echo $all_branches | grep -F -q -w "$1";
}

repo_dir()
{
    if [[ $fDir = "" ]] || [[ $flag_dir == "invalid" ]]
      then
        echo "Codebase directory :"
        read fDir < /dev/tty
    fi
    if [[ ${#fDir} -eq 0 ]]
      then
        flag_dir="invalid"
        echo -e "ERROR : Invalid directory!\nPlease try again"
        repo_dir
    fi
    cd $fDir 2> /dev/null && flag_dir="valid" || flag_dir="invalid"
    if [ $flag_dir == "invalid" ]
      then
        echo -e "ERROR : Invalid directory!\nPlease try again"
        repo_dir
    fi
}

for (( j=$((index)); j<=$((branch_count-1)); j++ ))
do
    echo -e "INFO : Automerge initiated"
    branch=`awk -v var=$j -v var2=$((j+1)) 'BEGIN {FS = "|"}; {print $var"|"$var2}' $cur_dir/temp_automerge.conf`
    
    for (( i=1; i<=2; ++i ));
    do
        branch_name=`echo $branch | awk -v I=$i 'BEGIN {FS = "|"}; {print $I}'`
        repo_dir
        validate "$branch_name" && flag="valid" || flag="invalid"
        
        if [[ $flag = "valid" ]]
          then
            if [[ $i == 1 ]]
              then
                awk -v var1=$branch_name 'BEGIN {FS = "|"}; {OFS = "|"}; {if (FNR == 2) {$3 = var1}; { print }}' $cur_dir/merge.conf > $cur_dir/merge1.conf
            elif [[ $i == 2 ]]
              then
                awk -v var1=$branch_name 'BEGIN {FS = "|"}; {OFS = "|"}; {if (FNR == 2) {$2 = var1}; { print }}' $cur_dir/merge1.conf > $cur_dir/merge2.conf
            fi
        else
            echo -e "ERROR : Automerge aborted!\nREASON : Invalid branch - $branch_name in automerge.conf"
            mv $cur_dir/merge2.conf $cur_dir/merge.conf &> /dev/null
            rm $cur_dir/merge1.conf &> /dev/null
            rm $cur_dir/branches.txt &> /dev/null
            rm $cur_dir/branches1.txt &> /dev/null
            rm $cur_dir/temp_push.conf &> /dev/null
            exit
        fi
    done
    mv $cur_dir/merge2.conf $cur_dir/merge.conf &> /dev/null
    rm $cur_dir/merge1.conf
    rm $cur_dir/branches.txt &> /dev/null
    rm $cur_dir/branches1.txt &> /dev/null
    cd $cur_dir
    flag_auto="true"
    export flag_auto
    ./git_merge.sh
    exit 1
done
done < temp_push.conf
rm $cur_dir/temp_push.conf &> /dev/null
echo -e "INFO : Automerge completed"
