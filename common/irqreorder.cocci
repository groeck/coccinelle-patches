// input: Request interrupt after registering device

virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@r@
expression e1, e2, E;
statement S1, S2;
position p;
expression list EL;
@@
- e1 = devm_request_threaded_irq@p(EL);
- if (e1) S1
  ...
  e2 = input_register_device(E);
  if (e2) S2
+ e1 = devm_request_threaded_irq(EL);
+ if (e1) S1

@script:python depends on r@
p << r.p;
@@

print >> f, "%s:replace1:%s" % (p[0].file, p[0].line)
