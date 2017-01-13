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

@worker depends on probe@
identifier initfn;
position p;
expression w;
type ptype.T;
identifier pdev;
@@
initfn(T *pdev, ...)
{
<+...
INIT_DELAYED_WORK@p(w,...);
...+>
}

@wd depends on worker@
identifier worker.initfn;
expression w, e;
position worker.p;
expression s;
@@
initfn(...)
{
<+...
INIT_DELAYED_WORK@p(w, e);
s = devm_add_action_or_reset(..., w);
...+>
}

@wc depends on worker@
identifier remove.removefn, worker.initfn;
expression worker.w;
@@

(
removefn
|
initfn
)
  (...){
  <+...
  cancel_delayed_work_sync(w);
  ...+>
}

@worker_probe depends on !wd && wc@
identifier worker.initfn;
expression w, e;
position worker.p;
identifier pdev;
type ptype.T;
fresh identifier cb = initfn ## "_work_cb";
@@

initfn(T *pdev, ...)
{
+ int wer;
  <+...
  INIT_DELAYED_WORK@p(w, e);
+ wer = devm_add_action_or_reset(&pdev->dev, cb, w);
+ if (wer)
+        return wer;
  ... when any
?-cancel_delayed_work_sync(w);
...+>
}

// Add callback function

@worker_cb depends on worker@
identifier worker.initfn;
identifier worker_probe.cb;
@@

+ static void cb(void *w)
+ { cancel_delayed_work_sync(w); }
  initfn(...) { ... }

// Try to do some variable folding.
// To do that, identify the newly introduced error variable as well
// as some other variable commonly used as return variable.
// If both are found, replace the new error variable with the already
// available variable.

@werr depends on worker_probe@
identifier worker.initfn;
identifier err;
expression w;
@@
initfn(...)
{
  int err;
<...
  INIT_DELAYED_WORK(w, ...);
  err = devm_add_action_or_reset(..., w);
...>
}

@wret depends on worker_probe@
identifier worker.initfn;
identifier ret != werr.err;
@@
initfn(...)
{
<...
  ret =
(
  watchdog_register_device
|
  devm_watchdog_register_device
|
  misc_register
|
  input_register_device
|
  devm_extcon_dev_register
|
  request_threaded_irq
|
  devm_request_threaded_irq
|
  request_irq
|
  devm_request_irq
|
  clk_prepare_enable
|
  PTR_ERR
|
  devm_regulator_bulk_get
|
  register_netdev
)
  (...);
...>
}

@depends on wret && werr@
identifier worker.initfn;
identifier werr.err;
identifier wret.ret;
expression E;
@@
initfn(...)
{
- int err;
<+...
- err = E; if (err) return err;
+ ret = E; if (ret) return ret;
...+>
}

@depends on worker_probe@
identifier remove.removefn, probe.probefn;
expression worker_probe.w;
@@

(
removefn
|
probefn
)
  (...){
  <...
- cancel_delayed_work_sync(w);
  ...>
}

@script:python depends on worker_probe@
p << worker.p;
@@

print >> f, "%s:worker1:%s" % (p[0].file, p[0].line)
