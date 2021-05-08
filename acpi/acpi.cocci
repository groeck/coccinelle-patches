virtual report
virtual patch

@initialize:python@
@@

import csv
import re
import os

acpi_re = re.compile(r'.*"([A-Z0-9]+)"')

# Specify the location of .csv files as needed.
# In most cases this should be the script location, but I don't know
# where to get that from.

csv_file_dir = '/home/groeck/src/coccinelle-patches/acpi'

with open(os.path.join(csv_file_dir, 'pnp_ids.csv')) as f:
    reader = csv.reader(f)
    pnp_ids = list(reader)

with open(os.path.join(csv_file_dir, 'acpi_ids.csv')) as f:
    reader = csv.reader(f)
    acpi_ids = list(reader)

# skip headers
pnp_ids.pop(0)
acpi_ids.pop(0)


@d@
identifier table, pvar;
position p;
@@

struct
(
  platform_driver
|
  spi_driver
|
  i2c_driver
)
pvar = {
  .driver@p = {
    .acpi_match_table = \( ACPI_PTR(table) \| table \) ,
  },
};


@m@
identifier d.table;
symbol acpi;
position p2;
declarer name MODULE_DEVICE_TABLE;
@@

MODULE_DEVICE_TABLE@p2(acpi, table);


@entries@
symbol acpi_device_id;
identifier d.table;
initializer list elements;
position p;
@@

  struct acpi_device_id table@p[] = {
   elements,
  };


@script:python depends on patch@
elements << entries.elements;
@@

for e in elements:
    matched = False
    e1 = acpi_re.match(e)
    if e1:
        id = e1.group(1)
	for acpi in acpi_ids:
	    if id.startswith(acpi[1]) and len(id) == 8:
		matched = True
	        break
	if not matched:
            for pnp in pnp_ids:
	        if id.startswith(pnp[1]) and len(id) == 7:
		    matched = True
	            break
    if matched:
        cocci.include_match(False)
	break


// The above completely removes matches, so the following transformations
// do not need to explicitly depend on it.

@depends on patch@
identifier d.table;
position d.p;
identifier s;
identifier d.pvar;
@@

struct s pvar = {
  .driver@p = {
-   .acpi_match_table = \( ACPI_PTR(table) \| table \) ,
  },
};


@depends on patch@
identifier d.table;
symbol acpi;
declarer name MODULE_DEVICE_TABLE;
@@

- MODULE_DEVICE_TABLE(acpi, table);


@depends on patch@
symbol acpi_device_id;
identifier d.table;
initializer list elements;
@@

- struct acpi_device_id table[] = {
-  elements,
- };


// Re-match for leftover table variables referenced with ACPI_PTR()

@acpi_ptr@
identifier table, pvar;
@@

struct
(
  platform_driver
|
  spi_driver
|
  i2c_driver
)
pvar = {
  .driver = {
    .acpi_match_table = ACPI_PTR(table),
  },
};


// Add __maybe_unused to tables referenced with ACPI_PTR()

@depends on patch@
symbol acpi_device_id;
identifier acpi_ptr.table;
fresh identifier unused_table = table ## " __maybe_unused";
@@

  struct acpi_device_id
- table
+ unused_table
  [] = {
   ...
  };


@script:python depends on report@
elements << entries.elements;
pos << entries.p;
@@

import re;

file_printed = False
for e in elements:
    e1 = re.match(r'.*"([A-Z0-9]+)"', e)
    if e1:
        if not file_printed:
	    print pos[0].file
	    file_printed = True
        id = e1.group(1)
        matched = False
	for acpi in acpi_ids:
	    if id.startswith(acpi[1]):
	        print "  %s: match (ACPI ID) against %s (%s)" % (id, acpi[1], acpi[0])
		matched = True
	        break
	if not matched:
            for pnp in pnp_ids:
	        if id.startswith(pnp[1]):
	            print "  %s: match (prefix) against %s (%s)" % (id, pnp[1], pnp[0])
		    matched = True
	            break
	if not matched:
	    print "  %s: No match" % id
