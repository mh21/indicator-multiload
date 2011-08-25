AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	$(MULTILOADDEPS_CFLAGS) \
	-include $(CONFIG_HEADER)

AM_CFLAGS = -Wall -g

VALAFLAGS =  \
	--pkg=gtk+-3.0 \
	--pkg=cairo \
	--pkg=appindicator3-0.1 \
	--pkg=glib-2.0 \
	--pkg=gio-unix-2.0 \
	--pkg=gmodule-2.0 \
	--enable-checking

bin_PROGRAMS = indicator-multiload

indicator_multiload_SOURCES = \
	cpuprovider.vala \
	provider.vala \
	providers.vala \
	diskprovider.vala \
	expressionparser.vala \
	graphmodel.vala \
	graphmodels.vala \
	loadprovider.vala \
	main.vala \
	memprovider.vala \
	menumodel.vala \
	menupreferences.vala \
	multiloadindicator.vala \
	netprovider.vala \
	preferences.vala \
	settingscache.vala \
	settingsconversion.vala \
	swapprovider.vala \
	tracemodel.vala \
	utils.vala \
	config.vapi \
	gsettings-fixed.vapi \
	gtop.vapi \
	various.vapi

indicator_multiload_LDFLAGS = \
	-Wl,--export-dynamic -Wl,--as-needed

indicator_multiload_LDADD = $(MULTILOADDEPS_LIBS)
