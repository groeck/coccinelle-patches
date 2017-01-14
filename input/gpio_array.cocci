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
)

@remove@
identifier probe.p, removefn;
@@

  struct platform_driver p = {
    .remove = \(__exit_p(removefn)\|removefn\),
  };

@tilt depends on probe@
identifier probe.probefn;
position p;
expression err;
identifier gpios, nr_gpios;
type T;
identifier pdata;
statement S;
@@
probefn(...)
{
  ...
  T *pdata;
<+...
  err = gpio_request_array@p(pdata->gpios, pdata->nr_gpios);
  if (err) S
...+>
}

@tiltd depends on tilt@
identifier probe.probefn;
position tilt.p;
type tilt.T;
identifier pdata;
statement S;
expression err;
identifier pdev;
identifier tilt.gpios, tilt.nr_gpios;
@@
probefn(struct platform_device *pdev)
{
  ...
  T *pdata;
<+...
  err = gpio_request_array@p(pdata->gpios, pdata->nr_gpios);
  if (err) S
  err = devm_add_action_or_reset(..., pdata);
...+>
}

@tilt_probe depends on tilt && !tiltd@
identifier probe.probefn;
statement S;
type tilt.T;
identifier pdev;
position p;
expression err;
identifier pdata;
identifier tilt.gpios, tilt.nr_gpios;
fresh identifier cb = probefn ## "_gpio_free_cb";
@@

probefn(struct platform_device *pdev)
{
  ...
  T *pdata;
<+...
  err = gpio_request_array@p(pdata->gpios, pdata->nr_gpios);
  if (err) S
+ err = devm_add_action_or_reset(&pdev->dev, cb, (void *)pdata);
+ if (err) S
...+>
}

@depends on tilt_probe@
identifier probe.probefn;
identifier tilt_probe.cb;
type tilt.T;
@@
+ void cb(void *_pdata)
+ { T *pdata = _pdata; gpio_free_array(pdata->gpios, pdata->nr_gpios); }
  probefn(...) { ... }

@depends on tilt_probe@
identifier remove.removefn, probe.probefn;
identifier pdata;
type tilt.T;
identifier tilt.gpios, tilt.nr_gpios;
@@
(
  removefn
|
  probefn
)
  (...){
  ...
  T *pdata;
  <...
- gpio_free_array(pdata->gpios, pdata->nr_gpios);
  ...>
}

@script:python depends on tilt_probe@
p << tilt.p;
@@

print >> f, "%s:tilt1:%s" % (p[0].file, p[0].line)
