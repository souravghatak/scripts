#!/bin/sh

awk '{if(NR>1)print}' clone_checkout.conf > temp_clone.conf

while IFS="|"  read -r fDir fURL fBase;
do

repo_dir()
{
    if [[ $fDir = "" ]] || [[ $flag_dir == "invalid" ]]
      then
        echo "Codebase directory : "
        read fDir < /dev/tty
    fi
    if [[ ${#fDir} -eq 0 ]]
      then
        flag_dir="invalid"
        echo -e "ERROR : Invalid directory!\nPlease try again"
        repo_dir
    fi
    cd $fDir &> /dev/null && flag_dir="valid" || flag_dir="invalid"
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
        echo -e "ERROR : Invalid URL!\nPlease try again"
        repo_clone
    fi
    git clone $fURL &> /dev/null
    dir_repo=`echo $fURL | awk -F '[/.]' '{print $(NF-1)}'`
    cd $dir_repo &> /dev/null && flag_repo="valid" || flag_repo="invalid"
    if [ $flag_repo == "invalid" ]
      then
        echo -e "ERROR : Invalid URL!\nPlease try again"
        repo_clone
    fi
}

list_of_files()
{
    status=$(git status)
    fBranch=`git rev-parse --abbrev-ref HEAD`
    echo -e "Branch name : $fBranch"

    if [[ $status == *"You have unmerged paths."* ]]
      then
        #merge_branch
        echo -e ""
    fi

    deleted_files=`git status --porcelain | awk '{if ($1 == "D") {print $2}}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    modified_files=`git status --porcelain | awk 'match($1, "M") || match($1, "UU") {print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    added_files=`git status --porcelain | awk 'match($1, "?") || match($1, "A"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`

    deleted_files1=`git status --porcelain | awk 'match($1, "UD"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    deleted_files2=`git status --porcelain | awk 'match($1, "DU"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    modified_files1=`git status --porcelain | awk 'match($1, "UU"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
    added_files1=`git status --porcelain | awk 'match($1, "AA"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`

    if [[ $deleted_files1 != "" ]]
      then
        echo -e "WARNING : Deleted $deleted_files1 from $fNew branch"
    fi

    if [[ $deleted_files2 != "" ]]
      then
        echo -e "WARNING : Removed $deleted_files2 from branch $fBranch . Adding  $deleted_files2 while merging $fNew branch"
    fi

    if [[ $deleted_files = "" ]] && [[ $modified_files = "" ]] && [[ $added_files = "" ]]
      then
        echo -e "EXIT !\nREASON : No files changed to commit. Thank you"
        rm $cur_dir/temp_push.conf &> /dev/null
        rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
        rm $cur_dir/${dir_repo}_tracker.csv &> /dev/null
        rm -rf $cur_dir/$dir_track_repo &> /dev/null
        exit
    else
        echo -e "*********************************************************\nList of changed files (Deleted/Modified/Added)\n*********************************************************"
        if [[ $deleted_files != "" ]]
          then
            echo -e "\nDeleted : $deleted_files"
        else
            echo -e "\nDeleted: -"
        fi
        if [[ $modified_files != "" ]]
          then
            echo -e "Modified : $modified_files"
        else
            echo -e "Modified: -"
        fi
        if [[ $added_files != "" ]]
          then
            echo -e "Added: $added_files"
        else
            echo -e "Added: -"
        fi
        echo -e "\n*********************************************************"
    fi
    if [[ $flag_merge = "true" ]]
      then
        module_list="$deleted_files1"$'\n'"$deleted_files2"$'\n'"${modified_files1}"$'\n'"${added_files1}"
    else
        module_list="$deleted_files"$'\n'"${modified_files}"$'\n'"${added_files}"
    fi
}

repo_dir
repo_clone
list_of_files
done < temp_clone.conf
