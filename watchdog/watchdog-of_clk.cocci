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
identifier initfn;
expression clk;
position p;
identifier ret;
@@
initfn(...)
{
  ...
  int ret;
<+...
(
clk = of_clk_get@p(...);
|
clk = of_clk_get_by_name@p(...);
)
...+>
}

@rx depends on r@
identifier r.initfn;
expression e, clk;
position r.p;
@@
initfn(...)
{
<+...
(
clk = of_clk_get@p(...);
|
clk = of_clk_get_by_name@p(...);
)
...
when any
e = devm_add_action_or_reset(..., clk);
...+>
}

@prb depends on !rx@
identifier r.initfn, pdev;
expression clk;
position r.p;
statement S;
identifier r.ret;
@@

initfn(struct platform_device *pdev, ...)
{
  <+...
(
clk = of_clk_get@p(...);
|
clk = of_clk_get_by_name@p(...);
)
(
  if (IS_ERR(clk)) S
+ ret = devm_add_action_or_reset(&pdev->dev, (void (*)(void *))clk_put, clk);
+ if (ret)
+        return ret;
|
  if (!IS_ERR(clk)) {
+ ret = devm_add_action_or_reset(&pdev->dev, (void (*)(void *))clk_put, clk);
+ if (ret)
+        return ret;
  ...
  when any
?-clk_put(clk);
  ...
  }
)
  ...
  when any
?-clk_put(clk);
...+>
}

@rem depends on prb@
identifier remove.removefn, probe.probefn;
expression prb.clk;
@@

(
removefn
|
probefn
)
  (...)
{
  <...
- clk_put(clk);
  ...>
}

@a depends on prb@
expression prb.clk, clk2;
@@
clk2 = clk;

@rem2 depends on a@
identifier remove.removefn;
expression a.clk2;
@@
removefn(...)
{
  <...
- clk_put(clk);
  ...>
}

@script:python depends on prb@
p << r.p;
@@

print >> f, "%s:o1:%s" % (p[0].file, p[0].line)
