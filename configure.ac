AC_INIT([indicator-multiload],
	[0.4],
	[mh21@mh21.de],
	[indicator-multiload],
	[http://mh21.de/])

AC_CONFIG_SRCDIR([src/main.vala])
AC_CONFIG_HEADERS([config.h])
AC_PROG_CC

AM_SILENT_RULES([yes])
AM_INIT_AUTOMAKE([foreign dist-xz no-dist-gzip subdir-objects tar-pax])
AM_PROG_VALAC([0.14.0])
AM_PROG_CC_C_O

IT_PROG_INTLTOOL
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.17])
GETTEXT_PACKAGE=indicator-multiload
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE", [gettext package name])

GLIB_GSETTINGS

PKG_CHECK_MODULES(MULTILOADDEPS, [gtk+-3.0 >= 3.4 cairo appindicator3-0.1 glib-2.0 gio-unix-2.0 gmodule-2.0 libgtop-2.0])

AC_CONFIG_FILES([
Makefile
data/preferences.ui
data/de.mh21.indicator-multiload.gschema.xml.in
po/Makefile.in
])

AC_OUTPUT

AC_MSG_RESULT([
  ------------------------
  $PACKAGE_NAME $VERSION
  ------------------------
  CPPFLAGS: ${CPPFLAGS}
  CFLAGS:   ${CFLAGS}
  LDFLAGS:  ${LDFLAGS}
  ------------------------
])
