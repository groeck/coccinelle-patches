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

@worker depends on probe@
identifier initfn;
position p;
expression w;
@@
initfn(...)
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
identifier remove.removefn, probe.probefn;
expression worker.w;
@@

(
removefn
|
probefn
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
statement S;
identifier pdev; 
@@

initfn(struct platform_device *pdev)
{
+ int wer;
  <+...
  INIT_DELAYED_WORK@p(w, e);
+ wer = devm_add_action_or_reset(&pdev->dev, (void (*)(void *))cancel_delayed_work_sync, w);
+ if (wer)
+        return wer;
  ... when any
?-cancel_delayed_work_sync(w);
...+>
}

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
)
  (...);
...>
}

@depends on wret && werr@
identifier worker.initfn;
identifier werr.err;
identifier wret.ret;
@@
initfn(...)
{
- int err;
<+...
- err
+ ret
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
