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

@empty_for depends on probe@
identifier initfn;
expression e1, e2, e3;
@@

initfn(...) {
<+...
- for (e1; e2; e3)
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
expression E, f;
expression list es;
identifier fn;
type T;
position p != e.p;
@@
fn(...)
{
  ...
  T i@p;
  <+... when != i
(
- i = i2c_get_clientdata(es);
|
- i = platform_get_irq_byname(es);
|
- i = regmap_irq_get_virq(es);
|
- i = platform_get_resource(es);
|
  i = <+... f(...) ...+>;
|
- i = E;
)
  ...+>
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

@ex@
identifier i;
position p;
type T;
@@

(
extern T i@p;
|
static T i@p;
)

// Remove trailing assignments if the result is not used and if the
// expression used to calculate it does not call a function.
// The second rule ensures that i != j. There should be (and probably is)
// a better way to do that.

@need_trailing depends on probe@
identifier fn;
identifier i;
identifier j;
expression E;
identifier f;
type T;
position p != ex.p;
position p1;
@@

fn(...)
{
  ...
  T i@p;
<...
(
  i = <+... f(...) ...+>;
  return j;
|
  i = E;
  return i;
|
  i@p1 = E;
  return j;
)
  ...>
}

@trailing depends on need_trailing@
identifier i;
expression E;
position need_trailing.p1;
@@

- i@p1 = E;

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

@script:python depends on trailing@
p << need_trailing.p1;
@@

print >> f, "%s:cleanup7:%s" % (p[0].file, p[0].line)
