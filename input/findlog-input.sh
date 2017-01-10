findlog_input()
{
	local file=$1

	for action in $(grep ${file} coccinelle.log | cut -f2 -d: | sort -u)
	do
	   case "${action}" in
	   "devm1")
		outmsg="${outmsg}
- Replace input_allocate_device with devm_input_allocate_device"
		d=1
		;;
	   "worker1")
		outmsg="${outmsg}
- Call cancel_delayed_work_sync through devm_add_action_or_reset"
		d=1
		o=1
		;;
	   "other1")
		outmsg="${outmsg}
- Call sparse_keymap_free through devm_add_action_or_reset"
		d=1
		o=1
		;;
	   *)
		;;
	   esac
	done
}