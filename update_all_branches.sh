#!/bin/bash

# get the file we want to add or remove 
#     a commit message
#     whether we want to add or remove a file.

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]; then
     echo "Error! Usage: $0 <file to update on all branches> <commit message> <[add|rm]>"
     echo "e.g. : $0 new_file.sh file-to-do-something add"
     echo "       $0 old_file.sh file-that-does-something rm"
     exit 1
fi

# Ensure the third parameter really is add or remove

if [ "$3" != "add" ] && [ "$3" != "rm" ]; then
    echo "Error! third argument MUST be either add or rm!"
    exit 1
fi	

file_to_update="test_file.txt"
commit_message=$2
git_op=$3

if [ ! -f ${file_to_update} ]; then
    echo "Error! ${file_to_update} non-existant!"
    exit 1
fi

echo "I will ${git_op} ${file_to_update} to/from all branches .."

if [ "${git_op}" == "add" ]; then
    mkdir /tmp/git
    if [ $? -ne 0 ]; then
        echo "Error! Unable to create /tmp/git"
        exit 1
    fi

    cp ${file_to_update} /tmp/git
    if [ $? -ne 0 ]; then
        echo "Error! Unable to cp ${file_to_update} to /tmp/git"
        exit 1  
    fi
fi

# Let's keep track of the branch we're in now.

initial_branch=`git status | head -1 | grep -o "[[:alnum:]]*$"`

# Iterate through each branch. 
# Tr is used to remove the * character, that is output
#    by git branch, to specify the current branch

for branch in `git branch | tr -d \*`; do
   
    echo "Updating ${file_to_update} on ${branch}"
    echo "Switching to ${branch}..."
    
    git checkout ${branch} 
    
    if [ $? -ne 0 ]; then
        echo "Error! Unable to switch to branch: ${branch}"
        exit 1
    fi
	
    echo "Now in branch: ${branch}"

    cp /tmp/git/${file_to_update} .
    if [ $? -ne 0 ]; then
        echo "Error! Unable to copy ${file_to_update} from /tmp/git to `pwd`"
	exit 1
    fi

    git ${git_op} ${file_to_update}
    if [ $? -ne 0]; then
        echo "Error! Unable to add ${file_to_update} to ${branch}"
	exit 1
    fi

    git commit -m "${commit_message}"
    if [ $? -ne 0 ]; then
        echo "Error! Unable to commit to ${branch} branch!"
	exit 1
    fi

    git push origin ${branch}
    if [ $? -ne 0 ]; then
        echo "Error! Unable to push to ${branch}"
	exit 1
    fi

    echo "Success! Branch: ${branch} has now been updated."
done


# Remove the temporary file
if [ "${git_op}" == "add" ]; then
    rm -rf /tmp/git
    if [ $? -ne 0 ]; then
   	echo "Error! Something went wrong during the cleanup operation"
	exit 1
    fi
fi

# Return to the branch we were on prior to updating all branches.

git checkout ${initial_branch}
if [ $? - ne 0 ]; then
    echo "Error! Unable to return to ${initial_branch}"
fi

echo "Back on branch: ${initial_branch}"
echo "Done."

exit 0
