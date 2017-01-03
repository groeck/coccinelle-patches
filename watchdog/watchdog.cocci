virtual patch

@r1 disable optional_qualifier@
identifier i;
position p;
@@
static struct watchdog_info i@p={...};

@ok@
identifier r1.i;
position p;
struct watchdog_device obj;
@@
obj.info=&i@p;

@bad@
position p!={r1.p,ok.p};
identifier r1.i;
@@
i@p

@depends on !bad disable optional_qualifier@
identifier r1.i;
@@
+const
struct watchdog_info i;
