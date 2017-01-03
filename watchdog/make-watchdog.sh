basedir=${1:-drivers/watchdog}

rm -f coccinelle.log

run()
{
    echo $1

    make coccicheck COCCI=$1.cocci SPFLAGS="--linux-spacing" \
    	MODE=patch M=${basedir} | patch -p 1
}

run watchdog-devm
run watchdog-irq
run watchdog-clk_get
run watchdog-of_clk
run watchdog-clkreturn
run watchdog-clk2
run watchdog-clk
run watchdog-of_iomap
# Only for iTCO, which we drop anyway
# run watchdog-ioremap
run watchdog-restart
run watchdog-reboot
run watchdog-goto
# This benefits from a second run
run watchdog-goto
run watchdog-pdata
run watchdog-pdev

# The following patches are known to be broken, problematic, or cosmetic

# Would require other cleanup first
#	(iomap/iounmap, request_resource and related cleanup)
# rm drivers/watchdog/iTCO_wdt.c; git checkout drivers/watchdog/iTCO_wdt.c
# rm drivers/watchdog/coh901327_wdt.c; git checkout drivers/watchdog/coh901327_wdt.c

# static struct ie6xx_wdt_data should really be allocated
rm drivers/watchdog/ie6xx_wdt.c; git checkout drivers/watchdog/ie6xx_wdt.c

# possible impact from pm_runtime functions
#	drivers/watchdog/renesas_wdt.c; git checkout drivers/watchdog/renesas_wdt.c
#	drivers/watchdog/shwdt.c; git checkout drivers/watchdog/shwdt.c
#

# Avoid mess with odd clock handling
rm drivers/watchdog/atlas7_wdt.c; git checkout drivers/watchdog/atlas7_wdt.c

# uses miscdevice, don't bother
rm drivers/watchdog/ath79_wdt.c; git checkout drivers/watchdog/ath79_wdt.c
rm drivers/watchdog/ar7_wdt.c; git checkout drivers/watchdog/ar7_wdt.c

# Cosmetic changes only
rm drivers/watchdog/riowd.c; git checkout drivers/watchdog/riowd.c
rm drivers/watchdog/sch311x_wdt.c; git checkout drivers/watchdog/sch311x_wdt.c
rm drivers/watchdog/sp5100_tco.c; git checkout drivers/watchdog/sp5100_tco.c
rm drivers/watchdog/at91rm9200_wdt.c; git checkout drivers/watchdog/at91rm9200_wdt.c
