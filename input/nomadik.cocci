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

// Rule to undo sparse_keymap_setup() with sparse_keymap_free()

@nomadik depends on probe@
identifier probe.probefn;
statement S;
position p;
identifier k; 
@@
probefn(...)
{
  ...
  struct ske_keypad *k;
<+...
  if (k@p->board->init) S
...+>
}

@nomadikd depends on nomadik@
identifier probe.probefn;
statement S1, S2;
identifier k;
@@
probefn(...)
{
  ...
  struct ske_keypad *k;
<+...
  if (k->board->init) S1
  if (k->board->exit) S2
...+>
}

@nomadik_probe depends on !nomadikd@
identifier probe.probefn;
fresh identifier cb = probefn ## "_exit_cb";
statement S;
identifier k;
type T;
identifier pdev;
@@

probefn(T *pdev)
{
  ...
  struct ske_keypad *k;
<+...
  if (k->board->init) S
+ if (k->board->exit) {
+   error = devm_add_action_or_reset(&pdev->dev, cb, k);
+   if (error) return error;
+ }
...+>
}

@depends on nomadik_probe@
identifier probe.probefn;
identifier nomadik_probe.cb;
@@
+ void cb(void *_k) { struct ske_keypad *k = _k; k->board->exit(); }
  probefn(...) { ... }

@depends on nomadik_probe@
identifier remove.removefn, probe.probefn;
statement S;
identifier k;
@@

removefn(...){
  ...
  struct ske_keypad *k;
  <...
- if (k->board->exit) S
  ...>
}

@script:python depends on nomadik_probe@
p << nomadik.p;
@@

print >> f, "%s:nomadik1:%s" % (p[0].file, p[0].line)
