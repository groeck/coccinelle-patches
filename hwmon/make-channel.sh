subdir=${1:-drivers/hwmon}
basedir=$(cd $(dirname $0); pwd)

noclean=$2

targets="${subdir}"
#	drivers/gpu/drm/amd/amdgpu/amdgpu_pm.c
#	drivers/gpu/drm/nouveau/nouveau_hwmon.c
#	drivers/gpu/drm/radeon/radeon_pm.c
#	drivers/net/ethernet/broadcom/bnxt/bnxt.c
#	drivers/net/ethernet/broadcom/tg3.c
#	drivers/net/ethernet/emulex/benet/be_main.c
#	drivers/net/ethernet/qlogic/qlcnic/qlcnic_sysfs.c
#	drivers/net/wireless/ath/ath10k/thermal.c
#	drivers/ntb/hw/idt/ntb_hw_idt.c
#	drivers/platform/mips/cpu_hwmon.c
#	drivers/rtc/rtc-ds1307.c
#	drivers/rtc/rtc-rv3029c2.c
#	drivers/platform/x86/thinkpad_acpi.c

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

run channel-info

cleanup()
{
	if [ -e $1 ]
	then
		rm $1; git checkout $1
	fi
}
