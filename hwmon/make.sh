subdir=${1:-drivers/hwmon}
basedir=$(cd $(dirname $0); pwd)

noclean=$2

rm -f coccinelle.log

run()
{
    echo $1

    make coccicheck COCCI=${basedir}/$1.cocci SPFLAGS="--linux-spacing" \
	MODE=patch M=${subdir} | patch -p 1
}

run sensor-devattr-w6

cleanup()
{
	if [ -e $1 ]
	then
		rm $1; git checkout $1
	fi
}

cleanup drivers/hwmon/adm1025.c
cleanup drivers/hwmon/adm1026.c
cleanup drivers/hwmon/adm1031.c
cleanup drivers/hwmon/adm9240.c
cleanup drivers/hwmon/adt7411.c
cleanup drivers/hwmon/asb100.c
cleanup drivers/hwmon/dme1737.c
cleanup drivers/hwmon/f75375s.c
cleanup drivers/hwmon/it87.c
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
cleanup drivers/hwmon/vt8231.c
cleanup drivers/hwmon/w83627ehf.c
cleanup drivers/hwmon/w83627hf.c
cleanup drivers/hwmon/w83791d.c
cleanup drivers/hwmon/w83l785ts.c
cleanup drivers/hwmon/wm831x-hwmon.c
cleanup drivers/hwmon/wm8350-hwmon.c
