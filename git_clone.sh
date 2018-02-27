#!/bin/bash
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

base_branch()
{
    if [[ $fBase != "" ]]
      then
        validate $fBase && flag="valid" || flag="invalid"
        if [[ $flag = "valid" ]]
          then
            git fetch &> /dev/null
            git checkout $fBase &> /dev/null
            git pull origin $fBase &> /dev/null
            echo -e "SUCCESS!\nINFO : Checked out branch : $fBase \nCodebase directory : $fDir$dir_repo"
        else
            echo -e "ERROR : Invalid branch - $fBase .\nPlease try again!"
            echo "Checkout branch :"
            read fBase < /dev/tty
            base_branch
        fi
    else
        cur_branch=`git rev-parse --abbrev-ref HEAD`
        echo -e "WARNING : No branch provided to checkout. Current branch : $cur_branch \nDo you want to checkout a different branch?\n\nFor Yes - Press 1\nFor No - Press 2"
        read fBranch < /dev/tty
        if [[ $fBranch == "2" ]]
          then
            echo -e "INFO : No changes made as requested.\nCurrent branch : $cur_branch"
        elif [[ $fBranch == "1" ]]
          then
            echo "Checkout branch :"
            read fBase < /dev/tty
            base_branch
        else
            echo -e "ERROR : Wrong input.\nPlease try again."
            base_branch
        fi
    fi
}


validate()
{
    git branch -r > $cur_dir/branches.txt
    awk '{gsub(/origin\//," ")}1' $cur_dir/branches.txt > $cur_dir/branches1.txt
    all_branches=`sed -e "/HEAD/d" $cur_dir/branches1.txt`
    echo $all_branches | grep -F -q -w "$1";
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
    clone_detail=$(git clone $fURL  2>&1 ) && flag_clone="true" || flag_clone="false"
    
    if [[ $flag_clone != "true" ]]
      then
        if [[ $clone_detail == *"already exists"* ]]
          then
            echo -e "EXIT!\nREASON : $dir_repo repository already exists in $fDir directory"
        else
            echo -e "EXIT!\nREASON : Unknown Error encountered - $clone_detail"
        fi
    else
        echo -e "SUCCESS!\nINFO : Cloned $dir_repo repository successfully\nCodebase directory : $fDir$dir_repo" 
    fi 

    cd $dir_repo &> /dev/null && flag_repo="valid" || flag_repo="invalid"
    if [ $flag_repo == "invalid" ]
      then
        echo -e "ERROR : Invalid URL!\nPlease try again"
        repo_clone
    fi
}

dir_repo=`echo $fURL | awk -F '[/.]' '{print $(NF-1)}'`

echo -e "INFO : Review the details provided in common.conf\n\n***********************************************************************************************\nDirectory for local codebase : $fDir \nURL (Git repository URL) : $fURL \nBranch : $fBase\n***********************************************************************************************\n\nPress 1 for Git Clone repository : $dir_repo \nPress 2 for Git Checkout branch: $fBase \nPress 3 for Both (Git clone and checkout) \nPress 4 for Exit"
read fResp < /dev/tty
if [[ $fResp = "1" ]]
  then
    repo_dir
    repo_clone
    #base_branch
elif [[ $fResp = "2" ]]
  then
    cd $fDir$dir_repo &> /dev/null && flag_checkout="true" || flag_checkout="false"
    if [[ $flag_checkout == "true" ]]
      then
        base_branch
    else
        echo -e "ERROR : No such directory - $fDir$dir_repo \nRECOMMENDED : Verify & update the common.conf with right inputs and try again"
    fi
elif [[ $fResp = "3" ]]
  then
    repo_dir
    repo_clone
    base_branch
elif [[ $fResp = "4" ]]
  then
    echo -e "EXIT !\nREASON : $dir_repo repository clone or branch checkout stopped as requested.\nRECOMMENDED : Update common.conf with the required inputs and try again"
else
    echo -e "ERROR : Wrong input.\nPlease try again."
    ./git_clone.sh
fi

done < temp_clone.conf
rm $cur_dir/temp_clone.conf &> /dev/null
rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
