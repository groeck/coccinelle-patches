virtual patch

@r@
identifier res, pdev;
expression a;
expression index;
expression e, e2;
@@

<+...
- res = platform_get_resource(pdev, IORESOURCE_MEM, index);
?-if (!res) return e2;
- a = devm_ioremap_resource(e, res);
+ a = devm_platform_ioremap_resource(pdev, index);
...+>

@depends on r@
identifier res;
@@
- struct resource *res;
  ... when != res

@@
identifier res, pdev;
expression index;
expression a, e;
@@
- struct resource *res = platform_get_resource(pdev, IORESOURCE_MEM, index);
?-if (!res) return e;
- a = devm_ioremap_resource(&pdev->dev, res);
+ a = devm_platform_ioremap_resource(pdev, index);
