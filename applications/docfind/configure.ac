dnl    Process this file with autoconf to produce a configure script
AC_REVISION($Revision$)
 
dnl    Initialisation: package name and version number
AC_INIT(docfind, 1.3-2, starlink@jiscmail.ac.uk)
AC_CONFIG_AUX_DIR([build-aux])
 
dnl    Require autoconf-2.50 at least
AC_PREREQ(2.50)

dnl    Require Starlink automake
AM_INIT_AUTOMAKE(1.8.2-starlink)
 
dnl    Sanity-check: name a file in the source directory -- if this
dnl    isn't found then configure will complain
AC_CONFIG_SRCDIR([docfind])

 
dnl    Include defaults for Starlink configurations
dnl    Need to find out whether we need this
STAR_DEFAULTS

dnl    Find required versions of the programs we need for configuration
AC_PROG_MAKE_SET

dnl    Depends on info package
STAR_DECLARE_DEPENDENCIES([build], [info])

dnl    We have a SUN document, so we should probably tell people it's there.
STAR_LATEX_DOCUMENTATION(sun38)

dnl    If you wish to configure extra files, you can add them to this
dnl    declaration.
AC_CONFIG_FILES(Makefile component.xml)

dnl    This is the bit that does the actual work
AC_OUTPUT
