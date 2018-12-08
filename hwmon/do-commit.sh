basedir=$(cd $(dirname $0); pwd)

maintainers()
{
    local file=$1
    local tmpfile=$(mktemp)
    local m

    cc=""

    scripts/get_maintainer.pl --no-l --no-rolestats ${file} | \
	egrep -v "Guenter Roeck|Delvare" > ${tmpfile}

    while read -r m; do
	cc="${cc}
Cc: $m"
    done < ${tmpfile}

    rm -f ${tmpfile}
}

git status | grep modified: | awk '{print $2}' | while read a
do
    echo "Handling $a"
    git add $a

    maintainers $a
    subject="Convert to use SENSOR_DEVICE_ATTR[_2]_{RO,RW,WO}"
    msg="Auto-convert to use SENSOR_DEVICE_ATTR[_2]_{RO,RW,WO}
to simplify the source code, improve readbility, and reduce the chance of
inconsistencies. As a side effect, this conversion eliminates the use of
S_<PERMS> in the driver.
"
    git commit -s \
	-m "hwmon: ($(basename -s .c $a)) ${subject}" \
	-m "${msg}" \
	-m "The conversion was done automatically with coccinelle. The semantic patches
and the scripts used to generate this commit log are available at
https://github.com/groeck/coccinelle-patches/hwmon/" \
-m "${cc}"
done
