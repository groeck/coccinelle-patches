#!/bin/bash

basedir="$(cd $(dirname $0); pwd)"

. ${basedir}/do-commit-one.sh

if [[ -n "$*" ]]; then
    files=$*
else
    files=$(git status | grep modified: | awk '{print $2}')
fi
for file in ${files}; do
    handle_one ${file}
done
