## Process this file with automake to produce Makefile.in

dist_bin_SCRIPTS = ctg_link_adam

lib_LTLIBRARIES = libctg.la

libctg_la_SOURCES = \
	$(PRIVATE_INCLUDES) \
	$(PUBLIC_INCLUDES) \
	$(F_ROUTINES) \
        $(ADAM_F_ROUTINES)

PRIVATE_INCLUDES = CTG_CONST
include_MESSAGES = CTG_ERR

stardocs_DATA = @STAR_LATEX_DOCUMENTATION@

F_ROUTINES = \
ctg1_appen.f ctg1_asexp.f ctg1_catch.f ctg1_crexp.f ctg1_expan.f \
ctg1_fpars.f ctg1_gtyps.f ctg1_match.f ctg1_sort.f  ctg1_subst.f \
ctg_catas.f  ctg_catcr.f  ctg_gtsup.f  ctg_ptsup.f  ctg_setsz.f

ADAM_F_ROUTINES = ctg_asso1.f ctg_assoc.f ctg_crea1.f ctg_creat.f 

BUILT_SOURCES = CTG_ERR
