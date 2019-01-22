#!/bin/bash

basedir="$(cd $(dirname $0); pwd)"

. ${basedir}/do-commit-one.sh

files=$(git status | grep modified: | awk '{print $2}')
for file in ${files}; do
    handle_one ${file}
done
