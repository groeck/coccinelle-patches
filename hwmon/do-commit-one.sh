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

    if [[ ! -e "${objfile}" ]]; then
	echo "$a: No object file. Skipping."
	return 0
    fi

    size1="$(cd drivers/hwmon; size ${obasename})"
    size2="$(cd drivers/hwmon/old; size ${obasename})"

    if [[ "${size1}" != "${size2}" ]]; then
	echo "${objbasename}: Object file size mismatch. Skipping."
	return 0
    fi

    if egrep -q 'SENSOR_ATTR\(|SENSOR_ATTR_2\(' $a; then
	echo "Warning: $a contains unconverted SENSOR_ATTR macros. Skipping."
	return 0
    fi
    if egrep -q 'SENSOR_DEVICE_ATTR\(|SENSOR_DEVICE_ATTR_2\(' $a; then
	echo "Warning: $a contains unconverted SENSOR_DEVICE_ATTR macros. Skipping."
	return 0
    fi
    if egrep -q "S_IR|S_IW" $a; then
	echo "Warning: $a contains permission defines. Skipping."
	return 0
    fi

    # Coccinelle sometimes leaves eight spaces instead of tabs
    sed -i -e 's/	        /		/' $a
    git add $a

    maintainers $a
    sensordev=0
    if egrep -q "SENSOR_ATTR|SENSOR_DEVICE_ATTR" $a; then
	sensordev=1
    fi

    if [[ "${sensordev}" -ne 0 ]]; then
        subject="Use permission specific [SENSOR_][DEVICE_]ATTR variants"
        msg="Use [SENSOR_][DEVICE_]ATTR[_2]_{RO,RW,WO} to simplify the source code,
to improve readbility, and to reduce the chance of inconsistencies.

Also replace any remaining S_<PERMS> in the driver with octal values."
    else
        subject="Replace S_<PERMS> with octal values"
	msg="Replace S_<PERMS> with octal values."
    fi
    msg+="

The conversion was done automatically with coccinelle. The semantic patches
and the scripts used to generate this commit log are available at
https://github.com/groeck/coccinelle-patches/hwmon/.

This patch does not introduce functional changes. It was verified by
compiling the old and new files and comparing text and data sizes.
"
    git commit -s \
	-m "hwmon: ($(basename -s .c $a)) ${subject}" \
	-m "${msg}" \
-m "${cc}"
}
