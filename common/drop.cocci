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

@drvdata depends on probe@
identifier remove.removefn;
expression dev;
@@

removefn(...) {
<+...
- dev_set_drvdata(dev, NULL);
...+>
}

@wakeup depends on probe@
identifier remove.removefn;
expression dev;
@@

removefn(...) {
<+...
- device_init_wakeup(...);
...+>
}

@script:python depends on drvdata@
p << remove.pos;
@@

print >> f, "%s:drop1:%s" % (p[0].file, p[0].line)

@script:python depends on wakeup@
p << remove.pos;
@@

print >> f, "%s:drop2:%s" % (p[0].file, p[0].line)
