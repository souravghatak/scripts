#!/bin/sh

awk '{if(NR>1)print}' push.conf > temp_push.conf
cur_dir=`pwd`
module_list=""
branch=""
flag_merge="false"

while IFS="|"  read -r fDir fNew ;
do
dir_repo=`echo $fDir | awk -F '[/]' '{print $(NF)}'`

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

merge_branch()
{
    if [[ $fNew = "" ]] || [[ $flag_new = "invalid" ]]
          then
            echo "Merge branch :"
            read fNew < /dev/tty
        fi
    validate $fNew && flag_new="valid" || flag_new="invalid"
    if [[ ${#fNew} -eq 0 ]]
      then
        flag_new="invalid"
    fi
    if [ $flag_new = "invalid" ]
          then
            echo "Invalid merge branch! Please try again"
            merge_branch
    else
        echo -e "Please confirm if merge conflicts recorded for merging $fNew branch to $fBranch branch are manually resolved? \n\nFor Yes, Press 1\nFor No, Press 2\nFor Exit - Press 9"
        read fConflict < /dev/tty
        if [[ $fConflict = "1" ]]
          then
            echo "Merging $fNew branch to $fBranch branch"
            flag_merge="true"
        elif [[ $fConflict = "2" ]]
          then
            echo "Resolve the conflicts manually and try git push"
            rm $cur_dir/temp_push.conf &> /dev/null
            rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
            exit
        elif [[ $fConflict = "9" ]]
          then
            echo "Thank you!Have a nice day."
            rm $cur_dir/temp_push.conf &> /dev/null
            rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
            exit
        else
            echo "Wrong input! Please try again"
            list_of_files
        fi
    fi
}

list_of_files()
{
    status=$(git status)
    fBranch=`git rev-parse --abbrev-ref HEAD`
    if [[ $status == *"You have unmerged paths."* ]]
      then
        merge_branch
    fi
    
    #deleted_files=`git status --porcelain | awk 'match($1, "D") || match($1, "UD") || match($1, "DU") {print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    deleted_files=`git status --porcelain | awk '{if ($1 == "D") {print $2}}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    modified_files=`git status --porcelain | awk 'match($1, "M") || match($1, "UU") {print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    added_files=`git status --porcelain | awk 'match($1, "?") || match($1, "A"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`

    deleted_files1=`git status --porcelain | awk 'match($1, "UD"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    deleted_files2=`git status --porcelain | awk 'match($1, "DU"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    modified_files1=`git status --porcelain | awk 'match($1, "UU"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    added_files1=`git status --porcelain | awk 'match($1, "AA"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`

    if [[ $deleted_files1 != "" ]]
      then
        echo -e "Removed $deleted_files1 from branch $fNew . Do you want to continue removing these files from $fBranch branch while merging $fNew branch? \n\nFor Yes, Press 1\nFor No, Press 2\nFor Exit - Press 9"
        read fDel < /dev/tty
        if [[ $fDel = "1" ]]
          then
            git rm $deleted_files1 &> /dev/null
            deleted_files+=" "$deleted_files1
            deleted_files1=""
        elif [[ $fDel = "2" ]]
          then
            echo "Not removing $deleted_files1 from $fBranch branch"
        elif [[ $fDel = "9" ]]
          then
            echo "Thank you! Have a nice day."
            rm $cur_dir/temp_push.conf &> /dev/null
            rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
            exit
        else
            echo "Wrong input! Please try again"
            list_of_files
        fi
    fi

    if [[ $deleted_files2 != "" ]]
      then
        echo -e "Removed $deleted_files2 from branch $fBranch . Do you want to continue adding these files to $fBranch branch while merging $fNew branch? \n\nFor Yes, Press 1\nFor No, Press 2\nFor Exit - Press 9"
        read fDel1 < /dev/tty
        if [[ $fDel1 = "1" ]]
          then
            echo "Adding $deleted_files2 to $fBranch branch"
            added_files+=" "$deleted_files2
        elif [[ $fDel1 = "2" ]]
          then
            git rm $deleted_files2 &> /dev/null
            deleted_files2=""
        elif [[ $fDel = "9" ]]
          then
            echo "Thank you! Have a nice day."
            rm $cur_dir/temp_push.conf &> /dev/null
            rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
            exit
        else
            echo "Wrong input! Please try again"
            list_of_files
        fi
    fi    
    
    if [[ $deleted_files = "" ]] && [[ $modified_files = "" ]] && [[ $added_files = "" ]]
      then
        echo "No files changed to commit. Thank you"
        rm $cur_dir/temp_push.conf &> /dev/null
        rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
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
    if [[ $flag_merge = "true" ]]
      then
        module_list="$deleted_files1"$'\n'"$deleted_files2"$'\n'"${modified_files1}"$'\n'"${added_files1}"
    else
        module_list="$deleted_files"$'\n'"${modified_files}"$'\n'"${added_files}"
    fi
}

validate()
{
    git branch -r > $cur_dir/branches.txt
    awk '{gsub(/origin\//," ")}1' $cur_dir/branches.txt > $cur_dir/branches1.txt
    all_branches=`sed -e "/HEAD/d" $cur_dir/branches1.txt`
    echo $all_branches | grep -F -q -w "$1";
}

download_tracker()
{
    awk '{if(NR>1)print}' $cur_dir/tracker.conf > $cur_dir/temp_tracker.conf
    while IFS="|"  read -r fTrack_URL fTrack_Path ;
    do
        if [[ $fTrack_URL = "" ]] || [[ $flag_tracker = "invalid" ]]
          then
            echo "Repo URL for tracker:"
            read fTrack_URL < /dev/tty
        fi
        if [[ ${#fTrack_URL} -eq 0 ]]
          then
            flag_tracker="invalid"
            echo "Invalid URL! Please try again"
            download_tracker
        fi
        cd $cur_dir
        git clone $fTrack_URL &> /dev/null
        dir_track_repo=`echo $fTrack_URL | awk -F '[/.]' '{print $(NF-1)}'`
        cd $dir_track_repo &> /dev/null && flag_tracker="valid" || flag_tracker="invalid"
        if [ $flag_tracker == "invalid" ]
          then
            echo "Invalid URL for tracker! Please try again"
            download_tracker
        fi

        git fetch &> /dev/null
        git checkout origin/master -- $fTrack_Path${dir_repo}_tracker.csv &> /dev/null && flag_repo_tracker="valid" || flag_repo_tracker="invalid"
        if [ $flag_repo_tracker == "invalid" ]
          then
            echo "${dir_repo}_tracker.csv file is not available in remote repository.Creating new ${dir_repo}_tracker.csv file."
        else
            mv ${dir_repo}_tracker.csv $cur_dir/
            git reset HEAD ${dir_repo}_tracker.csv &> /dev/null
        fi
    done < $cur_dir/temp_tracker.conf
    rm $cur_dir/temp_tracker.conf
}


git_add()
{
    fBranch=`git rev-parse --abbrev-ref HEAD`
    fProd_branch=`awk 'BEGIN {FS = ", "}; {if ($7 == "In-Production") {print $3}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    live=`awk -v var1=$fBranch 'BEGIN {FS = ", "}; {if ($13 == var1) {print $13}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    sys_owner=`awk -v var1=$fBranch 'BEGIN {FS = ", "}; {if ($13 == var1) {print $8}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    updated_username=`git config user.name`

    [[ $live =~ (^|[[:space:]])"$fBranch"($|[[:space:]]) ]] && flag_live="true" || flag_live="false"
    [[ $fProd_branch =~ (^|[[:space:]])"$fBranch"($|[[:space:]]) ]] && flag_prod="true" || flag_prod="false"
    [[ $sys_owner =~ (^|[[:space:]])"$updated_username"($|[[:space:]]) ]] && flag_user="true" || flag_user="false"
    
    if [[ $flag_live = "true" && $flag_merge = "false" ]]
      then
        echo "Sorry! You cannot push changes directly to $fBranch branch as this is a live / production branch. You can only merge branches to $fBranch branch."
        rm $cur_dir/temp_push.conf &> /dev/null
        rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
        exit
    elif [[ $flag_live = "true" && $flag_user = "false" ]]
      then
        echo "Sorry! You cannot push changes directly to $fBranch branch as this is a live / production branch. You can only merge branches to $fBranch branch when there are no merge conflicts. If it's really required, please consult your system owner."
        rm $cur_dir/temp_push.conf &> /dev/null
        rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
        exit
    fi
    
    if [[ $flag_prod = "true" ]]
      then
        echo "Sorry! You cannot push any more changes to $fBranch branch. This branch is already in production and no more changes to this branch will be acknowledged."
        rm $cur_dir/temp_push.conf &> /dev/null
        rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
        exit
    fi
    echo -e "Do you want to push all the above files? \n\nFor Yes, Press 1\nFor No, Press 2\nFor Exit - Press 9"
    read fFile < /dev/tty
    if [[ $fFile = "1" ]]
      then
        git add $module_list &> /dev/null
    elif [[ $fFile = "2" ]]
      then
        echo "Please specify the file names below (space separated)"
        read module_list < /dev/tty
        git add $module_list &> /dev/null
    elif [[ $fFile = "9" ]]
      then
        echo "Thank you! Have a nice day"
        rm $cur_dir/temp_push.conf &> /dev/null
        rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
        exit
    else
        echo "Wrong input! Please try again"
        git_add
    fi  
}

git_commit()
{ 
    if [[ $flag_merge = "true" ]]
      then
        git commit --no-edit &> /dev/null
    else
        printf "Commit message :\n"
        read fCommit < /dev/tty
        if [[ ${#fCommit} -eq 0 ]]
          then
            echo "Commit message cannot be empty! Please try again."
            git_commit
        fi
        git commit -m "$fCommit" &> /dev/null
    fi
}

git_push_decide()
{
    fBranch=`git rev-parse --abbrev-ref HEAD`
    echo -e "Git commit successful for $fBranch branch! Do you want to push the changes to remote repository? \n\nFor Yes, Press 1\nFor No, Press 2\nFor Exit - Press 9"
    read fPush < /dev/tty
    if [[ $fPush = "1" ]]
      then
        git_push $fBranch
    elif [[ $fPush = "2" ]]
      then
        echo "Code push to remote is stopped as requested. Changes are committed locally in $fDir directory"
    elif [[ $fPush = "9" ]]
      then
        echo "Thank you! Have a nice day"
        rm $cur_dir/temp_push.conf &> /dev/null
        rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
        exit
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
    remote_del=`git diff --name-status HEAD@{1} HEAD@{0} | awk 'match($1, "D"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    remote_mod=`git diff --name-status HEAD@{1} HEAD@{0} | awk 'match($1, "M"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    remote_add=`git diff --name-status HEAD@{1} HEAD@{0} | awk 'match($1, "A"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    updated_email=`git config user.email`
    updated_username=`git config user.name`
    
    if [[ $flag_merge = "true" ]]
      then
        if [[ $flag_live = "true" ]]
          then
            `awk -v var1=$branch -v var2=" $remote_del" -v var3=" $remote_mod" -v var4=" $remote_add" -v var5=$commit -v var6=$updated_email -v var7=$updated_username -v var8="$(date "+%Y-%m-%d %H:%M:%S")" -v var9=$fNew 'BEGIN {FS = ", "} {OFS = ", "}; {if ($3 == var9) {$6 = $6 "  Merge Commit (" var9 " -> " var1 ") - Id: " var5 " - Deleted : " var2 " Modified : " var3 " Added : " var4; $7 = "In-Production"; $10 = var7; $11 = var6; $12 = var8};  print}' $cur_dir/${dir_repo}_tracker.csv >> $cur_dir/${dir_repo}_tracker1.csv` &> /dev/null
            mv $cur_dir/${dir_repo}_tracker1.csv $cur_dir/${dir_repo}_tracker.csv &> /dev/null
        else
            `awk -v var1=$branch -v var2=" $remote_del" -v var3=" $remote_mod" -v var4=" $remote_add" -v var5=$commit -v var6=$updated_email -v var7=$updated_username -v var8="$(date "+%Y-%m-%d %H:%M:%S")" -v var9=$fNew 'BEGIN {FS = ", "} {OFS = ", "}; {if ($3 == var1) {$6 = $6 "  Merge Commit (" var9 " -> " var1 ") - Id: " var5 " - Deleted : " var2 " Modified : " var3 " Added : " var4; $7 = "Active"; $10 = var7; $11 = var6; $12 = var8};  print}' $cur_dir/${dir_repo}_tracker.csv >> $cur_dir/${dir_repo}_tracker1.csv` &> /dev/null
            mv $cur_dir/${dir_repo}_tracker1.csv $cur_dir/${dir_repo}_tracker.csv &> /dev/null
        fi
    else
        `awk -v var1=$branch -v var2=" $remote_del" -v var3=" $remote_mod" -v var4=" $remote_add" -v var5=$commit -v var6=$updated_email -v var7=$updated_username -v var8="$(date "+%Y-%m-%d %H:%M:%S")" 'BEGIN {FS = ", "} {OFS = ", "}; {if ($3 == var1) {$6 = $6 "  Commit Id : " var5 " - Deleted : " var2 " Modified : " var3 " Added : " var4; $7 = "Active"; $10 = var7; $11 = var6; $12 = var8};  print}' $cur_dir/${dir_repo}_tracker.csv >> $cur_dir/${dir_repo}_tracker1.csv` &> /dev/null
        mv $cur_dir/${dir_repo}_tracker1.csv $cur_dir/${dir_repo}_tracker.csv &> /dev/null
    fi
}

rebase_email ()
{        
    if [[ $flag_merge = "true" ]]
      then
        rebase_user=`awk -v var1=$branch -v var2=$fNew -v var3="In-Production" 'BEGIN {FS = ", "}; {if ($2 == var1 && $3 != var2 && $7 != var3) {print $4}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        rebase_email_id=`awk -v var1=$branch -v var2=$fNew -v var3="In-Production" 'BEGIN {FS = ", "}; {if ($2 == var1 && $3 != var2 && $7 != var3) {print $5}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        rebase_branch=`awk -v var1=$branch -v var2=$fNew -v var3="In-Production" 'BEGIN {FS = ", "}; {if ($2 == var1 && $3 != var2 && $7 != var3) {print $3}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    else
        rebase_user=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($2 == var1) {print $4}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        rebase_email_id=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($2 == var1) {print $5}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        rebase_branch=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($2 == var1) {print $3}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    fi
    if [[ $flag_live = "true" ]]
      then
        email=`git config user.email`
        username=`git config user.name`
        date=$(date "+%Y-%m-%d %H:%M:%S")
    else
        username=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $10}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        email=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $11}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        date=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $12}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/" "/,"")}1'`
    fi
    if [[ $rebase_user != "" ]] && [[ $rebase_email_id != "" ]] && [[ $rebase_branch != "" ]]
      then
        array1=(${rebase_user// / })
        array2=(${rebase_email_id// / })
        array3=(${rebase_branch// / })
        length=${#array1[@]}
            
        for ((i=0;i<=$length-1;i++)); do
            echo -e "Hi ${array1[$i]},\n\nBranch ${array3[$i]} created by you is baselined to $branch branch. Changes are made to $branch branch by $username ($email) for commit id: $commit at $date . \nThe list of changed files is as below: \n\nDeleted: $remote_del \nModified: $remote_mod \nAdded: $remote_add \n\nPlease rebaseline your ${array3[$i]} branch to $branch branch. \n\n\nRegards,\nErlang L3 \nEmail ID: erlang_l3@thbs.com"
        done
        if [[ $flag_merge = "true" ]]
          then
            echo -e "Hi $username , \n\nYou have successfully merged $fNew branch into $branch branch for commit id: $commit at $date .\nThe list of changed files is as below: \n\nDeleted: $deleted_files \nModified: $modified_files \nAdded: $added_files \n\n\nRegards,\nErlang L3 \nEmail ID: erlang_l3@thbs.com"
        fi
    fi
}

download_tracker
repo_dir
list_of_files
git_add
git_commit
git_push_decide
tracker_update
rebase_email

cd $cur_dir/$dir_track_repo
#git checkout master &> /dev/null
mv $cur_dir/${dir_repo}_tracker.csv . &> /dev/null
git add ${dir_repo}_tracker.csv &> /dev/null
git commit -m "Created new branch : $fNew" &> /dev/null
echo "Updated ${dir_repo}_tracker.csv"
git_push master

rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
done < temp_push.conf
rm $cur_dir/temp_push.conf &> /dev/null
