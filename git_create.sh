#!/bin/sh
#set -e
awk '{if(NR>1)print}' create.conf > temp_create.conf
cur_dir="$PWD"
email=`git config user.email`
username=`git config user.name`
while IFS="|"  read -r fDir fBase fNew fURL fOwner fOwner_email live;
do
dir_repo=""
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
        git checkout $fBase &> /dev/null
        git pull origin $fBase &> /dev/null
    else
        echo -e "ERROR : Invalid base branch.\nPlease try again!"
        base_branch
    fi
}

live_branch()
{
    if [[ $live = "" ]] || [[ $flag_live = "invalid" ]]
      then
        echo "Live/Production branch :"
        read live < /dev/tty
    fi
    validate $live && flag_live="valid" || flag_live="invalid"
    if [[ ${#live} -eq 0 ]]
      then
        flag_live="invalid"
    fi
    if [ $flag_live != "valid" ]
      then
        echo -e "ERROR : Invalid live branch.\nPlease try again!"
        live_branch
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
    else
        echo -e "ERROR : Branch $fNew already exists or invalid branch name.\nPlease provide a different branch name and try again"
        new_branch
    fi
}

code_push()
{
    git push origin $1 &> /dev/null && flag_push="success" || flag_push="failed"
    if [[ $flag_push = "success" ]]
      then
        echo         
    else
        echo -e "ERROR : Code push failed! Wrong git credentials!\nPlease try again"
        code_push $1
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
            echo -e "ERROR : Invalid URL for tracker!\nPlease try again"
            download_tracker
        fi
        cd $cur_dir 
        git clone $fTrack_URL &> /dev/null
        dir_track_repo=`echo $fTrack_URL | awk -F '[/.]' '{print $(NF-1)}'`
        cd $dir_track_repo &> /dev/null && flag_tracker="valid" || flag_tracker="invalid"
        if [ $flag_tracker == "invalid" ]
          then
            echo -e "ERROR : Invalid URL for tracker!\nPlease try again"
            download_tracker
        fi

        git fetch &> /dev/null
        git checkout origin/master -- $fTrack_Path${dir_repo}_tracker.csv &> /dev/null && flag_repo_tracker="valid" || flag_repo_tracker="invalid"
        if [ $flag_repo_tracker == "invalid" ]
          then
            echo -e "WARNING : ${dir_repo}_tracker.csv file is not available in remote repository.\nCreating new ${dir_repo}_tracker.csv file."
        else
            mv ${dir_repo}_tracker.csv $cur_dir/
            git reset HEAD ${dir_repo}_tracker.csv &> /dev/null
        fi
    done < $cur_dir/temp_tracker.conf
    rm $cur_dir/temp_tracker.conf &> /dev/null
}

echo -e "Do you want to create a new branch $fNew - baselined to $fBase branch? \n\nFor Yes - Press 1\nFor No - Press 2"
read fResp < /dev/tty
if [[ $fResp = "1" ]]
  then
    #git config --global credential.helper 'cache --timeout=900'
    repo_dir
    repo_clone
    base_branch
    new_branch
    live_branch
    code_push $fNew
    download_tracker
    if [ ! -f $cur_dir/${dir_repo}_tracker.csv ]
      then
        echo "Repository name","Base Branch","New Branch","Created By","Branch Owner's Email address","Commit Id & Changed files, Status", "System Owner Git username", "System Owner's Email address", "Last Updated By", "Last Updated Email address", "Last Updated time", "Live Branch" > excel_header
        paste -sd, excel_header >> $cur_dir/${dir_repo}_tracker.csv && rm excel_header
    fi
    date=`date "+%Y-%m-%d %H:%M:%S"`
    echo $dir_repo, $fBase, $fNew, $username, $email, , "Active", $fOwner, $fOwner_email, $username, $email, $date, $live > excel_convert
    paste -sd, excel_convert >> $cur_dir/${dir_repo}_tracker.csv && rm excel_convert
    
    git checkout master &> /dev/null
    mv $cur_dir/${dir_repo}_tracker.csv . &> /dev/null
    git add ${dir_repo}_tracker.csv &> /dev/null
    git commit -m "Created new branch : $fNew" &> /dev/null
    echo -e "INFO : Updated ${dir_repo}_tracker.csv"
    code_push master
    cd ..
    rm -rf $cur_dir/$dir_track_repo
    rm $cur_dir/branches.txt $cur_dir/branches1.txt &> /dev/null
    
    echo -e "SUCCESS!\nINFO : New branch : $fNew created successfully and baselined to : $fBase branch"
elif [[ $fResp = "2" ]]
  then
    echo -e "EXIT !\nREASON : Branch creation stopped as requested.\nRECOMMENDED : Update create.conf with the required inputs and try again"
else
    echo -e "ERROR : Wrong input.\nPlease try again."
    ./git_create.sh
fi
done < temp_create.conf
rm $cur_dir/temp_create.conf &> /dev/null
