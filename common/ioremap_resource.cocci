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
expression res;
position pr;
statement S;
@@
probefn(...)
{
<+...
(
  if (!request_mem_region@pr(res->start, ...)) S
|
  res = request_mem_region@pr(res->start, ...);
  if (\(!res\|res==NULL\)) S
|
  res = platform_get_resource@pr(...);
)
  ... when any
  ap = ioremap(res->start, ...);
...+>
}

@prb@
identifier probe.probefn, pdev;
expression ap;
position r.pr;
expression r.res, s;
statement S;
expression list es1, es2;
expression err;
@@

probefn(struct platform_device *pdev)
{
  <+...
(
- if (!request_mem_region@pr(res->start, es1))
-   S
|
- res = request_mem_region@pr(res->start, ...);
- if (\(!res\|res==NULL\)) S
|
  res = platform_get_resource@pr(pdev, ...);
)
  ... when any
- ap = ioremap(res->start, es2);
+ ap = devm_ioremap_resource(&pdev->dev, res);
  ... when != ap
(
- if (\(ap == NULL\|!ap\))
+ if (IS_ERR(ap))
  {
    ...
-   err = \(-ENXIO\|-ENOMEM\);
+   err = PTR_ERR(ap);
    ...
  }
|
)
  ...
  when any
?-iounmap(ap);
  ... when any
?-release_mem_region(res->start, ...);
...+>
}

@rem depends on prb@
identifier remove.removefn;
expression prb.ap;
expression r.res;
@@

removefn(...)
{
  <...
- iounmap(ap);
  ... when any
?-release_mem_region(res->start, ...);
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

print >> f, "%s:ioremap3:%s" % (p[0].file, p[0].line)
