#!/bin/bash

basedir="$(cd $(dirname $0); pwd)"

maintainers()
{
    local file="$1"
    local tmpfile="$(mktemp)"
    local m

    cc=""

    scripts/get_maintainer.pl --no-l --no-rolestats ${file} | \
	egrep -v "Roeck|Delvare" > ${tmpfile}

    while read -r m; do
	cc="${cc}
Cc: $m"
    done < ${tmpfile}

    rm -f ${tmpfile}
}

handle_one()
{
    local a="$1"
    local objfile="${a/%.c/.o}"
    local obasename="$(basename ${objfile})"

    echo "Handling $a"

    # Coccinelle sometimes leaves eight spaces instead of tabs
    sed -i -e 's/	        /		/' $a
    git add $a

    maintainers $a

    subject="Use HWMON_CHANNEL_INFO macro"
    msg="The HWMON_CHANNEL_INFO macro simplifies the code, reduces the likelihood
of errors, and makes the code easier to read."

    msg+="

The conversion was done automatically with coccinelle. The semantic patch
used to make this change is as follows.
"

    msg+="$(cat ${basedir}/channel-info.cocci | egrep -v virtual)"
    msg+="

This patch does not introduce functional changes. Many thanks to
Julia Lawall for providing the patch.

"
    git commit -s \
	-m "hwmon: ($(basename -s .c $a)) ${subject}" \
	-m "${msg}" \
-m "${cc}"
}
