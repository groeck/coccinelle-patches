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

// Drop matrix_keypad_free_gpio()

@matrix depends on probe@
position p;
@@
- matrix_keypad_free_gpio@p(...) { ... }

@depends on matrix@
identifier remove.removefn, probe.probefn;
@@

(
  removefn
|
  probefn
)
  (...){
  <...
- matrix_keypad_free_gpio(...);
  ...>
}

@script:python depends on matrix@
p << matrix.p;
@@

print >> f, "%s:matrix1:%s" % (p[0].file, p[0].line)
