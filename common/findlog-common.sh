findlog_common()
{
	local file=$1

	outmsg_common=""

	for action in $(grep ${file} coccinelle.log | cut -f2 -d: | sort -u)
	do
	   case "${action}" in
	   "clk1")
		outmsg="${outmsg}
- Use devm_add_action_or_reset() for calls to clk_disable_unprepare"
		d=1
		;;
	   "clk3")
		outmsg="${outmsg}
- Check return value from clk_prepare_enable()"
		o=1
		;;
	   "clk4")
		outmsg="${outmsg}
- Use devm_clk_get() if the device parameter is not NULL"
		d=1
		;;
	   "clk5")
		outmsg="${outmsg}
- Use devm_add_action_or_reset() for calls to clk_put() after clk_get()
  with NULL device parameter"
		d=1
		;;
	   "goto1")
		outmsg="${outmsg}
- Replace 'goto l; ... l: return e;' with 'return e;'"
		;;
	   "goto3")
		outmsg="${outmsg}
- Replace 'val = e; return val;' with 'return e;'"
		;;
	   "goto4")
		outmsg="${outmsg}
- Replace 'if (e) return e; return 0;' with 'return e;'"
		g4=1
		;;
	    "cleanup1")
		outmsg="${outmsg}
- Drop assignments to otherwise unused variables"
		;;
	    "cleanup2")
		outmsg="${outmsg}
- Drop unused variables"
		;;
	    "cleanup3")
		outmsg="${outmsg}
- Replace 'if (e) { return expr; }' with 'if (e) return expr;'"
		;;
	    "cleanup4")
		outmsg="${outmsg}
- Drop remove function"
		;;
	    "cleanup5" | "cleanup6")
		# No message for now
		;;
	    "drop1")
		outmsg="${outmsg}
- Drop 'dev_set_drvdata(dev, NULL);'"
		r=1
		;;
	    "drop2")
		outmsg="${outmsg}
- Drop 'device_init_wakeup();' from remove function"
		r=1
		;;
	    "gpio1")
		outmsg="${outmsg}
- Replace gpio_request with devm_gpio_request and gpio_request_one with
  devm_gpio_request_one"
		d=1
		;;
	    "ioremap1")
		outmsg="${outmsg}
- Replace ioremap with devm_ioremap and ioremap_nocache with
  devm_ioremap_nocache"
		d=1
		;;
	    "ioremap2")
		outmsg="${outmsg}
- Replace ioremap with devm_ioremap_resource"
		d=1
		;;
	    "ioremap3")
		outmsg="${outmsg}
- Replace request_mem_region or platform_get_resource followed by ioremap
  with devm_ioremap_resource"
		d=1
		;;
	    "irq1")
		outmsg="${outmsg}
- Replace request_irq, request_threaded_irq, and request_any_context_irq
  with their device managed equivalent"
		d=1
		;;
	    "kzalloc1")
		outmsg="${outmsg}
- Replace kzalloc with devm_kzalloc and kmalloc with devm_kmalloc"
		d=1
		;;
	   "mutex1")
		outmsg="${outmsg}
- Drop unnecessary mutex_destroy() on allocated data"
		o=1
		;;
	   "ofclk1")
		outmsg="${outmsg}
- Replace 'of_clk_get(np, 0)' with 'devm_clk_get(dev, NULL)'"
		d=1
		;;
	   "ofclk2")
		outmsg="${outmsg}
- Replace 'of_clk_get_by_name(np, name)' with 'devm_clk_get(dev, name)'"
		d=1
		;;
	   "ofiomap1")
		outmsg="${outmsg}
- Replace of_iomap() with platform_get_resource() followed by
  devm_ioremap_resource()"
		d=1
		;;
	   "pdata1")
		outmsg="${outmsg}
- Drop platform_set_drvdata()"
		x1=1
		;;
	   "pdata2")
		outmsg="${outmsg}
- Drop dev_set_drvdata()"
		x2=1
		;;
	   "pdata3")
		outmsg="${outmsg}
- Drop i2c_set_clientdata()"
		x3=1
		;;
	   "pdata4")
		outmsg="${outmsg}
- Drop spi_set_clientdata()"
		x4=1
		;;
	   "pdev1")
		outmsg="${outmsg}
- Use local variable 'struct device *dev' consistently"
		p=1
		;;
	   "pdev2")
		outmsg="${outmsg}
- Introduce local variable 'struct device *dev' and use it instead of
  dereferencing it repeatedly"
		p=2
		;;
	   "timer1")
		outmsg="${outmsg}
- Call del_timer() using devm_add_action()"
		d=1
		;;
	   "timer2")
		outmsg="${outmsg}
- Call del_timer_sync() using devm_add_action()
  Introduce helper function since we can not call del_timer_sync() directly"
		d=1
		;;
	    "worker1")
		outmsg="${outmsg}
- Call cancel_delayed_work_sync() using devm_add_action_or_reset()"
		o=1
		;;
	   "devm_kzalloc1")
		outmsg="${outmsg}
- Drop error message after devm_kzalloc() failure"
		e=1
		;;
	    "action1")
		outmsg="${outmsg}
- Replace devm_add_action() followed by failure action with
  devm_add_action_or_reset()"
		o=1
		;;
	   *)
		;;
	   esac
	done
}
