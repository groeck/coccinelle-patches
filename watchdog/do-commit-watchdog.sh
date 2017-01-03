findlog()
{
	local file=$1

	outmsg=""

	for action in $(grep ${file} coccinelle.log | cut -f2 -d: | sort -u)
	do
	   case "${action}" in
	   "c1" | "c2")
	   	outmsg="${outmsg}
- Use devm_add_action_or_reset() for calls to clk_disable_unprepare"
		;;
	   "c3")
	   	outmsg="${outmsg}
- Check return value from clk_prepare_enable()"
		;;
	   "c4")
	   	outmsg="${outmsg}
- Use devm_clk_get() if the device parameter is not NULL"
		;;
	   "c5")
	   	outmsg="${outmsg}
- Use devm_add_action_or_reset() for calls to clk_put() after clk_get()
  with NULL device parameter"
		;;
	   "d1")
		outmsg="${outmsg}
- Use devm_watchdog_register_driver() to register watchdog device"
		;;
	   "g1")
		outmsg="${outmsg}
- Replace goto followed by return with direct return"
	   	;;
	   "g3" | "g5")
		outmsg="${outmsg}
- Replace return value assignment followed by return with return"
		;;
	   "g4")
		outmsg="${outmsg}
- Replace conditional return value followed by return 0 with return value"
		;;
	   "g6")
		outmsg="${outmsg}
- Drop variable assignments if variable is unused"
		;;
	   "g7")
		outmsg="${outmsg}
- Drop unused variables"
		;;
	   "g8")
		outmsg="${outmsg}
- Drop unnecessary { } in if clauses with a single return statement"
		;;
	   "g9")
		outmsg="${outmsg}
- Drop empty remove functions"
		;;
	   "i1")
	   	outmsg="${outmsg}
- Replace request_irq() with devm_request_irq()"
		;;
	   "o1")
	   	outmsg="${outmsg}
- Use devm_add_action_or_reset() for calls to clk_put() after of_clk_get()
  and of_clk_get_by_name()"
		;;
	   "o2")
	   	outmsg="${outmsg}
- Use devm_add_action_or_reset() for calls to iounmap() after of_iomap()"
		;;
	   "p1")
	   	outmsg="${outmsg}
- Drop platform_set_drvdata()"
		;;
	   "p2")
	   	outmsg="${outmsg}
- Drop dev_set_drvdata()"
		;;
	   "p3")
	   	outmsg="${outmsg}
- Replace &pdev->dev with dev if struct device *dev exists"
		;;
	   "r1")
	   	outmsg="${outmsg}
- Use devm_add_action_or_reset for calls to unregister_reboot_notifier"
		;;
	   "r2")
	   	outmsg="${outmsg}
- Use devm_add_action_or_reset for calls to unregister_restart_handler"
		;;
	   *)
		;;
	   esac
	done
}

git status | grep modified: | awk '{print $2}' | while read a
do
    echo "Handling $a"
    git add $a
    findlog $a
    git commit -s \
	-m "watchdog: $(basename -s .c $a): Convert to use device managed functions" \
	-m "Use device managed functions to simplify error handling, reduce
source code size, improve readability, and reduce the likelyhood of bugs." \
	-m "The conversion was done automatically with coccinelle using the following
semantic patches. The semantic patches and the scripts used to generate this
commit log are available at https://github.com/groeck/coccinelle-patches." \
-m "${outmsg}"
done
