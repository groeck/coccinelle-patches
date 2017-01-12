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

@remove@
identifier probe.p, removefn;
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
    .remove = \(__exit_p(removefn)\|removefn\),
  };

@used depends on probe@
identifier fn != probe.probefn;
@@

fn(...) {
 <+...
(
platform_get_drvdata(...)
|
dev_get_drvdata(...)
|
i2c_get_clientdata(...)
|
spi_get_drvdata(...)
)
 ...+>
}

@r1 depends on !used@
identifier probe.probefn;
position p;
@@

probefn(...) {
<...
- platform_set_drvdata@p(...);
...> }

@r2 depends on !used@
identifier probe.probefn;
position p;
@@

probefn(...) {
<...
- dev_set_drvdata@p(...);
...> }

@r3 depends on !used@
identifier probe.probefn;
position p;
@@

probefn(...) {
<...
- i2c_set_clientdata@p(...);
...> }

@r4 depends on !used@
identifier probe.probefn;
position p;
@@

probefn(...) {
<...
- spi_set_drvdata@p(...);
...> }

@script:python@
p << r1.p;
@@

print >> f, "%s:pdata1:%s" % (p[0].file, p[0].line)

@script:python@
p << r2.p;
@@

print >> f, "%s:pdata2:%s" % (p[0].file, p[0].line)

@script:python@
p << r3.p;
@@

print >> f, "%s:pdata3:%s" % (p[0].file, p[0].line)

@script:python@
p << r4.p;
@@

print >> f, "%s:pdata4:%s" % (p[0].file, p[0].line)
