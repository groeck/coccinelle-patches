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
expression e1;
expression e2;
position p;
@@
initfn(...)
{
<+...
e1 = clk_prepare_enable@p(e2);
...+>
}

@rx depends on r@
identifier r.initfn;
expression e1, e2, e3;
position r.p;
statement S;
@@
initfn(...)
{
<+...
e1 = clk_prepare_enable@p(e2);
S
e3 = devm_add_action_or_reset(..., e2);
...+>
}

@prb depends on !rx@
identifier r.initfn, pdev;
local idexpression v;
expression e1;
position r.p;
statement S;
@@

initfn(struct platform_device *pdev, ...)
{
  <+...
  v = clk_prepare_enable@p(e1);
  if (
(
v
|
v < 0
)
  ) S
+ v = devm_add_action_or_reset(&pdev->dev, (void (*)(void *))clk_disable_unprepare, e1);
+ if (v)
+        return v;
  ... when any
?-clk_disable_unprepare(e1);
...+>
}

@rem depends on prb@
identifier remove.removefn, probe.probefn;
expression prb.e1;
@@

(
removefn
|
probefn
)
  (...)
{
  <...
- clk_disable_unprepare(e1);
  ...>
}

@a depends on prb@
expression prb.e1, e2;
@@
e2 = e1;

@rem2 depends on a@
identifier remove.removefn;
expression a.e2;
@@
removefn(...)
{
  <...
- clk_disable_unprepare(e2);
  ...>
}

@script:python depends on prb@
p << r.p;
@@

print >> f, "%s:clk2:%s" % (p[0].file, p[0].line)
