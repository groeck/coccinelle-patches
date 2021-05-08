virtual patch

@initialize:ocaml@
@@

let taken = Hashtbl.create 101

@initialize:python@
@@

import re

// -------------------------------------------------------------------------
// Easy case

@d@
declarer name SENSOR_DEVICE_ATTR,SENSOR_DEVICE_ATTR_2;
expression X;
identifier show,store;
expression p;
identifier SENSOR_ATTR,SENSOR_ATTR_2;
@@

(
  SENSOR_DEVICE_ATTR(X,p,show,store,...);
|
  SENSOR_DEVICE_ATTR_2(X,p,show,store,...);
|
  SENSOR_ATTR(X,p,show,store,...)
|
  SENSOR_ATTR_2(X,p,show,store,...)
)

@script:ocaml depends on d@
@@

Hashtbl.clear taken

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
expression d.X;
identifier expected.x_show,expected.func;
expression e;
identifier SENSOR_ATTR;
@@

- SENSOR_ATTR(X, \(0444\|S_IRUGO\), x_show, NULL, e)
+ SENSOR_ATTR_RO(X, func, e)

@@
expression d.X;
identifier expected.x_show,expected.x_store,expected.func;
expression e;
identifier SENSOR_ATTR;
@@

- SENSOR_ATTR(x, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e)
+ SENSOR_ATTR_RW(x, func, e)

@@
expression d.X;
identifier expected.x_show,expected.func;
expression e1, e2;
identifier SENSOR_ATTR_2;
@@

- SENSOR_ATTR_2(X, \(0444\|S_IRUGO\), x_show, NULL, e1, e2)
+ SENSOR_ATTR_2_RO(X, func, e1, e2)

@@
expression d.X;
identifier expected.x_show,expected.x_store,expected.func;
expression e1, e2;
identifier SENSOR_ATTR_2;
@@

- SENSOR_ATTR_2(X, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e1, e2)
+ SENSOR_ATTR_2_RW(X, func, e1, e2)

@@
declarer name SENSOR_DEVICE_ATTR_RO;
expression d.X;
identifier expected.x_show,expected.func;
expression e;
@@

- SENSOR_DEVICE_ATTR(X, \(0444\|S_IRUGO\), x_show, NULL, e);
+ SENSOR_DEVICE_ATTR_RO(X, func, e);

@@
declarer name SENSOR_DEVICE_ATTR_WO;
expression d.X;
identifier expected.x_store,expected.func;
expression e;
@@

- SENSOR_DEVICE_ATTR(X, \(0200\|S_IWUSR\), NULL, x_store, e);
+ SENSOR_DEVICE_ATTR_WO(X, func, e);

@@
declarer name SENSOR_DEVICE_ATTR_RW;
expression d.X;
identifier expected.x_show,expected.x_store,expected.func;
expression e;
@@

- SENSOR_DEVICE_ATTR(X, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e);
+ SENSOR_DEVICE_ATTR_RW(X, func, e);

@@
declarer name SENSOR_DEVICE_ATTR_2_RO;
expression d.X;
identifier expected.x_show,expected.func;
expression e1,e2;
@@

- SENSOR_DEVICE_ATTR_2(X, \(0444\|S_IRUGO\), x_show, NULL, e1, e2);
+ SENSOR_DEVICE_ATTR_2_RO(X, func, e1, e2);

@@
declarer name SENSOR_DEVICE_ATTR_2_WO;
expression d.X;
identifier expected.x_store,expected.func;
expression e1,e2;
@@

- SENSOR_DEVICE_ATTR_2(X, \(0200\|S_IWUSR\), NULL, x_store, e1, e2);
+ SENSOR_DEVICE_ATTR_2_WO(X, func, e1, e2);

@@
declarer name SENSOR_DEVICE_ATTR_2_RW;
expression d.X;
identifier expected.x_show,expected.x_store,expected.func;
expression e1, e2;
@@

- SENSOR_DEVICE_ATTR_2(X, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e1, e2);
+ SENSOR_DEVICE_ATTR_2_RW(X, func, e1, e2);

// -------------------------------------------------------------------------
// Other calls

@o@
expression d.X;
identifier show,store;
expression list es;
identifier SENSOR_ATTR,SENSOR_ATTR_2;
@@

(
SENSOR_DEVICE_ATTR(X,\(0444\|S_IRUGO\|0200\|S_IWUSR\|0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\),show,store,es);
|
SENSOR_DEVICE_ATTR_2(X,\(0444\|S_IRUGO\|0200\|S_IWUSR\|0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\),show,store,es);
|
SENSOR_ATTR(X,\(0444\|S_IRUGO\|0200\|S_IWUSR\|0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\),show,store,es)
|
SENSOR_ATTR_2(X,\(0444\|S_IRUGO\|0200\|S_IWUSR\|0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\),show,store,es)
)

@script:ocaml@
show << o.show;
store << o.store;
@@

if (not(store = "NULL") && Hashtbl.mem taken store)
then Coccilib.include_match false
else (Hashtbl.add taken show (); Hashtbl.add taken store ())

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
expression d.X;
identifier expected.x_show,expected.func;
expression e;
identifier SENSOR_ATTR;
@@

- SENSOR_ATTR(X, \(0444\|S_IRUGO\), x_show, NULL, e)
+ SENSOR_ATTR_RO(X, func, e)

@@
expression d.X;
identifier expected.x_show,expected.x_store,expected.func;
expression e;
identifier SENSOR_ATTR;
@@

- SENSOR_ATTR(X, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e)
+ SENSOR_ATTR_RW(X, func, e)

@@
expression d.X;
identifier expected.x_show,expected.func;
expression e1, e2;
identifier SENSOR_ATTR_2;
@@

- SENSOR_ATTR_2(X, \(0444\|S_IRUGO\), x_show, NULL, e1, e2)
+ SENSOR_ATTR_2_RO(X, func, e1, e2)

@@
expression d.X;
identifier expected.x_show,expected.x_store,expected.func;
expression e1, e2;
identifier SENSOR_ATTR_2;
@@

- SENSOR_ATTR_2(X, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e1, e2)
+ SENSOR_ATTR_2_RW(X, func, e1, e2)

@@
expression d.X;
identifier expected.x_show,expected.func;
expression e;
@@

- SENSOR_DEVICE_ATTR(X, \(0444\|S_IRUGO\), x_show, NULL, e);
+ SENSOR_DEVICE_ATTR_RO(X, func, e);

@@
expression d.X;
identifier expected.x_store,expected.func;
expression e;
@@

- SENSOR_DEVICE_ATTR(X, \(0200\|S_IWUSR\), NULL, x_store, e);
+ SENSOR_DEVICE_ATTR_WO(X, func, e);

@@
expression d.X;
identifier expected.x_show,expected.x_store,expected.func;
expression e;
@@

- SENSOR_DEVICE_ATTR(X, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e);
+ SENSOR_DEVICE_ATTR_RW(X, func, e);

@@
expression d.X;
identifier expected.x_show,expected.func;
expression e1,e2;
@@

- SENSOR_DEVICE_ATTR_2(X, \(0444\|S_IRUGO\), x_show, NULL, e1, e2);
+ SENSOR_DEVICE_ATTR_2_RO(X, func, e1, e2);

@@
expression d.X;
identifier expected.x_store,expected.func;
expression e1, e2;
@@

- SENSOR_DEVICE_ATTR_2(X, \(0200\|S_IWUSR\), NULL, x_store, e1, e2);
+ SENSOR_DEVICE_ATTR_2_WO(X, func, e1, e2);

@@
expression d.X;
identifier expected.x_show,expected.x_store,expected.func;
expression e1, e2;
@@

- SENSOR_DEVICE_ATTR_2(X, \(0644\|S_IRUGO|S_IWUSR\|S_IWUSR|S_IRUGO\), x_show, x_store, e1, e2);
+ SENSOR_DEVICE_ATTR_2_RW(X, func, e1, e2);
