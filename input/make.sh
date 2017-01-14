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
run errmsg
run keypad
run gpio_array
run pxa_ssp
run ../common/worker
run ../common/ioremap_resource
run ../common/ioremap_resource_assigned
run ../common/ioremap
run ../common/kzalloc
run ../common/devm_kzalloc
run ../common/gpio
run ../common/clk_get
# run ../common/of_clk
run ../common/clkreturn
run ../common/clk2
# run ../common/clk
# run ../common/of_iomap
# run ../common/mutex_destroy
run ../common/irq
run ../common/pdev

# 1st round of cleanup
run ../common/goto
run ../common/cleanup
run ../common/pdata

# input specific cleanup
run cleanup
run nomadik
run gp2a

# 2nd round of cleanup
run ../common/goto
run ../common/cleanup
run ../common/pdata

# 3rd round of cleanup. Only goto needed here.
run ../common/goto

if [ -n "${noclean}" ]
then
    exit 0
fi

cleanup()
{
	rm $1; git checkout $1
}

# drivers/input/keyboard/adp5588-keys.c
#	adp5588_gpio_remove
#   	->  Not really needed because adp5588_gpio_add() is called last
#	    in the probe function
# drivers/input/keyboard/adp5589-keys.c
#	adp5589_gpio_remove
#   	->  Not really needed because adp5589_gpio_add() is called last
#	    in the probe function
# drivers/input/misc/gpio_tilt_polled.c
#	gpio_free_array
#	-> gpio_array.cocci

# drivers/input/keyboard/matrix_keypad.c
#	matrix_keypad_free_gpio
#	-> Free function no longer needed at all since
#	   probe function uses devm_ calls.
#	-> cleanup.cocci

# drivers/input/keyboard/nomadik-ske-keypad.c
#	Needs to address
#		if (keypad->board->exit)
#	                keypad->board->exit();
#	-> nomadik.cocci

# drivers/input/misc/gp2ap002a00f.c
#	Need to address
#		if (pdata->hw_shutdown)
#	                pdata->hw_shutdown(client);
#	-> gp2a.cocci

# drivers/input/mouse/gpio_mouse.c
#	Revisit. Manual cleanup ?
# cleanup drivers/input/mouse/gpio_mouse.c

# drivers/input/mouse/navpoint.c
#	Needs to address pxa_ssp_free().
#	-> pxa_ssp.cocci

cleanup drivers/input/serio/at32psif.c		# misses non-serio kzalloc/kfree

# The following patches are known to be broken, problematic, or cosmetic

# cleanup drivers/input/keyboard/adp5520-keys.c	# cosmetic
cleanup drivers/input/keyboard/bf54x-keys.c	# del_timer_sync, peripheral_free_list
cleanup drivers/input/keyboard/ep93xx_keypad.c	# ep93xx_keypad_release_gpio,
						# conditional clk_disable
cleanup drivers/input/keyboard/imx_keypad.c	# wrong (clk_enable_prepare!)
# cleanup drivers/input/keyboard/gpio_keys.c	# cosmetic
cleanup drivers/input/keyboard/gpio_keys_polled.c # cosmetic
cleanup drivers/input/keyboard/lm8323.c		# various
cleanup drivers/input/keyboard/lpc32xx-keys.c	# wrong (clk_enable...)
cleanup drivers/input/keyboard/max7359_keypad.c # cosmetic
cleanup drivers/input/keyboard/omap-keypad.c	# various
cleanup drivers/input/keyboard/omap4-keypad.c	# various
cleanup drivers/input/keyboard/sh_keysc.c	# pwm
cleanup drivers/input/keyboard/tca6416-keypad.c	# irq handling 
cleanup drivers/input/misc/88pm80x_onkey.c	# irq handling
cleanup drivers/input/misc/bfin_rotary.c	# cosmetic
cleanup drivers/input/misc/bma150.c		# various
cleanup drivers/input/misc/ixp4xx-beeper.c	# removal complexity
cleanup drivers/input/misc/kxtj9.c		# complex
cleanup drivers/input/misc/m68kspkr.c		# cleanup sequence
cleanup drivers/input/misc/max8997_haptic.c	# pwm, regulator
cleanup drivers/input/misc/mpu3050.c		# pwm
cleanup drivers/input/misc/pwm-beeper.c		# pwm
cleanup drivers/input/misc/pcspkr.c		# cleanup sequence
cleanup drivers/input/misc/sparcspkr.c		# of_ioremap
cleanup drivers/input/mouse/elan_i2c_core.c	# cosmetic
cleanup drivers/input/mouse/synaptics_i2c.c	# missed kfree()
cleanup drivers/input/serio/ct82c710.c		# no value
cleanup drivers/input/serio/maceps2.c		# not worth it
cleanup drivers/input/serio/q40kbd.c		# missed kzalloc/kfree
cleanup drivers/input/serio/rpckbd.c		# missed kzalloc/kfree
cleanup drivers/input/serio/sun4i-ps2.c		# missed kzalloc/kfree
cleanup drivers/input/serio/xilinx_ps2.c	# removal complexity
cleanup drivers/input/touchscreen/ad7877.c	# wrong
cleanup drivers/input/touchscreen/ad7879-spi.c	# wrong
cleanup drivers/input/touchscreen/atmel_mxt_ts.c # wrong
cleanup drivers/input/touchscreen/egalax_ts.c	# cosmetic, wrong ?
cleanup drivers/input/touchscreen/goodix.c	# wrong
cleanup drivers/input/touchscreen/ili210x.c	# touchup
cleanup drivers/input/touchscreen/raydium_i2c_ts.c # wrong
cleanup drivers/input/touchscreen/s3c2410_ts.c	# del_timer_sync failed
