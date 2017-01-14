virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@probe@
identifier p, probefn;
@@
(
  struct i2c_driver p = {
    .probe = probefn,
  };
)

@remove@
identifier probe.p, removefn;
@@

  struct i2c_driver p = {
    .remove = \(__exit_p(removefn)\|removefn\),
  };

@gp2a depends on probe@
identifier probe.probefn;
statement S;
position p;
identifier g;
@@
probefn(...)
{
  ...
  struct gp2a_platform_data *g;
<+...
  if (g@p->hw_setup) S
...+>
}

@gp2ad depends on gp2a@
identifier probe.probefn;
statement S1, S2;
identifier g;
@@
probefn(...)
{
  ...
  struct gp2a_platform_data *g;
<+...
  if (g->hw_setup) S1
  if (g->hw_shutdown) S2
...+>
}

@gp2a_probe depends on !gp2ad@
identifier probe.probefn;
fresh identifier cb = probefn ## "_shutdown_cb";
statement S;
identifier g;
type T;
identifier client;
@@

probefn(T *client, ...)
{
  ...
  struct gp2a_platform_data *g;
<+...
  if (g->hw_setup) S
+ if (g->hw_shutdown) {
+   error = devm_add_action_or_reset(&client->dev, cb, g);
+   if (error) return error;
+ }
...+>
}

@depends on gp2a_probe@
identifier probe.probefn;
identifier gp2a_probe.cb;
identifier gp2a_probe.client;
@@
+ void cb(void *_g) { struct gp2a_platform_data *g = _g; g->hw_shutdown(client); }
  probefn(...) { ... }

@depends on gp2a_probe@
identifier remove.removefn, probe.probefn;
statement S;
identifier g;
@@

(
  removefn
|
  probefn
)
  (...){
  ...
  struct gp2a_platform_data *g;;
  <...
- if (g->hw_shutdown) S
  ...>
}

@script:python depends on gp2a_probe@
p << gp2a.p;
@@

print >> f, "%s:gp2a1:%s" % (p[0].file, p[0].line)
