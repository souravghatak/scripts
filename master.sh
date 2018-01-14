#!/bin/sh

welcome()
{
echo -e "***********Welcome to Git automation tool***********\n\nFeel free to post your suggestions or defects, if any, to sourav_ghatak@thbs.com/sourav.ghatak@ee.co.uk\n\nPlease specify the operation you would like to perform.\n\nPress 1 for New Git Branch Creation   (Note : Update create.conf to initiate new branch creation)\nPress 2 for Git merge                 (Note : Update merge.conf to initiate git merge)\nPress 3 for Git Commit & Push         (Note : Update push.conf to initiate git commit & push)\nPress 4 for Git Automerge             (Note : Update automerge.conf & merge.conf to initiate git automerge)\nPress 5 for Exit"
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
    export direct_automerge="true"
    export index=1
    ./git_automerge.sh
elif [[ $fMaster == "5" ]]
  then
    echo "Thanks! Have a nice day"
else
    echo "Wrong input! Please try again"
    welcome
fi
}

welcome
