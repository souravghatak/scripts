#!/bin/sh

awk '{if(NR>1)print}' common.conf > temp_clone.conf

cur_dir=`pwd`
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
    echo -e "\nBranch name : $fBranch"

    if [[ $status == *"You have unmerged paths."* ]]
      then
        fNew=`git rev-parse --abbrev-ref @{-1}`
        deleted_files1=`git status --porcelain | awk 'match($1, "UD"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
        deleted_files2=`git status --porcelain | awk 'match($1, "DU"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
        modified_files1=`git status --porcelain | awk 'match($1, "UU"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
        added_files1=`git status --porcelain | awk 'match($1, "AA"){print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
       
        echo -e "\nINFO : You have unmerged paths while merging $fNew branch to $fBranch branch. \nRECOMMENDED : Fix conflicts and run git commit & push\n"
        echo -e "*********************************************************\nStaged files - Changes to be committed\n*********************************************************"
        staged_added_files=`git diff --name-status --staged | awk 'match($1,"A") {print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
        staged_modified_files=`git diff --name-status --staged | awk 'match($1,"M") {print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
        staged_deleted_files=`git diff --name-status --staged | awk 'match($1,"D") {print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`

        if [[ $staged_added_files != "" ]]
          then
            echo -e "Added : $staged_added_files"
        fi
        if [[ $staged_modified_files != "" ]]
          then
            echo -e "Modified : $staged_modified_files"
        fi
        if [[ $staged_deleted_files != "" ]]
          then
            echo -e "Deleted : $staged_deleted_files"
        fi

        echo -e "\n*********************************************************\nUnmerged paths - Conflicted files\n*********************************************************"

        if [[ $deleted_files1 != "" ]]
          then
            echo -e "Deleted by $fNew branch : $deleted_files1 \n(Details : Removing $deleted_files1 from $fBranch branch while merging $fNew branch)\n"
        fi
        if [[ $deleted_files2 != "" ]]
          then
            echo -e "Deleted by $fBranch branch : $deleted_files2 \n(Details : Adding  $deleted_files2 to $fBranch branch while merging $fNew branch)\n"
        fi
        if [[ $modified_files1 != "" ]]
          then
            echo -e "Modified by both : $modified_files1 \n(Details : Modified $modified_files1 by both $fBranch branch and $fNew branch)\n"
        fi
        if [[ $added_files1 != "" ]]
          then
            echo -e "Added by both : $added_files1 \n(Details : Added $added_files1 by both $fBranch branch and $fNew branch)\n"
        fi
        echo -e "*********************************************************" 
    else    
        staged_files=`git diff --name-status --staged`
        if [[ $staged_files != "" ]]
          then
            echo -e "\n*********************************************************\nStaged files - Changes to be committed\n*********************************************************"
            staged_added_files=`git diff --name-status --staged | awk 'match($1,"A") {print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
            staged_modified_files=`git diff --name-status --staged | awk 'match($1,"M") {print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
            staged_deleted_files=`git diff --name-status --staged | awk 'match($1,"D") {print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`

            if [[ $staged_added_files != "" ]]
              then
                echo -e "Added : $staged_added_files"
            fi
            if [[ $staged_modified_files != "" ]]
              then
                echo -e "Modified : $staged_modified_files"
            fi
            if [[ $staged_deleted_files != "" ]]
              then
                echo -e "Deleted : $staged_deleted_files"
            fi
        fi

        unstaged_files=`git diff --name-only`
        if [[ $unstaged_files != "" ]]
          then
            echo -e "\n*********************************************************\nUnstaged files - Changes not staged for commit\n*********************************************************"
            unstaged_added_files=`git diff --name-status | awk 'match($1,"A") {print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
            unstaged_modified_files=`git diff --name-status | awk 'match($1,"M") {print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
            unstaged_deleted_files=`git diff --name-status | awk 'match($1,"D") {print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`

            if [[ $unstaged_added_files != "" ]]
              then
                echo -e "Added : $unstaged_added_files"
            fi
            if [[ $unstaged_modified_files != "" ]]
              then
                echo -e "Modified : $unstaged_modified_files"
            fi
            if [[ $unstaged_deleted_files != "" ]]
              then
                echo -e "Deleted : $unstaged_deleted_files"
            fi
        fi

        untracked_files=`git ls-files --others --exclude-standard`
        if [[ $untracked_files != "" ]]
          then
            echo -e "\n*********************************************************\nUntracked files\n*********************************************************"
            untracked_added_files=`git ls-files --others --exclude-standard -t | awk 'match($1,"?") {print $2}' | awk -v RS="" '{gsub (/\n/," ")}1'`
            echo -e "Added : $untracked_added_files"
        fi
        if [[ $staged_files = "" ]] && [[ $unstaged_files = "" ]] && [[ $untracked_files = "" ]]
          then
            echo -e "INFO : No files changed to commit. Thank you"
            rm $cur_dir/temp_clone.conf &> /dev/null
            rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
            exit
        fi
        echo -e "\n*********************************************************"
    fi
}


repo_dir
repo_clone
list_of_files
done < temp_clone.conf
rm $cur_dir/temp_clone.conf &> /dev/null
