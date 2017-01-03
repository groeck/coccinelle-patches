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
expression irq;
position p;
@@
probefn(...)
{
<+...
request_irq@p(irq, ...)
...+>
}

@prb@
identifier probe.probefn, pdev;
expression list es;
position r.p;
expression irq;
@@

probefn(struct platform_device *pdev)
{
  <+...
- request_irq@p(irq, es)
+ devm_request_irq(&pdev->dev, irq, es)
  ...
  when any
?-free_irq(irq, ...);
...+>
}

@rem depends on prb@
identifier remove.removefn;
expression prb.irq;
@@

removefn(...)
{
  <...
- free_irq(irq, ...);
  ...>
}

@a depends on prb@
expression prb.irq, irq2;
@@
irq2 = irq;

@rem2 depends on a@
identifier remove.removefn;
expression a.irq2;
@@
removefn(...)
{
  <+...
- free_irq(irq2, ...);
  ...+>
}

@script:python depends on prb@
p << r.p;
@@

print >> f, "%s:i1:%s" % (p[0].file, p[0].line)
