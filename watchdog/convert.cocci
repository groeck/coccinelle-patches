virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@miscdev@
identifier m, fo;
position p;
@@
struct miscdevice m@p = {
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
position p;
@@
struct file_operations fo@p = {
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
  ...
  break;
|
  return pingfunc@p(...);
|
  pingfunc@p(...);
  ...
  return E;
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
		<+...
		startfunc@p(...);
		...+>
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

@have_stt@
identifier var;
position p;
statement S;
@@

<+...
  switch (var) {
  case WDIOC_SETTIMEOUT@p:
  	S
  }
...+>

@have_stt_ping@
identifier var;
identifier io.pingfunc;
position p;
expression E;
@@

<+...
  switch (var) {
  case WDIOC_SETTIMEOUT:
? {
	<+...
	pingfunc@p(E, ...)
	...+>
? }
  }
...+>

@io_settimeout@
identifier var;
identifier settimeout != {io.pingfunc,io_start.startfunc,io_stop.stopfunc,
	 get_user,put_user,copy_from_user,copy_to_user,
	 spin_lock,spin_unlock,
	 superio_enter,superio_select,superio_exit};
position p;
expression E;
@@

<+...
  switch (var) {
  case WDIOC_SETTIMEOUT:
? {
	<+...
	settimeout@p(E, ...)
	...+>
? }
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
position p;
@@
ioctl(...)
{
  <...
  struct watchdog_info i = {
    .options@p = o,
  };
  ...>
}

@info_fw@
identifier i;
expression fw;
identifier fops.ioctl;
position p;
@@
ioctl(...)
{
  <...
  struct watchdog_info i = {
    .firmware_version@p = fw,
  };
  ...>
}

@info_id@
identifier i;
expression id;
identifier fops.ioctl;
position p;
@@
ioctl(...)
{
  <...
  struct watchdog_info i = {
    .identity@p = id,
  };
  ...>
}

// We have everything we need from ioctl, let's remove it
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
wsettimeout;
@@

wops :=
   make_ident (Str.replace_first (Str.regexp "wdt_wdt") "wdt"
   		(List.hd(Str.split (Str.regexp "_") fo) ^ "_wdt_ops"));
wdev :=
   make_ident (Str.replace_first (Str.regexp "wdt_wdt") "wdt"
   		(List.hd(Str.split (Str.regexp "_") fo) ^ "_wdt_dev"));
winfo :=
   make_ident (Str.replace_first (Str.regexp "wdt_wdt") "wdt"
   		(List.hd(Str.split (Str.regexp "_") fo) ^ "_wdt_info"));
wsettimeout :=
   make_ident (Str.replace_first (Str.regexp "wdt_wdt") "wdt"
   		(List.hd(Str.split (Str.regexp "_") fo) ^ "_wdt_set_timeout"))

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
+
+ };

// simple cases first: One parameter, presumably the timeout
// Convert it to integer, just in case.

@sttr1@
identifier io_settimeout.settimeout;
identifier f.wsettimeout;
identifier time;
type t;
@@
- void settimeout(t time)
+ int wsettimeout(struct watchdog_device *wdd, int time)
  {
  ...
+ wdd->timeout = time;
+ return 0;
  }

@sttr2 depends on !sttr1@
identifier io_settimeout.settimeout;
identifier f.wsettimeout;
type t1, t2;
identifier time;
expression E;
@@
- t1 settimeout(t2 time)
+ int wsettimeout(struct watchdog_device *wdd, int time)
  {
  ...
  }

// Everything else just convert

@sttr3 depends on !sttr1 && !sttr2@
identifier io_settimeout.settimeout;
identifier f.wsettimeout;
@@
- void settimeout(...)
+ int wsettimeout(struct watchdog_device *wdd, int timeout)
  {
  ...
+ wdd->timeout = timeout;
+ return 0;
  }

@sttr4 depends on !sttr1 && !sttr2 && !sttr3@
identifier io_settimeout.settimeout;
identifier f.wsettimeout;
@@
- settimeout(...)
+ wsettimeout(struct watchdog_device *wdd, int timeout)
  {
  ...
  }

@replace_fops@
identifier miscdev.fo;
identifier f.wops;
@@

- struct file_operations fo = { ... };
+ struct watchdog_ops wops = {
+
+ };

@replace_add_settimeout depends on sttr1 || sttr2 || sttr3 || sttr4@
identifier f.wops;
identifier f.wsettimeout;
@@
  struct watchdog_ops wops = {
+	.settimeout = wsettimeout,
  };

@replace_add_ping@
identifier io.pingfunc;
identifier f.wops;
@@
  struct watchdog_ops wops = {
+	.ping = pingfunc,
  };

@fops_add_stop@
identifier io_stop.stopfunc;
identifier f.wops;
@@
  struct watchdog_ops wops = {
+	.stop = stopfunc,
  };

@fops_add_start depends on replace_fops@
identifier io_start.startfunc;
identifier f.wops;
@@

  struct watchdog_ops wops = {
+	.start = startfunc,
  };

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

@@
identifier miscdev.m;
identifier ret;
identifier f.wdev;
@@

(
- misc_register(&m);
+ watchdog_register_device(&wdd);
|
- ret = misc_register(&m);
+ ret = watchdog_device_register(&wdev);
)

@@
identifier miscdev.m;
identifier f.wdev;
@@

- misc_deregister(&m);
+ watchdog_unregister_device(&wdd);

@script:python depends on miscdev@
m << miscdev.m;
p << miscdev.p;
@@

print >> f, "miscdev: %s @ %s:%s" % (m, p[0].file, p[0].line)

@script:python depends on fops@
ioctl << fops.ioctl;
p << fops.p;
@@

print >> f, "ioctl: %s @ %s:%s" % (ioctl, p[0].file, p[0].line)


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

@script:python depends on have_stt@
pos << have_stt.p;
@@

print >> f, "have_settimeout: case @ %s:%s" % (pos[0].file, pos[0].line)

@script:python depends on have_stt_ping@
pos << have_stt_ping.p;
@@

print >> f, "have_settimeout_ping: case @ %s:%s" % (pos[0].file, pos[0].line)

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

@script:python depends on info_opts@
pos << info_opts.p;
o << info_opts.o;
@@

print >> f, "info_opts: opts='%s' @ %s:%s" % (o, pos[0].file, pos[0].line)

@script:python depends on info_fw@
pos << info_fw.p;
fw << info_fw.fw;
@@

print >> f, "info_fw: fw='%s' @ %s:%s" % (fw, pos[0].file, pos[0].line)

@script:python depends on info_id@
pos << info_id.p;
id << info_id.id;
@@

print >> f, "info_id: id='%s' @ %s:%s" % (id, pos[0].file, pos[0].line)
