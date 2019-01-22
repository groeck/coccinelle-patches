virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@d@
expression o;
declarer name vin, in_reg, set_in, set_temp, fan_offset, fan_offset_div;
declarer name temp_reg, temp_offset_reg, temp_auto_point, temp_crit_enable;
declarer name show_temp_reg;
// declarer name show_temp_offset;
declarer name show_temp_index;
declarer name temp_crit_reg;
declarer name auto_temp_reg;
declarer name fan, set_fan;
declarer name show_fan_offset;
declarer name show_in_offset;
declarer name show_in_reg;
declarer name show_pwm_reg;
declarer name pwm_auto;
declarer name temp_auto;
declarer name create_voltage_sysfs;
declarer name define_voltage_sysfs, define_temperature_sysfs, define_fan_sysfs;
declarer name fan_present;
declarer name sysfs_vin_decl, sysfs_fan_decl, sysfs_temp_decl, sysfs_temp_type;
position p;
@@

(
  sysfs_vin_decl(o@p);
|
  sysfs_fan_decl(o@p);
|
  sysfs_temp_decl(o@p);
|
  sysfs_temp_type(o@p);
|
  define_voltage_sysfs(o@p);
|
  define_temperature_sysfs(o@p);
|
  define_fan_sysfs(o@p);
|
  temp_auto(o@p);
|
  pwm_auto(o@p);
|
  show_pwm_reg(o@p);
|
  show_fan_offset(o@p);
|
  fan_offset(o@p);
|
  fan_present(o@p);
|
  fan_offset_div(o@p);
|
  show_in_reg(o@p);
|
  in_reg(o@p);
|
  vin(o@p);
|
  create_voltage_sysfs(o@p);
|
  set_in(o@p);
|
  show_in_offset(o@p);
|
  temp_offset_reg(o@p);
|
  temp_reg(o@p);
|
  show_temp_reg(o@p);
|
//  show_temp_offset(o@p);
//|
  show_temp_index(o@p);
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
|
  set_fan(o@p);
|
  auto_temp_reg(o@p);
)

@script:python swap@
o << d.o;
p << d.p;
input;
imin;
imax;
ilabel;
pwm;
pwm_enable;
pwm_freq;
pwm_auto_channels;
pwm_auto_pwm_min;
pwm_auto_pwm_minctl;
temp;
tindex;
tmin;
tmax;
tmaxhyst;
ttype;
toffset;
tautooff;
tautomin;
tautomax;
tautocrit;
tauto1temp;
tauto1hyst;
tauto2temp;
tcritenable;
tcrit;
faninput;
findex;
fmin;
fdiv;
falarm;
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
coccinelle.ilabel = "in" + o + "_label";

coccinelle.pwm = "pwm" + o;
coccinelle.pwm_enable = "pwm" + o + "_enable";
coccinelle.pwm_freq = "pwm" + o + "_freq";
coccinelle.pwm_auto_channels = "pwm" + o + "_auto_channels";
coccinelle.pwm_auto_pwm_min = "pwm" + o + "_auto_pwm_min";
coccinelle.pwm_auto_pwm_minctl = "pwm" + o + "_auto_pwm_minctl";

coccinelle.temp = "temp" + o + "_input";
coccinelle.tmin = "temp" + o + "_min";
coccinelle.tmax = "temp" + o + "_max";
coccinelle.tmaxhyst = "temp" + o + "_max_hyst";
coccinelle.toffset = "temp" + o + "_offset";
coccinelle.tcrit = "temp" + o + "_crit";
coccinelle.ttype = "temp" + o + "_type";
coccinelle.tautooff = "temp" + o + "_auto_temp_off";
coccinelle.tautomin = "temp" + o + "_auto_temp_min";
coccinelle.tautomax = "temp" + o + "_auto_temp_max";
coccinelle.tautocrit = "temp" + o + "_auto_temp_crit";
coccinelle.tauto1temp = "temp" + o + "_auto_point1_temp";
coccinelle.tauto1hyst = "temp" + o + "_auto_point1_temp_hyst";
coccinelle.tauto2temp = "temp" + o + "_auto_point2_temp";
coccinelle.tcritenable = "temp" + o + "_crit_enable";

coccinelle.faninput = "fan" + o + "_input";
coccinelle.fmin = "fan" + o + "_min";
coccinelle.fdiv = "fan" + o + "_div";
coccinelle.falarm = "fan" + o + "_alarm";

coccinelle.findex = str(int(o) - 1);
coccinelle.tindex = str(int(o) - 1);

coccinelle.ifunc = "show_in_input"
coccinelle.tfunc = "show_temp"
coccinelle.tfunc_minget = "show_temp_min"
coccinelle.tfunc_maxget = "show_temp_max"
coccinelle.tfunc_minset = "set_temp_min"
coccinelle.tfunc_maxset = "set_temp_max"

@@
expression d.o;
declarer name vin, in_reg, set_in, show_in_offset, set_temp, show_temp_reg;
declarer name SENSOR_DEVICE_ATTR;
declarer name DEVICE_ATTR;
identifier swap.input;
identifier swap.imax;
identifier swap.imin;
identifier swap.ilabel;
identifier swap.pwm;
identifier swap.pwm_enable;
identifier swap.pwm_freq;
identifier swap.pwm_auto_channels;
identifier swap.pwm_auto_pwm_min;
identifier swap.pwm_auto_pwm_minctl;
identifier swap.temp;
identifier swap.tmax;
identifier swap.tmaxhyst;
identifier swap.tindex;
identifier swap.tmin;
identifier swap.toffset;
identifier swap.tautooff;
identifier swap.tautomin;
identifier swap.tautomax;
identifier swap.tautocrit;
identifier swap.tauto1temp;
identifier swap.tauto1hyst;
identifier swap.tauto2temp;
identifier swap.tcritenable;
identifier swap.tcrit;
identifier swap.ttype;
identifier swap.faninput;
identifier swap.fmin;
identifier swap.fdiv;
identifier swap.falarm;
identifier swap.findex;
identifier swap.ifunc;
identifier swap.tfunc;
identifier swap.tfunc_minget;
identifier swap.tfunc_minset;
identifier swap.tfunc_maxget;
identifier swap.tfunc_maxset;
@@

(
- pwm_auto(o);
+ static SENSOR_DEVICE_ATTR(pwm_auto_channels, 0644, show_pwm_auto_channels, set_pwm_auto_channels, tindex);
+ static SENSOR_DEVICE_ATTR(pwm_auto_pwm_min, 0644, show_pwm_auto_pwm_min, set_pwm_auto_pwm_min, tindex);
+ static SENSOR_DEVICE_ATTR(pwm_auto_pwm_minctl, 0644, show_pwm_auto_pwm_minctl, set_pwm_auto_pwm_minctl, tindex);
|
- show_pwm_reg(o);
+ static SENSOR_DEVICE_ATTR(pwm, 0644, show_pwm, set_pwm, tindex);
+ static SENSOR_DEVICE_ATTR(pwm_enable, 0644, show_pwm_enable, set_pwm_enable, tindex);
+ static SENSOR_DEVICE_ATTR(pwm_freq, 0644, show_pwm_freq, set_pwm_freq, tindex);
|
- \(auto_temp_reg\|temp_auto\)(o);
+ static SENSOR_DEVICE_ATTR(tautooff, 0644, show_temp_auto_temp_off, set_temp_auto_temp_off, tindex);
+ static SENSOR_DEVICE_ATTR(tautomin, 0644, show_temp_auto_temp_min, set_temp_auto_temp_min, tindex);
+ static SENSOR_DEVICE_ATTR(tautomax, 0644, show_temp_auto_temp_max, set_temp_auto_temp_max, tindex);
+ static SENSOR_DEVICE_ATTR(tautocrit, 0644, show_temp_auto_temp_crit, set_temp_auto_temp_crit, tindex);
|
- \(set_in\|in_reg\|vin\|show_in_reg\|define_voltage_sysfs\|sysfs_vin_decl\)(o);
+ static SENSOR_DEVICE_ATTR(input, 0444, ifunc, NULL, o);
+ static SENSOR_DEVICE_ATTR(imin, 0644, show_in_min, store_in_min, o);
+ static SENSOR_DEVICE_ATTR(imax, 0644, show_in_max, store_in_max, o);
|
- show_in_offset(o);
+ static SENSOR_DEVICE_ATTR(input, 0444, ifunc, NULL, o);
+ static SENSOR_DEVICE_ATTR(imin, 0644, show_in_min, set_in_min, o);
+ static SENSOR_DEVICE_ATTR(imax, 0644, show_in_max, set_in_max, o);
|
- create_voltage_sysfs(o);
+ static SENSOR_DEVICE_ATTR(input, 0444, ifunc, NULL, o);
+ static SENSOR_DEVICE_ATTR(imin, 0444, show_min, NULL, o);
+ static SENSOR_DEVICE_ATTR(imax, 0444, show_max, NULL, o);
+ static SENSOR_DEVICE_ATTR(ilabel, 0444, show_label, NULL, o);
|
- \(set_temp\|temp_reg\|show_temp_reg\)(o);
+ static SENSOR_DEVICE_ATTR(temp, 0444, tfunc, NULL, tindex);
+ static SENSOR_DEVICE_ATTR(tmin, 0644, tfunc_minget, tfunc_minset, tindex);
+ static SENSOR_DEVICE_ATTR(tmax, 0644, tfunc_maxget, tfunc_maxset, tindex);
|
- temp_auto_point(o);
+ static SENSOR_DEVICE_ATTR(tauto1temp, 0644, show_temp_auto_point1_temp, set_temp_auto_point1_temp, tindex);
+ static SENSOR_DEVICE_ATTR(tauto1hyst, 0444, show_temp_auto_point1_temp_hyst, NULL, tindex);
+ static SENSOR_DEVICE_ATTR(tauto2temp, 0444, show_temp_auto_point2_temp, NULL, tindex);
|
- \(define_temperature_sysfs\|show_temp_index\)(o);
+ static SENSOR_DEVICE_ATTR(temp, 0444, show_temp, NULL, tindex);
+ static SENSOR_DEVICE_ATTR(tmin, 0644, show_temp_min, set_temp_min, tindex);
+ static SENSOR_DEVICE_ATTR(tmax, 0644, show_temp_max, set_temp_max, tindex);
+ static SENSOR_DEVICE_ATTR(toffset, 0644, show_temp_offset, set_temp_offset, tindex);
|
- sysfs_temp_decl(o);
+ static SENSOR_DEVICE_ATTR(temp, 0444, show_temp, NULL, tindex);
+ static SENSOR_DEVICE_ATTR(tmax, 0644, show_temp_max, store_temp_max, tindex);
+ static SENSOR_DEVICE_ATTR(tmaxhyst, 0644, show_temp_max_hyst, store_temp_max_hyst, tindex);
|
- sysfs_temp_type(o);
+ static SENSOR_DEVICE_ATTR(ttype, 0644, show_temp_type, store_temp_type, tindex);
|
- temp_crit_enable(o);
+ static DEVICE_ATTR(tcritenable, 0644, show_temp_crit_enable, set_temp_crit_enable);
|
- temp_crit_reg(o);
+ static SENSOR_DEVICE_ATTR(tcrit, 0644, show_temp_crit, set_temp_crit, tindex);
|
- fan_offset_div(o);
+ static SENSOR_DEVICE_ATTR(fdiv, 0644, show_fan_div, set_fan_div, findex);
|
- \(fan\|set_fan\|fan_offset\|show_fan_offset\|define_fan_sysfs\|sysfs_fan_decl\)(o);
+ static SENSOR_DEVICE_ATTR(faninput, 0444, show_fan_input, NULL, findex);
+ static SENSOR_DEVICE_ATTR(fmin, 0644, show_fan_min, store_fan_min, findex);
// + static SENSOR_DEVICE_ATTR(fdiv, 0644, show_fan_div, set_fan_div, findex);
|
- fan_present(o);
+ static SENSOR_DEVICE_ATTR(faninput, 0444, get_fan, NULL, findex);
+ static SENSOR_DEVICE_ATTR(fmin, 0644, get_fan_min, set_fan_min, findex);
+ static SENSOR_DEVICE_ATTR(fdiv, 0644, get_fan_div, set_fan_div, findex);
+ static SENSOR_DEVICE_ATTR(falarm, 0444, get_fan_alarm, NULL, findex);
+ static SENSOR_DEVICE_ATTR(pwm, 0644, get_pwm, set_pwm, tindex);
+ static SENSOR_DEVICE_ATTR(pwm_enable, 0644, get_pwm_en, set_pwm_en, tindex);
)

