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

// Get type of device.
// Using it ensures that we don't touch any other data structure
// which might have a '->dev' object.

@ptype depends on probe@
type T;
identifier probe.probefn;
identifier pdev;
@@
probefn(T *pdev, ...) { ... }

@check depends on probe@
identifier initfn, pdev;
expression pin, flag, name;
expression dev;
position p;
identifier ret;
type ptype.T;
@@
initfn(T *pdev, ...)
{
<+...
(
  ret = gpio_request@p(pin, name);
|
  ret = gpio_request_one@p(pin, flag, name);
)
...+>
}

@prb@
identifier check.initfn, check.pdev;
expression pin, flag, name;
position check.p;
identifier ret;
type ptype.T;
@@

initfn(T *pdev, ...)
{
<+...
(
- ret = gpio_request@p(pin, name);
+ ret = devm_gpio_request(&pdev->dev, pin, name);
|
- ret = gpio_request_one@p(pin, flag, name);
+ ret = devm_gpio_request_one(&pdev->dev, pin, flag, name);
)
  ...
  when any
?-gpio_free(pin);
...+>
}

@rem depends on prb@
identifier remove.removefn;
expression prb.pin;
@@

removefn(...)
{
  <...
- gpio_free(pin);
  ...>
}

@a depends on prb@
expression prb.pin, pin2;
@@
pin2 = pin;

@rema depends on a@
identifier remove.removefn;
expression a.pin2;
@@
removefn(...)
{
  <+...
- gpio_free(pin2);
  ...+>
}

@script:python@
p << check.p;
@@

print >> f, "%s:gpio1:%s" % (p[0].file, p[0].line)
