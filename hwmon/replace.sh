#!/bin/bash

if [[ ! -e $1 ]]; then
	echo "No such file: $1"
	exit 1
fi

basedir="$(cd $(dirname $0); pwd)"
. ${basedir}/do-commit-one.sh

run()
{
    echo $1

    make coccicheck COCCI=${basedir}/$1.cocci SPFLAGS="--linux-spacing" \
	MODE=patch M=$2 | patch -p 1
}

# Remove multi-line macros starting with a lowercase letter
sed -i -e '/#define [a-z].*\\/,/[^\\]$/d' $1
# Remove multiple empty lines
sed -i -n '/./,/^$/p' $1

run replace $1
run sensor-attr-w2 $1
run sensor-devattr-w8 $1
run permissions $1

if ! make -j ${1/%.c/.o}; then
	echo "test build failed - check output"
	exit 1
fi

handle_one $1
