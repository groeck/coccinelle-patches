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

@prb_c depends on probe@
identifier initfn, pdev;
expression clk;
position p;
@@

initfn@p(struct platform_device *pdev, ...)
{
<+...
- clk = of_clk_get(..., 0);
+ clk = devm_clk_get(&pdev->dev, NULL);
  ...
  when any
?-clk_put(clk);
...+>
}

@rem_c@
identifier remove.removefn, probe.probefn;
expression prb_c.clk;
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

@ac@
expression prb_c.clk, clk2;
@@
clk2 = clk;

@rem2_c@
identifier remove.removefn;
expression ac.clk2;
@@
removefn(...)
{
  <...
- clk_put(clk2);
  ...>
}

@prb_cn@
identifier initfn, pdev;
expression clk;
position p;
expression np, name;
@@

initfn@p(struct platform_device *pdev, ...)
{
<+...
- clk = of_clk_get_by_name(np, name);
+ clk = devm_clk_get_by_name(&pdev->dev, name);
  ...
  when any
?-clk_put(clk);
...+>
}

@rem_cn@
identifier remove.removefn, probe.probefn;
expression prb_cn.clk;
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

@acn@
expression prb_cn.clk, clk2;
@@
clk2 = clk;

@rem2_cn@
identifier remove.removefn;
expression acn.clk2;
@@
removefn(...)
{
  <...
- clk_put(clk2);
  ...>
}

@script:python@
p << prb_c.p;
@@

print >> f, "%s:o1a:%s" % (p[0].file, p[0].line)

@script:python@
p << prb_cn.p;
@@

print >> f, "%s:o1b:%s" % (p[0].file, p[0].line)
