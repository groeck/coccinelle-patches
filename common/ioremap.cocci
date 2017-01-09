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


@r depends on probe@
identifier probe.probefn;
expression ap;
position p;
@@
probefn(...)
{
<+...
(
ap = ioremap@p(...);
|
ap = ioremap_nocache@p(...);
)
...+>
}

@prb@
identifier probe.probefn, pdev;
expression ap;
expression list es;
position r.p;
statement S;
@@

probefn(struct platform_device *pdev)
{
  <+...
(
- ap = ioremap@p(es);
+ ap = devm_ioremap(&pdev->dev, es);
|
- ap = ioremap_nocache@p(es);
+ ap = devm_ioremap_nocache(&pdev->dev, es);
)
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
  <...
- iounmap(ap);
  ...>
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
  <...
- iounmap(ap2);
  ...>
}

@script:python depends on prb@
p << r.p;
@@

print >> f, "%s:ioremap1:%s" % (p[0].file, p[0].line)
