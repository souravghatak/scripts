#!/bin/sh

awk '{if(NR>1)print}' merge.conf > temp_merge.conf
cur_dir=`pwd`
while IFS="|"  read -r fDir fBase fNew fURL ;
do
dir_repo=""
flag=""
echo $fURL
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
    if [[ $fBase != "master" ]]
      then
        flag="valid"
    else
        echo "You are about to merge $fNew to branch master branch. Please confirm the changes made as part of $fNew branch is in production. (Y/N)"
        read fMaster < /dev/tty
        if [[ $fMaster = "Y" ]]
          then
            flag="valid"
        elif [[ $fMaster = "N" ]]
          then
            flag="invalid"
        else
            echo "Wrong input! Please try again"
            base_branch
        fi
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

#dormant function - not in use
rebase_branch ()
{
    rebase_branch=`awk -v var1=$fNew 'BEGIN {FS = ", "}; {if ($3 == var1) {print $2}}' $cur_dir/research_tracker.csv`
    if [[ $fBase == $rebase_branch ]]
      then
        flag="valid"
    else
        echo "Branch $fNew is created baselined to $rebase_branch . Hence ideally branch $fNew should be merged to $rebase_branch . Do you still want to merge branch $fNew to branch $fBase? (Y/N)"
        read fBaseMerge < /dev/tty
        if [[ $fBaseMerge = "Y" ]]
          then
            flag="valid"
            username=`awk -v var1=$rebase_branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $4}}' $cur_dir/research_tracker.csv`
            email=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $5}}' $cur_dir/research_tracker.csv`

        elif [[ $fBaseMerge = "N" ]]
          then
            echo "Do you want to merge branch $fNew to $rebase_branch ? (Y/N)"
            read fRebaseMerge < /dev/tty
            if [[ $fRebaseMerge == "Y" ]]
              then
                fBase=$rebase_branch
                validate $fBase && flag="valid" || flag="invalid"
            elif [[ $fRebaseMerge == "N" ]]
              then
                flag="invalid"
            else
                echo "Wrong input! Please try again"
                base_branch
            fi
        else
            echo "Wrong input! Please try again"
            base_branch
        fi
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
        if [[ $fBase != "master" ]]
          then
             rebase_email $fBase
        else
            `awk -v var1=$fNew 'BEGIN {FS = ", "} {OFS = ", "}; {if ($3 == var1) {$7 = "In-Production"};  print}' $cur_dir/research_tracker.csv >> $cur_dir/research_tracker1.csv` &> /dev/null
             mv $cur_dir/research_tracker1.csv $cur_dir/research_tracker.csv &> /dev/null
        fi
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

#dormant function - not in use
tracker_update ()
{
    branch=`echo $1`

    commit=`git rev-parse --verify $branch`
    remote_del=`git show --name-status --oneline HEAD | awk 'match($1, "D"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    remote_mod=`git show --name-status --oneline HEAD | awk 'match($1, "M"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    remote_add=`git show --name-status --oneline HEAD | awk 'match($1, "A"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`

    `awk -v var1=$branch -v var2=" $remote_del" -v var3=" $remote_mod" -v var4=" $remote_add" -v var5=$commit 'BEGIN {FS = ", "} {OFS = ", "}; {if ($3 == var1) {$6 = $6 "  Commit Id : " var5 " - Deleted : " var2 " Modified : " var3 " Added : " var4};  print}' $cur_dir/research_tracker.csv >> $cur_dir/research_tracker1.csv` &> /dev/null
    mv $cur_dir/research_tracker1.csv $cur_dir/research_tracker.csv &> /dev/null
}

rebase_email ()
{
    branch=`echo $1`
    rebase_user=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($2 == var1) {print $4}}' $cur_dir/research_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    rebase_email_id=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($2 == var1) {print $5}}' $cur_dir/research_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    rebase_branch=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($2 == var1) {print $3}}' $cur_dir/research_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    username=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $4}}' $cur_dir/research_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    email=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $5}}' $cur_dir/research_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    if [[ $rebase_user != "" ]] && [[ $rebase_email_id != "" ]] && [[ $rebase_branch != "" ]]
      then
        array1=(${rebase_user// / })
        array2=(${rebase_email_id// / })
        array3=(${rebase_branch// / })
        length=${#array1[@]}

        for ((i=0;i<=$length-1;i++)); do
            echo -e "Hi ${array1[$i]},\n\n\nBranch ${array3[$i]} created by you is baselined to $branch branch. Changes are made to $branch branch by $username ($email) for commit id: $commit . \nPlease rebaseline your ${array3[$i]} branch to $branch branch. \n\n\nRegards,\nErlang L3 \nEmail ID: erlang_l3@thbs.com"
        done
    fi
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
done < temp_merge.conf
rm $cur_dir/temp_merge.conf &> /dev/null
