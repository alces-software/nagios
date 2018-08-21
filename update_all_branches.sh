#!/bin/bash

if [ -z $1 ]; then
     echo "Error! Usage: $0 <file to update on all branches>"
     exit 1
fi

file_to_update="test_file.txt"

if [ ! -f ${file_to_update} ]; then
    echo "Error! ${file_to_update} non-existant!"
    exit 1
fi

echo "Updating ${file_to_update} on all branches..."

for branch in 

exit 0
