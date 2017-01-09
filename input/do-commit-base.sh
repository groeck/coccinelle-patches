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
	egrep -v "Nothing yet" > ${tmpfile}

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
    p=0
    g4=0

    findlog_common $a
    findlog_input $a
    maintainers $a
    subject=""
    msg=""
    if [ $x -ne 0 ]
    then
        subject="Drop unnecessary call to platform_set_drvdata"
	msg="There is no call to platform_get_drvdata() or dev_get_drvdata().
Drop the unnecessary call to platform_set_drvdata()."
	if [ $p -ne 0 ]
	then
		subject="${subject} and other improvements"
		msg="${msg}
Also replace '&pdev->dev' with 'dev' since dev is locally defined."
	elif [ ${g4} != 0 ]
	then
		subject="${subject} and other improvements"
		msg="${msg}
Also simplify error return."
	fi
    elif [ $y -ne 0 ]
    then
	subject="Drop unnecessary call to dev_set_drvdata"
	msg="There is no call to platform_get_drvdata() or dev_get_drvdata().
Drop the unnecessary call to platform_set_drvdata()."
	if [ $p -ne 0 ]
	then
		subject="${subject} and other improvements"
		msg="${msg}
Also replace '&pdev->dev' with 'dev' since dev is locally defined."
	fi
    elif [ $p -ne 0 ]
    then
	subject="Replace '&pdev->dev' with 'dev'"
	msg="'dev' is locally defined, so use it instead of '&pdev->dev'."
    elif [ ${g4} != 0 ]
    then
	subject="Simplify error return"
	msg="Simplify error return if the code returns anyway."
    else
	subject="Various improvements"
	msg="Various coccinelle driven transformations as detailed below."
    fi
    git commit -s \
	-m "Input: $(basename -s .c $a) - ${subject}" \
	-m "${msg}" \
	-m "The conversion was done automatically with coccinelle using the
following semantic patches. The semantic patches and the scripts
used to generate this commit log are available at
https://github.com/groeck/coccinelle-patches" \
-m "${outmsg}" \
-m "${cc}"
done
