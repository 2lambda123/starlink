dnl    Process this file with autoconf to produce a configure script
AC_REVISION($Revision$)

dnl    Initialisation: package name and version number
AC_INIT([ndf],[2.2],[starlink@jiscmail.ac.uk])
AC_CONFIG_AUX_DIR([build-aux])

dnl    Require autoconf-2.50 at least
AC_PREREQ([2.69])
dnl    Require Starlink automake
AM_INIT_AUTOMAKE(1.8.2-starlink)

dnl    Sanity-check: name a file in the source directory -- if this
dnl    isn't found then configure will complain
AC_CONFIG_SRCDIR([ndf.h])


dnl    Include defaults for Starlink configurations
STAR_DEFAULTS

dnl    Find required versions of the programs we need for configuration
AC_PROG_FC
LT_INIT

STAR_CHECK_PROGS([cgeneric])

STAR_CHECK_PROGS(perl)

dnl    If --with-pic=no is set we should honour that.
AM_CONDITIONAL(NOPIC, test x$pic_mode = xno)

STAR_CNF_COMPATIBLE_SYMBOLS
STAR_PRM_COMPATIBLE_SYMBOLS

dnl  Look for pthreads library
AC_CHECK_HEADERS(pthread.h)
AC_CHECK_LIB([pthread],[pthread_mutex_lock])

dnl check required rtl functions

AC_HEADER_TIME
AC_HEADER_STDC
AC_CHECK_HEADERS([unistd.h sys/types.h errno.h])

AC_CHECK_FUNCS([getpwuid geteuid getlogin cuserid getusername getenv gettimeofday uname])
AC_CHECK_DECLS([cuserid getusername])

dnl    Declare the build and use dependencies for this package
STAR_DECLARE_DEPENDENCIES([build], [pcs cnf prm hds ems mers ary ast par sae generic])
STAR_DECLARE_DEPENDENCIES([link],  [pcs cnf prm hds ems mers ary ast par])

dnl    List the sun/ssn/... numbers which document this package and
dnl    which are present as .tex files in this directory.
STAR_LATEX_DOCUMENTATION(ssn20 sun33)

STAR_MESSGEN(ndf_err.msg)

AC_CONFIG_HEADERS(config.h)

dnl    If you wish to configure extra files, you can add them to this
dnl    declaration.
AC_CONFIG_FILES(Makefile component.xml)
AC_CONFIG_FILES([make_h], [chmod +x make_h])

dnl    This is the bit that does the actual work
AC_OUTPUT
