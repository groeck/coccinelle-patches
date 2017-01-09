basedir=$(cd $(dirname $0); pwd)

. ${basedir}/../common/findlog-common.sh

findlog_watchdog()
{
	local file=$1

	for action in $(grep ${file} coccinelle.log | cut -f2 -d: | sort -u)
	do
	   case "${action}" in
	   "devm1")
		outmsg="${outmsg}
- Use devm_watchdog_register_driver() to register watchdog device"
		d=1
		;;
	   "reboot1")
		outmsg="${outmsg}
- Use devm_add_action_or_reset for calls to unregister_reboot_notifier"
		d=1
		;;
	   "restart1")
		outmsg="${outmsg}
- Use devm_add_action_or_reset for calls to unregister_restart_handler"
		d=1
		;;
	   "shutdown1")
		outmsg="${outmsg}
- Replace shutdown function with call to watchdog_stop_on_reboot()"
		o=1
		s=1
		;;
	   *)
		;;
	   esac
	done
}

maintainers()
{
    local file=$1
    local tmpfile=/tmp/watchdog.$$
    local m

    cc=""

    scripts/get_maintainer.pl --no-l --no-rolestats ${file} | \
	egrep -v "Guenter Roeck|Wim Van" > ${tmpfile}

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
    s=0

    findlog_common $a
    findlog_watchdog $a
    maintainers $a
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
    else
        if [ $s -ne 0 ]
	then
		subject="Replace shutdown function with call to watchdog_stop_on_reboot"
		msg="The shutdown function calls the stop function.
Call watchdog_stop_on_reboot() from probe instead."
	else
		subject="Various improvements"
		msg="Various coccinelle driven transformations as detailed below."
	fi
    fi
    git commit -s \
	-m "watchdog: $(basename -s .c $a): ${subject}" \
	-m "${msg}" \
	-m "The conversion was done automatically with coccinelle using the
following semantic patches. The semantic patches and the scripts used
to generate this commit log are available at
https://github.com/groeck/coccinelle-patches" \
-m "${outmsg}" \
-m "${cc}"
done
