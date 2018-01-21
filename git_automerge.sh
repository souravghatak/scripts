#!/bin/bash
cur_dir=`pwd`

if [[ $direct_automerge = "true" ]]
  then
    awk '{if(NR>1)print}' automerge.conf > temp_automerge.conf
    branch_count=`head -1 $cur_dir/temp_automerge.conf | tr '|' '\n' | wc -l`
else
    branch_count=`head -1 $cur_dir/temp_automerge.conf | tr '|' '\n' | wc -l`
fi

awk '{if(NR>1)print}' merge.conf > temp_merge.conf

while IFS="|"  read -r fDir fBase fNew fURL ;
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

repo_clone()
{
    if [[ $fURL = "" ]] || [[ $flag_repo = "invalid" ]]
      then
        echo "Repo URL :"
        read fURL < /dev/tty
    fi
    if [[ ${#fURL} -eq 0 ]]
      then
        flag_repo="invalid"
        echo -e "ERROR : Invalid URL! \nPlease try again"
        repo_clone
    fi

    git clone $fURL &> /dev/null
    dir_repo=`echo $fURL | awk -F '[/.]' '{print $(NF-1)}'`
    cd $dir_repo &> /dev/null && flag_repo="valid" || flag_repo="invalid"
    if [ $flag_repo == "invalid" ]
      then
        echo -e "ERROR : Invalid URL! \nPlease try again"
        repo_clone
    fi
}

for (( j=$((index)); j<=$((branch_count-1)); j++ ))
do
    echo -e "INFO : Review the details provided in automerge.conf\n\n***********************************************************************************************\nBranch names in order of deployment('|' separated) : `cat $cur_dir/temp_automerge.conf`\n***********************************************************************************************\n\nINFO : Review the details provided in merge.conf\n\n***********************************************************************************************\nDirectory for local codebase : $fDir \nURL (Git repository URL) : $fURL \n***********************************************************************************************\n"
    echo -e "INFO : Automerge initiated"
    branch=`awk -v var=$j -v var2=$((j+1)) 'BEGIN {FS = "|"}; {print $var"|"$var2}' $cur_dir/temp_automerge.conf`
    for (( i=1; i<=2; ++i ));
    do
        branch_name=`echo $branch | awk -v I=$i 'BEGIN {FS = "|"}; {print $I}'`
        repo_dir
        repo_clone
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
done < temp_merge.conf
rm $cur_dir/temp_merge.conf &> /dev/null
echo -e "INFO : Automerge completed"
