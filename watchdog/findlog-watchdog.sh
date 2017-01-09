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
