SUBDIRS = src data po

multiloaddocdir = ${datadir}/doc/indicator-multiload
multiloaddoc_DATA = \
	COPYING \
	AUTHORS \
	HACKING

EXTRA_DIST = \
	$(multiloaddoc_DATA) \
	autogen.sh

uninstall-hook:
	-rmdir $(multiloaddocdir)

test-run:
	-rm -rf local-xdg-data-dir
	-mkdir -p local-xdg-data-dir/glib-2.0/schemas local-xdg-data-dir/indicator-multiload
	-ln -s ../../../data/de.mh21.indicator.multiload.gschema.xml local-xdg-data-dir/glib-2.0/schemas
	-ln -s ../../data/preferences.ui local-xdg-data-dir/indicator-multiload
	-glib-compile-schemas local-xdg-data-dir/glib-2.0/schemas
	-XDG_DATA_DIRS=./local-xdg-data-dir:$$XDG_DATA_DIRS src/indicator-multiload
	-rm -rf local-xdg-data-dir
