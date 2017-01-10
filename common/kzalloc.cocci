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
expression mp, mp2, e1, e2;
position p;
@@
initfn(...) {
  <+...
  mp =
(
  kzalloc@p
|
  kmalloc@p
)
  (e1, e2)
  ...
(
  mp2 = mp;
|
)
  ... when any
  serio_register_port(\(mp\|mp2\));
  ...+>
}

@alloc depends on probe@
identifier initfn, pdev;
expression mp, mp2, e1, e2;
position p != serio.p;
position p1;
@@
initfn@p1(struct platform_device *pdev, ...) {
  <+...
  mp =
(
- kzalloc@p
|
- kmalloc@p
)
- (e1, e2)
+ devm_kzalloc(&pdev->dev, e1, e2)
  ...
(
  mp2 = mp;
|
)
  ... when any
?-kfree(\(mp\|mp2\));
  ...+>
}

@@
identifier remove.removefn;
expression alloc.mp, alloc.mp2;
@@
removefn(...) {
  <...
- kfree(\(mp\|mp2\));
  ...>
}

@kcalloc depends on probe@
identifier initfn, pdev;
expression mp;
expression list es;
position p;
@@
initfn@p(struct platform_device *pdev, ...) {
  <+...
- mp = kcalloc(es);
+ mp = devm_kcalloc(&pdev->dev, es);
  ...
?-kfree(mp);
  ...+>
}

@@
identifier remove.removefn;
expression kcalloc.mp;
@@
removefn(...) {
  <...
- kfree(mp);
  ...>
}

@akc@
expression kcalloc.mp, mp2;
@@
mp2 = mp;

@@
identifier remove.removefn;
expression akc.mp2;
@@
removefn(...) {
  <...
- kfree(mp2);
  ...>
}

@script:python@
p << alloc.p1;
@@

print >> f, "%s:kzalloc1:%s" % (p[0].file, p[0].line)
