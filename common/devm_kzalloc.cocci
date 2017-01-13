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

@msg depends on probe@
expression mp;
position p;
@@
  <...
  mp = devm_kzalloc@p(...);
  if (\(!mp\|mp==NULL\)) {
  ...
- \(dev_err\|pr_err\)(...);
  ... when != mp
  }
  ...>

@script:python@
p << msg.p;
@@

print >> f, "%s:devm_kzalloc1:%s" % (p[0].file, p[0].line)
