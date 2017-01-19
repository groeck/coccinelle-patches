subdir=${1:-drivers/input}
basedir=$(cd $(dirname $0); pwd)
patchdir=${basedir}/patches.base

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
run ../common/deref
# run ../common/goto
# run ../common/devm_kzalloc
run ../common/action
# run ../common/cleanup

for p in $(cd ${patchdir}; ls)
do
	echo "applying $p"
	patch -p 1 < ${patchdir}/$p
done

if [ -n "${noclean}" ]
then
    exit 0
fi

cleanup()
{
	if [ -e $1 ]
	then
		rm $1; git checkout $1
	else
		echo "Warning: $1 does not exist"
	fi
}

# rejected (sysfs action)

cleanup drivers/input/misc/axp20x-pek.c
cleanup drivers/input/mouse/cyapa.c
cleanup drivers/input/touchscreen/atmel_mxt_ts.c
cleanup drivers/input/touchscreen/elants_i2c.c
cleanup drivers/input/touchscreen/melfas_mip4.c
cleanup drivers/input/touchscreen/raydium_i2c_ts.c
cleanup drivers/input/touchscreen/rohm_bu21023.c
cleanup drivers/input/mouse/elan_i2c_core.c

# repeat without action changes

run ../common/pdev
run ../common/deref

# The following patches are duplicates with the full set of changes

cleanup drivers/input/keyboard/davinci_keyscan.c
cleanup drivers/input/keyboard/gpio_keys.c
cleanup drivers/input/misc/e3x0-button.c
cleanup drivers/input/misc/gpio_tilt_polled.c
cleanup drivers/input/misc/hisi_powerkey.c

