AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	$(MULTILOADDEPS_CFLAGS) \
	-include $(CONFIG_HEADER)

AM_CFLAGS = -Wall -g

VALAFLAGS =  \
	--pkg=posix \
	--pkg=gtk+-3.0 \
	--pkg=cairo \
	--pkg=appindicator3-0.1 \
	--pkg=glib-2.0 \
	--pkg=gio-unix-2.0 \
	--pkg=gmodule-2.0 \
	--enable-checking

bin_PROGRAMS = indicator-multiload

indicator_multiload_VALASOURCES = \
	cpuprovider.vala \
	diskprovider.vala \
	expressionparser.vala \
	function.vala \
	graphmodels.vala \
	graphmodel.vala \
	itempreferences.vala \
	loadprovider.vala \
	main.vala \
	memprovider.vala \
	menumodel.vala \
	multiloadindicator.vala \
	netprovider.vala \
	preferences.vala \
	providers.vala \
	provider.vala \
	reaper.vala \
	settingscache.vala \
	settingsconversion.vala \
	swapprovider.vala \
	tracemodel.vala \
	utils.vala

indicator_multiload_SOURCES = \
	$(indicator_multiload_VALASOURCES) \
	config.vapi \
	gsettings-fixed.vapi \
	gtop.vapi \
	various.vapi

indicator_multiload_LDFLAGS = \
	-Wl,--export-dynamic -Wl,--as-needed

indicator_multiload_LDADD = $(MULTILOADDEPS_LIBS) -lm

DISTCLEANFILES = \
	$(indicator_multiload_VALASOURCES:.vala=.c) indicator_multiload_vala.stamp
