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

@mcs depends on probe@
identifier probe.probefn;
statement S;
position p;
identifier m;
@@
probefn(...)
{
  ...
  struct mcs_platform_data *m;
<+...
  if (m@p->poweron) S
...+>
}

@mcsd depends on mcs@
identifier probe.probefn;
statement S;
identifier m;
@@
probefn(...)
{
  ...
  struct mcs_platform_data *m;
<+...
  if (m->poweron) {
    if (devm_add_action_or_reset(...)) S
    ...
  }
...+>
}

@mcs_probe depends on !mcsd@
identifier probe.probefn;
fresh identifier cb = probefn ## "_poweroff_cb";
identifier d, m;
type T;
identifier client;
@@

probefn(T *client, ...)
{
  ...
  struct mcs_platform_data *m;
  struct mcs_touchkey_data *d;
<+...
  if (m->poweron) {
    d->poweron = m->poweron;
    d->poweron(...);
+   error = devm_add_action_or_reset(&client->dev, cb, d);
+   if (error) return error;
  }
...+>
}

@depends on mcs_probe@
identifier probe.probefn;
identifier mcs_probe.cb;
@@
+ static void cb(void *_d) { struct mcs_touchkey_data *d = _d; d->poweron(false); }
  probefn(...) { ... }

@depends on mcs_probe@
identifier remove.removefn;
statement S;
identifier d;
expression E;
@@

  removefn(...){
  struct mcs_touchkey_data *d = E;
  <...
- if (d->poweron) S
  ...>
}

@script:python depends on mcs_probe@
p << mcs.p;
@@

print >> f, "%s:mcs1:%s" % (p[0].file, p[0].line)
