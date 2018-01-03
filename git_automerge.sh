#!/bin/bash

cur_dir=`pwd`
branch_count=`head -1 automerge.conf | tr '|' '\n' | wc -l`
Dir="/home/sghatak/research/test/Repo1"
validate()
{
    git branch -r > $cur_dir/branches.txt
    awk '{gsub(/origin\//," ")}1' $cur_dir/branches.txt > $cur_dir/branches1.txt
    all_branches=`sed -e "/HEAD/d" $cur_dir/branches1.txt`
    echo $all_branches | grep -F -q -w "$1";
}

for (( j=1; j<=$((branch_count-1)); j++ ))
do
    branch=`awk -v var=$j -v var2=$((j+1)) 'BEGIN {FS = "|"}; {print $var"|"$var2}' $cur_dir/automerge.conf`
    
    for (( i=1; i<=2; ++i ));
    do
        branch_name=`echo $branch | awk -v I=$i 'BEGIN {FS = "|"}; {print $I}'`
        cd $Dir
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
            echo "ERROR : Invalid branch - $branch_name"
            mv $cur_dir/merge2.conf $cur_dir/merge.conf &> /dev/null
            rm $cur_dir/merge1.conf &> /dev/null
            rm $cur_dir/branches.txt &> /dev/null
            rm $cur_dir/branches1.txt &> /dev/null
            exit
        fi
    done
    mv $cur_dir/merge2.conf $cur_dir/merge.conf &> /dev/null
    rm $cur_dir/merge1.conf
    rm $cur_dir/branches.txt &> /dev/null
    rm $cur_dir/branches1.txt &> /dev/null
    cd $cur_dir
    ./git_merge.sh
done
