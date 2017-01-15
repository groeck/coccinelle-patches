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

@check depends on probe@
identifier initfn, pdev;
expression name;
expression dev;
position p;
expression pwm;
@@
initfn(...)
{
<+...
  pwm = pwm_get@p(dev, name);
...+>
}

@prb@
identifier check.initfn;
expression dev, name;
position check.p;
expression pwm;
@@

initfn(...)
{
<+...
- pwm = pwm_get@p(dev, name);
+ pwm = devm_pwm_get(dev, name);
  ...
  when any
?-pwm_free(pwm);
...+>
}

@rem depends on prb@
identifier remove.removefn;
expression prb.pwm;
@@

removefn(...)
{
  <...
- pwm_free(pwm);
  ...>
}

@a depends on prb@
expression prb.pwm, pwm2;
@@
pwm2 = pwm;

@rema depends on a@
identifier remove.removefn;
expression a.pwm2;
@@
removefn(...)
{
  <+...
- pwm_free(pwm2);
  ...+>
}

@script:python@
p << check.p;
@@

print >> f, "%s:pwm1:%s" % (p[0].file, p[0].line)
