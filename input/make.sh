subdir=${1:-drivers/input}
basedir=$(cd $(dirname $0); pwd)

noclean=$2

rm -f coccinelle.log

run()
{
    echo $1

    make coccicheck COCCI=${basedir}/$1.cocci SPFLAGS="--linux-spacing" \
	MODE=patch M=${subdir} | patch -p 1
}

run devm
run serio
# run errmsg
run keypad
run gpio_array
run pxa_ssp
run mcs_touchkey
run ep93xx_keypad
run nomadik
run gp2a

run ../common/worker
run ../common/ioremap_resource
run ../common/ioremap_resource_assigned
run ../common/ioremap
run ../common/kzalloc
# run ../common/devm_kzalloc
run ../common/gpio
run ../common/clk_get
run ../common/timer
run ../common/pwm_get
# run ../common/of_clk
run ../common/clkreturn
run ../common/clk2
# run ../common/clk
# run ../common/of_iomap
# run ../common/mutex_destroy
run ../common/irq
run ../common/action
run ../common/pdev
run ../common/deref

run ../common/drop

# 1st round of cleanup
run ../common/goto
run ../common/cleanup
run ../common/pdata

# input specific cleanup
run cleanup

# 2nd round of cleanup
run ../common/goto
run ../common/cleanup
run ../common/pdata

# 3rd round of cleanup.
run ../common/goto
run ../common/cleanup

# 4th round. Still more gotos to drop.
run ../common/goto

if [ -n "${noclean}" ]
then
    exit 0
fi

cleanup()
{
	if [ -e $1 ]
	then
		rm $1; git checkout $1
	fi
}

# drivers/input/keyboard/adp5588-keys.c
#	adp5588_gpio_remove
#   	->  Not really needed because adp5588_gpio_add() is called last
#	    in the probe function
# drivers/input/keyboard/adp5589-keys.c
#	adp5589_gpio_remove
#   	->  Not really needed because adp5589_gpio_add() is called last
#	    in the probe function

# drivers/input/keyboard/mcs_touchkey.c
#	handle:
#		if (data->poweron)
#			data->poweron(false);
#	-> mcs_touchkey.cocci

# rejected in base

cleanup drivers/input/misc/axp20x-pek.c
cleanup drivers/input/mouse/cyapa.c
cleanup drivers/input/touchscreen/atmel_mxt_ts.c
cleanup drivers/input/touchscreen/elants_i2c.c
cleanup drivers/input/touchscreen/melfas_mip4.c
cleanup drivers/input/touchscreen/raydium_i2c_ts.c
cleanup drivers/input/touchscreen/rohm_bu21023.c

# cosmetic

cleanup drivers/input/keyboard/goldfish_events.c
cleanup drivers/input/keyboard/mpr121_touchkey.c
cleanup drivers/input/mouse/synaptics_i2c.c
cleanup drivers/input/rmi4/rmi_smbus.c
cleanup drivers/input/rmi4/rmi_spi.c
cleanup drivers/input/touchscreen/ad7877.c
cleanup drivers/input/touchscreen/ads7846.c
cleanup drivers/input/touchscreen/bu21013_ts.c
cleanup drivers/input/touchscreen/jornada720_ts.c
cleanup drivers/input/touchscreen/st1232.c
cleanup drivers/input/touchscreen/surface3_spi.c

cleanup drivers/input/keyboard/cap11xx.c
cleanup drivers/input/keyboard/sun4i-lradc-keys.c
cleanup drivers/input/touchscreen/88pm860x-ts.c
cleanup drivers/input/touchscreen/auo-pixcir-ts.c
cleanup drivers/input/touchscreen/max11801_ts.c
cleanup drivers/input/touchscreen/sx8654.c

# The following patches are known to be broken, problematic, or cosmetic

# cleanup drivers/input/keyboard/adp5520-keys.c	# cosmetic (err msg)
cleanup drivers/input/keyboard/bcm-keypad.c	# bad clk_prepare_enable hndl
cleanup drivers/input/keyboard/bf54x-keys.c	# peripheral_free_list
# cleanup drivers/input/keyboard/ep93xx_keypad.c # conditional clk_disable
						# should be ok
cleanup drivers/input/keyboard/imx_keypad.c	# bad clk_prepare_enable hndl 
# cleanup drivers/input/keyboard/gpio_keys.c	# cosmetic (err msg)
# cleanup drivers/input/keyboard/gpio_keys_polled.c # cosmetic (err msg)
cleanup drivers/input/keyboard/lm8323.c		# various
cleanup drivers/input/keyboard/lpc32xx-keys.c	# wrong (clk_enable...)
# cleanup drivers/input/keyboard/max7359_keypad.c # cosmetic (err msg)
cleanup drivers/input/keyboard/omap-keypad.c	# device_remove_file, gpio_free,
						# tasklet_kill,
						# ...
# cleanup drivers/input/keyboard/omap4-keypad.c	# pm, device_init_wakeup
						# cleanup reorder should be safe
cleanup drivers/input/keyboard/pxa27x_keypad.c	# cosmetic
cleanup drivers/input/keyboard/samsung-keypad.c	# various
cleanup drivers/input/keyboard/sh_keysc.c	# pwm
cleanup drivers/input/keyboard/spear-keyboard.c	# clk_prepare/clk_unprepare,
						# input_unregister_device called
						# even though devm_input_allocate_device
						# is already used
cleanup drivers/input/keyboard/tc3589x-keypad.c	# cosmetic
cleanup drivers/input/keyboard/tca6416-keypad.c	# irq handling 
# cleanup drivers/input/misc/88pm80x_onkey.c	# irq handling
						# should be ok (released first)
cleanup drivers/input/misc/bfin_rotary.c	# cosmetic
cleanup drivers/input/misc/bma150.c		# various
cleanup drivers/input/misc/drv2667.c		# cosmetic
cleanup drivers/input/misc/ixp4xx-beeper.c	# removal complexity
cleanup drivers/input/misc/kxtj9.c		# complex
cleanup drivers/input/misc/m68kspkr.c		# cleanup sequence
						# (m68kspkr_event last)
cleanup drivers/input/misc/max8997_haptic.c	# pwm, regulator
# cleanup drivers/input/misc/mpu3050.c		# pwm
						# should be safe (removal # sequence not changed)
cleanup drivers/input/misc/pcspkr.c		# cleanup sequence
						# pcspkr_event comes last
# cleanup drivers/input/misc/sparcspkr.c	# of_ioremap
# 						# should be ok
cleanup drivers/input/misc/wistron_btns.c	# cosmetic
cleanup drivers/input/mouse/cyapa.c		# cosmetic
cleanup drivers/input/mouse/elan_i2c_core.c	# cosmetic
cleanup drivers/input/mouse/synaptics_i2c.c	# unsynchronized kfree (indirect)
cleanup drivers/input/serio/altera_ps2.c	# no improvement
cleanup drivers/input/serio/arc_ps2.c		# incomplete
cleanup drivers/input/serio/at32psif.c		# misses non-serio kzalloc/kfree
cleanup drivers/input/serio/ct82c710.c		# no value
cleanup drivers/input/serio/maceps2.c		# not worth it
cleanup drivers/input/serio/q40kbd.c		# missed kzalloc/kfree
cleanup drivers/input/serio/rpckbd.c		# missed kzalloc/kfree
cleanup drivers/input/serio/sun4i-ps2.c		# missed kzalloc/kfree
cleanup drivers/input/serio/xilinx_ps2.c	# removal complexity
cleanup drivers/input/touchscreen/ad7877.c	# wrong
						# free_irq, sysfs_remove_group
cleanup drivers/input/touchscreen/ads7846.c	# wrong, incomplete
cleanup drivers/input/touchscreen/ad7879-spi.c	# wrong
cleanup drivers/input/touchscreen/atmel-wm97xx.c # wrong, incomplete
cleanup drivers/input/touchscreen/atmel_mxt_ts.c # wrong
cleanup drivers/input/touchscreen/bu21013_ts.c	# regulator
cleanup drivers/input/touchscreen/chipone_icn8318.c # cosmetic
cleanup drivers/input/touchscreen/cy8ctmg110_ts.c # removal complexity
cleanup drivers/input/touchscreen/da9034-ts.c	# cosmetic
cleanup drivers/input/touchscreen/eeti_ts.c	# free_irq followed by enable_irq
cleanup drivers/input/touchscreen/egalax_ts.c	# cosmetic, wrong in egalax_wake_up_device
cleanup drivers/input/touchscreen/ektf2127.c	# cosmetic
cleanup drivers/input/touchscreen/goodix.c	# cosmetic
cleanup drivers/input/touchscreen/ili210x.c	# missed free_irq
cleanup drivers/input/touchscreen/mainstone-wm97xx.c # cosmetic
cleanup drivers/input/touchscreen/raydium_i2c_ts.c # wrong
cleanup drivers/input/touchscreen/s3c2410_ts.c	# del_timer_sync failed
cleanup drivers/input/touchscreen/st1232.c	# not worth it
cleanup drivers/input/touchscreen/ti_am335x_tsc.c # removal complexity
cleanup drivers/input/touchscreen/zylonite-wm97xx.c # cosmetic
