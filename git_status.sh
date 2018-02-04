#!/bin/sh

awk '{if(NR>1)print}' clone_checkout.conf > temp_clone.conf

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
    echo -e "Branch name : $fBranch"

    if [[ $status == *"You have unmerged paths."* ]]
      then
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
    fi
    
    staged_files=`git diff --name-status --staged`
    if [[ $staged_files != "" ]]
      then
        echo -e "*********************************************************\nList of staged files (Deleted/Modified/Added)\n*********************************************************"
        staged_added_files=`git diff --name-status --staged | awk 'match($1,"A") {print "Added : " $2}'`
        staged_modified_files=`git diff --name-status --staged | awk 'match($1,"M") {print "Modified : " $2}'`
        staged_deleted_files=`git diff --name-status --staged | awk 'match($1,"D") {print "Deleted : " $2}'`

        echo -e $staged_added_files"\n"$staged_modified_files"\n"$staged_deleted_files
        echo -e "*********************************************************"
    fi

    unstaged_files=`git diff --name-only`
    if [[ $unstaged_files != "" ]]
      then
        echo -e "*********************************************************\nList of unstaged files (Deleted/Modified/Added)\n*********************************************************"
        unstaged_added_files=`git diff --name-status | awk 'match($1,"A") {print "Added : " $2}'`
        unstaged_modified_files=`git diff --name-status | awk 'match($1,"M") {print "Modified : " $2}'`
        unstaged_deleted_files=`git diff --name-status | awk 'match($1,"D") {print "Deleted : " $2}'`

        echo -e $unstaged_added_files"\n"$unstaged_modified_files"\n"$unstaged_deleted_files
        echo -e "*********************************************************"
    fi

    untracked_files=`git ls-files --others --exclude-standard`
    if [[ $untracked_files != "" ]]
      then
        echo -e "*********************************************************\nList of untracked files (Deleted/Modified/Added)\n*********************************************************"
        untracked_added_files=`git ls-files --others --exclude-standard -t | awk 'match($1,"?") {print "Added : " $2}'`
        
        echo -e $untracked_added_files 
        echo -e "*********************************************************"
    fi
    if [[ $staged_files = "" ]] && [[ $unstaged_files = "" ]] && [[ $untracked_files = "" ]]
      then
        echo -e "INFO : No files changed to commit. Thank you"
        rm $cur_dir/temp_clone.conf &> /dev/null
        rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
        exit
    fi
}


repo_dir
repo_clone
list_of_files
done < temp_clone.conf
rm $cur_dir/temp_clone.conf &> /dev/null
