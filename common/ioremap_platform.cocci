virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@r1@
identifier res, pdev;
expression a;
expression index;
expression e, e2;
position p;
@@

<+...
- res = platform_get_resource@p(pdev, IORESOURCE_MEM, index);
?-if (!res) return e2;
- a = devm_ioremap_resource(e, res);
+ a = devm_platform_ioremap_resource(pdev, index);
...+>

@depends on r1@
identifier res;
@@
- struct resource *res;
  ... when != res

@r2@
identifier res, pdev;
expression index;
expression a, e;
position p;
@@
- struct resource *res = platform_get_resource@p(pdev, IORESOURCE_MEM, index);
?-if (!res) return e;
- a = devm_ioremap_resource(&pdev->dev, res);
+ a = devm_platform_ioremap_resource(pdev, index);

@script:python depends on r1@
p << r1.p;
@@

print >> f, "%s:resource1:%s" % (p[0].file, p[0].line)

@script:python depends on r2@
p << r2.p;
@@

print >> f, "%s:ioremap4:%s" % (p[0].file, p[0].line)
