dnl    Process this file with autoconf to produce a configure script
AC_REVISION($Revision$)

dnl    Initialisation: package name and version number
AC_INIT([pgplot-base],[5.2.2-1],[starlink@jiscmail.ac.uk])

dnl    Require autoconf-2.50 at least
AC_PREREQ([2.69])
dnl    Require Starlink automake
AM_INIT_AUTOMAKE(1.8.2-starlink)

dnl    Sanity-check: name a file in the source directory -- if this
dnl    isn't found then configure will complain
AC_CONFIG_SRCDIR([pgbind.c])

dnl    Include defaults for Starlink configurations
dnl    Need to find out whether we need this
STAR_DEFAULTS

dnl    Find required versions of the programs we need for configuration
AC_PROG_CC
LT_INIT

AC_HEADER_STDC
AC_PATH_XTRA


dnl    Grab the F77 runtime libraries into FLIBS variable
AC_FC_LIBRARY_LDFLAGS

dnl    Should investigate whether we really need this for a non-starlink
dnl    encumbered pgplot
STAR_CNF_COMPATIBLE_SYMBOLS


dnl    If you wish to configure extra files, you can add them to this
dnl    declaration.
AC_CONFIG_FILES(Makefile)

dnl    This is the bit that does the actual work
AC_OUTPUT
