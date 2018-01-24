#!/bin/sh

welcome()
{
echo -e "***********Welcome to Git automation tool***********\n\nFeel free to post your suggestions or defects, if any, to sourav_ghatak@thbs.com/sourav.ghatak@ee.co.uk\n\nPlease specify the operation you would like to perform.\n\nPress 1 for Git Clone and/or Git Checkout       (Note : Update clone_checkout.conf for cloning a git repository and/or checking out a branch)\nPress 2 for New Git Branch Creation             (Note : Update create.conf to initiate new branch creation)\nPress 3 for Git merge                           (Note : Update merge.conf to initiate git merge)\nPress 4 for Git Commit & Push                   (Note : Update push.conf to initiate git commit & push)\nPress 5 for Git Automerge                       (Note : Update automerge.conf & merge.conf to initiate git automerge)\nPress 6 for Code Healthcheck                    (Note : Update automerge.conf & merge.conf to initiate code healthcheck)\nPress 7 for Exit"
read fMaster

if [[ $fMaster == "1" ]]
  then
    ./git_clone.sh
elif [[ $fMaster == "2" ]]
  then
    ./git_create.sh
elif [[ $fMaster == "3" ]]
  then
    ./git_merge.sh
elif [[ $fMaster == "4" ]]
  then
    ./git_push.sh
elif [[ $fMaster == "5" ]]
  then
    export direct_automerge="true"
    export index=1
    ./git_automerge.sh
elif [[ $fMaster == "6" ]]
  then
    export healthcheck="true"
    export index=1
    ./git_healthcheck.sh
elif [[ $fMaster == "7" ]]
  then
    echo "Thanks! Have a nice day"
else
    echo "Wrong input! Please try again"
    welcome
fi
}

welcome
