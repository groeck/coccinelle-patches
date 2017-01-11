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

cleanup drivers/input/touchscreen/st1232.c
cleanup drivers/input/touchscreen/tps6507x-ts.c
cleanup drivers/input/touchscreen/zylonite-wm97xx.c
cleanup drivers/input/touchscreen/wm831x-ts.c
cleanup drivers/input/touchscreen/tps6507x-ts.c
cleanup drivers/input/touchscreen/migor_ts.c
cleanup drivers/input/touchscreen/mainstone-wm97xx.c
cleanup drivers/input/touchscreen/ektf2127.c
cleanup drivers/input/touchscreen/eeti_ts.c
cleanup drivers/input/touchscreen/edt-ft5x06.c
cleanup drivers/input/touchscreen/chipone_icn8318.c
cleanup drivers/input/touchscreen/bu21013_ts.c
cleanup drivers/input/serio/at32psif.c
cleanup drivers/input/mouse/gpio_mouse.c
cleanup drivers/input/mouse/cyapa.c
cleanup drivers/input/misc/wistron_btns.c
cleanup drivers/input/misc/sparcspkr.c
cleanup drivers/input/misc/gp2ap002a00f.c
cleanup drivers/input/keyboard/tc3589x-keypad.c
cleanup drivers/input/keyboard/sh_keysc.c
cleanup drivers/input/keyboard/mpr121_touchkey.c
