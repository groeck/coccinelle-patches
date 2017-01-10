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

// Note: devm_kzalloc() must not be called for parameters
// to serio_register_port().

@serio depends on probe@
identifier initfn;
expression e, e1, e2;
position p;
@@
initfn(...) {
  <+...
  e = kzalloc@p(e1, e2)
  ... when any
  serio_register_port(e);
  ...+>
}

@alloc depends on probe@
identifier initfn, pdev;
expression e, e1, e2;
position p != serio.p;
position p1;
@@
initfn@p1(struct platform_device *pdev, ...) {
  <+...
  e =
(
- kzalloc@p
|
- kmalloc@p
)
- (e1, e2)
+ devm_kzalloc(&pdev->dev, e1, e2)
  ...
?-kfree(e);
  ...+>
}

@@
identifier remove.removefn;
expression alloc.e;
@@
removefn(...) {
  <...
- kfree(e);
  ...>
}

@ak@
expression alloc.e, e2;
@@
e2 = e;

@@
identifier remove.removefn;
expression ak.e2;
@@
removefn(...) {
  <...
- kfree(e2);
  ...>
}

@kcalloc depends on probe@
identifier initfn, pdev;
expression e;
expression list es;
position p;
@@
initfn@p(struct platform_device *pdev, ...) {
  <+...
- e = kcalloc(es);
+ e = devm_kcalloc(&pdev->dev, es);
  ...
?-kfree(e);
  ...+>
}

@@
identifier remove.removefn;
expression kcalloc.e;
@@
removefn(...) {
  <...
- kfree(e);
  ...>
}

@akc@
expression kcalloc.e, e2;
@@
e2 = e;

@@
identifier remove.removefn;
expression akc.e2;
@@
removefn(...) {
  <...
- kfree(e2);
  ...>
}

@script:python@
p << alloc.p1;
@@

print >> f, "%s:kzalloc1:%s" % (p[0].file, p[0].line)
