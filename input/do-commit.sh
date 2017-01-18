basedir=$(cd $(dirname $0); pwd)

. ${basedir}/../common/findlog-common.sh
. ${basedir}/findlog-input.sh

maintainers()
{
    local file=$1
    local tmpfile=/tmp/input.$$
    local m

    cc=""

    scripts/get_maintainer.pl --no-l --nogit-fallback --no-rolestats ${file} | \
	egrep -v "Dmitry Torokhov|Guenter Roeck|Support Opensource|bcm-kernel-feedback-list" > ${tmpfile}

    while read -r m
    do
	cc="${cc}
Cc: $m"
    done < ${tmpfile}

    rm -f ${tmpfile}
}

git status | grep modified: | awk '{print $2}' | while read fname
do
    echo "Handling ${fname}"
    git add ${fname}

    outmsg=""
    a=0
    d=0
    o=0
    e=0
    r=0
    p=0
    x1=0
    x2=0
    x3=0
    x4=0
    rf=0

    findlog_common ${fname}
    findlog_input ${fname}
    maintainers ${fname}

    o=$(($o + $a + $p + $x1 + $x2 + $x3 + $x4 + $e + $r + $rf))
    subject=""
    msg=""
    if [ $d -ne 0 ]
    then
        subject="Use device managed functions"
	msg="Use device managed functions to simplify error handling, reduce
source code size, improve readability, and reduce the likelyhood of bugs."
	if [ $o -ne 0 ]
	then
		o=2
	fi
    elif [ $e -ne 0 ]
    then
	subject="Drop unnecessary error messages"
	msg="The kernel already displays an error message after memory
allocation failures. Messages in the driver are unnecessary."
    elif [ $r -ne 0 ]
    then
	subject="Drop unnecessary cleanup calls"
	msg="Calling dev_set_drvdata() or device_init_wakeup() from a
driver's remove function is unnecessary and can be dropped."
    else
	subject="Various improvements"
	msg="Various coccinelle driven transformations as detailed below."
    fi
    if [ $o -gt 1 ]
    then
	subject="${subject} and other changes"
	msg="${msg}
Other changes as listed below."
    fi
    git commit -s \
	-m "Input: $(basename -s .c ${fname}) - ${subject}" \
	-m "${msg}" \
	-m "The conversion was done automatically with coccinelle using the
following semantic patches. The semantic patches and the scripts used
to generate this commit log are available at
https://github.com/groeck/coccinelle-patches" \
-m "${outmsg}" \
-m "${cc}"
done
