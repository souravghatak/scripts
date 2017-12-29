#!/bin/sh

awk '{if(NR>1)print}' merge.conf > temp_merge.conf
cur_dir=`pwd`
while IFS="|"  read -r fDir fBase fNew fURL ;
do
dir_repo=""
flag=""
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

download_tracker()
{
    cd $cur_dir
    awk '{if(NR>1)print}' tracker.conf > temp_tracker.conf
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
            echo -e "ERROR : Invalid URL!\nPlease try again"
            download_tracker
        fi
        git clone $fTrack_URL &> /dev/null
        #echo $fTrack_URL
        dir_track_repo=`echo $fTrack_URL | awk -F '[/.]' '{print $(NF-1)}'`
        #echo $dir_track_repo
        cd $dir_track_repo &> /dev/null && flag_tracker="valid" || flag_tracker="invalid"
        if [ $flag_tracker == "invalid" ]
          then
            echo -e "ERROR : Invalid URL for tracker!\nPlease try again"
            download_tracker
        fi
        git fetch &> /dev/null
        git checkout origin/master -- $fTrack_Path${dir_repo}_tracker.csv &> /dev/null && flag_repo_tracker="valid" || flag_repo_tracker="invalid"
        if [[ $flag_repo_tracker == "invalid" ]]
          then
            echo -e "ERROR : ${dir_repo}_tracker.csv file is not available.\nPlease try again"
            download_tracker
        else
            mv ${dir_repo}_tracker.csv $cur_dir/
            git reset HEAD ${dir_repo}_tracker.csv &> /dev/null
        fi
    done < $cur_dir/temp_tracker.conf
    rm $cur_dir/temp_tracker.conf &> /dev/null
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
    
    live=`awk -v var1=$fBase 'BEGIN {FS = ", "}; {if ($13 == var1) {print $13}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    fProd_branch=`awk 'BEGIN {FS = ", "}; {if ($7 == "In-Production") {print $3}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    [[ $live =~ (^|[[:space:]])"$fBase"($|[[:space:]]) ]] && flag_live="true" || flag_live="false"
    [[ $fProd_branch =~ (^|[[:space:]])"$fBase"($|[[:space:]]) ]] && flag_prod="true" || flag_prod="false"

    if [[ $flag_prod = "true" ]]
      then
        echo -e "EXIT !\nREASON : This branch ($fBase branch) is already in production and no more changes to this branch will be acknowledged."
        rm $cur_dir/temp_merge.conf &> /dev/null
        rm -rf $cur_dir/$dir_track_repo &> /dev/null
        rm $cur_dir/${dir_repo}_tracker.csv &> /dev/null
        exit
    fi
    if [[ $flag_live = "false" ]]
      then
        flag="valid"
    else
        echo -e "INFO : $fBase is the live branch and you are about to merge $fNew branch to $fBase branch.\nPlease confirm the changes made as part of $fNew branch is in production. \n\nFor Yes, Press 1\nFor No, Press 2"
        read fMaster < /dev/tty
        if [[ $fMaster = "1" ]]
          then
            flag="valid"
        elif [[ $fMaster = "2" ]]
          then
            flag="invalid"
        else
            echo -e "ERROR : Wrong input!\nPlease try again"
            base_branch
        fi
    fi        
    if [ $flag = "valid" ]
      then
        git fetch &> /dev/null
        git checkout $fBase &> /dev/null
        git pull origin $fBase &> /dev/null
    else
        echo -e "ERROR : Invalid base branch.\nPlease try again!"
        base_branch
    fi
}

#dormant function - not in use
rebase_branch ()
{
    rebase_branch=`awk -v var1=$fNew 'BEGIN {FS = ", "}; {if ($3 == var1) {print $2}}' $cur_dir/${dir_repo}_tracker.csv`
    if [[ $fBase == $rebase_branch ]]
      then
        flag="valid"
    else
        echo "Branch $fNew is created baselined to $rebase_branch . Hence ideally branch $fNew should be merged to $rebase_branch . Do you still want to merge branch $fNew to branch $fBase? (Y/N)"
        read fBaseMerge < /dev/tty
        if [[ $fBaseMerge = "Y" ]]
          then
            flag="valid"
            username=`awk -v var1=$rebase_branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $4}}' $cur_dir/${dir_repo}_tracker.csv`
            email=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $5}}' $cur_dir/${dir_repo}_tracker.csv`

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
                echo -e "ERROR : Wrong input!\nPlease try again"
                base_branch
            fi
        else
            echo -e "ERROR : Wrong input!\nPlease try again"
            base_branch
        fi
    fi
}

merge_branch()
{
    cd $fDir/$dir_repo
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
        echo -e "ERROR : Invalid branch name.\nPlease try again"
        merge_branch
    fi
}

merge()
{
    merge_var=$(git merge $fNew --no-commit --no-ff; git merge --abort 2>&1) 
    if [[ $merge_var == *"CONFLICT"* ]]
      then
        echo -e "MERGE PREVIEW : Conflicts recorded.\nDo you want to continue merging? \n\nFor Yes, Press 1\nFor No and Exit, Press 2"
        read fConf < /dev/tty
        if [[ $fConf = "1" ]]
          then
            git merge $fNew &> /dev/null
            echo -e "EXIT !\nREASON : Conflicts recorded while merging $fNew branch to $fBase branch.\nRECOMMENDED : Resolve the conflicts manually and do git push."
            rm $cur_dir/temp_merge.conf &> /dev/null
            rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
            rm -rf $cur_dir/$dir_track_repo &> /dev/null
            rm $cur_dir/${dir_repo}_tracker.csv &> /dev/null
            exit
        elif [[ $fConf = "2" ]]
          then
            rm $cur_dir/${fBase}_diff_${fNew}.txt &> /dev/null
            git diff $fNew >> $cur_dir/${fBase}_diff_${fNew}.txt
            echo -e "EXIT !\nREASON : Merge stopped as requested!\nRECOMMENDED : Please consult $cur_dir/${fBase}_diff_${fNew}.txt file for the conflicts recorded and try again."
            rm $cur_dir/temp_merge.conf &> /dev/null
            rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
            rm -rf $cur_dir/$dir_track_repo &> /dev/null
            rm $cur_dir/${dir_repo}_tracker.csv &> /dev/null
            exit
        else
            echo -e "ERROR : Wrong input!\nPlease try again"
            merge
        fi
    elif [[ $merge_var == *"There is no merge to abort"* ]]
      then
        git_diff=$(git diff $fNew)
        if [[ ${#git_diff} -eq 0 ]]
          then
            echo "EXIT !\nREASON : There is nothing to merge and no difference between branch $fBase and $fNew"
            rm $cur_dir/temp_merge.conf &> /dev/null
            rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
            rm -rf $cur_dir/$dir_track_repo &> /dev/null
            rm $cur_dir/${dir_repo}_tracker.csv &> /dev/null
            exit
        else
            rm $cur_dir/${fBase}_diff_${fNew}.txt &> /dev/null
            echo $git_diff > $cur_dir/${fBase}_diff_${fNew}.txt
            printf "EXIT !\nREASON : $fBase branch is ahead of $fNew branch!\nRECOMMENDED : Please re-baseline $fNew branch i.e., Merge $fBase branch into $fNew branch.\nPlease consult $cur_dir/${fBase}_diff_${fNew}.txt file for the differences.\n"
            rm $cur_dir/temp_merge.conf &> /dev/null
            rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
            rm -rf $cur_dir/$dir_track_repo &> /dev/null
            rm $cur_dir/${dir_repo}_tracker.csv &> /dev/null
            exit
        fi
    elif [[ $merge_var == "" ]]
      then
        echo -e "MERGE PREVIEW : Automerge would be successful.\nDo you want to continue automerging $fNew branch to $fBase branch and code push to remote repository? \n\nFor Yes, Press 1\nFor No and Exit, Press 2"
        read fMerge < /dev/tty
        if [[ $fMerge = "1" ]]
          then
            git merge $fNew &> /dev/null
            code_push
        elif [[ $fMerge = "2" ]]
          then
            echo -e "EXIT !\nREASON : Auto-merging stopped before committing as requested!"
            rm $cur_dir/temp_merge.conf &> /dev/null
            rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
            rm -rf $cur_dir/$dir_track_repo &> /dev/null
            rm $cur_dir/${dir_repo}_tracker.csv &> /dev/null
            exit
        else
            echo -e "ERROR : Wrong input!\nPlease try again"
            merge
        fi
    elif [[ $merge_var == *"Removing"* ]]
      then
        echo -e "MERGE PREVIEW : "$merge_var "\nDo you want to continue removing the files from $fBase branch? \n\nFor Yes, Press 1\nFor No and Exit, Press 2"
        read fRemove < /dev/tty
        if [[ $fRemove = "1" ]]
          then
            git merge $fNew &> /dev/null
            code_push
        elif [[ $fRemove = "2" ]]
          then
            echo "EXIT !\nREASON : Auto-merging stopped before committing as requested!"
            rm $cur_dir/temp_merge.conf &> /dev/null
            rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
            rm -rf $cur_dir/$dir_track_repo &> /dev/null
            rm $cur_dir/${dir_repo}_tracker.csv &> /dev/null
            exit
        else
            echo -e "ERROR : Wrong input!\nPlease try again"
            merge
        fi
    else
        echo -e "EXIT !\nREASON :  Merge failure. Unknown Error.\nRECOMMENDED : Please investigate with the below stacktrace and re-try.\n\n********ERROR********\n\n$merge_var"
        rm $cur_dir/temp_merge.conf &> /dev/null
        rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
        rm -rf $cur_dir/$dir_track_repo &> /dev/null
        rm $cur_dir/${dir_repo}_tracker.csv &> /dev/null
        exit
    fi
}

code_push()
{
    git push origin $fBase &> /dev/null && flag_merge="success" || flag_merge="failed"
    if [[ $flag_merge = "success" ]]
      then
        echo -e "SUCCESS!\nINFO : $fNew branch is merged to $fBase branch and pushed to remote repository"
        updated_email=`git config user.email`
        updated_username=`git config user.name`
        commit_details=`git rev-parse --verify $fBase`
        
        deleted_files=`git diff --name-status HEAD@{1} HEAD@{0} | awk 'match($1, "D") || match($1, "UD"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
        modified_files=`git diff --name-status HEAD@{1} HEAD@{0} | awk 'match($1, "M") || match($1, "UU"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
        added_files=`git diff --name-status HEAD@{1} HEAD@{0} | awk 'match($1, "?") || match($1, "A"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
        if [[ $flag_live = "false" ]]
          then
            `awk -v var1=$fBase -v var2="$commit_details" -v var3=$fNew -v var4="$deleted_files" -v var5="$modified_files" -v var9="$added_files" -v var6=$updated_email -v var7=$updated_username -v var8="$(date "+%Y-%m-%d %H:%M:%S")" 'BEGIN {FS = ", "} {OFS = ", "}; {if ($3 == var1) {$6 = $6 "  Merge Commit (" var3 " -> " var1 ") - Id: " var2 " - Deleted: " var4 " Modified: " var5 " Added: " var9; $10 = var7; $11 = var6; $12 = var8};  print}' $cur_dir/${dir_repo}_tracker.csv >> $cur_dir/${dir_repo}_tracker1.csv` &> /dev/null
            mv $cur_dir/${dir_repo}_tracker1.csv $cur_dir/${dir_repo}_tracker.csv &> /dev/null
 
            rebase_email $fBase
        else
            `awk -v var1=$fNew -v var2="$commit_details" -v var3=$fBase -v var4="$deleted_files" -v var5="$modified_files" -v var9="$added_files" -v var6=$updated_email -v var7=$updated_username -v var8="$(date "+%Y-%m-%d %H:%M:%S")" 'BEGIN {FS = ", "} {OFS = ", "}; {if ($3 == var1) {$6 = $6 "  Merge Commit (" var1 " -> " var3 ") - Id: " var2 " - Deleted: " var4 " Modified: " var5 " Added: " var9; $7 = "In-Production"; $10 = var7; $11 = var6; $12 = var8};  print}' $cur_dir/${dir_repo}_tracker.csv >> $cur_dir/${dir_repo}_tracker1.csv` &> /dev/null
            mv $cur_dir/${dir_repo}_tracker1.csv $cur_dir/${dir_repo}_tracker.csv &> /dev/null
            rebase_email $fBase
        fi
    else
        echo -e "ERROR : Code push failed! Wrong git credentials!\nPlease try again"
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
    remote_both_mod=`git show --name-status --oneline HEAD | awk 'match($1, "UU"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`

    `awk -v var1=$branch -v var2=" $remote_del" -v var3=" $remote_mod" -v var4=" $remote_add" -v var5=$commit -v var6=$remote_both_mod 'BEGIN {FS = ", "} {OFS = ", "}; {if ($3 == var1) {$6 = $6 "  Commit Id : " var5 " - Deleted : " var2 " Modified : " var3 " Added : " var4 " Both modified(only when merging) : " var6 };  print}' $cur_dir/${dir_repo}_tracker.csv >> $cur_dir/${dir_repo}_tracker1.csv` &> /dev/null
    mv $cur_dir/${dir_repo}_tracker1.csv $cur_dir/${dir_repo}_tracker.csv &> /dev/null
}

rebase_email ()
{
    branch=`echo $1`
    commit=`git rev-parse --verify $branch`
    
    if [[ $flag_live = "false" ]]
      then
        username=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $10}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        email=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $11}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        date=`awk -v var1=$branch 'BEGIN {FS = ", "}; {if ($3 == var1) {print $12}}' $cur_dir/${dir_repo}_tracker.csv`
    else
        username=`awk -v var1=$fNew 'BEGIN {FS = ", "}; {if ($3 == var1) {print $10}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        email=`awk -v var1=$fNew 'BEGIN {FS = ", "}; {if ($3 == var1) {print $11}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
        date=`awk -v var1=$fNew 'BEGIN {FS = ", "}; {if ($3 == var1) {print $12}}' $cur_dir/${dir_repo}_tracker.csv`
    fi
    rebase_user=`awk -v var1=$branch -v var2=$fNew -v var3="In-Production" 'BEGIN {FS = ", "}; {if ($2 == var1 && $3 != var2 && $7 != var3) {print $4}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    rebase_email_id=`awk -v var1=$branch -v var2=$fNew -v var3="In-Production" 'BEGIN {FS = ", "}; {if ($2 == var1 && $3 != var2 && $7 != var3) {print $5}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    rebase_branch=`awk -v var1=$branch -v var2=$fNew -v var3="In-Production" 'BEGIN {FS = ", "}; {if ($2 == var1 && $3 != var2 && $7 != var3) {print $3}}' $cur_dir/${dir_repo}_tracker.csv | awk -v RS="" '{gsub (/\n/," ")}1'`
    
    if [[ $rebase_user != "" ]] && [[ $rebase_email_id != "" ]] && [[ $rebase_branch != "" ]]
      then
        array1=(${rebase_user// / })
        array2=(${rebase_email_id// / })
        array3=(${rebase_branch// / })
        length=${#array1[@]}

        for ((i=0;i<=$length-1;i++)); do
            echo -e "Hi ${array1[$i]},\n\nBranch ${array3[$i]} created by you is baselined to $branch branch. Changes are made to $branch branch by $username ($email) for commit id: $commit at $date .\nThe list of changed files is as below: \n\nDeleted: $deleted_files \nModified: $modified_files \nAdded: $added_files \n\nPlease rebaseline your ${array3[$i]} branch to $branch branch. \n\n\nRegards,\nErlang L3 \nEmail ID: erlang_l3@thbs.com"
        done
        echo -e "Hi $username , \n\nYou have successfully merged $fNew branch to $branch branch for commit id: $commit at $date .\nThe list of changed files is as below: \n\nDeleted: $deleted_files \nModified: $modified_files \nAdded: $added_files \n\n\nRegards,\nErlang L3 \nEmail ID: erlang_l3@thbs.com"
    fi
}

git_push()
{
    git push origin $1 &> /dev/null && flag_push="success" || flag_push="failed"
    branch=`echo $1`
    if [[ $flag_push = "success" ]]
      then
        if [[ $flag_tracker_push = "true" ]]
          then
            echo -e "INFO : Updated ${dir_repo}_tracker.csv"
        else
            echo -e "SUCCESS!\nINFO : Changes pushed to remote $branch branch!"
        fi
    else
        echo -e "ERROR : Code push failed! Wrong git credentials!\nPlease try again"
        git_push $branch
    fi
}


echo -e "Do you want to merge $fNew branch into $fBase branch? \n\nFor Yes, Press 1\nFor No and Exit, Press 2"
read fResp < /dev/tty
if [[ $fResp = "1" ]]
  then
    #git config --global credential.helper 'cache --timeout=900'
    repo_dir
    repo_clone
    download_tracker
    merge_branch
    base_branch
    merge
    cd $cur_dir/$dir_track_repo
    mv $cur_dir/${dir_repo}_tracker.csv . &> /dev/null
    git add ${dir_repo}_tracker.csv &> /dev/null
    git commit -m "Merged branch $fNew into $fBase branch" &> /dev/null
    #echo "Updated ${dir_repo}_tracker.csv"
    flag_tracker_push="true"
    git_push master
    cd ..
    rm -rf $cur_dir/$dir_track_repo &> /dev/null
    rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
elif [[ $fResp = "2" ]]
  then
    echo "Thank you! Have a nice day"
else
    echo -e "ERROR : Wrong input!\nPlease try again"
    ./git_merge.sh
fi
done < temp_merge.conf
rm $cur_dir/temp_merge.conf &> /dev/null
