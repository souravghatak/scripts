#!/bin/sh
#set -e
awk '{if(NR>1)print}' create.conf > temp_create.conf
cur_dir="$PWD"
while IFS="|"  read -r fDir fBase fNew fURL ;
do
dir_repo=""
repo_dir()
{
    if [[ $fDir = "" ]] || [[ $flag_dir == "invalid" ]]
      then
        echo "Provide directory to clone the repo"
        read fDir < /dev/tty
    fi
    cd $fDir && flag_dir="valid" || flag_dir="invalid"
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
        git pull origin $fBase &> /dev/null
    else
        echo "Invalid base branch. Please try again!"
        base_branch
    fi
}

new_branch()
{
    if [[ $fNew = "" ]] || [[ $flag_new = "valid" ]]
      then
        echo "New branch :"
        read fNew < /dev/tty
    fi
    validate $fNew && flag_new="valid" || flag_new="invalid"
    if [[ ${#fNew} -eq 0 ]]
      then
        flag_new="valid"
    fi
    if [ $flag_new = "invalid" ]
      then
        git checkout -b $fNew &> /dev/null
        git push origin $fNew &> /dev/null
    else
        echo "Branch $fNew already exists or invalid branch name. Please provide a different branch name and try again"
        new_branch
    fi
}

repo_clone()
{
    if [[ $fURL = "" ]] || [[ $flag_repo = "invalid" ]]
      then
        echo "Repo URL :"
        read fURL < /dev/tty
    fi

    git clone $fURL &> /dev/null 
    dir_repo=`echo $fURL | awk -F '[/.]' '{print $(NF-1)}'`
    cd $dir_repo && flag_repo="valid" || flag_repo="invalid"
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

echo "Do you want to create a new branch? (Y/N)"
read fResp < /dev/tty
if [[ $fResp = "Y" ]]
  then
    repo_dir
    repo_clone
    base_branch
    new_branch
    if [ ! -f $cur_dir/${dir_repo}_tracker.csv ]
      then
        echo "Repository name","Base Branch","New Branch" > excel_header
        paste -sd, excel_header >> $cur_dir/${dir_repo}_tracker.csv && rm excel_header
    fi
    echo $dir_repo, $fBase, $fNew > excel_convert
    paste -sd, excel_convert >> $cur_dir/${dir_repo}_tracker.csv && rm excel_convert
    rm $cur_dir/branches.txt $cur_dir/branches1.txt
    echo "New branch : $fNew created successfully and baselined to : $fBase branch"
elif [[ $fResp = "N" ]]
  then
    echo "Thank you! Have a nice day"
else
    echo "Wrong input"
    ./git_create.sh
fi
done < temp_create.conf
rm $cur_dir/temp_create.conf
