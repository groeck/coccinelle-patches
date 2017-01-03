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

@prb depends on probe@
identifier initfn, pdev;
expression clk, e2;
position p;
@@

initfn(struct platform_device *pdev, ...)
{
<+...
- clk = clk_get@p(&pdev->dev, e2);
+ clk = devm_clk_get(&pdev->dev, e2);
  ...
  when any
?-clk_put(clk);
...+>
}

@rem depends on prb@
identifier remove.removefn;
expression prb.clk;
@@

removefn(...)
{
  <...
- clk_put(clk);
  ...>
}

@r@
identifier probe.probefn;
position p;
expression clk, e;
@@
probefn(...)
{
<+...
  clk = clk_get@p(NULL, e);
  ...+>
}

@rx depends on r@
identifier probe.probefn;
expression e;
position r.p;
identifier ret;
expression clk;
@@
probefn(...)
{
<+...
  clk = clk_get@p(NULL, e);
  ... when any
  devm_add_action_or_reset(..., e);
...+>
}

@prb2 depends on !rx@
identifier probe.probefn, pdev, ret;
expression clk, e2;
statement S;
position p;
@@

probefn(struct platform_device *pdev, ...)
{
  ...
  int ret;
<+...
  clk = clk_get@p(NULL, e2);
  if (IS_ERR(clk)) S
+ ret = devm_add_action_or_reset(&pdev->dev, (void(*)(void *))clk_put, e2);
+ if (ret)
+   return ret;
  ...
  when any
?-clk_put(clk);
...+>
}

@rem2 depends on prb2@
identifier remove.removefn;
expression prb2.clk;
@@

removefn(...)
{
  <...
- clk_put(clk);
  ...>
}

@a depends on prb@
expression prb.clk, clk2;
@@
clk2 = clk;

@rema depends on a@
identifier remove.removefn;
expression a.clk2;
@@
removefn(...)
{
  <+...
- clk_put(clk2);
  ...+>
}

@script:python@
p << prb.p;
@@

print >> f, "%s:c4:%s" % (p[0].file, p[0].line)

@script:python@
p << prb2.p;
@@

print >> f, "%s:c5:%s" % (p[0].file, p[0].line)
