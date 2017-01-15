basedir=$(cd $(dirname $0); pwd)

. ${basedir}/../common/findlog-common.sh
. ${basedir}/findlog-input.sh

maintainers()
{
    local file=$1
    local tmpfile=/tmp/input.$$
    local m

    cc=""

    scripts/get_maintainer.pl --no-l --no-rolestats ${file} | \
	egrep -v "Dmitry Torokhov|Guenter Roeck|Support Opensource|bcm-kernel-feedback-list" > ${tmpfile}

    while read -r m
    do
	cc="${cc}
Cc: $m"
    done < ${tmpfile}

    rm -f ${tmpfile}
}

git status | grep modified: | awk '{print $2}' | while read a
do
    echo "Handling $a"
    git add $a

    outmsg=""
    d=0
    o=0
    e=0
    r=0
    x1=0
    x2=0
    x3=0
    x4=0

    findlog_common $a
    findlog_input $a
    maintainers $a

    o=$(($o + $x1 + $x2 + $x3 + $x4 + $e + $r))
    subject=""
    msg=""
    if [ $d -ne 0 ]
    then
        subject="Convert to use device managed functions"
	msg="Use device managed functions to simplify error handling, reduce
source code size, improve readability, and reduce the likelyhood of bugs."
	if [ $o -ne 0 ]
	then
		subject="${subject} and other improvements"
		msg="${msg}
Other improvements as listed below."
	fi
    elif [ $e -ne 0 ]
    then
	subject="Drop unnecessary error messages"
	msg="The kernel already displays an error message after memory
allocation failures. Messages in the driver are unnecessary."
	if [ $o -gt 1 ]
	then
		subject="${subject} and other improvements"
		msg="${msg}
Other improvements as listed below."
	fi
    elif [ $r -ne 0 ]
    then
	subject="Drop unnecessary cleanup calls"
	msg="Calling dev_set_drvdata() or device_init_wakeup() from a
driver's remove function is unnecessary and can be dropped."
	if [ $o -gt 1 ]
	then
		subject="${subject} and other improvements"
		msg="${msg}
Other improvements as listed below."
	fi
    else
	subject="Various improvements"
	msg="Various coccinelle driven transformations as detailed below."
    fi
    git commit -s \
	-m "Input: $(basename -s .c $a) - ${subject}" \
	-m "${msg}" \
	-m "The conversion was done automatically with coccinelle using the
following semantic patches. The semantic patches and the scripts used
to generate this commit log are available at
https://github.com/groeck/coccinelle-patches" \
-m "${outmsg}" \
-m "${cc}"
done
