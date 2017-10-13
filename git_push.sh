#!/bin/sh

awk '{if(NR>1)print}' push.conf > temp_push.conf
cur_dir=`pwd`

while IFS="|"  read -r fDir fBase ;
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
    #module_list=`git status -s`
    #echo $module_list
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
}

git_add()
{
    echo "Do you want to push all the above files? (Y/N)"
    read fFile < /dev/tty
    if [[ $fFile = "Y" ]]
      then
        git add --all
    elif [[ $fFile = "N" ]]
      then
        echo "Please specify the file names below (space separated)"
        read fModules < /dev/tty
        git add $fModules &> /dev/null
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
        git_push
    fi
}
repo_dir
list_of_files
git_add
git_commit
git_push_decide
done < temp_push.conf
rm $cur_dir/temp_push.conf &> /dev/null
