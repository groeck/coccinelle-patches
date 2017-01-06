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
identifier probe.probefn;
expression data;
identifier lock;
position p;
@@
  probefn(...) {
  <+...
  data = \(devm_kzalloc\|kzalloc\)(...);
  ...
  mutex_init@p(&data->lock);
  ...+>
  }

@prb depends on probe@
identifier probe.probefn;
position r.p;
expression r.data;
identifier r.lock;
@@

  probefn(...) {
  <+...
  mutex_init@p(&data->lock);
  ...
  when any
?-mutex_destroy(&data->lock);
  ...+>
}

@rem depends on prb@
identifier remove.removefn;
expression r.data;
identifier r.lock;
@@

removefn(...)
{
  <+...
- mutex_destroy(&data->lock);
  ...+>
}

@script:python depends on rem && prb@
p << r.p;
@@

print >> f, "%s:m1:%s" % (p[0].file, p[0].line)
