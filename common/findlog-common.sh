findlog_common()
{
	local file=$1

	outmsg_common=""

	for action in $(grep ${file} coccinelle.log | cut -f2 -d: | sort -u)
	do
	   case "${action}" in
	   "clk1" | "clk2")
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
	   "goto3" | "goto5")
		outmsg="${outmsg}
- Replace 'val = e; return val;' with 'return e;'"
		;;
	   "goto4")
		outmsg="${outmsg}
- Replace 'if (e) return e; return 0;' with 'return e;'"
		g4=1
		;;
	   "goto6")
		outmsg="${outmsg}
- Drop assignments to unused variables"
		;;
	   "goto7")
		outmsg="${outmsg}
- Drop unused variables"
		;;
	   "goto8")
		outmsg="${outmsg}
- replace 'if (e) { return expr; }' with 'if (e) return expr;'"
		;;
	   "goto9")
		outmsg="${outmsg}
- Drop remove function"
		;;
	   "goto10" | "goto11")
	   	# No message for now
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
- Replace kzalloc and kmalloc with devm_kzalloc"
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
		x=1
		;;
	   "pdata2")
		outmsg="${outmsg}
- Drop dev_set_drvdata()"
		y=1
		;;
	   "pdev1")
		outmsg="${outmsg}
- Replace &pdev->dev with dev if 'struct device *dev' is a declared
  variable"
  		p=1
		;;
	   "timer1")
		outmsg="${outmsg}
- Call del_timer() using devm_add_action()"
		d=1
		;;
	   *)
		;;
	   esac
	done
}
