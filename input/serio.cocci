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

@serio depends on probe@
identifier initfn;
expression mp;
position p;
@@
initfn(...)
{
<+...
serio_register_port@p(mp);
...+>
}

@seriod depends on serio@
identifier serio.initfn;
expression s, serio.mp;
position serio.p;
@@
initfn(...)
{
<+...
serio_register_port@p(mp);
s = devm_add_action_or_reset(..., mp);
...+>
}

@serio_probe depends on serio && !seriod@
identifier serio.initfn;
expression mp;
position p;
identifier pdev; 
fresh identifier cb = initfn ## "_serio_cb";
@@

initfn(struct platform_device *pdev)
{
  <+...
  serio_register_port@p(mp);
+ sret = devm_add_action_or_reset(&pdev->dev, cb, mp);
+ if (sret)
+        return sret;
  ... when any
?-serio_unregister_port(mp);
...+>
}

@depends on serio_probe@
identifier serio.initfn;
identifier serio_probe.cb;
@@
+ void cb(void *mp) { serio_unregister_port(mp); }
  initfn(...) {
+ int sret;
  ...
  }

// Try to do some variable folding.
// To do that, identify the newly introduced error variable as well
// as some other variable commonly used as return variable.
// If both are found, replace the new error variable with the already
// available variable.

@serr depends on serio_probe@
identifier serio.initfn;
identifier err;
expression mp;
@@
initfn(...)
{
  int err;
<...
  serio_register_port(mp);
  err = devm_add_action_or_reset(..., mp);
...>
}

@sret depends on serio_probe@
identifier serio.initfn;
identifier ret != serr.err;
@@
initfn(...)
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
  clk_prepare_enable
|
  PTR_ERR
|
  of_address_to_resource
)
  (...);
...>
}

@depends on sret && serr@
identifier serio.initfn;
identifier serr.err;
identifier sret.ret;
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

@depends on serio_probe@
identifier remove.removefn, probe.probefn;
expression serio_probe.mp;
@@

(
removefn
|
probefn
)
  (...){
  <...
- serio_unregister_port(mp);
  ...>
}

@serio_assign depends on serio_probe@
expression serio_probe.mp, mp2;
@@
mp2 = mp;

@serio_rem2 depends on serio_assign@
identifier remove.removefn;
expression serio_assign.mp2;
@@

removefn(...)
{
  <...
- serio_unregister_port(mp2);
  ...>
}

@script:python depends on serio_probe@
p << serio.p;
@@

print >> f, "%s:serio1:%s" % (p[0].file, p[0].line)
