dnl    Process this file with autoconf to produce a configure script
AC_REVISION($Revision$)

dnl    Initialisation: package name and version number
AC_INIT(star2html, 2.0-1, starlink@jiscmail.ac.uk)
AC_CONFIG_AUX_DIR([build-aux])

dnl    Require autoconf-2.50 at least
AC_PREREQ(2.50)
dnl    Require Starlink automake
AM_INIT_AUTOMAKE(1.8.2-starlink)

dnl    Sanity-check: name a file in the source directory -- if this
dnl    isn't found then configure will complain
AC_CONFIG_SRCDIR([star2html.in])

dnl    Include defaults for Starlink configurations
AC_PROG_MAKE_SET
STAR_DEFAULTS

dnl    This package has one dependencies,  latexsupport.
STAR_DECLARE_DEPENDENCIES([build], [latexsupport perl])

dnl    And requires that Perl is already built, from which we use the
dnl    starperl command.
STAR_DECLARE_DEPENDENCIES([configure], [perl])
STAR_CHECK_PROGS([env])

dnl    List the sun/ssn/... numbers which document this package and
dnl    which are present as .tex files in this directory.
STAR_LATEX_DOCUMENTATION(sun199,
                         [sun199.tex sun199.pdf sun199.htx_tar])
dnl    We override the standard .tex.htx_tar rule inside Makefile.am, and so
dnl    don't need the @STAR2HTML@ substitution.

dnl    Note that the star2html.in files contain
dnl    references to the installation directories, and so must be
dnl    substituted here at make time, rather than by ./configure at
dnl    configuration time.  See section `Installation Directory
dnl    Variables' in the autoconf manual for discussion.
AC_CONFIG_FILES([Makefile component.xml xlabel])

dnl    This is the bit that does the actual work
AC_OUTPUT
