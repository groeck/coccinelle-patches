// Convert driver to platform device

virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@platform@
identifier pd;
position p;
@@

struct platform_driver pd@p = { ... };

@i depends on !platform@
declarer name module_init;
identifier initfn;
position p;
@@
module_init@p(initfn);

@e depends on !platform@
declarer name module_exit;
identifier exitfn;
position p;
@@

module_exit@p(exitfn);

@script:ocaml f@
fn << i.initfn;
pdriver;
pprobe;
premove;
pdevname;
@@

pdriver :=
   make_ident (List.hd(Str.split (Str.regexp "_") fn) ^ "_platform_driver");
pprobe :=
   make_ident (List.hd(Str.split (Str.regexp "_") fn) ^ "_probe");
premove :=
   make_ident (List.hd(Str.split (Str.regexp "_") fn) ^ "_remove");
pdevname :=
   make_ident (List.hd(Str.split (Str.regexp "_") fn) ^ "_platform_device")

// Replace init function with probe function
@probe depends on i@
identifier i.initfn;
identifier f.pprobe;
@@

- initfn(void)
+ pprobe(struct platform_device *pdev)
  { ... }

@have_msg depends on probe@
identifier f.pprobe;
@@

  pprobe(...)
  {
  <+...
(
  pr_err(...)
|
  pr_info(...)
|
  pr_debug(...)
|
  pr_crit(...)
|
  pr_warn(...)
)
  ...+>
  }

@depends on probe&& have_msg@
identifier f.pprobe;
@@

  pprobe(...)
  {
+ struct device *dev = &pdev->dev;
  <+...
(
- pr_info(
+ dev_info(dev,
  ...);
|
- pr_err(
+ dev_err(dev,
  ...);
|
- pr_err(
+ dev_err(dev,
  ...);
|
- pr_crit(
+ dev_crit(dev,
  ...);
|
- pr_warn(
+ dev_warn(dev,
  ...);
)
  ...+>
  }

// Replace exit function with remove function
@depends on e@
identifier e.exitfn;
identifier f.premove;
type T;
@@

- void __exit exitfn(void)
+ int __exit premove(struct platform_device *pdev)
  { ...
+ return 0;
  }

@depends on i@
identifier i.initfn;
identifier f.pdriver;
identifier f.pprobe;
identifier f.premove;
identifier f.pdevname;
@@
- module_init(initfn);
+ static struct platform_driver pdriver = {
+	.remove = premove,
+	.driver = {
+		.name = KBUILD_MODNAME,
+	},
+ };
+
+ static struct platform_device *pdevname;
+
+ static int __init initfn(void)
+ {
+ int err;
+
+ pdevname = platform_device_register_simple(KBUILD_MODNAME, -1, NULL, 0);
+ if (IS_ERR(pdevname))
+	return PTR_ERR(pdevname);
+ err = platform_driver_probe(&pdriver, pprobe);
+ if (err)
+	goto unreg;
+ return 0;
+ unreg:
+ platform_device_unregister(pdevname);
+ return err;
+ }
+ module_init(initfn);
+

@depends on e@
identifier e.exitfn;
identifier f.pdevname;
identifier f.pdriver;
@@

- module_exit(exitfn);
+ static void __exit exitfn(void)
+ {
+ platform_device_unregister(pdevname);
+ platform_driver_unregister(&pdriver);
+ }
+ module_exit(exitfn);

// This also removes any comments in the header. Drop for now.
// @have_prfunc depends on i || e@
// @@
// 
// (
  // pr_info
// |
  // pr_debug
// |
  // pr_err
// )
  // (...);
//
// @depends on !have_prfunc@
// @@
// 
// - #define pr_fmt(...) ...

@depends on i || e@
@@
- #include <linux/watchdog.h>
+ #include <linux/platform_device.h>
+ #include <linux/watchdog.h>

@script:python depends on platform@
pd << platform.pd;
p << platform.p;
@@

print >> f, "platform: %s @ %s:%s" % (pd, p[0].file, p[0].line)

@script:python depends on i@
fn << i.initfn;
p << i.p;
@@

print >> f, "init: %s @ %s:%s" % (fn, p[0].file, p[0].line)

@script:python depends on e@
fn << e.exitfn;
p << e.p;
@@

print >> f, "exit: %s @ %s:%s" % (fn, p[0].file, p[0].line)
