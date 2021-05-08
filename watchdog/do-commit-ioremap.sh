basedir=$(cd $(dirname $0); pwd)

. ${basedir}/../common/findlog-common.sh
. ${basedir}/findlog-watchdog.sh

maintainers()
{
    local file=$1
    local tmpfile=/tmp/watchdog.$$
    local m

    cc=""

    scripts/get_maintainer.pl --no-l --no-rolestats ${file} | \
	egrep -v "Guenter Roeck|Wim Van" > ${tmpfile}

    while read -r m
    do
	cc="${cc}
Cc: $m"
    done < ${tmpfile}

    rm -f ${tmpfile}
}

patches="$(git status | grep modified: | awk '{print $2}')"

#    echo "Handling $a"
    git add ${patches}

    outmsg=""
    d=0
    o=0
    s=0

    # findlog_common $a
    # findlog_watchdog $a
    maintainers "${patches}"
    subject="Convert to use devm_platform_ioremap_resource"
    msg="Use devm_platform_ioremap_resource to reduce source code size,
improve readability, and reduce the likelyhood of bugs."
    git commit -s \
	-m "watchdog: ${subject}" \
	-m "${msg}" \
	-m "The conversion was done automatically with coccinelle using the
following semantic patch." \
	-m "$(cat ${basedir}/ioremap.cocci | egrep -v virtual)" \
-m "${outmsg}" \
-m "${cc}"
