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

# drop all patches associated with clk_disable_unprepare
# (courtesy C standard)

cleanup drivers/watchdog/asm9260_wdt.c
cleanup drivers/watchdog/at91sam9_wdt.c
cleanup drivers/watchdog/atlas7_wdt.c
cleanup drivers/watchdog/bcm7038_wdt.c
cleanup drivers/watchdog/cadence_wdt.c
cleanup drivers/watchdog/coh901327_wdt.c
cleanup drivers/watchdog/davinci_wdt.c
cleanup drivers/watchdog/dw_wdt.c
cleanup drivers/watchdog/imgpdc_wdt.c
cleanup drivers/watchdog/imx2_wdt.c
cleanup drivers/watchdog/loongson1_wdt.c
cleanup drivers/watchdog/lpc18xx_wdt.c
cleanup drivers/watchdog/meson_gxbb_wdt.c
cleanup drivers/watchdog/of_xilinx_wdt.c
cleanup drivers/watchdog/orion_wdt.c
cleanup drivers/watchdog/pic32-dmt.c
cleanup drivers/watchdog/pic32-wdt.c
cleanup drivers/watchdog/pnx4008_wdt.c
cleanup drivers/watchdog/qcom-wdt.c
cleanup drivers/watchdog/st_lpc_wdt.c
cleanup drivers/watchdog/sunxi_wdt.c
cleanup drivers/watchdog/tangox_wdt.c
cleanup drivers/watchdog/txx9wdt.c

# The following patches are known to be broken, problematic, or cosmetic

# cpufreq interaction
cleanup drivers/watchdog/s3c2410_wdt.c

# static struct ie6xx_wdt_data should really be allocated
cleanup drivers/watchdog/ie6xx_wdt.c

# possible impact from pm_runtime functions
#	drivers/watchdog/renesas_wdt.c; git checkout drivers/watchdog/renesas_wdt.c
#	drivers/watchdog/shwdt.c; git checkout drivers/watchdog/shwdt.c

# uses miscdevice, don't bother
cleanup drivers/watchdog/ath79_wdt.c
cleanup drivers/watchdog/ar7_wdt.c
cleanup drivers/watchdog/cpwd.c
cleanup drivers/watchdog/gef_wdt.c
cleanup drivers/watchdog/at91rm9200_wdt.c
cleanup drivers/watchdog/riowd.c
cleanup drivers/watchdog/sch311x_wdt.c
cleanup drivers/watchdog/sp5100_tco.c
