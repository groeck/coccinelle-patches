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

@keymap depends on probe@
identifier initfn;
expression status;
expression input;
position p;
@@
initfn(...)
{
<+...
status = sparse_keymap_setup@p(input, ...);
...+>
}

@keymapd depends on keymap@
identifier keymap.initfn;
expression s1, s2;
expression list es;
position keymap.p;
statement S;
expression input;
@@
initfn(...)
{
<+...
s1 = sparse_keymap_setup@p(input, es);
S
s2 = devm_add_action_or_reset(..., input);
...+>
}

@keymap_probe depends on !keymapd@
identifier keymap.initfn;
expression input;
local idexpression v;
expression list es;
position keymap.p;
statement S;
identifier pdev; 
@@

initfn(struct platform_device *pdev)
{
  <+...
  v = sparse_keymap_setup@p(input, es);
  if (
(
v
|
v < 0
)
  ) S
+ v = devm_add_action_or_reset(&pdev->dev, (void (*)(void *))sparse_keymap_free, input, es);
+ if (v)
+        S
  ... when any
?-sparse_keymap_free(input);
...+>
}

@depends on keymap_probe@
identifier remove.removefn, probe.probefn;
expression keymap_probe.input;
@@

(
removefn
|
probefn
)
  (...){
  <...
- sparse_keymap_free(input);
  ...>
}

@keymap_assign depends on keymap_probe@
expression keymap_probe.input, i2;
@@
i2 = input;

@keymap_rem2 depends on keymap_assign@
identifier remove.removefn;
expression keymap_assign.i2;
@@

removefn(...)
{
  <...
- sparse_keymap_free(i2);
  ...>
}

@script:python depends on keymap_probe@
p << keymap.p;
@@

print >> f, "%s:other1:%s" % (p[0].file, p[0].line)
