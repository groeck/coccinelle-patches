virtual patch

@initialize:python@
@@

import re

// -------------------------------------------------------------------------
// Easy case

@d@
declarer name SENSOR_DEVICE_ATTR,SENSOR_DEVICE_ATTR_2;
identifier x,show,store;
expression p;
@@

(
  SENSOR_DEVICE_ATTR(x,p,show,store,...);
|
  SENSOR_DEVICE_ATTR_2(x,p,show,store,...);
)

@script:python expected@
show << d.show;
store << d.store;
x_show;
x_store;
func;
@@
coccinelle.func = re.sub('show_|get_|_show|_get|_read', '', show)
coccinelle.x_show = re.sub('show_|get_|_show|_get|_read', '', show) + "_show"
coccinelle.x_store = re.sub('show_|get_|_get|_show|_read', '', show) + "_store"

if show == "NULL":
    coccinelle.x_store = re.sub('store_|set_|_set|_store|_write|_reset', '', store) + "_store"
    coccinelle.func = re.sub('store_|set_|_store|_set|_write|_reset', '', store)

@@
declarer name SENSOR_DEVICE_ATTR_RO;
identifier d.x,expected.x_show,expected.func;
expression e;
@@

- SENSOR_DEVICE_ATTR(x, \(0444\|S_IRUGO\), x_show, NULL, e);
+ SENSOR_DEVICE_ATTR_RO(x, func, e);

@@
declarer name SENSOR_DEVICE_ATTR_WO;
identifier d.x,expected.x_store,expected.func;
expression e;
@@

- SENSOR_DEVICE_ATTR(x, \(0200\|S_IWUSR\), NULL, x_store, e);
+ SENSOR_DEVICE_ATTR_WO(x, func, e);

@@
declarer name SENSOR_DEVICE_ATTR_RW;
identifier d.x,expected.x_show,expected.x_store,expected.func;
expression e;
@@

- SENSOR_DEVICE_ATTR(x, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e);
+ SENSOR_DEVICE_ATTR_RW(x, func, e);

@@
declarer name SENSOR_DEVICE_ATTR_2_RO;
identifier d.x,expected.x_show,expected.func;
expression e1,e2;
@@

- SENSOR_DEVICE_ATTR_2(x, \(0444\|S_IRUGO\), x_show, NULL, e1, e2);
+ SENSOR_DEVICE_ATTR_2_RO(x, func, e1, e2);

@@
declarer name SENSOR_DEVICE_ATTR_2_WO;
identifier d.x,expected.x_store,expected.func;
expression e1,e2;
@@

- SENSOR_DEVICE_ATTR_2(x, \(0200\|S_IWUSR\), NULL, x_store, e1, e2);
+ SENSOR_DEVICE_ATTR_2_WO(x, func, e1, e2);

@@
declarer name SENSOR_DEVICE_ATTR_2_RW;
identifier d.x,expected.x_show,expected.x_store,expected.func;
expression e1, e2;
@@

- SENSOR_DEVICE_ATTR_2(x, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e1, e2);
+ SENSOR_DEVICE_ATTR_2_RW(x, func, e1, e2);

// -------------------------------------------------------------------------
// Other calls

@o@
identifier d.x,show,store;
expression list es;
@@

(
SENSOR_DEVICE_ATTR(x,\(0444\|S_IRUGO\|0200\|S_IWUSR\|0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\),show,store,es);
|
SENSOR_DEVICE_ATTR_2(x,\(0444\|S_IRUGO\|0200\|S_IWUSR\|0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\),show,store,es);
)

// rename functions

@show1@
identifier o.show,expected.x_show;
parameter list ps;
@@

static
- show(ps)
+ x_show(ps)
  { ... }

@depends on show1@
identifier o.show,expected.x_show;
expression list es;
@@
- show(es)
+ x_show(es)

@depends on show1@
identifier o.show,expected.x_show;
@@
- show
+ x_show

@store1@
identifier o.store,expected.x_store;
parameter list ps;
@@

static
- store(ps)
+ x_store(ps)
  { ... }

@depends on store1@
identifier o.store,expected.x_store;
expression list es;
@@
- store(es)
+ x_store(es)

@depends on store1@
identifier o.store,expected.x_store;
@@
- store
+ x_store

// try again

@@
identifier d.x,expected.x_show,expected.func;
expression e;
@@

- SENSOR_DEVICE_ATTR(x, \(0444\|S_IRUGO\), x_show, NULL, e);
+ SENSOR_DEVICE_ATTR_RO(x, func, e);

@@
identifier d.x,expected.x_store,expected.func;
expression e;
@@

- SENSOR_DEVICE_ATTR(x, \(0200\|S_IWUSR\), NULL, x_store, e);
+ SENSOR_DEVICE_ATTR_WO(x, func, e);

@@
identifier d.x,expected.x_show,expected.x_store,expected.func;
expression e;
@@

- SENSOR_DEVICE_ATTR(x, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e);
+ SENSOR_DEVICE_ATTR_RW(x, func, e);

@@
identifier d.x,expected.x_show,expected.func;
expression e1,e2;
@@

- SENSOR_DEVICE_ATTR_2(x, \(0444\|S_IRUGO\), x_show, NULL, e1, e2);
+ SENSOR_DEVICE_ATTR_2_RO(x, func, e1, e2);

@@
identifier d.x,expected.x_store,expected.func;
expression e1, e2;
@@

- SENSOR_DEVICE_ATTR_2(x, \(0200\|S_IWUSR\), NULL, x_store, e1, e2);
+ SENSOR_DEVICE_ATTR_2_WO(x, func, e1, e2);

@@
identifier d.x,expected.x_show,expected.x_store,expected.func;
expression e1, e2;
@@

- SENSOR_DEVICE_ATTR_2(x, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e1, e2);
+ SENSOR_DEVICE_ATTR_2_RW(x, func, e1, e2);
