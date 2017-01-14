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

@pxa depends on probe@
identifier probe.probefn;
expression ssp;
position p;
@@
probefn(...)
{
<+...
  ssp = pxa_ssp_request@p(...);
...+>
}

@pxad depends on pxa@
identifier probe.probefn;
expression err, pxa.ssp;
position pxa.p;
statement S;
@@
probefn(...)
{
<+...
  ssp = pxa_ssp_request@p(...);
  if (!ssp) S
  err = devm_add_action_or_reset(..., ssp);
...+>
}

@pxa_probe depends on pxa && !pxad@
identifier probe.probefn;
expression ssp;
position p;
identifier pdev; 
statement S;
fresh identifier cb = probefn ## "_pxa_ssb_cb";
@@

probefn(struct platform_device *pdev)
{
  <+...
  ssp = pxa_ssp_request@p(...);
  if (!ssp) S
+ derr = devm_add_action_or_reset(&pdev->dev, cb, ssp);
+ if (derr)
+        return derr;
  ... when any
?-pxa_ssp_free(ssp);
...+>
}

@depends on pxa_probe@
identifier probe.probefn;
identifier pxa_probe.cb;
@@
+ void cb(void *ssp) { pxa_ssp_free(ssp); }
  probefn(...) {
+ int derr;
  ...
  }

// Try to do some variable folding.
// To do that, identify the newly introduced error variable as well
// as some other variable commonly used as return variable.
// If both are found, replace the new error variable with the already
// available variable.

@derr depends on pxa_probe@
identifier probe.probefn;
identifier err;
expression ssp;
position p;
statement S;
@@
probefn(...)
{
  int err;
<...
  ssp = pxa_ssp_request@p(...);
  if (!ssp) S
  err = devm_add_action_or_reset(..., ssp);
...>
}

@dret depends on pxa_probe@
identifier probe.probefn;
identifier ret != derr.err;
@@
probefn(...)
{
<...
  ret =
(
  devm_request_threaded_irq
|
  request_irq
|
  devm_request_irq
|
  devm_gpio_request_one
)
  (...);
...>
}

@depends on dret && derr@
identifier probe.probefn;
identifier derr.err;
identifier dret.ret;
expression E;
@@
probefn(...)
{
- int err;
<+...
- err = E; if (err) return err;
+ ret = E; if (ret) return ret;
...+>
}

@depends on pxa_probe@
identifier remove.removefn;
expression pxa_probe.ssp;
@@

removefn(...){
  <...
- pxa_ssp_free(ssp);
  ...>
}

@script:python depends on pxa_probe@
p << pxa.p;
@@

print >> f, "%s:pxa1:%s" % (p[0].file, p[0].line)
