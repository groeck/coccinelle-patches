virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@probe@
identifier p, probefn;
declarer name module_platform_driver_probe;
position pos;
@@
(
  module_platform_driver_probe(p, probefn@pos);
|
  struct platform_driver p = {
    .probe = probefn@pos,
  };
|
  struct i2c_driver p = {
    .probe = probefn@pos,
  };
|
  struct spi_driver p = {
    .probe = probefn@pos,
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

// Get type of device.
// Using it ensures that we don't touch any other data structure
// which might have a '->dev' object.

@ptype depends on probe@
type T;
identifier probe.probefn;
identifier pdev;
@@
probefn(T *pdev, ...) { ... }

@have_action depends on probe@
identifier initfn;
position p;
type ptype.T;
identifier pdev;
identifier func;
expression err;
expression data;
@@
initfn(T *pdev, ...)
{
<+...
  err = devm_add_action@p(..., func, data);
  if (err) {
    func(data);
    ...
  }
...+>
}

@action depends on have_action@
position have_action.p;
expression have_action.err;
identifier have_action.func;
expression list es;
@@

- err = devm_add_action@p(es);
+ err = devm_add_action_or_reset(es);
  if (err) {
- func(...);
  ...
  }

@script:python depends on have_action@
p << have_action.p;
@@

print >> f, "%s:action1:%s" % (p[0].file, p[0].line)

@ha2 depends on probe@
identifier initfn;
position p, p1;
type ptype.T;
identifier pdev;
identifier f1, f2;
expression err;
expression d1, d2;
@@
initfn@p1(T *pdev, ...)
{
<+...
  err = devm_add_action@p(..., f1, d1);
  if (err) {
    ...
    f2(d2);
    ...
  }
...+>
}

@ha3 depends on ha2@
identifier ha2.f1, ha2.f2;
position p;
@@

  f1@p(...)
  {
  <+...
  f2(...);
  ...+>
  }

@ha4 depends on ha2 && ha3@
expression ha2.err;
identifier ha2.f2;
expression ha2.d2;
position ha2.p;
expression list es;
@@

- err = devm_add_action@p(es);
+ err = devm_add_action_or_reset(es);
  if (err) {
  ...
- f2(d2);
  ...
  }

@script:python depends on ha4@
p << probe.pos;
@@

print >> f, "%s:action1:%s" % (p[0].file, p[0].line)
