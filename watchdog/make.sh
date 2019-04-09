subdir=${1:-drivers/watchdog}
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
run shutdown
run stop
run ../common/irq
run ../common/timer
run ../common/clk_get
run ../common/of_clk
run ../common/clkreturn
run ../common/clk2
run ../common/clk
run ../common/of_iomap
# run ../common/devm_kzalloc
# run ../common/kzalloc
run ../common/action
# Only for iTCO, which we drop anyway
# run ../common/ioremap
# Done manually: use watchdog core
# run watchdog-restart
# Don't bother
# run watchdog-reboot
run ../common/mutex_destroy
run ../common/worker
run ../common/goto
run ../common/pdata
run ../common/pdev
run ../common/pdev-addvar
run ../common/cleanup
run ../common/goto
run ../common/cleanup

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

# The following patches are known to be broken, problematic, or cosmetic

# cpufreq interaction
cleanup drivers/watchdog/s3c2410_wdt.c

# static struct ie6xx_wdt_data should really be allocated
cleanup drivers/watchdog/ie6xx_wdt.c

# uses soft timer, and request_irq w/o release_irq
cleanup drivers/watchdog/at91sam9_wdt.c
# private timer
cleanup drivers/watchdog/bcm47xx_wdt.c
cleanup drivers/watchdog/retu_wdt.c

# private reset control
cleanup drivers/watchdog/dw_wdt.c

# multiple clock init calls
cleanup drivers/watchdog/orion_wdt.c

# Calls private disable function
cleanup drivers/watchdog/coh901327_wdt.c

# Calls ping on remove, does not call clk_disable_unprepare
# on remove
cleanup drivers/watchdog/imx2_wdt.c

# Manually stops watchdog on remove
cleanup drivers/watchdog/nic7018_wdt.c

# removes a global extern
cleanup drivers/watchdog/rc32434_wdt.c

# interference with pm functions
cleanup drivers/watchdog/renesas_wdt.c
cleanup drivers/watchdog/shwdt.c
cleanup drivers/watchdog/omap_wdt.c

# interference with put function - should use devm_clk_get()
cleanup drivers/watchdog/txx9wdt.c

# incomplete (does not replace watchdog_register_device)
cleanup drivers/watchdog/ziirave_wdt.c

#
# possible impact from pm_runtime functions
#	drivers/watchdog/renesas_wdt.c; git checkout drivers/watchdog/renesas_wdt.c
#	drivers/watchdog/shwdt.c; git checkout drivers/watchdog/shwdt.c

# uses miscdevice, don't bother
cleanup drivers/watchdog/ar7_wdt.c
cleanup drivers/watchdog/at91rm9200_wdt.c
cleanup drivers/watchdog/ath79_wdt.c
cleanup drivers/watchdog/bcm63xx_wdt.c
cleanup drivers/watchdog/cpwd.c
cleanup drivers/watchdog/gef_wdt.c
cleanup drivers/watchdog/mtx-1_wdt.c
cleanup drivers/watchdog/nuc900_wdt.c
cleanup drivers/watchdog/rdc321x_wdt.c
cleanup drivers/watchdog/riowd.c
cleanup drivers/watchdog/sch311x_wdt.c
cleanup drivers/watchdog/sp5100_tco.c
