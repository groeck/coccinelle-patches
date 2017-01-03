virtual patch

@initialize:python@
@@

f = open('watchdog-of_iomap.log', 'w')

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
expression ap;
position p;
identifier ret;
@@
probefn(...)
{
  ...
  int ret;
<+...
ap = of_iomap@p(...);
...+>
}

@rx depends on r@
identifier probe.probefn;
expression e, ap;
position r.p;
@@
probefn(...)
{
<+...
ap = of_iomap@p(...);
...
when any
e = devm_add_action_or_reset(..., ap);
...+>
}

@prb depends on !rx@
identifier probe.probefn, pdev;
expression ap;
position r.p;
statement S;
identifier r.ret;
@@

probefn(struct platform_device *pdev)
{
  <+...
  ap = of_iomap@p(...);
  if (!ap) S
+ ret = devm_add_action_or_reset(&pdev->dev, (void (*)(void *))iounmap, ap);
+ if (ret)
+        return ret;
  ...
  when any
?-iounmap(ap);
...+>
}

@rem depends on prb@
identifier remove.removefn;
expression prb.ap;
@@

removefn(...)
{
  <+...
?-iounmap(ap);
  ...+>
}

@a depends on prb@
expression prb.ap, ap2;
@@
ap2 = ap;

@rem2 depends on a@
identifier remove.removefn;
expression a.ap2;
@@
removefn(...)
{
  <+...
- iounmap(ap2);
  ...+>
}

@script:python depends on prb@
p << r.p;
@@

print >> f, "%s:o2:%s" % (p[0].file, p[0].line)
