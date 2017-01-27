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

// Catch function parameters.
// Handle those first to trigger reformatting.

@prb depends on probe@
identifier d;
identifier svar;
identifier elem;
position p;
type T;
expression e;
expression list es;
identifier fn;
@@

  T d@p = &svar->elem;
<...
- fn(&svar->elem, es)
+ fn(d, es)
...>
? d = e;

@script:python depends on prb@
p << prb.p;
@@

print >> f, "%s:deref1:%s:%d" % (p[0].file, p[0].line, len(p))

// Now address non-functions and multiple transformations in function
// parameters.

@prb2 depends on probe@
identifier d;
identifier svar;
identifier elem;
type T;
identifier i;
expression e;
position p;
@@

  T d@p = &svar->elem;
  <...
(
- &svar->elem
+ d
|
- svar->elem.i
+ d->i
)
  ...>
? d = e;

// logging

@script:python depends on prb2@
p << prb2.p;
@@

print >> f, "%s:deref1:%s:%d" % (p[0].file, p[0].line, len(p))
