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
expression ap;
position p;
@@
probefn(...)
{
<+...
ap = of_iomap@p(...);
...+>
}

@prb@
identifier probe.probefn, pdev;
expression index;
expression np, ap;
position r.p;
statement S;
@@

probefn(struct platform_device *pdev)
{
+ struct resource *res;
  <+...
- ap = of_iomap@p(np, index);
- if (\(!ap\|ap==NULL\)) S
+ res = platform_get_resource(pdev, IORESOURCE_MEM, index);
+ ap = devm_ioremap_resource(&pdev->dev, res);
+ if (IS_ERR(ap))
+   return PTR_ERR(ap);
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

print >> f, "%s:ofiomap1:%s" % (p[0].file, p[0].line)
