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

@r@
identifier probe.probefn;
position p;
@@
probefn(...)
{
<+...
  register_restart_handler@p(...);
...+>
}

@rx depends on r@
identifier probe.probefn;
expression e;
position r.p;
identifier ret;
@@
probefn(...)
{
<+...
  register_restart_handler@p(e);
  ... when any
  devm_add_action_or_reset(..., e);
...+>
}

@prb depends on !rx@
identifier probe.probefn, pdev;
expression e;
statement S;
identifier ret;
position p;
@@

probefn(struct platform_device *pdev, ...)
{
  <+...
(
  ret = register_restart_handler@p(e);
- if (ret) S
+ if (ret)
+    S
+ else
+    devm_add_action_or_reset(&pdev->dev, (void (*)(void *))unregister_restart_handler, e);
|
  register_restart_handler(e);
+ devm_add_action_or_reset(&pdev->dev, (void (*)(void *))unregister_restart_handler, e);
)
  ...+>
}

@rem depends on prb@
identifier remove.removefn;
expression prb.e;
@@

removefn(...)
{
  <+...
?-unregister_restart_handler(e);
  ...+>
}

@script:python depends on prb@
p << prb.p;
@@

print >> f, "%s:restart1:%s" % (p[0].file, p[0].line)
