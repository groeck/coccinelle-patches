virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@miscdev@
identifier m, fo;
@@
struct miscdevice m = {
  .fops = &fo,
};

@depends on miscdev@
@@
- #include <linux/miscdevice.h>

@depends on miscdev@
@@
- #include <linux/fs.h>

@depends on miscdev@
@@
- #include <linux/uaccess.h>

@fops@
identifier miscdev.fo;
identifier ioctl;
@@
struct file_operations fo = {
   .unlocked_ioctl = ioctl,
};

@fopso@
identifier miscdev.fo;
identifier fopen;
position pos;
@@
struct file_operations fo = {
   .open = fopen@pos,
};

@fopsc@
identifier miscdev.fo;
identifier fclose;
@@
struct file_operations fo = {
   .release = fclose,
};

@fopsw@
identifier miscdev.fo;
identifier fwrite;
@@
struct file_operations fo = {
   .write = fwrite,
};

@io@
identifier fops.ioctl;
identifier var;
identifier pingfunc;
statement S;
expression E;
position p;
@@

ioctl(...)
{
  <+...
  switch (var) {
  case WDIOC_KEEPALIVE:
(
  pingfunc@p(...);
  break;
|
  return pingfunc@p(...);
|
  pingfunc@p(...);
  return E;
|
  pingfunc@p(...);
  S
  return E;
|
  pingfunc@p(...);
  S
  break;
)
  }
  ...+>
}

@io_start@
identifier var, val, val2;
identifier startfunc;
statement S;
expression E;
position p;
@@

<+...
  switch (var) {
  case WDIOC_SETOPTIONS:
	...
(
	<+...
	if (val & WDIOS_ENABLECARD) {
		<+...
		startfunc@p(...);
		...+>
	}
	...+>
|
	switch (val2) {
	case WDIOS_ENABLECARD:
		startfunc@p(...);
		break;
	}
)
?	S
(
	break;
|
	return E;
)
  }
...+>

@io_stop@
identifier var, val, val2;
identifier stopfunc;
statement S;
expression E;
position p;
@@

<+...
  switch (var) {
  case WDIOC_SETOPTIONS:
	...
(
	<+...
	if (val & WDIOS_DISABLECARD) {
		<+...
		stopfunc@p(...);
		...+>
	}
	...+>
|
	switch (val2) {
	case WDIOS_DISABLECARD:
		stopfunc@p(...);
		break;
	}
)
?	S
(
	break;
|
	return E;
)
  }
...+>

@io_settimeout@
identifier var, res;
identifier settimeout != io.pingfunc;
statement S;
expression E;
position p;
@@

<+...
  switch (var) {
  case WDIOC_SETTIMEOUT:
	<+...
(
	settimeout@p(...);
|
	res = settimeout@p(...);
)
	...+>
?	S
(
	break;
|
	return E;
|
	/* nothing */
)
  }
...+>

@checkping@
identifier fopsw.fwrite;
identifier io.pingfunc;
position ppos;
expression E;
@@
fwrite(...) {
...
(
pingfunc@ppos(...);
|
  if (E) {
    ...
    pingfunc@ppos(...);
    ...
  }
|
  if (E) {
    ...
    pingfunc@ppos(...);
  }
)
...
}

@checkstart@
identifier fopso.fopen;
identifier io_start.startfunc;
position pos;
expression E;
@@
fopen(...) {
<+...
(
startfunc@pos(...);
|
  if (E) {
    <+...
    startfunc@pos(...);
    ...+>
  }
)
...+>
}

@info_opts@
identifier i;
expression o;
identifier fops.ioctl;
@@
ioctl(...)
{
  <...
  struct watchdog_info i = {
    .options = o,
  };
  ...>
}

@info_fw@
identifier i;
expression fw;
identifier fops.ioctl;
@@
ioctl(...)
{
  <...
  struct watchdog_info i = {
    .firmware_version = fw,
  };
  ...>
}

@info_id@
identifier i;
expression id;
identifier fops.ioctl;
@@
ioctl(...)
{
  <...
  struct watchdog_info i = {
    .identity = id,
  };
  ...>
}

@depends on io@
identifier fops.ioctl;
@@

- ioctl(...) { ... }

@@
identifier fopso.fopen;
@@

- fopen(...) { ... }

@@
identifier fopsw.fwrite;
@@

- fwrite(...) { ... }

@script:ocaml f@
fo << miscdev.fo;
wops;
wdev;
winfo;
@@

wops :=
   make_ident (List.hd(Str.split (Str.regexp "_") fo) ^ "_ops");
wdev :=
   make_ident (List.hd(Str.split (Str.regexp "_") fo) ^ "_dev");
winfo :=
   make_ident (List.hd(Str.split (Str.regexp "_") fo) ^ "_info")

@info@
identifier i;
identifier f.winfo;
@@

- struct watchdog_info i
+ struct watchdog_info winfo
  = {...};

@info_all depends on !info@
identifier f.winfo;
identifier miscdev.fo;
expression info_opts.o;
expression info_id.id;
expression info_fw.fw;
@@

  struct file_operations fo = { ... };
+
+ static struct watchdog_info winfo = {
+	/* FIXME may be incomplete; declared locally in ioctl */
+	.options = o,
+	.firmware_version = fw,
+	.identity = id,
+ };

@info_base depends on !info && !info_all@
identifier f.winfo;
identifier miscdev.fo;
expression info_opts.o;
expression info_id.id;
@@

  struct file_operations fo = { ... };
+
+ static struct watchdog_info winfo = {
+	/* FIXME may be incomplete; declared locally in ioctl */
+	.options = o,
+	.identity = id,
+ };

@depends on !info && !info_all && !info_base@
identifier f.winfo;
identifier miscdev.fo;
@@

  struct file_operations fo = { ... };
+
+ static struct watchdog_info winfo = {
+	/* FIXME probably declared locally in ioctl */
+ };

@replace_fops_all@
identifier miscdev.fo;
identifier io_start.startfunc;
identifier io_stop.stopfunc;
identifier io.pingfunc;
identifier f.wops;
@@

- struct file_operations fo = { ... };
+ struct watchdog_ops wops = {
+	.start = startfunc,
+	.stop = stopfunc,
+	.ping = pingfunc,
+ };

@replace_fops_nostop depends on !replace_fops_all@
identifier miscdev.fo;
identifier io_start.startfunc;
identifier io.pingfunc;
identifier f.wops;
@@

- struct file_operations fo = { ... };
+ struct watchdog_ops wops = {
+	.start = startfunc,
	/* FIXME check for stop function */
+	.ping = pingfunc,
+ };

@replace_fops_start depends on !replace_fops_nostop@
identifier miscdev.fo;
identifier io_start.startfunc;
identifier f.wops;
@@
- struct file_operations fo = { ... };
+ struct watchdog_ops wops = {
+	.start = startfunc,
+	/* FIXME check for ping function */
+ };

@replace_fops_ping depends on !replace_fops_start@
identifier miscdev.fo;
identifier io.pingfunc;
identifier f.wops;
@@
- struct file_operations fo = { ... };
+ struct watchdog_ops wops = {
+	/* FIXME start function missing */
+	.ping = pingfunc,
+ };

@depends on !replace_fops_start@
identifier miscdev.fo;
identifier f.wops;
@@
- struct file_operations fo = { ... };
+ struct watchdog_ops wops = {
+	/* FIXME */
+ };

@@
identifier miscdev.m;
identifier f.wops;
identifier f.wdev;
identifier f.winfo;
@@
- struct miscdevice m = { ... };
+ struct watchdog_device wdev = {
+	.info = &winfo,
+	.min_timeout = 1,		/* FIXME */
+	.max_timeout = MAX_TIMEOUT,	/* FIXME */
+	.timeout = DEFAULT_TIMEOUT,	/* FIXME */
+	.ops = &wops,
+ };

@@
identifier fopsc.fclose;
@@

- fclose(...) { ... }

@depends on io && checkping@
identifier io.pingfunc;
@@
- void pingfunc(...)
+ int pingfunc(struct watchdog_device *wdd)
  {
  ...
+ return 0;
  }

@depends on io_start@
identifier io_start.startfunc;
@@
- void startfunc(...)
+ int startfunc(struct watchdog_device *wdd)
  {
  ...
+ return 0;
  }

@depends on io_stop@
identifier io_stop.stopfunc;
@@
- void stopfunc(...)
+ int stopfunc(struct watchdog_device *wdd)
  {
  ...
+ return 0;
  }

@settimeout_replace depends on io_settimeout@
identifier io_settimeout.settimeout;
@@
- void settimeout(
+ int settimeout(struct watchdog_device *wdd,
  ...)
  {
  ...
+ return 0;
  }

@settimeout_replace2 depends on !settimeout_replace@
identifier io_settimeout.settimeout;
@@
- settimeout(
+ settimeout(struct watchdog_device *wdd,
  ...)
  { ... }

@@
identifier miscdev.m;
identifier ret;
identifier f.wdev;
@@

(
- misc_register(&m);
+ watchdog_device_register(&wdd);
|
- ret = misc_register(&m);
+ ret = watchdog_device_register(&wdev);
)

@script:python depends on miscdev@
m << miscdev.m;
@@

print >> f, "miscdev: %s" % m

@script:python depends on fops@
ioctl << fops.ioctl;
@@

print >> f, "ioctl: %s" % ioctl


@script:python depends on io@
pingfunc << io.pingfunc;
pos << io.p;
@@

print >> f, "pingfunc: %s @ %s:%s" % (pingfunc, pos[0].file, pos[0].line)

@script:python depends on io_start@
startfunc << io_start.startfunc;
pos << io_start.p;
@@

print >> f, "startfunc: %s @ %s:%s" % (startfunc, pos[0].file, pos[0].line)

@script:python depends on io_stop@
stopfunc << io_stop.stopfunc;
pos << io_stop.p;
@@

print >> f, "stopfunc: %s @ %s:%s" % (stopfunc, pos[0].file, pos[0].line)

@script:python depends on io_settimeout@
settimeout << io_settimeout.settimeout;
pos << io_settimeout.p;
@@

print >> f, "settimeout: %s @ %s:%s" % (settimeout, pos[0].file, pos[0].line)

@script:python depends on checkping@
pos << checkping.ppos;
pingfunc << io.pingfunc;
@@

print >> f, "checkping: pingfunc: %s @ %s:%s" % (pingfunc, pos[0].file, pos[0].line)

@script:python depends on checkstart@
pos << checkstart.pos;
startfunc << io_start.startfunc;
@@

print >> f, "checkstart: startfunc: %s @ %s:%s" % (startfunc, pos[0].file, pos[0].line)

@script:python depends on fopso@
pos << fopso.pos;
fopen << fopso.fopen;
@@

print >> f, "fopso: openfunc: %s @ %s:%s" % (fopen, pos[0].file, pos[0].line)
