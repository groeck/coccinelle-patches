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
	egrep -v "Dmitry Torokhov|Support Opensource" > ${tmpfile}

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
    x=0
    y=0
    z=0
    p=0
    g4=0

    findlog_common $a
    findlog_input $a
    maintainers $a
    subject=""
    msg=""
    xmsg=""
    if [ $x -ne 0 ]
    then
        xmsg="platform_set_drvdata"
	xmsg1="platform_get_drvdata"
    elif [ $y -ne 0 ]
    then
        xmsg="dev_set_drvdata"
	xmsg1="platform_get_drvdata"
    elif [ $z -ne 0 ]
    then
        xmsg="i2c_set_clientdata"
	xmsg1="i2c_get_clientdata"
    fi
    if [ -n "${xmsg}" ]
    then
        subject="Drop unnecessary call to ${xmsg}"
	msg="There is no call to ${xmsg1}() or dev_get_drvdata().
Drop the unnecessary call to ${xmsg}()."
	if [ $p -ne 0 ]
	then
		subject="${subject} and other cleanup"
		msg="${msg}
Also use 'dev' instead of dereferencing it several times."
	elif [ ${g4} != 0 ]
	then
		subject="${subject} and other cleanup"
		msg="${msg}
Also simplify error return."
	fi
    elif [ $p -ne 0 ]
    then
	subject="Use 'dev' instead of dereferencing it"
	msg="Use 'dev' instead of dereferencing it several times."
    elif [ ${g4} != 0 ]
    then
	subject="Simplify error return"
	msg="Simplify error return if the code returns anyway."
    else
	subject="Various cleanup"
	msg="Various coccinelle driven transformations as detailed below."
    fi
    git commit -s \
	-m "Input: $(basename -s .c $a) - ${subject}" \
	-m "${msg}" \
	-m "This conversion was done automatically with coccinelle using the
following semantic patches. The semantic patches and the scripts
used to generate this commit log are available at
https://github.com/groeck/coccinelle-patches" \
-m "${outmsg}" \
-m "${cc}"
done
