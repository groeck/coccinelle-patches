virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@miscdev@
identifier m, fo;
position p;
@@
struct miscdevice m@p = {
  .minor = WATCHDOG_MINOR,
  .fops = &fo,
};

@omiscdev depends on miscdev@
identifier m != miscdev.m;
@@
struct miscdevice m = { ... };

@depends on miscdev && !omiscdev@
@@
- #include <linux/miscdevice.h>

@depends on miscdev && !omiscdev@
@@
- #include <linux/fs.h>

@depends on miscdev && !omiscdev@
@@
- #include <linux/uaccess.h>

@notifier depends on miscdev@
identifier nb, nf;
position p;
@@
struct notifier_block nb@p = {
  .notifier_call = nf,
};

@priority depends on notifier@
identifier notifier.nb;
constant prio;
@@
struct notifier_block nb = {
  .priority = prio,
};

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

@io_ping depends on miscdev@
identifier fops.ioctl;
identifier var;
identifier pingfunc != {spin_lock, spin_unlock, writel_relaxed, readl_relaxed, pr_info};
position p;
@@

ioctl(...) {
<+...
  switch (var) {
  case WDIOC_KEEPALIVE:
  <+...
    pingfunc@p(...)
  ...+>
  }
...+>
}

@fping depends on !io_ping && !fops@
identifier fopsw.fwrite;
identifier pingfunc != get_user;
position p;
@@
fwrite(...) {
<+...
  pingfunc@p(...)
...+>
}

@io_start@
identifier var, val, val2;
identifier startfunc != {io_ping.pingfunc, spin_lock, spin_unlock};
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
		startfunc@p(...)
		...+>
	}
	...+>
|
	switch (val2) {
	case WDIOS_ENABLECARD:
		<+...
		startfunc@p(...)
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

// If we did not find a start function in the ioctl,
// maybe there is a usable one in the open function.
// Look for it.
@io_start2 depends on !io_start@
identifier fopso.fopen;
identifier startfunc !=
	{io_ping.pingfunc, fping.pingfunc, test_and_set_bit, clear_bit, set_bit,
	stream_open, __module_get, __raw_writeb, writel_relaxed, readl_relaxed,
	request_irq, test_and_clear_bit, request_irq };
position p;
@@

fopen(...) {
<+...
  startfunc@p(...)
...+>
}

@io_stop@
identifier var, val;
identifier stopfunc != set_bit;
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
		stopfunc@p(...)
		...+>
	}
	...+>
|
	switch (val) {
	case WDIOS_DISABLECARD:
		<+...
		stopfunc@p(...)
		...+>
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

// if there is no stop function, maybe there is a local
// function called from the release function. Try it.
@io_stop2 depends on !io_stop@
identifier fopsc.fclose;
identifier stopfunc;
position p;
@@

fclose(...) {
<+...
  stopfunc@p(...)
...+>
}

@havestoplocal@
identifier io_stop2.stopfunc != io_ping.pingfunc;
@@
stopfunc(...) { ... }

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
identifier io_ping.pingfunc;
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
identifier settimeout != {io_ping.pingfunc,io_start.startfunc,io_stop.stopfunc,
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

@haveping@
identifier io_ping.pingfunc;
position p;
@@
pingfunc@p(...) { ... }

@checkping depends on haveping@
identifier fopsw.fwrite;
identifier io_ping.pingfunc;
position ppos;
@@
fwrite(...) {
<+...
  pingfunc@ppos(...)
...+>
}

@havestart2local@
identifier io_start2.startfunc;
@@
startfunc(...) { ... }

@checkstart@
identifier fopso.fopen;
identifier io_start.startfunc;
position pos;
@@
fopen(...) {
<+...
  startfunc@pos(...)
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
@depends on miscdev@
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
+ int wsettimeout(struct watchdog_device *wdd, unsigned int time)
  {
  ...
+ /* FIXME: set wdd->timeout to actually selected timeout */
+ wdd->timeout = time;
+ return 0;
  }

@sttr2 depends on !sttr1@
identifier io_settimeout.settimeout;
identifier f.wsettimeout;
type t1, t2;
identifier time;
@@
- t1 settimeout(t2 time)
+ /* FIXME: Check error returns; set wdd->timeout */
+ int wsettimeout(struct watchdog_device *wdd, unsigned int time)
  {
  ...
  }

// Everything else just convert

@sttr3 depends on !sttr1 && !sttr2@
identifier io_settimeout.settimeout;
identifier f.wsettimeout;
@@
- void settimeout(...)
+ /* FIXME: Check parameters and error returns */
+ int wsettimeout(struct watchdog_device *wdd, unsigned int timeout)
  {
  ...
+ /* FIXME: set wdd->timeout to actually selected timeout */
+ wdd->timeout = timeout;
+ return 0;
  }

@sttr4 depends on !sttr1 && !sttr2 && !sttr3@
identifier io_settimeout.settimeout;
identifier f.wsettimeout;
@@
- settimeout(...)
+ /* FIXME: Check parameters and error returns; set wdd->timeout */
+ wsettimeout(struct watchdog_device *wdd, unsigned int timeout)
  {
  ...
  }

@replace_fops@
identifier miscdev.fo;
identifier f.wops;
@@

- struct file_operations fo = { ... };
+ struct watchdog_ops wops = { };

@replace_add_settimeout depends on sttr1 || sttr2 || sttr3 || sttr4@
identifier f.wops;
identifier f.wsettimeout;
@@
  struct watchdog_ops wops = {
+	.set_timeout = wsettimeout,
  };

@replace_add_ping depends on haveping@
identifier io_ping.pingfunc;
identifier f.wops;
@@
  struct watchdog_ops wops = {
+	.ping = pingfunc,
  };

@replace_add_ping2 depends on !replace_add_ping@
identifier fping.pingfunc;
identifier f.wops;
@@
  struct watchdog_ops wops = {
+	.ping = pingfunc,
  };

@fops_add_stop depends on io_stop@
identifier io_stop.stopfunc;
identifier f.wops;
@@
  struct watchdog_ops wops = {
+	.stop = stopfunc,
  };

@fops_add_stop2 depends on !fops_add_stop && havestoplocal@
identifier io_stop2.stopfunc;
identifier f.wops;
@@
  struct watchdog_ops wops = {
+	.stop = stopfunc,
  };

@fops_add_start@
identifier io_start.startfunc;
identifier f.wops;
@@

  struct watchdog_ops wops = {
+	.start = startfunc,
  };

// first alternate start, identified from open function
@fops_add_start2 depends on havestart2local && !fops_add_start@
identifier io_start2.startfunc;
identifier f.wops;
@@

  struct watchdog_ops wops = {
+	.start = startfunc,
  };

// Second alternate start function: If we did not add a start function,
// but a ping function was found, use it as start function.
// The ping function will then be unnecessary and can be removed.
// This is currently unnecessary because all drivers meet above requirements,
// but keep it around just in case.
@fops_add_start3 depends on !fops_add_start && !io_start2 && !havestart2local && haveping@
identifier io_ping.pingfunc;
identifier f.wops;
@@

  struct watchdog_ops wops = {
+	.start = pingfunc,
  };

// Now remove ping function if it matches the start function
@@
identifier f.wops;
identifier pingfunc;
@@
  struct watchdog_ops wops = {
	.start = pingfunc,
-	.ping = pingfunc,
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

@depends on checkping@
identifier io_ping.pingfunc;
@@
- void pingfunc(...)
+ int pingfunc(struct watchdog_device *wdd)
  {
  ...
+ return 0;
  }

@s1 depends on io_start@
identifier io_start.startfunc;
@@
- void startfunc(...)
+ int startfunc(struct watchdog_device *wdd)
  {
  ...
+ return 0;
  }

// Maybe the start function type is already declared as int.
// If so, use it.
@s2 depends on !s1@
identifier io_start.startfunc;
@@
- int startfunc(...)
+ /* FIXME: Check parameters and error returns */
+ int startfunc(struct watchdog_device *wdd)
  { ... }

// or maybe we have an alternate start function.
@depends on !s1 && !s2@
identifier io_start2.startfunc;
@@
- void startfunc(...)
+ int startfunc(struct watchdog_device *wdd)
  {
  ...
+ return 0;
  }

@sr depends on io_stop@
identifier io_stop.stopfunc;
@@
- void stopfunc(...)
+ int stopfunc(struct watchdog_device *wdd)
  {
  ...
+ return 0;
  }

@sr2 depends on io_stop && !sr@
identifier io_stop.stopfunc;
type t;
@@
- t stopfunc(...)
+ int stopfunc(struct watchdog_device *wdd)
  { ... }

@sr2a depends on !sr && !sr2 && havestoplocal@
identifier io_stop2.stopfunc;
@@
- void stopfunc(...)
+ int stopfunc(struct watchdog_device *wdd)
  {
  ...
+ return 0;
  }

@depends on !sr && !sr2 && !sr2a && havestoplocal@
identifier io_stop2.stopfunc;
type t;
@@
- t stopfunc(...)
+ int stopfunc(struct watchdog_device *wdd)
  { ... }

// Replace reboot handler
@reboot@
identifier notifier.nb;
identifier ret;
expression E;
identifier f.wdev;
@@

- ret = register_reboot_notifier(&nb);
- if (E) { ... }
+ watchdog_stop_on_reboot(&wdev);

@depends on reboot@
identifier notifier.nb;
@@

- unregister_reboot_notifier(&nb);

@depends on reboot@
identifier notifier.nb;
@@

- struct notifier_block nb = { ... };

// Replace restart handler with callback
@restart@
identifier notifier.nb;
@@

<+...
  register_restart_handler(&nb)
...+>

@depends on restart@
identifier notifier.nb;
identifier ret;
@@

(
- unregister_restart_handler(&nb);
|
- ret = unregister_restart_handler(&nb);
- if (ret) { ... }
)

@depends on restart || reboot@
@@

- #include <linux/reboot.h>

@depends on restart || reboot@
@@

- #include <linux/notifier.h>

@depends on restart@
identifier notifier.nb;
@@

- struct notifier_block nb = { ... };

@depends on reboot && !restart@
identifier notifier.nf;
@@

- nf(...) { ... }

@rr depends on restart && !reboot@
identifier notifier.nf;
identifier v1, v2, v3;
type t1, t2, t3;
@@

- nf(t1 v1, t2 v2, t3 v3)
+ nf(struct watchdog_device *wdd, t2 v2, t3 v3)
  { ... }

@add_restart depends on rr@
identifier f.wops;
identifier notifier.nf;
@@
  struct watchdog_ops wops = {
+	.restart = nf,
  };

@depends on add_restart@
constant priority.prio;
identifier notifier.nb;
identifier f.wdev;
identifier ret;
@@

- ret = register_restart_handler(&nb);
- if (ret) { ... }
+ /* FIXME make sure this call is made ahead of watchdog registration */
+ watchdog_set_restart_priority(&wdev, prio);

// Registration
@wr@
identifier miscdev.m;
identifier ret;
identifier f.wdev;
@@

(
- misc_register(&m);
+ watchdog_register_device(&wdev);
|
- ret = misc_register(&m);
+ ret = watchdog_register_device(&wdev);
)

@depends on wr@
identifier f.wdev;
identifier wr.ret;
@@

  ret = watchdog_register_device(&wdev);
  if (\(ret\|ret < 0\|ret != 0\)) {
    <...
-   \(pr_err\|dev_err\)(...);
    ...>
  }

@@
identifier miscdev.m;
identifier f.wdev;
@@

- misc_deregister(&m);
+ watchdog_unregister_device(&wdev);

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


@script:python depends on io_ping@
pingfunc << io_ping.pingfunc;
pos << io_ping.p;
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
pingfunc << io_ping.pingfunc;
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

@script:python depends on notifier@
pos << notifier.p;
nb << notifier.nb;
nf << notifier.nf;
@@

print >> f, "notifier: '%s' @ %s:%s calling %s" % (nb, pos[0].file, pos[0].line, nf)

@script:python depends on havestoplocal@
func << io_stop2.stopfunc;
pos << io_stop2.p;
@@

print >> f, "iostop2 %s @ %s:%s" % (func, pos[0].file, pos[0].line)

@script:python@
func << io_start.startfunc;
pos << io_start.p;
@@

print >> f, "iostart %s @ %s:%s" % (func, pos[0].file, pos[0].line)

@script:python@
func << io_start2.startfunc;
pos << io_start2.p;
@@

print >> f, "iostart2 %s @ %s:%s" % (func, pos[0].file, pos[0].line)

@script:python depends on fops_add_start@
func << io_start.startfunc;
@@

print >> f, "add_start %s" % func

@script:python depends on fops_add_start2@
func << io_start2.startfunc;
@@

print >> f, "add_start2 %s" % func

@script:python depends on fops_add_start3@
func << io_ping.pingfunc;
@@

print >> f, "add_start3 %s" % func

@script:python depends on priority@
nb << notifier.nb;
prio << priority.prio;
@@

print >> f, "priority %s in %s" % (prio, nb)

@script:python depends on fping@
func << fping.pingfunc;
pos << fping.p;
@@

print >> f, "fping %s @ %s:%s" % (func, pos[0].file, pos[0].line)
