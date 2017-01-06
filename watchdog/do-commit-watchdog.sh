findlog()
{
	local file=$1

	outmsg=""
	d=0
	o=0
	s=1

	for action in $(grep ${file} coccinelle.log | cut -f2 -d: | sort -u)
	do
	   case "${action}" in
	   "c1" | "c2")
		outmsg="${outmsg}
- Use devm_add_action_or_reset() for calls to clk_disable_unprepare"
		d=1
		;;
	   "c3")
		outmsg="${outmsg}
- Check return value from clk_prepare_enable()"
		o=1
		;;
	   "c4")
		outmsg="${outmsg}
- Use devm_clk_get() if the device parameter is not NULL"
		d=1
		;;
	   "c5")
		outmsg="${outmsg}
- Use devm_add_action_or_reset() for calls to clk_put() after clk_get()
  with NULL device parameter"
		d=1
		;;
	   "d1")
		outmsg="${outmsg}
- Use devm_watchdog_register_driver() to register watchdog device"
		d=1
		;;
	   "g1")
		outmsg="${outmsg}
- Replace 'goto l; ... l: return e;' with 'return e;'"
		;;
	   "g3" | "g5")
		outmsg="${outmsg}
- Replace 'val = e; return val;' with 'return e;'"
		;;
	   "g4")
		outmsg="${outmsg}
- Replace 'if (e) return e; return 0;' with 'return e;'"
		;;
	   "g6")
		outmsg="${outmsg}
- Drop assignments to unused variables"
		;;
	   "g7")
		outmsg="${outmsg}
- Drop unused variables"
		;;
	   "g8")
		outmsg="${outmsg}
- replace 'if (e) { return expr; }' with 'if (e) return expr;'"
		;;
	   "g9")
		outmsg="${outmsg}
- Drop remove function"
		;;
	   "i1")
		outmsg="${outmsg}
- Replace request_irq() with devm_request_irq()"
		d=1
		;;
	   "o1a")
		outmsg="${outmsg}
- Replace 'of_clk_get(np, 0)' with 'devm_clk_get(dev, NULL)'"
		d=1
		;;
	   "o1b")
		outmsg="${outmsg}
- Replace 'of_clk_get_by_name(np, name)' with 'devm_clk_get(dev, name)'"
		d=1
		;;
	   "o2")
		outmsg="${outmsg}
- Replace of_iomap() with platform_get_resource() followed by
  devm_ioremap_resource()"
		d=1
		;;
	   "p1")
		outmsg="${outmsg}
- Drop no longer required platform_set_drvdata()"
		;;
	   "p2")
		outmsg="${outmsg}
- Drop no longer required dev_set_drvdata()"
		;;
	   "p3")
		outmsg="${outmsg}
- Replace &pdev->dev with dev if 'struct device *dev' is a declared
  variable"
		;;
	   "r1")
		outmsg="${outmsg}
- Use devm_add_action_or_reset for calls to unregister_reboot_notifier"
		d=1
		;;
	   "r2")
		outmsg="${outmsg}
- Use devm_add_action_or_reset for calls to unregister_restart_handler"
		d=1
		;;
	   "s1")
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
    findlog $a
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
