subdir=${1:-drivers/hwmon}
basedir=$(cd $(dirname $0); pwd)

noclean=$2

targets="${subdir}
	drivers/gpu/drm/amd/amdgpu/amdgpu_pm.c
	drivers/gpu/drm/nouveau/nouveau_hwmon.c
	drivers/gpu/drm/radeon/radeon_pm.c
	drivers/net/ethernet/broadcom/bnxt/bnxt.c
	drivers/net/ethernet/broadcom/tg3.c
	drivers/net/ethernet/emulex/benet/be_main.c
	drivers/net/ethernet/qlogic/qlcnic/qlcnic_sysfs.c
	drivers/net/wireless/ath/ath10k/thermal.c
	drivers/ntb/hw/idt/ntb_hw_idt.c
	drivers/platform/mips/cpu_hwmon.c
	drivers/rtc/rtc-ds1307.c
	drivers/rtc/rtc-rv3029c2.c
	drivers/platform/x86/thinkpad_acpi.c"

rm -f coccinelle.log

run()
{
    local func=$1
    local m
    shift


    for m in ${targets}
    do
        echo "${func}:${m}"
        make coccicheck COCCI=${basedir}/${func}.cocci \
	    SPFLAGS="--linux-spacing" \
	    MODE=patch M="${m}" | patch -p 1
    done
}

run device-attr
run sensor-attr-w2
run sensor-devattr-w8
run permissions

cleanup()
{
	if [ -e $1 ]
	then
		rm $1; git checkout $1
	fi
}

exit 0

cleanup drivers/hwmon/adm1025.c
cleanup drivers/hwmon/adm1026.c
cleanup drivers/hwmon/adm1031.c
cleanup drivers/hwmon/adm9240.c
cleanup drivers/hwmon/adt7411.c
cleanup drivers/hwmon/asb100.c
cleanup drivers/hwmon/dme1737.c
cleanup drivers/hwmon/f71805f.c
cleanup drivers/hwmon/f75375s.c
cleanup drivers/hwmon/it87.c
cleanup drivers/hwmon/lm63.c
cleanup drivers/hwmon/lm78.c
cleanup drivers/hwmon/lm85.c
cleanup drivers/hwmon/lm87.c
cleanup drivers/hwmon/max1111.c
cleanup drivers/hwmon/max197.c
cleanup drivers/hwmon/menf21bmc_hwmon.c
cleanup drivers/hwmon/nct6775.c
cleanup drivers/hwmon/nct6683.c
cleanup drivers/hwmon/sis5595.c
cleanup drivers/hwmon/smm665.c
cleanup drivers/hwmon/smsc47m192.c
cleanup drivers/hwmon/smsc47m1.c
cleanup drivers/hwmon/thmc50.c
cleanup drivers/hwmon/ultra45_env.c
cleanup drivers/hwmon/via686a.c
cleanup drivers/hwmon/vt1211.c
cleanup drivers/hwmon/vt8231.c
cleanup drivers/hwmon/w83627ehf.c
cleanup drivers/hwmon/w83627hf.c
cleanup drivers/hwmon/w83791d.c
cleanup drivers/hwmon/w83793.c
cleanup drivers/hwmon/w83l785ts.c
cleanup drivers/hwmon/w83l786ng.c
cleanup drivers/hwmon/wm831x-hwmon.c
cleanup drivers/hwmon/wm8350-hwmon.c
