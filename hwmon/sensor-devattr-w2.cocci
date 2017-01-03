virtual patch

@initialize:python@
@@

import re

// @initialize:ocaml@
// @@

// let taken = Hashtbl.create 101

// -------------------------------------------------------------------------
// Easy case

@d@
declarer name SENSOR_DEVICE_ATTR;
identifier x;
expression p;
identifier show;
identifier store;
@@

SENSOR_DEVICE_ATTR(x,p,show,store,...);

@d2@
declarer name SENSOR_DEVICE_ATTR_2;
identifier x;
expression p;
identifier show;
identifier store;
@@

SENSOR_DEVICE_ATTR_2(x,p,show,store,...);

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

@script:python expected2@
show << d2.show;
store << d2.store;
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
identifier d2.x,expected2.x_show,expected2.func;
expression e1,e2;
@@

- SENSOR_DEVICE_ATTR_2(x, \(0444\|S_IRUGO\), x_show, NULL, e1, e2);
+ SENSOR_DEVICE_ATTR__2_RO(x, func, e1, e2);

@@
declarer name SENSOR_DEVICE_ATTR_2_WO;
identifier d2.x,expected2.x_store,expected2.func;
expression e1,e2;
@@

- SENSOR_DEVICE_ATTR_2(x, \(0200\|S_IWUSR\), NULL, x_store, e1, e2);
+ SENSOR_DEVICE_ATTR__2_WO(x, func, e1, e2);

@@
declarer name SENSOR_DEVICE_ATTR_2_RW;
identifier d2.x,expected2.x_show,expected2.x_store,expected2.func;
expression e1, e2;
@@

- SENSOR_DEVICE_ATTR_2(x, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e1, e2);
+ SENSOR_DEVICE_ATTR_RW(x, func, e1, e2);

// -------------------------------------------------------------------------
// Other calls

@o@
declarer name SENSOR_DEVICE_ATTR;
identifier d.x,show,store;
expression e;
@@

SENSOR_DEVICE_ATTR(x,\(0444\|S_IRUGO\|0200\|S_IWUSR\|0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\),
            show,store,e);

@o2@
declarer name SENSOR_DEVICE_ATTR_2;
identifier d2.x,show,store;
expression e1,e2;
@@

SENSOR_DEVICE_ATTR_2(x,\(0444\|S_IRUGO\|0200\|S_IWUSR\|0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\),
            show,store,e1,e2);

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

@show2@
identifier o2.show,expected2.x_show;
parameter list ps;
@@

static
- show(ps)
+ x_show(ps)
  { ... }

@depends on show2@
identifier o2.show,expected2.x_show;
expression list es;
@@
- show(es)
+ x_show(es)

@depends on show2@
identifier o2.show,expected2.x_show;
@@
- show
+ x_show

@store2@
identifier o2.store,expected2.x_store;
parameter list ps;
@@

static
- store(ps)
+ x_store(ps)
  { ... }

@depends on store2@
identifier o2.store,expected2.x_store;
expression list es;
@@
- store(es)
+ x_store(es)

@depends on store2@
identifier o2.store,expected2.x_store;
@@
- store
+ x_store

// try again

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
identifier d2.x,expected2.x_show,expected2.func;
expression e1,e2;
@@

- SENSOR_DEVICE_ATTR_2(x, \(0444\|S_IRUGO\), x_show, NULL, e1, e2);
+ SENSOR_DEVICE_ATTR_2_RO(x, func, e1, e2);

@@
declarer name SENSOR_DEVICE_ATTR_2_WO;
identifier d2.x,expected2.x_store,expected2.func;
expression e1, e2;
@@

- SENSOR_DEVICE_ATTR_2(x, \(0200\|S_IWUSR\), NULL, x_store, e1, e2);
+ SENSOR_DEVICE_ATTR_2_WO(x, func, e1, e2);

@@
declarer name SENSOR_DEVICE_ATTR_2_RW;
identifier d2.x,expected2.x_show,expected2.x_store,expected2.func;
expression e1, e2;
@@

- SENSOR_DEVICE_ATTR_2(x, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e1, e2);
+ SENSOR_DEVICE_ATTR_2_RW(x, func, e1, e2);
