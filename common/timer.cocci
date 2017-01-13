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

@r depends on probe@
identifier initfn;
expression timer;
expression list es;
position p;
@@
initfn(...)
{
<+...
setup_timer@p(timer, es);
...+>
}

@rx@
identifier r.initfn;
expression timer, res;
expression list es;
position r.p;
statement S;
@@
initfn(...)
{
<+...
setup_timer@p(timer, es);
S
res = devm_add_action(..., timer);
...+>
}

@tc@
identifier remove.removefn, probe.probefn;
expression r.timer;
@@

(
removefn
|
probefn
)
  (...){
  <+...
  del_timer(timer);
  ...+>
}

@prb depends on !rx && tc@
identifier r.initfn, pdev;
expression timer;
expression list es;
position r.p;
fresh identifier cb = initfn ## "_del_timer_cb";
@@

initfn(struct platform_device *pdev, ...)
{
+ int terr;
  <+...
  setup_timer@p(timer, es);
+ terr = devm_add_action(&pdev->dev, cb, timer);
+ if (terr)
+        return terr;
  ... when any
?-del_timer(timer);
...+>
}

@depends on prb@
identifier r.initfn;
identifier prb.cb;
@@
+ static void cb(void *t)
+ {
+	del_timer(t);
+ }
  initfn(...) {...}

@rem@
identifier remove.removefn, probe.probefn;
expression prb.timer;
@@

(
removefn
|
probefn
)
  (...)
{
  <...
- del_timer(timer);
  ...>
}

@a@
expression prb.timer, t2;
@@
t2 = timer;

@rem2@
identifier remove.removefn;
expression a.t2;
@@
removefn(...)
{
  <...
- del_timer(t2);
  ...>
}

// repeat with del_timer_sync() instead of del_timer()

@rs depends on probe@
identifier initfn;
expression timer;
expression list es;
position p;
@@
initfn(...)
{
<+...
setup_timer@p(timer, es);
...+>
}

@rsx@
identifier rs.initfn;
expression timer, res;
expression list es;
position rs.p;
statement S;
@@
initfn(...)
{
<+...
setup_timer@p(timer, es);
S
res = devm_add_action(..., timer);
...+>
}

@tcs@
identifier remove.removefn, probe.probefn;
expression rs.timer;
@@

(
removefn
|
probefn
)
  (...){
  <+...
  del_timer_sync(timer);
  ...+>
}

@prbs depends on !rsx && tcs@
identifier rs.initfn, pdev;
expression timer;
expression list es;
position rs.p;
fresh identifier cb = initfn ## "_timer_sync_cb";
@@

initfn(struct platform_device *pdev, ...)
{
+ int terr;
  <+...
  setup_timer@p(timer, es);
+ terr = devm_add_action(&pdev->dev, cb, timer);
+ if (terr)
+        return terr;
  ... when any
?-del_timer_sync(timer);
...+>
}

@depends on prbs@
identifier rs.initfn;
identifier prbs.cb;
@@
+ static void cb(void *t)
+ {
+	del_timer_sync(t);
+ }
  initfn(...) {...}

// Try to do some variable folding.
// To do that, identify the newly introduced error variable as well
// as some other variable commonly used as return variable.
// If both are found, remove terr and replace it with the other
// variable.

@terr depends on prb || prbs@
identifier initfn;
identifier t;
expression timer;
expression list es;
@@
initfn(...)
{
  int t;
<...
  setup_timer(timer, es);
  t = devm_add_action(..., timer);
...>
}

@tret depends on prb || prbs@
identifier rs.initfn;
identifier ret != terr.t;
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
  request_irq
)
  (...);
...>
}

@depends on tret && terr@
identifier rs.initfn;
identifier terr.t;
identifier tret.ret;
expression list es;
@@
initfn(...)
{
- int t;
<+...
- t = devm_add_action(es); if (t) return t;
+ ret = devm_add_action(es); if (ret) return ret;
...+>
}

@rems@
identifier remove.removefn, probe.probefn;
expression prbs.timer;
@@

(
removefn
|
probefn
)
  (...)
{
  <...
- del_timer_sync(timer);
  ...>
}

@as@
expression prbs.timer, t2;
@@
t2 = timer;

@rems2@
identifier remove.removefn;
expression as.t2;
@@
removefn(...)
{
  <...
- del_timer_sync(t2);
  ...>
}

@script:python depends on prb@
p << r.p;
@@

print >> f, "%s:timer1:%s" % (p[0].file, p[0].line)

@script:python depends on prbs@
p << rs.p;
@@

print >> f, "%s:timer2:%s" % (p[0].file, p[0].line)
