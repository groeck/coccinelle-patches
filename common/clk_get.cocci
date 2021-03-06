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

@check0 depends on probe@
identifier initfn, pdev;
expression clk, clk2, e2;
expression dev;
position p;
@@
initfn(struct platform_device *pdev, ...)
{
<+...
  clk = clk_get@p(dev, e2);
  ... when any
  clk2 = clk;
...+>
}

@prb0@
identifier check0.initfn, check0.pdev;
expression clk, check0.clk2, e2;
position check0.p;
expression check0.dev != NULL;
@@

initfn(struct platform_device *pdev, ...)
{
<+...
- clk = clk_get@p(dev, e2);
+ clk = devm_clk_get(dev, e2);
  ...
  when any
?-clk_put(\(clk\|clk2\));
...+>
}

@rem0@
identifier remove.removefn;
expression prb0.clk, check0.clk2;
@@

removefn(...)
{
  <...
- clk_put(\(clk\|clk2\));
  ...>
}

@check depends on probe@
identifier initfn, pdev;
expression clk, e2;
expression dev;
position p;
@@
initfn(struct platform_device *pdev, ...)
{
<+...
  clk = clk_get@p(dev, e2);
...+>
}

@prb@
identifier check.initfn, check.pdev;
expression clk, e2;
position check.p;
expression check.dev != NULL;
@@

initfn(struct platform_device *pdev, ...)
{
<+...
- clk = clk_get@p(dev, e2);
+ clk = devm_clk_get(dev, e2);
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

@rx@
identifier probe.probefn;
expression e, e2;
position r.p;
identifier ret;
expression clk;
statement S;
@@
probefn(...)
{
<+...
  clk = clk_get@p(NULL, e);
  ... when != e
  e2 = devm_add_action_or_reset(..., e);
...+>
}

@prb2 depends on !rx@
identifier probe.probefn, pdev, ret;
expression clk, e2;
statement S;
position p;
fresh identifier cb = probefn ## "_clk_put_cb";
@@

probefn(struct platform_device *pdev, ...)
{
  ...
  int ret;
<+...
  clk = clk_get@p(NULL, e2);
  if (IS_ERR(clk)) S
+ ret = devm_add_action_or_reset(&pdev->dev, cb, e2);
+ if (ret)
+   return ret;
  ...
  when any
?-clk_put(clk);
...+>
}

@depends on prb2@
identifier probe.probefn;
identifier prb2.cb;
@@

+ static void cb(void *w) { clk_put(w); }
  probefn(...) { ... }

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
p << check.p;
@@

print >> f, "%s:clk4:%s" % (p[0].file, p[0].line)

@script:python@
p << prb2.p;
@@

print >> f, "%s:clk5:%s" % (p[0].file, p[0].line)
