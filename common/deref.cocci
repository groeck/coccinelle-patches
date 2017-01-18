virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@probe@
identifier p, probefn;
declarer name module_platform_driver_probe;
@@
(
  module_platform_driver_probe(p, probefn);
|
  struct platform_driver p = {
    .probe = probefn,
  };
|
  struct i2c_driver p = {
    .probe = probefn,
  };
|
  struct spi_driver p = {
    .probe = probefn,
  };
)

// Try to find situations where a local structure variable dereferences another
// structure variable, then try to find situations where the original structure
// variable is used anyway.
// Note: This will miss situations where d is subsequently reassigned.

@check depends on probe exists@
identifier initfn;
identifier svar, elem;
type T;
position p;
identifier i;
identifier d;
@@

initfn@p(...) {
  ...
  T d = &svar->elem;
  <+...
(
  &svar->elem
|
  svar->elem.i
)
  ...+>
}

@prb depends on check@
identifier check.d;
identifier initfn;
identifier check.svar;
identifier check.elem;
position check.p;
type check.T;
identifier i;
position p1;
@@

initfn@p(...) {
  ...
  T d = &svar->elem;
<...
(
- &svar@p1->elem
+ d
|
- svar@p1->elem.i
+ d->i
)
...> }

// logging and formatting cleanup

@script:python depends on prb@
p << check.p;
p1 << prb.p1;
@@

print >> f, "%s:deref1:%s:%d" % (p[0].file, p[0].line, len(p1))

@depends on prb@
identifier check.d;
identifier fn != dev_name;
expression list es;
identifier prb.initfn;
@@

  initfn(...) {
  <...
- fn(d, es)
+ fn(d, es)
  ...>
  }
