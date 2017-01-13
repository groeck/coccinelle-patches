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
run other
run ../common/worker
run ../common/ioremap_resource
run ../common/ioremap_resource_assigned
run ../common/ioremap
run ../common/kzalloc
run ../common/gpio
run ../common/goto # Need to run multiple times to avoid hangup
run ../common/clk_get
# run ../common/of_clk
run ../common/clkreturn
run ../common/clk2
# run ../common/clk
# run ../common/of_iomap
# run ../common/mutex_destroy
run ../common/irq
run ../common/goto
run ../common/pdata
run ../common/pdev
run ../common/goto
run ../common/cleanup

if [ -n "${noclean}" ]
then
    exit 0
fi

cleanup()
{
	rm $1; git checkout $1
}

# The following patches are known to be broken, problematic, or cosmetic

# cosmetic
# cleanup drivers/input/keyboard/adc-keys.c
# cleanup drivers/input/keyboard/bcm-keypad.c
# cleanup drivers/input/keyboard/pxa27x_keypad.c
# cleanup drivers/input/keyboard/tc3589x-keypad.c
# cleanup drivers/input/misc/bfin_rotary.c
# cleanup drivers/input/misc/wistron_btns.c
# cleanup drivers/input/keyboard/goldfish_events.c
# cleanup drivers/input/misc/tps65218-pwrbutton.c
# cleanup drivers/input/touchscreen/zylonite-wm97xx.c
# cleanup drivers/input/touchscreen/mainstone-wm97xx.c
# cleanup drivers/input/touchscreen/jornada720_ts.c
# cleanup drivers/input/touchscreen/intel-mid-touch.c
# cleanup drivers/input/touchscreen/da9034-ts.c
# cleanup drivers/input/touchscreen/88pm860x-ts.c
# cleanup drivers/input/keyboard/pmic8xxx-keypad.c

cleanup drivers/input/mouse/elan_i2c_core.c

# wrong or too complex
cleanup drivers/input/touchscreen/raydium_i2c_ts.c
cleanup drivers/input/mouse/synaptics_i2c.c
cleanup drivers/input/serio/q40kbd.c
cleanup drivers/input/touchscreen/atmel_mxt_ts.c
cleanup drivers/input/touchscreen/egalax_ts.c
cleanup drivers/input/touchscreen/goodix.c
cleanup drivers/input/touchscreen/ili210x.c	# touchup
cleanup drivers/input/touchscreen/s3c2410_ts.c	# del_timer_sync failed
cleanup drivers/input/misc/kxtj9.c
cleanup drivers/input/keyboard/lm8323.c
cleanup drivers/input/misc/bfin_rotary.c
cleanup drivers/input/keyboard/bf54x-keys.c
cleanup drivers/input/keyboard/imx_keypad.c
cleanup drivers/input/keyboard/omap-keypad.c
cleanup drivers/input/misc/88pm80x_onkey.c # irq handling
cleanup drivers/input/keyboard/lpc32xx-keys.c
cleanup drivers/input/misc/gpio_tilt_polled.c # gpio_free_array
cleanup drivers/input/misc/max8997_haptic.c # pwm, regulator
cleanup drivers/input/misc/m68kspkr.c # cleanup sequence
cleanup drivers/input/misc/pcspkr.c # cleanup sequence
cleanup drivers/input/misc/sparcspkr.c # of_ioremap
cleanup drivers/input/serio/xilinx_ps2.c # removal complexity
cleanup drivers/input/keyboard/matrix_keypad.c # various
cleanup drivers/input/misc/pwm-beeper.c # pwm
cleanup drivers/input/misc/ixp4xx-beeper.c # removal complexity
