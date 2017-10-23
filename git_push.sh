#!/bin/sh

awk '{if(NR>1)print}' push.conf > temp_push.conf
cur_dir=`pwd`
module_list=""
branch=""

while IFS="|"  read -r fDir ;
do

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

list_of_files()
{
    deleted_files=`git status --porcelain | awk 'match($1, "D"){print $2}'`
    modified_files=`git status --porcelain | awk 'match($1, "M"){print $2}'`
    added_files=`git status --porcelain | awk 'match($1, "?"){print $2}'`
    
    if [[ $deleted_files = "" ]] && [[ $modified_files = "" ]] && [[ $added_files = "" ]]
      then
        echo "No files changed to commit. Thank you"
        exit
    else 
        echo "Please find the list of files (Deleted/Modified/Added)"
        if [[ $deleted_files != "" ]]
          then
            printf "\nDeleted:\n$deleted_files\n"
        fi
        if [[ $modified_files != "" ]]
          then
            printf "\nModified:\n$modified_files\n"
        fi
        if [[ $added_files != "" ]]
          then
            printf "\nAdded:\n$added_files\n"
        fi
    fi
    module_list="$deleted_files"$'\n'"${modified_files}"$'\n'"${added_files}"
}

git_add()
{
    fBranch=`git rev-parse --abbrev-ref HEAD`
    fProd_branch=`awk 'BEGIN {FS = ", "}; {if ($7 == "In-Production") {print $3}}' $cur_dir/research_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    if [[ $fBranch = "master" ]]
      then
        echo "Sorry! You cannot push changes directly to $fBranch branch. Only other branches can be merged to $fBranch branch."
        exit
    elif [[ $fBranch = $fProd_branch ]]
      then
        echo "Sorry! You cannot push any more changes to $fBranch branch. This branch is already in production and no more changes to this branch will be acknowledged."
        exit
    fi
    echo "Do you want to push all the above files? (Y/N)"
    read fFile < /dev/tty
    if [[ $fFile = "Y" ]]
      then
        git add $module_list &> /dev/null
    elif [[ $fFile = "N" ]]
      then
        echo "Please specify the file names below (space separated)"
        read module_list < /dev/tty
        git add $module_list &> /dev/null
    else
        echo "Wrong input! Please try again"
        git_add
    fi  
}

git_commit()
{ 
    printf "Commit message :\n"
    read fCommit < /dev/tty
    if [[ ${#fCommit} -eq 0 ]]
      then
        echo "Commit message cannot be empty! Please try again."
        git_commit
    fi
    git commit -m "$fCommit" &> /dev/null
}

git_push_decide()
{
    fBranch=`git rev-parse --abbrev-ref HEAD`
    echo "Git commit successful for $fBranch branch! Do you want to push the changes to remote repository? (Y/N)"
    read fPush < /dev/tty
    if [[ $fPush = "Y" ]]
      then
        git_push $fBranch
    elif [[ $fPush = "N" ]]
      then
        echo "Code push to remote is stopped as requested. Changes are committed locally in $fDir directory"
    else
        echo "Wrong input! Please try again"
        git_push_decide 
    fi
}

git_push()
{
    git push origin $1 &> /dev/null && flag_push="success" || flag_push="failed"
    branch=`echo $1`
    if [[ $flag_push = "success" ]]
      then
        echo "Changes pushed to remote $branch branch!"
    else
        echo "Wrong git credentials! Code push failed! Please try again"
        git_push $branch
    fi
}

tracker_update ()
{       
    commit=`git rev-parse --verify $branch`
    remote_del=`git show --name-status --oneline HEAD | awk 'match($1, "D"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    remote_mod=`git show --name-status --oneline HEAD | awk 'match($1, "M"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    remote_add=`git show --name-status --oneline HEAD | awk 'match($1, "A"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    updated_email=`git config user.email`
    updated_username=`git config user.name`

    `awk -v var1=$branch -v var2=" $remote_del" -v var3=" $remote_mod" -v var4=" $remote_add" -v var5=$commit -v var6=$updated_email -v var7=$updated_username -v var8="$(date "+%Y-%m-%d %H:%M:%S")" 'BEGIN {FS = ", "} {OFS = ", "}; {if ($3 == var1) {$6 = $6 "  Commit Id : " var5 " - Deleted : " var2 " Modified : " var3 " Added : " var4; $7 = "Active"; $10 = var7; $11 = var6; $12 = var8};  print}' $cur_dir/research_tracker.csv >> $cur_dir/research_tracker1.csv` &> /dev/null
    mv $cur_dir/research_tracker1.csv $cur_dir/research_tracker.csv &> /dev/null
}

rebase_email ()
{        
        rebase_user=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($2 == var1) {print $4}}' $cur_dir/research_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        rebase_email_id=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($2 == var1) {print $5}}' $cur_dir/research_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        rebase_branch=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($2 == var1) {print $3}}' $cur_dir/research_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        username=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $10}}' $cur_dir/research_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        email=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $11}}' $cur_dir/research_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        date=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $12}}' $cur_dir/research_tracker.csv | awk -v RS="" '{gsub (/" "/,"")}1'`
        if [[ $rebase_user != "" ]] && [[ $rebase_email_id != "" ]] && [[ $rebase_branch != "" ]]
          then
            array1=(${rebase_user// / })
            array2=(${rebase_email_id// / })
            array3=(${rebase_branch// / })
            length=${#array1[@]}
            
            for ((i=0;i<=$length-1;i++)); do
                echo -e "Hi ${array1[$i]},\n\n\nBranch ${array3[$i]} created by you is baselined to $branch branch. Changes are made to $branch branch by $username ($email) for commit id: $commit at $date . \nPlease rebaseline your ${array3[$i]} branch to $branch branch. \n\n\nRegards,\nErlang L3 \nEmail ID: erlang_l3@thbs.com"
            done
        fi
}


repo_dir
list_of_files
git_add
git_commit
git_push_decide
tracker_update
rebase_email
done < temp_push.conf
rm $cur_dir/temp_push.conf &> /dev/null
