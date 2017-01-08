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
run ../common/ioremap_resource
run ../common/ioremap_resource_assigned
run ../common/ioremap
run ../common/kzalloc
run ../common/clk_get
run ../common/of_clk
run ../common/clk2
# run ../common/clk
run ../common/of_iomap
# run ../common/mutex_destroy
run ../common/irq
run ../common/goto
run ../common/pdata
run ../common/pdev
# This may benefit from a second run
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
