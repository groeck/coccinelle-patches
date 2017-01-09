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
run worker
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
cleanup drivers/input/keyboard/adc-keys.c
cleanup drivers/input/keyboard/bcm-keypad.c
cleanup drivers/input/keyboard/pxa27x_keypad.c
cleanup drivers/input/keyboard/tc3589x-keypad.c
cleanup drivers/input/misc/bfin_rotary.c
cleanup drivers/input/misc/wistron_btns.c
cleanup drivers/input/keyboard/goldfish_events.c
cleanup drivers/input/misc/tps65218-pwrbutton.c
cleanup drivers/input/touchscreen/zylonite-wm97xx.c
cleanup drivers/input/touchscreen/mainstone-wm97xx.c
cleanup drivers/input/touchscreen/jornada720_ts.c
cleanup drivers/input/touchscreen/intel-mid-touch.c
cleanup drivers/input/touchscreen/da9034-ts.c
cleanup drivers/input/touchscreen/colibri-vf50-ts.c # platform_set_drvdata
cleanup drivers/input/touchscreen/88pm860x-ts.c
cleanup drivers/input/misc/twl4030-pwrbutton.c # platform_set_drvdata
cleanup drivers/input/misc/soc_button_array.c # pdev->dev
cleanup drivers/input/misc/retu-pwrbutton.c # drop remove function
cleanup drivers/input/misc/hisi_powerkey.c # pdev->dev -> dev
cleanup drivers/input/misc/e3x0-button.c # platform_set_drvdata
cleanup drivers/input/misc/gpio_decoder.c # platform_set_drvdata
cleanup drivers/input/misc/da9063_onkey.c # platform_set_drvdata
cleanup drivers/input/misc/arizona-haptics.c # platform_set_drvdata
cleanup drivers/input/misc/ab8500-ponkey.c # platform_set_drvdata
cleanup drivers/input/keyboard/sun4i-lradc-keys.c # platform_set_drvdata
cleanup drivers/input/keyboard/pmic8xxx-keypad.c
cleanup drivers/input/keyboard/opencores-kbd.c # platform_set_drvdata
cleanup drivers/input/keyboard/nspire-keypad.c # platform_set_drvdata
cleanup drivers/input/keyboard/jornada680_kbd.c # platform_set_drvdata
cleanup drivers/input/keyboard/gpio_keys_polled.c # platform_set_drvdata, pdev
cleanup drivers/input/keyboard/gpio_keys.c # pdev
cleanup drivers/input/keyboard/cros_ec_keyb.c # dev_set_drvdata

# wrong or too complex
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
