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

@serio@
identifier probe.probefn, pdev;
expression e, e1, e2;
position p;
@@
probefn(...) {
  <+...
  e = kzalloc@p(e1, e2)
  ... when any
  serio_register_port(e);
  ...+>
}

@alloc@
identifier probe.probefn, pdev;
expression e, e1, e2;
position p != serio.p;
position p1;
@@
probefn@p1(struct platform_device *pdev, ...) {
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

@rem depends on alloc@
identifier remove.removefn;
expression e;
@@
removefn(...) {
  <...
- kfree(e);
  ...>
}

@script:python@
p << alloc.p1;
@@

print >> f, "%s:kzalloc1:%s" % (p[0].file, p[0].line)
