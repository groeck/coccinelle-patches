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
)

@remove@
identifier probe.p, removefn;
@@

(
  struct platform_driver p = {
    .remove = \(__exit_p(removefn)\|removefn\),
  };
|
  struct i2c_driver p = {
    .remove = \(__exit_p(removefn)\|removefn\),
  };
)

@e depends on probe@
identifier initfn;
identifier d;
identifier pdev;
type T;
@@

initfn(T *pdev, ...) {
  ...
  struct device *d = &pdev->dev;
  ...
}

@prb@
identifier e.d;
identifier initfn;
identifier e.pdev;
position p;
type e.T;
@@

initfn@p(T *pdev, ...) {
  ...
  struct device *d = &pdev->dev;
<+...
- &pdev->dev
+ d
...+> }

@have_dev depends on !prb@
identifier probe.probefn;
type T;
@@
  probefn(...) {
  <+...
  T dev;
  ...+>
  }

@count depends on !prb@
identifier probe.probefn;
identifier pdev;
type T;
@@

  probefn(T *pdev, ...) {
  ...
  &pdev->dev
  <+...
  &pdev->dev
  ...+>
  }

@new depends on !have_dev@
identifier probe.probefn;
identifier count.pdev;
type T;
position p;
@@

  probefn@p(T *pdev, ...) {
+ struct device *dev = &pdev->dev;
<+...
- &pdev->dev
+ dev
...+> }

@script:python@
p << prb.p;
@@

print >> f, "%s:pdev1:%s" % (p[0].file, p[0].line)

@script:python@
p << new.p;
@@

print >> f, "%s:pdev2:%s" % (p[0].file, p[0].line)
