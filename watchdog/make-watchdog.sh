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

run watchdog-devm
run watchdog-shutdown
run watchdog-irq
run watchdog-clk_get
run watchdog-of_clk
run watchdog-clkreturn
run watchdog-clk2
run watchdog-clk
run watchdog-of_iomap
# Only for iTCO, which we drop anyway
# run watchdog-ioremap
# Done manually: use watchdog core
# run watchdog-restart
# Don't bother
# run watchdog-reboot
run watchdog-goto
# This benefits from a second run
run watchdog-goto
run watchdog-pdata
run watchdog-pdev

if [ -n "${noclean}" ]
then
    exit 0
fi

# The following patches are known to be broken, problematic, or cosmetic

# static struct ie6xx_wdt_data should really be allocated
rm drivers/watchdog/ie6xx_wdt.c; git checkout drivers/watchdog/ie6xx_wdt.c

# possible impact from pm_runtime functions
#	drivers/watchdog/renesas_wdt.c; git checkout drivers/watchdog/renesas_wdt.c
#	drivers/watchdog/shwdt.c; git checkout drivers/watchdog/shwdt.c

# uses miscdevice, don't bother
rm drivers/watchdog/ath79_wdt.c; git checkout drivers/watchdog/ath79_wdt.c
rm drivers/watchdog/ar7_wdt.c; git checkout drivers/watchdog/ar7_wdt.c
rm drivers/watchdog/gef_wdt.c; git checkout drivers/watchdog/gef_wdt.c
rm drivers/watchdog/at91rm9200_wdt.c; git checkout drivers/watchdog/at91rm9200_wdt.c
rm drivers/watchdog/riowd.c; git checkout drivers/watchdog/riowd.c
rm drivers/watchdog/sch311x_wdt.c; git checkout drivers/watchdog/sch311x_wdt.c
rm drivers/watchdog/sp5100_tco.c; git checkout drivers/watchdog/sp5100_tco.c
