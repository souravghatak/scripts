#!/bin/sh

awk '{if(NR>1)print}' create.conf > temp_create.conf
cur_dir=`pwd`
while IFS="|"  read -r fDir fBase fNew fURL ;
do
dir_repo=""

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
        echo "Invalid directory! Please try again"
        repo_dir
    fi
    cd $fDir 2> /dev/null && flag_dir="valid" || flag_dir="invalid"  
    if [ $flag_dir == "invalid" ]
      then
        echo "Invalid directory! Please try again"
        repo_dir
    fi
}

base_branch()
{
    if [[ $fBase = "" ]] || [[ $flag = "invalid" ]]
      then
        echo "Base branch :"
        read fBase < /dev/tty
    fi
    validate $fBase && flag="valid" || flag="invalid"
    if [[ ${#fBase} -eq 0 ]]
      then
        flag="invalid"
    fi
    if [ $flag = "valid" ]
      then
        git fetch &> /dev/null
        git checkout $fBase &> /dev/null
        git pull origin $fBase &> /dev/null
    else
        echo "Invalid base branch. Please try again!"
        base_branch
    fi
}

merge_branch()
{
    if [[ $fNew = "" ]] || [[ $flag_new = "invalid" ]]
      then
        echo "Merge Branch :"
        read fNew < /dev/tty
    fi
    validate $fNew && flag_new="valid" || flag_new="invalid"
    if [[ ${#fNew} -eq 0 ]]
      then
        flag_new="invalid"
    fi
    if [ $flag_new = "valid" ]
      then
        git checkout $fNew &> /dev/null
        git pull origin $fNew &> /dev/null
    else
        echo "Invalid branch name. Please try again"
        merge_branch
    fi
}

merge()
{
    merge_var=$(git merge $fNew --no-commit --no-ff; git merge --abort 2>&1) 
    if [[ $merge_var == *"CONFLICT"* ]]
      then
        echo "There are merge conflicts. Do you want to continue merging? (Y/N)"
        read fConf < /dev/tty
        if [[ $fConf = "Y" ]]
          then
            git merge $fNew &> /dev/null
            echo "Resolve the conflicts and try again"
        elif [[ $fConf = "N" ]]
          then
            rm $cur_dir/${fBase}_diff_${fNew}.txt &> /dev/null
            git diff $fNew >> $cur_dir/${fBase}_diff_${fNew}.txt
            echo "Please consult $cur_dir/${fBase}_diff_${fNew}.txt file for the conflicts recorded and try again."
        else
            echo "Wrong input! Please try again"
            merge
        fi
    elif [[ $merge_var == *"There is no merge to abort"* ]]
      then
        git_diff=$(git diff $fNew)
        if [[ ${#git_diff} -eq 0 ]]
          then
            echo "There is nothing to merge and no difference between branch $fBase and $fNew"
        else
            rm $cur_dir/${fBase}_diff_${fNew}.txt &> /dev/null
            echo $git_diff > $cur_dir/${fBase}_diff_${fNew}.txt
            printf "Please re-baseline $fNew branch. $fBase branch is ahead of $fNew branch!\nPlease consult $cur_dir/${fBase}_diff_${fNew}.txt file.\n"
        fi
    else
        printf "Do you want to continue with automerging and code push to remote repository? (Y/N)"
        read fMerge < /dev/tty
        if [[ $fMerge = "Y" ]]
          then
            git merge $fNew &> /dev/null
            code_push
        elif [[ $fMerge = "N" ]]
          then
            echo "Auto-merging stopped before committing as requested!"
        else
            echo "Wrong input! Please try again"
            merge
        fi
     fi
}

code_push()
{
    git push origin $fBase &> /dev/null && flag_merge="success" || flag_merge="failed"
    if [[ $flag_merge = "success" ]]
      then
        echo "Code merge success! $fNew branch is merged to $fBase branch and pushed to remote repository"
    else
        echo "Code push failed! Please try again"
        code_push
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
        echo "Invalid URL! Please try again"
        repo_clone
    fi
 
    git clone $fURL &> /dev/null 
    dir_repo=`echo $fURL | awk -F '[/.]' '{print $(NF-1)}'`
    cd $dir_repo &> /dev/null && flag_repo="valid" || flag_repo="invalid"
    if [ $flag_repo == "invalid" ]
      then
        echo "Invalid URL! Please try again"
        repo_clone
    fi
}

validate()
{
    git branch -r > $cur_dir/branches.txt
    awk '{gsub(/origin\//," ")}1' $cur_dir/branches.txt > $cur_dir/branches1.txt
    all_branches=`sed -e "/HEAD/d" $cur_dir/branches1.txt`
    echo $all_branches | grep -F -q -w "$1";
}

echo "Do you want to do git merging? (Y/N)"
read fResp < /dev/tty
if [[ $fResp = "Y" ]]
  then
    repo_dir
    repo_clone
    merge_branch
    base_branch
    merge
    rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
elif [[ $fResp = "N" ]]
  then
    echo "Thank you! Have a nice day"
else
    echo "Wrong input"
    ./git_merge.sh
fi
done < temp_create.conf
rm $cur_dir/temp_create.conf &> /dev/null

