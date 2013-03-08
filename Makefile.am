SUBDIRS = po

# general stuff

AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	$(MULTILOADDEPS_CFLAGS) \
	-include $(CONFIG_HEADER)

AM_CFLAGS = -Wall \
           -Wno-unused-but-set-variable \
           -Wno-unused-variable \
           -Wno-unused-function \
           -Wno-missing-braces

VALAFLAGS =  \
	--pkg=posix \
	--pkg=gtk+-3.0 \
	--pkg=cairo \
	--pkg=appindicator3-0.1 \
	--pkg=glib-2.0 \
	--pkg=gio-unix-2.0 \
	--pkg=gmodule-2.0 \
	--enable-checking

@INTLTOOL_DESKTOP_RULE@
@INTLTOOL_XML_NOMERGE_RULE@
@GSETTINGS_RULES@

# the indicator

bin_PROGRAMS = indicator-multiload

indicator_multiload_VALASOURCES = \
	src/advpreferences.vala \
	src/appindicatorview.vala \
	src/colormapper.vala \
	src/cpufreqprovider.vala \
	src/cpuprovider.vala \
	src/diskprovider.vala \
	src/expressionparser.vala \
	src/function.vala \
	src/graphmodels.vala \
	src/graphmodel.vala \
	src/indicator.vala \
	src/indicatorview.vala \
	src/itemhelp.vala \
	src/itempreferences.vala \
	src/loadprovider.vala \
	src/main.vala \
	src/memprovider.vala \
	src/menumodel.vala \
	src/netprovider.vala \
	src/preferences.vala \
	src/providers.vala \
	src/provider.vala \
	src/reaper.vala \
	src/settingscache.vala \
	src/settingsconversion.vala \
	src/swapprovider.vala \
	src/tracemodel.vala \
	src/utils.vala

indicator_multiload_SOURCES = \
	$(indicator_multiload_VALASOURCES) \
	src/config.vapi \
	src/gtop.vapi \
	src/various.vapi

indicator_multiload_LDFLAGS = \
	-Wl,--export-dynamic -Wl,--as-needed

indicator_multiload_LDADD = $(MULTILOADDEPS_LIBS) -lm

# documentation

multiloaddocdir = ${datadir}/doc/indicator-multiload
multiloaddoc_DATA = \
	COPYING \
	AUTHORS \
	TODO \
	HACKING

# gui

uidir = $(pkgdatadir)
nodist_ui_DATA = data/preferences.ui

# desktop file

desktopdir = $(datadir)/applications
desktop_in_files = data/indicator-multiload.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)

# gsettings schema

gsettings_SCHEMAS = data/de.mh21.indicator-multiload.gschema.xml

# clean and dist

CLEANFILES = \
	$(desktop_DATA) \
	$(gsettings_SCHEMAS)

DISTCLEANFILES = \
	$(indicator_multiload_VALASOURCES:.vala=.c) indicator_multiload_vala.stamp

EXTRA_DIST = \
	$(multiloaddoc_DATA) \
	$(desktop_in_files) \
	data/preferences.ui.in \
	data/de.mh21.indicator-multiload.gschema.xml.in.in \
	autogen.sh

uninstall-hook:
	-rmdir $(multiloaddocdir) $(pkgdatadir)

# run targets

test-run: all
	-rm -rf local-xdg-data-dir
	-mkdir -p local-xdg-data-dir/glib-2.0/schemas local-xdg-data-dir/indicator-multiload
	-ln -s ../../../data/de.mh21.indicator-multiload.gschema.xml local-xdg-data-dir/glib-2.0/schemas
	-ln -s ../../data/preferences.ui local-xdg-data-dir/indicator-multiload
	-glib-compile-schemas local-xdg-data-dir/glib-2.0/schemas
	-XDG_DATA_DIRS=./local-xdg-data-dir:$$XDG_DATA_DIRS G_SLICE=always-malloc ./indicator-multiload
	-rm -rf local-xdg-data-dir

test-verbose: all
	-rm -rf local-xdg-data-dir
	-mkdir -p local-xdg-data-dir/glib-2.0/schemas local-xdg-data-dir/indicator-multiload
	-ln -s ../../../data/de.mh21.indicator-multiload.gschema.xml local-xdg-data-dir/glib-2.0/schemas
	-ln -s ../../data/preferences.ui local-xdg-data-dir/indicator-multiload
	-glib-compile-schemas local-xdg-data-dir/glib-2.0/schemas
	-XDG_DATA_DIRS=./local-xdg-data-dir:$$XDG_DATA_DIRS G_MESSAGES_DEBUG=all G_SLICE=always-malloc ./indicator-multiload
	-rm -rf local-xdg-data-dir

test-debug: all
	-rm -rf local-xdg-data-dir
	-mkdir -p local-xdg-data-dir/glib-2.0/schemas local-xdg-data-dir/indicator-multiload
	-ln -s ../../../data/de.mh21.indicator-multiload.gschema.xml local-xdg-data-dir/glib-2.0/schemas
	-ln -s ../../data/preferences.ui local-xdg-data-dir/indicator-multiload
	-glib-compile-schemas local-xdg-data-dir/glib-2.0/schemas
	-XDG_DATA_DIRS=./local-xdg-data-dir:$$XDG_DATA_DIRS G_MESSAGES_DEBUG=all G_SLICE=always-malloc gdb --args ./indicator-multiload
	-rm -rf local-xdg-data-dir

test-valgrind: all
	-rm -rf local-xdg-data-dir
	-mkdir -p local-xdg-data-dir/glib-2.0/schemas local-xdg-data-dir/indicator-multiload
	-ln -s ../../../data/de.mh21.indicator-multiload.gschema.xml local-xdg-data-dir/glib-2.0/schemas
	-ln -s ../../data/preferences.ui local-xdg-data-dir/indicator-multiload
	-glib-compile-schemas local-xdg-data-dir/glib-2.0/schemas
	-XDG_DATA_DIRS=./local-xdg-data-dir:$$XDG_DATA_DIRS G_MESSAGES_DEBUG=all G_SLICE=always-malloc G_DEBUG=gc-friendly valgrind --tool=memcheck --leak-check=full --leak-resolution=high --num-callers=20 --show-reachable=yes --log-file=vgdump ./indicator-multiload
	-rm -rf local-xdg-data-dir

# these are a bit of a hack, as automake has tags support
tags:
	-anjuta-tags -R -o tags src

tags-vala:
	-anjuta-tags -o tags-vala /usr/share/vala-$$($(VALAC) --version | sed 's/.*\(0\.[0-9]\+\)\.[0-9]\+/\1/')/vapi/*.vapi
