virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@d@
expression o;
declarer name vin, in_reg, set_in, set_temp, fan_offset, fan_offset_div;
declarer name temp_reg, temp_offset_reg, temp_auto_point, temp_crit_enable;
declarer name temp_crit_reg;
declarer name fan;
position p;
@@

(
  fan_offset(o@p);
|
  fan_offset_div(o@p);
|
  in_reg(o@p);
|
  vin(o@p);
|
  set_in(o@p);
|
  temp_offset_reg(o@p);
|
  temp_reg(o@p);
|
  set_temp(o@p);
|
  temp_auto_point(o@p);
|
  temp_crit_enable(o@p);
|
  temp_crit_reg(o@p);
|
  fan(o@p);
)

@script:python swap@
o << d.o;
p << d.p;
input;
imin;
imax;
temp;
tindex;
tmin;
tmax;
toffset;
tauto1temp;
tauto1hyst;
tauto2temp;
tcritenable;
tcrit;
faninput;
findex;
fmin;
fdiv;
ifunc;
tfunc;
tfunc_minget;
tfunc_minset;
tfunc_maxget;
tfunc_maxset;
tfunc_critget;
tfunc_critset;
@@

coccinelle.input = "in" + o + "_input";
coccinelle.imin = "in" + o + "_min";
coccinelle.imax = "in" + o + "_max";
coccinelle.temp = "temp" + o + "_input";
coccinelle.tmin = "temp" + o + "_min";
coccinelle.tmax = "temp" + o + "_max";
coccinelle.toffset = "temp" + o + "_offset";
coccinelle.tcrit = "temp" + o + "_crit";
coccinelle.tauto1temp = "temp" + o + "_auto_point1_temp";
coccinelle.tauto1hyst = "temp" + o + "_auto_point1_temp_hyst";
coccinelle.tauto2temp = "temp" + o + "_auto_point2_temp";
coccinelle.tcritenable = "temp" + o + "_crit_enable";
coccinelle.faninput = "fan" + o + "_input";
coccinelle.fmin = "fan" + o + "_min";
coccinelle.fdiv = "fan" + o + "_div";

coccinelle.findex = str(int(o) - 1);
coccinelle.tindex = str(int(o) - 1);

if p[0].file == "drivers/hwmon/lm87.c":
    coccinelle.ifunc = "show_in_input"
    coccinelle.tfunc = "show_temp_input"
    coccinelle.tfunc_minget = "show_temp_low"
    coccinelle.tfunc_maxget = "show_temp_high"
    coccinelle.tfunc_minset = "set_temp_low"
    coccinelle.tfunc_maxset = "set_temp_high"
if p[0].file == "drivers/hwmon/thmc50.c":
    coccinelle.ifunc = "show_in_input"
    coccinelle.tfunc = "show_temp"
    coccinelle.tfunc_minget = "show_temp_min"
    coccinelle.tfunc_maxget = "show_temp_max"
    coccinelle.tfunc_critget = "show_temp_critical"
    coccinelle.tfunc_minset = "set_temp_min"
    coccinelle.tfunc_maxset = "set_temp_max"
    coccinelle.tfunc_critset = "NULL"
else:
    coccinelle.ifunc = "show_in"
    coccinelle.tfunc = "show_temp"
    coccinelle.tfunc_minget = "show_temp_min"
    coccinelle.tfunc_maxget = "show_temp_max"
    coccinelle.tfunc_minset = "set_temp_min"
    coccinelle.tfunc_maxset = "set_temp_max"

@@
expression d.o;
declarer name vin, in_reg, set_in, set_temp;
declarer name SENSOR_DEVICE_ATTR;
declarer name DEVICE_ATTR;
identifier swap.input;
identifier swap.imax;
identifier swap.imin;
identifier swap.temp;
identifier swap.tmax;
identifier swap.tindex;
identifier swap.tmin;
identifier swap.toffset;
identifier swap.tauto1temp;
identifier swap.tauto1hyst;
identifier swap.tauto2temp;
identifier swap.tcritenable;
identifier swap.tcrit;
identifier swap.faninput;
identifier swap.fmin;
identifier swap.fdiv;
identifier swap.findex;
identifier swap.ifunc;
identifier swap.tfunc;
identifier swap.tfunc_minget;
identifier swap.tfunc_minset;
identifier swap.tfunc_maxget;
identifier swap.tfunc_maxset;
@@

(
- \(set_in\|in_reg\|vin\)(o);
+ static SENSOR_DEVICE_ATTR(input, 0444, ifunc, NULL, o);
+ static SENSOR_DEVICE_ATTR(imin, 0644, show_in_min, set_in_min, o);
+ static SENSOR_DEVICE_ATTR(imax, 0644, show_in_max, set_in_max, o);
|
- \(set_temp\|temp_reg\)(o);
+ static SENSOR_DEVICE_ATTR(temp, 0444, tfunc, NULL, tindex);
+ static SENSOR_DEVICE_ATTR(tmin, 0644, tfunc_minget, tfunc_minset, tindex);
+ static SENSOR_DEVICE_ATTR(tmax, 0644, tfunc_maxget, tfunc_maxset, tindex);
|
- temp_auto_point(o);
+ static SENSOR_DEVICE_ATTR(tauto1temp, 0644, show_temp_auto_point1_temp, set_temp_auto_point1_temp, tindex);
+ static SENSOR_DEVICE_ATTR(tauto1hyst, 0444, show_temp_auto_point1_temp_hyst, NULL, tindex);
+ static SENSOR_DEVICE_ATTR(tauto2temp, 0444, show_temp_auto_point2_temp, NULL, tindex);
|
- temp_offset_reg(o);
+ static SENSOR_DEVICE_ATTR(toffset, 0644, show_temp_offset, set_temp_offset, tindex);
|
- temp_crit_enable(o);
+ static DEVICE_ATTR(tcritenable, 0644, show_temp_crit_enable, set_temp_crit_enable);
|
- temp_crit_reg(o);
+ static SENSOR_DEVICE_ATTR(tcrit, 0644, show_temp_crit, set_temp_crit, tindex);
|
- fan_offset(o);
+ static SENSOR_DEVICE_ATTR(faninput, 0444, show_fan, NULL, findex);
+ static SENSOR_DEVICE_ATTR(fmin, 0644, show_fan_min, set_fan_min, findex);
|
- fan_offset_div(o);
+ static SENSOR_DEVICE_ATTR(fdiv, 0644, show_fan_div, set_fan_div, findex);
|
- fan(o);
+ static SENSOR_DEVICE_ATTR(faninput, 0444, show_fan, NULL, findex);
+ static SENSOR_DEVICE_ATTR(fmin, 0644, show_fan_min, set_fan_min, findex);
+ static SENSOR_DEVICE_ATTR(fdiv, 0444, show_fan_div, NULL, findex);
)

