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
|
  struct i2c_driver p = {
    .probe = probefn@pos,
  };
|
  struct spi_driver p = {
    .probe = probefn@pos,
  };
)

@unneeded_label depends on probe exists@
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
<...
- goto l1;
+ goto l2;
  ...
-l1:
 <... when != S
 l:@p1
 ...>
 l2:@p
...> }

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

@extra_return depends on probe@
identifier initfn;
expression e, e1;
@@

initfn(...) {
<+...
- if (\(e\|e<0\|e>0\|e!=e1\))
-     return e;
- return \(0\|e\);
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

@e@
identifier i;
position p;
type T;
@@

(
extern T i@p;
|
static T i@p;
)

@script:python depends on direct_return@
p << probe.pos;
@@

print >> f, "%s:goto1:%s" % (p[0].file, p[0].line)

@script:python depends on direct_return2@
p << probe.pos;
@@

print >> f, "%s:goto1:%s" % (p[0].file, p[0].line)

@script:python depends on merge_return@
p << probe.pos;
@@

print >> f, "%s:goto3:%s" % (p[0].file, p[0].line)

@script:python depends on extra_return@
p << probe.pos;
@@

print >> f, "%s:goto4:%s" % (p[0].file, p[0].line)

@script:python depends on extra_return2@
p << probe.pos;
@@

print >> f, "%s:goto4:%s" % (p[0].file, p[0].line)
