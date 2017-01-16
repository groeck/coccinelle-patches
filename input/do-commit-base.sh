basedir=$(cd $(dirname $0); pwd)
patchdir=${basedir}/patches

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
    x1=0
    x2=0
    x3=0
    x4=0
    p=0
    g4=0
    e=0
    o=0

    ho=0

    findlog_common $a
    findlog_input $a
    maintainers $a
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
    if [ -n "${xmsg}" ]
    then
	subject="Drop unnecessary call to ${xmsg}"
	msg="There is no call to ${xmsg1}() or dev_get_drvdata().
Drop the unnecessary call to ${xmsg}()."
	if [ $p -ne 0 ]
	then
		msg="${msg}
Also use 'dev' instead of dereferencing it several times."
		ho=1
	elif [ ${g4} != 0 ]
	then
		ho=1
		msg="${msg}
Also simplify error return."
	elif [ $e -ne 0 ]
	then
		ho=1
		msg="${msg}
Also drop error messages after memory allocation failures."
	fi
    elif [ $e -ne 0 ]
    then
	subject="Drop error messages after memory allocation failures"
	msg="${msg}
Error messages after memory allocation failures are unnecessary and
can be dropped."
	if [ $p -ne 0 ]
	then
	    ho=1
	    msg="${msg}
Also use 'dev' instead of dereferencing it several times."
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
    if [ $ho -ne 0 -o $o -ne 0 ]
    then
	    subject="${subject} and other changes"
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
    do=0
    case "$a" in
    "drivers/input/keyboard/ipaq-micro-keys.c")
	patch -p 1 < ${patchdir}/0001-drivers-input-keyboard-ipaq-micro-keys.c-fixup.patch
	do=1
	;;
    "drivers/input/misc/adxl34x-i2c.c")
	patch -p 1 < ${patchdir}/0002-drivers-input-misc-adxl34x-i2c.c-fixup.patch
	do=1
	;;
    "drivers/input/misc/tps65218-pwrbutton.c")
	patch -p 1 < ${patchdir}/0003-drivers-input-misc-tps65218-pwrbutton.c-fixup.patch
	do=1
	;;
    "drivers/input/mouse/elan_i2c_core.c")
	patch -p 1 < ${patchdir}/0004-drivers-input-mouse-elan_i2c_core.c-fixup.patch
	do=1
	;;
    "drivers/input/touchscreen/ad7879-spi.c")
	patch -p 1 < ${patchdir}/0005-drivers-input-touchscreen-ad7879-spi.c-fixup.patch
	do=1
	;;
    *)
	;;
    esac
    if [ $do -ne 0 ]
    then
	git add $a
	git commit --amend --no-edit
    fi
done
