virtual patch

@initialize:python@
@@

f = open('coccinelle.log', 'a')

@probe@
identifier p, probefn;
declarer name module_platform_driver_probe;
position pos;
@@
(
  module_platform_driver_probe(p, probefn@pos);
|
  struct platform_driver p = {
    .probe = probefn@pos,
  };
)

@remove@
identifier probe.p, removefn;
position pos;
@@

  struct platform_driver p@pos = {
    .remove = \(__exit_p(removefn)\|removefn\),
  };

@unneeded_label depends on probe@
identifier fn;
position p1;
identifier l1,l2;
@@

fn(...) {
<+...
l1:@p1
l2:
...+> }

@fold_label depends on probe@
identifier unneeded_label.fn;
identifier l,l1,l2;
position p != unneeded_label.p1;
position any p1;
statement S;
@@

fn(...) {
<+...
- goto l1;
+ goto l2;
  ...
-l1:
 <... when != S
 l:@p1
 ...>
 l2:@p
...+> }

@needed_return exists@
identifier initfn;
identifier l;
position p;
expression e;
@@

initfn(...) {
... when != goto l;
    when any
l: return@p e;
}

@direct_return depends on probe@
identifier initfn;
identifier l1;
expression e;
position p != needed_return.p;
@@

initfn(...) {
<+...
- goto l1;
+ return e;
  ...
- l1: return@p e;
...+> }

@direct_return2 depends on probe@
identifier initfn;
identifier l1;
expression e;
@@

initfn(...) {
<+...
- goto l1;
+ return e;
   ...
- l1:
  return e;
...+> }

@merge_return depends on probe@
identifier initfn;
expression ret, e;
@@

initfn(...) {
<+...
- ret = e;
- return ret;
+ return e;
...+> }

@empty_if depends on probe@
identifier initfn;
expression e;
@@

initfn(...) {
<+...
- if (e)
-  {}
...+> }

@extra_return depends on probe@
identifier initfn;
expression e;
@@

initfn(...) {
<+...
- if (e)
-     return e;
- return 0;
+ return e;
...+> }

@extra_return2 depends on probe@
identifier initfn;
identifier f;
expression list el;
expression e;
@@

initfn(...) {
<+...
- e = f(el);
- return e;
+ return f(el);
...+> }

@unused_assign depends on probe@
type T;
identifier i;
expression E;
@@
- T i = E;
 ... when != i

@unused_var depends on probe@
type T;
identifier i;
@@
- T i;
 ... when != i

@unnecessary_brackets depends on probe@
expression e1, e2;
@@

  if (e1)
- {
    return e2;
- }

@rrem depends on remove@
identifier remove.removefn;
@@

- removefn(...) {
?-\(dev_warn\|dev_info\|pr_warn\|pr_crit\)(...);
- return 0;
- }

@depends on rrem@
identifier probe.p, remove.removefn;
@@

struct platform_driver p = {
- .remove = \(__exit_p(removefn)\|removefn\),
};

@script:python depends on direct_return@
p << probe.pos;
@@

print >> f, "%s:g1:%s" % (p[0].file, p[0].line)

@script:python depends on direct_return2@
p << probe.pos;
@@

print >> f, "%s:g1:%s" % (p[0].file, p[0].line)

@script:python depends on merge_return@
p << probe.pos;
@@

print >> f, "%s:g3:%s" % (p[0].file, p[0].line)

@script:python depends on extra_return@
p << probe.pos;
@@

print >> f, "%s:g4:%s" % (p[0].file, p[0].line)

@script:python depends on extra_return2@
p << probe.pos;
@@

print >> f, "%s:g3:%s" % (p[0].file, p[0].line)

@script:python depends on unused_assign@
p << probe.pos;
@@

print >> f, "%s:g6:%s" % (p[0].file, p[0].line)

@script:python depends on unused_var@
p << probe.pos;
@@

print >> f, "%s:g7:%s" % (p[0].file, p[0].line)

@script:python depends on unnecessary_brackets@
p << probe.pos;
@@

print >> f, "%s:g8:%s" % (p[0].file, p[0].line)

@script:python depends on rrem@
p << remove.pos;
@@

print >> f, "%s:g9:%s" % (p[0].file, p[0].line)
