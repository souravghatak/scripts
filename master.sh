#!/bin/sh

welcome()
{
echo -e "***********Welcome to Git automation tool***********\n\nPlease specify the operation you would like to perform.\n\n\nPress 1 for New Git Branch Creation\nPress 2 for Git merge\nPress 3 for Git push\nPress 4 for Exit"
read fMaster
if [[ $fMaster == "1" ]]
  then
    ./git_create.sh
elif [[ $fMaster == "2" ]]
  then
    ./git_merge.sh
elif [[ $fMaster == "3" ]]
  then
    ./git_push.sh
elif [[ $fMaster == "4" ]]
  then
    echo "Thanks! Have a nice day"
else
    echo "Wrong input! Please try again"
    welcome
fi
}

welcome
