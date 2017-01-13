virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@probe@
identifier p, probefn;
declarer name module_platform_driver_probe;
position pos;
@@
(
  module_platform_driver_probe(p, probefn@pos);
|
  struct platform_driver p = {
    .probe = probefn@pos,
  };
|
  struct i2c_driver p = {
    .probe = probefn@pos,
  };
|
  struct spi_driver p = {
    .probe = probefn@pos,
  };
)

@remove@
identifier probe.p, removefn;
position pos;
@@

  struct
(
  platform_driver
|
  i2c_driver
|
  spi_driver
)
  p@pos = {
    .remove = \(__exit_p(removefn)\|removefn\),
  };

@empty_if depends on probe@
identifier initfn;
expression e;
@@

initfn(...) {
<+...
- if (e)
-  {}
...+> }

@empty_while depends on probe@
identifier initfn;
expression e;
@@

initfn(...) {
<+...
- while (e)
-  {}
...+> }

@e@
identifier i;
position p;
type T;
@@

(
extern T i@p;
|
static T i@p;
)

@unused_assign depends on probe@
identifier i;
expression E;
identifier fn;
type T;
position p != e.p;
@@
fn(...)
{
  ...
  T i@p;
  ... when any
- i = E;
  ... when != i
}

@unused_assign2 depends on probe@
type T;
identifier i;
expression E;
@@
- T i = E;
 ... when != i

@unused_var depends on probe@
type T;
identifier i;
@@
- T i;
 ... when != i

@unnecessary_brackets depends on probe@
expression e1, e2;
@@
  if (e1)
- {
    return e2;
- }

@rrem depends on remove@
identifier remove.removefn;
@@

- removefn(...) {
?-\(dev_warn\|dev_info\|pr_warn\|pr_crit\)(...);
- return 0;
- }

@depends on rrem@
identifier probe.p, remove.removefn;
@@

struct
(
  platform_driver
|
  i2c_driver
|
  spi_driver
)
  p = {
- .remove = \(__exit_p(removefn)\|removefn\),
};

@script:python depends on unused_assign@
p << probe.pos;
@@

print >> f, "%s:cleanup1:%s" % (p[0].file, p[0].line)

@script:python depends on unused_assign2@
p << probe.pos;
@@

print >> f, "%s:cleanup1:%s" % (p[0].file, p[0].line)

@script:python depends on unused_var@
p << probe.pos;
@@

print >> f, "%s:cleanup2:%s" % (p[0].file, p[0].line)

@script:python depends on unnecessary_brackets@
p << probe.pos;
@@

print >> f, "%s:cleanup3:%s" % (p[0].file, p[0].line)

@script:python depends on rrem@
p << remove.pos;
@@

print >> f, "%s:cleanup4:%s" % (p[0].file, p[0].line)

@script:python depends on empty_if@
p << remove.pos;
@@

print >> f, "%s:cleanup5:%s" % (p[0].file, p[0].line)

@script:python depends on empty_while@
p << remove.pos;
@@

print >> f, "%s:cleanup6:%s" % (p[0].file, p[0].line)
