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

# The following patches are bad, unrelated, or problematic

cleanup drivers/input/touchscreen/tps6507x-ts.c
cleanup drivers/input/touchscreen/zylonite-wm97xx.c
cleanup drivers/input/touchscreen/mainstone-wm97xx.c
cleanup drivers/input/touchscreen/ektf2127.c
cleanup drivers/input/touchscreen/chipone_icn8318.c
cleanup drivers/input/mouse/cyapa.c
cleanup drivers/input/misc/wistron_btns.c
cleanup drivers/input/misc/sparcspkr.c

# The following patches are duplicates with the full set of changes

cleanup drivers/input/joystick/as5011.c
cleanup drivers/input/keyboard/adp5588-keys.c
cleanup drivers/input/keyboard/bcm-keypad.c
cleanup drivers/input/keyboard/davinci_keyscan.c
cleanup drivers/input/keyboard/mcs_touchkey.c
cleanup drivers/input/keyboard/pxa930_rotary.c
cleanup drivers/input/keyboard/qt1070.c
cleanup drivers/input/keyboard/w90p910_keypad.c
cleanup drivers/input/misc/da9052_onkey.c
cleanup drivers/input/misc/da9055_onkey.c
cleanup drivers/input/misc/mc13783-pwrbutton.c
cleanup drivers/input/misc/wm831x-on.c
cleanup drivers/input/mouse/pxa930_trkball.c
cleanup drivers/input/touchscreen/cy8ctmg110_ts.c
cleanup drivers/input/touchscreen/da9052_tsi.c
cleanup drivers/input/touchscreen/ili210x.c
cleanup drivers/input/touchscreen/mc13783_ts.c
cleanup drivers/input/touchscreen/s3c2410_ts.c
cleanup drivers/input/touchscreen/ucb1400_ts.c
cleanup drivers/input/touchscreen/wacom_i2c.c
