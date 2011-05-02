@INTLTOOL_DESKTOP_RULE@
desktopdir = $(datadir)/applications
desktop_in_files = indicator-multiload.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)

@INTLTOOL_XML_NOMERGE_RULE@
@GSETTINGS_RULES@
gsettings_SCHEMAS = de.mh21.indicator.multiload.gschema.xml

uidir = $(pkgdatadir)
nodist_ui_DATA = preferences.ui

EXTRA_DIST = \
	$(desktop_in_files) \
	$(ui_DATA) \
	de.mh21.indicator.multiload.gschema.xml.in.in

CLEANFILES = \
	$(desktop_DATA) \
	$(gsettings_SCHEMAS)

uninstall-hook:
	-rmdir $(pkgdatadir)
