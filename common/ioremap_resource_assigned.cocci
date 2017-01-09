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
expression res, r2;
position pr, pi;
statement S;
expression base;
@@
probefn(...)
{
<+...
  base = res->start;
  ... when any
(
  if (!request_mem_region@pr(base, ...)) S
|
  r2 = request_mem_region@pr(base, ...);
  ... when != r2
  if (\(!r2\|r2==NULL\)) S
)
  ... when any
  ap = ioremap@pi(base, ...);
...+>
}

@prb@
identifier probe.probefn, pdev;
expression ap;
position r.pr;
expression r.res, r.r2;
statement S;
expression list es, es2;
expression err;
expression r.base;
@@

probefn(struct platform_device *pdev)
{
  <+...
- base = res->start;
  ... when any
(
- if (!request_mem_region@pr(base, es)) S
|
- r2 = request_mem_region@pr(base, es);
- if (!r2) S
)
  ...
- ap = ioremap(base, es2);
+ ap = devm_ioremap_resource(&pdev->dev, res);
  ... when != ap
- if (\(ap == NULL\|!ap\))
+ if (IS_ERR(ap))
  {
    ...
-   err = \(-ENXIO\|-ENOMEM\);
+   err = PTR_ERR(ap);
    ...
  }
  ...
  when any
?-iounmap(ap);
  ...
  when any
?-release_mem_region(base, ...);
...+>
}

@rem depends on prb@
identifier remove.removefn;
expression prb.ap, r.base;
@@

removefn(...)
{
  <...
- iounmap(ap);
  ... when any
- release_mem_region(base, ...);
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

@script:python depends on r@
p << r.pr;
@@

print >> f, "%s:ioremap2:%s" % (p[0].file, p[0].line)
