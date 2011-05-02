AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	$(MULTILOADDEPS_CFLAGS) \
	-include $(CONFIG_HEADER)

AM_CFLAGS = -Wall -g

VALAFLAGS =  \
	--pkg=gtk+-2.0 \
	--pkg=cairo \
	--pkg=appindicator-0.1 \
	--pkg=glib-2.0 \
	--pkg=gio-unix-2.0 \
	--pkg=gmodule-2.0 \
	--enable-checking

bin_PROGRAMS = indicator-multiload

indicator_multiload_SOURCES = \
	cpuicondata.vala \
	diskicondata.vala \
	icondata.vala \
	icontracedata.vala \
	loadicondata.vala \
	memicondata.vala \
	multiloadindicator.vala \
	main.vala \
	neticondata.vala \
	swapicondata.vala \
	utils.vala \
	appindicator-fixed.vapi \
	config.vapi \
	gsettings-fixed.vapi \
	gtop.vapi \
	various.vapi

indicator_multiload_LDFLAGS = \
	-Wl,--export-dynamic

indicator_multiload_LDADD = $(MULTILOADDEPS_LIBS)
