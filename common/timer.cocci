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
expression timer;
expression list es;
position p;
@@
initfn(...)
{
<+...
setup_timer@p(timer, es);
...+>
}

@rx depends on r@
identifier r.initfn;
expression timer, res;
expression list es;
position r.p;
statement S;
@@
initfn(...)
{
<+...
setup_timer@p(timer, es);
S
res = devm_add_action(..., timer);
...+>
}

@tc depends on r@
identifier remove.removefn, probe.probefn;
expression r.timer;
@@

(
removefn
|
probefn
)
  (...){
  <+...
  del_timer(timer);
  ...+>
}

@prb depends on !rx && tc@
identifier r.initfn, pdev;
expression timer;
expression list es;
position r.p;
statement S;
@@

initfn(struct platform_device *pdev, ...)
{
+ int terr;
  <+...
  setup_timer@p(timer, es);
+ terr = devm_add_action(&pdev->dev, (void (*)(void *))del_timer, timer);
+ if (terr)
+        return terr;
  ... when any
?-del_timer(timer);
...+>
}

@rem depends on prb@
identifier remove.removefn, probe.probefn;
expression prb.timer;
@@

(
removefn
|
probefn
)
  (...)
{
  <...
- del_timer(timer);
  ...>
}

@a depends on prb@
expression prb.timer, t2;
@@
t2 = timer;

@rem2 depends on a@
identifier remove.removefn;
expression a.t2;
@@
removefn(...)
{
  <...
- del_timer(t2);
  ...>
}

@script:python depends on prb@
p << r.p;
@@

print >> f, "%s:timer1:%s" % (p[0].file, p[0].line)
