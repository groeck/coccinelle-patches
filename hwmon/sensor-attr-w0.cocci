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
identifier x,show,store;
expression p;
identifier a;
function SENSOR_ATTR;
@@
  struct sensor_device_attribute a[] = {
  <...
  SENSOR_ATTR(x,p,show,store,...)
  ...>
  };

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
identifier d.x,expected.x_show,expected.func;
expression e;
function SENSOR_ATTR;
@@

- SENSOR_ATTR(x, \(0444\|S_IRUGO\), x_show, NULL, e)
+ SENSOR_ATTR_RO(x, func, e)

@@
identifier d.x,expected.x_show,expected.x_store,expected.func;
expression e;
function SENSOR_ATTR;
@@

- SENSOR_ATTR(x, \(0444\|S_IRUGO\), x_show, x_store, e)
+ SENSOR_ATTR_RW(x, func, e)

// -------------------------------------------------------------------------
// Other calls

@o@
identifier d.x,show,store;
identifier a;
expression p;
function SENSOR_ATTR;
@@
  struct sensor_device_attribute a[] = {
  <...
  SENSOR_ATTR(x,p,show,store,...)
  ...>
  };

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
identifier d.x,expected.x_show,expected.func;
expression e;
function SENSOR_ATTR;
@@

- SENSOR_ATTR(x, \(0444\|S_IRUGO\), x_show, NULL, e)
+ SENSOR_ATTR_RO(x, func, e)

@@
identifier d.x,expected.x_show,expected.x_store,expected.func;
expression e;
function SENSOR_ATTR;
@@

- SENSOR_ATTR(x, \(0444\|S_IRUGO\), x_show, x_store, e)
+ SENSOR_ATTR_RW(x, func, e)
