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

@worker depends on probe@
identifier initfn;
position p;
expression w;
@@
initfn(...)
{
<+...
INIT_DELAYED_WORK@p(w,...);
...+>
}

@wd depends on worker@
identifier worker.initfn;
expression w, e;
position worker.p;
expression s;
@@
initfn(...)
{
<+...
INIT_DELAYED_WORK@p(w, e);
s = devm_add_action_or_reset(..., w);
...+>
}

@wc depends on worker@
identifier remove.removefn, probe.probefn;
expression worker.w;
@@

(
removefn
|
probefn
)
  (...){
  <+...
  cancel_delayed_work_sync(w);
  ...+>
}

@worker_probe depends on !wd && wc@
identifier worker.initfn;
expression w, e;
position worker.p;
statement S;
identifier pdev; 
@@

initfn(struct platform_device *pdev)
{
+ int werror;
  <+...
  INIT_DELAYED_WORK@p(w, e);
+ werror = devm_add_action_or_reset(&pdev->dev, (void (*)(void *))cancel_delayed_work_sync, w);
+ if (werror)
+        return werror;
  ... when any
?-cancel_delayed_work_sync(w);
...+>
}

@depends on worker_probe@
identifier remove.removefn, probe.probefn;
expression worker_probe.w;
@@

(
removefn
|
probefn
)
  (...){
  <...
- cancel_delayed_work_sync(w);
  ...>
}

@script:python depends on worker_probe@
p << worker.p;
@@

print >> f, "%s:worker1:%s" % (p[0].file, p[0].line)
