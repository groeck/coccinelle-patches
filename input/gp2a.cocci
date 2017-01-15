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
position gp2a.p;
@@
probefn(...)
{
  ...
  struct gp2a_platform_data *g;
<+...
  if (g@p->hw_setup) S1
  if (g->hw_shutdown) S2
...+>
}

@gp2a_probe depends on gp2a && !gp2ad@
identifier probe.probefn;
fresh identifier cb = probefn ## "_shutdown_cb";
identifier pdata;
identifier client;
position gp2a.p;
statement S1, S2;
@@

probefn(struct i2c_client *client, ...)
{
  ...
  struct gp2a_platform_data *pdata;
<+...
  if (pdata@p->hw_setup) S1
+ if (pdata->hw_shutdown) {
+   error = devm_add_action_or_reset(&client->dev, cb, client);
+   if (error) return error;
+ }
  ... when any
?-if (pdata->hw_shutdown) S2
  ...+>
}

@depends on gp2a_probe@
identifier probe.probefn;
identifier gp2a_probe.cb;
@@
+ static void cb(void *_c)
+ { struct i2c_client *c = _c;
+   const struct gp2a_platform_data *pdata = dev_get_platdata(&c->dev);
+   pdata->hw_shutdown(c); }
  probefn(...) { ... }

@depends on gp2a_probe@
identifier remove.removefn;
statement S;
identifier g;
@@

  removefn(...){
  ...
  struct gp2a_platform_data *g;
  <...
- if (g->hw_shutdown) S
  ...>
}

@script:python depends on gp2a_probe@
p << gp2a.p;
@@

print >> f, "%s:gp2a1:%s" % (p[0].file, p[0].line)
