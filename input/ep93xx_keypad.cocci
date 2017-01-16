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

// Rule to undo sparse_keypad_setup() with sparse_keypad_free()

@keypad depends on probe@
identifier initfn;
identifier pdev;
identifier err;
position p;
@@
initfn(struct platform_device *pdev)
{
<+...
err = ep93xx_keypad_acquire_gpio@p(pdev);
...+>
}

@keypadd depends on keypad@
identifier keypad.initfn;
identifier err;
position keypad.p;
statement S;
identifier pdev;
@@
initfn(struct platform_device *pdev)
{
<+...
err = ep93xx_keypad_acquire_gpio@p(pdev);
if (err) S
err = devm_add_action_or_reset(..., pdev);
...+>
}

@keypad_probe depends on !keypadd@
identifier keypad.initfn;
identifier err;
position keypad.p;
statement S;
identifier pdev; 
fresh identifier cb = initfn ## "_keypad_cb";
@@

initfn(struct platform_device *pdev)
{
  <+...
  err = ep93xx_keypad_acquire_gpio@p(pdev);
  if (err) S
+ err = devm_add_action_or_reset(&pdev->dev, cb, pdev);
+ if (err) S
  ... when any
?-ep93xx_keypad_release_gpio(pdev);
...+>
}

@depends on keypad_probe@
identifier keypad.initfn;
identifier keypad_probe.cb;
@@
+ static void cb(void *pdev) { ep93xx_keypad_release_gpio(pdev); }
  initfn(...) { ... }

@depends on keypad_probe@
identifier remove.removefn;
identifier pdev;
@@

removefn(struct platform_device *pdev){
  <...
- ep93xx_keypad_release_gpio(pdev);
  ...>
}

@script:python depends on keypad_probe@
p << keypad.p;
@@

print >> f, "%s:ep_keypad:%s" % (p[0].file, p[0].line)
