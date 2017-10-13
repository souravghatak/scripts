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

list_of_modules()
{
    module_list=`git status -s`
    echo $module_list
    deleted_modules=`${module_list} | grep D`
    echo $deleted_modules
}
repo_dir
list_of_modules

done < temp_push.conf
rm $cur_dir/temp_push.conf &> /dev/null
