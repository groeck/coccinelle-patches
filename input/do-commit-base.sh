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
	egrep -v "Dmitry Torokhov|Support Opensource" > ${tmpfile}

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
    x1=0
    x2=0
    x3=0
    x4=0
    p=0
    g4=0
    e=0
    o=0
    a=0
    rf=0
    dr=0

    findlog_common ${fname}
    findlog_input ${fname}
    maintainers ${fname}

    subject=""
    msg=""
    xmsg=""
    if [ $x1 -ne 0 ]
    then
	xmsg="platform_set_drvdata"
	xmsg1="platform_get_drvdata"
    elif [ $x2 -ne 0 ]
    then
	xmsg="dev_set_drvdata"
	xmsg1="platform_get_drvdata"
    elif [ $x3 -ne 0 ]
    then
	xmsg="i2c_set_clientdata"
	xmsg1="i2c_get_clientdata"
    elif [ $x4 -ne 0 ]
    then
	xmsg="spi_set_clientdata"
	xmsg1="spi_get_clientdata"
    fi
    # primary messages
    if [ -n "${xmsg}" ]
    then
	subject="Drop unnecessary call to ${xmsg}"
	msg="There is no call to ${xmsg1}() or dev_get_drvdata().
Drop the unnecessary call to ${xmsg}()."
    elif [ $p -ne 0 ]
    then
	subject="Use 'dev' instead of dereferencing it"
	msg="Use local variable 'dev' instead of dereferencing it several times."
	p=0
    elif [ $dr -ne 0 ]
    then
	subject="Use local structure pointers"
	msg="Use available local structure pointers to access structure elements."
	p=0
    elif [ ${g4} -ne 0 ]
    then
	subject="Simplify error return"
	msg="Simplify error return if the code returns anyway."
	g4=0
    elif [ $a -ne 0 ]
    then
	subject="Use devm_add_action_or_reset"
	msg="Replace devm_add_action() followed by failure action with
devm_add_action_or_reset()"
	a=0
    else
	subject="Various cleanups"
	msg="Various coccinelle driven transformations as detailed below."
    fi
    # secondary messages
    smsg="Other relevant changes:"
    if [ $p -ne 0 ]
    then
	smsg="${smsg}
  Use existing variable 'dev' instead of dereferencing it several times"
    fi
    if [ ${g4} -ne 0 ]
    then
	smsg="${smsg}
  Simplify error return"
    fi
    if [ $a -ne 0 ]
    then
	smsg="${smsg}
  Replace devm_add_action() with devm_add_action_or_reset()"
    fi
    if [ $e -ne 0 ]
    then
	smsg="${smsg}
  Drop error messages after memory allocation failures"
    fi
    if [ $rf -ne 0 ]
    then
	smsg="${smsg}
  Drop empty remove function"
    fi

    if [ "${smsg}" != "Other relevant changes:" ]
    then
	msg="${msg}
${smsg}"
    fi
    git commit -s \
	-m "Input: $(basename -s .c ${fname}) - ${subject}" \
	-m "${msg}" \
	-m "This conversion was done automatically with coccinelle.
The semantic patches and the scripts used to generate this commit log
are available at https://github.com/groeck/coccinelle-patches." \
-m "${cc}"
done
