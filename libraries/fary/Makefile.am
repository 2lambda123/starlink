## Process this file with automake to produce Makefile.in

dist_bin_SCRIPTS = ary_link ary_link_adam
cincludedir = $(includedir)/star

# Note that "classic" has a libary and libary_adam but they
# are identical. Since everyone goes through the _link scripts
# there is no reason to persist with this madness so we have only
# one library here.

lib_LTLIBRARIES = libary.la

libary_la_SOURCES = \
	$(PUBLIC_INCLUDES) \
	$(include_MESSAGES) \
	$(F_ROUTINES) \
	$(C_ROUTINES) \
	$(PRIVATE_INCLUDES)

# Make all library code position independent. This is handy for creating
# shareable libraries from the static ones (Java JNI libraries).
if !NOPIC
libary_la_FCFLAGS = $(AM_FCFLAGS) -prefer-pic
libary_la_CFLAGS = $(AM_CFLAGS) -prefer-pic
endif

include_HEADERS = $(PUBLIC_INCLUDES)

stardocs_DATA = @STAR_LATEX_DOCUMENTATION@

PRIVATE_INCLUDES = ARY_ACB ARY_CONST ARY_DCB ARY_MCB ARY_PCB ARY_TCB \
                   ary_dlt.h

PUBLIC_F_INCLUDES = ARY_PAR
PUBLIC_C_INCLUDES = ary.h
PUBLIC_INCLUDES = $(PUBLIC_F_INCLUDES) $(PUBLIC_C_INCLUDES)
include_MESSAGES = ary_err.h ARY_ERR

GEN_F_ROUTINES = $(ARY_N_GEN:.gn=.f)

F_ROUTINES = $(NONGEN_F_ROUTINES) $(GEN_F_ROUTINES)

ARY_N_GEN = ary_ptszx.gn ary_gtszx.gn ary1_badx.gn ary1_bppx.gn        \
ary1_gtnx.gn ary1_gt1x.gn ary1_cvfx.gn ary1_cvtx.gn ary1_pt1x.gn       \
ary1_ptnx.gn ary1_zerx.gn

C_ROUTINES = ary1_s2dlt.c ary1_undlt.c ary.c

NONGEN_F_ROUTINES = ary1_init.f ary1_accok.f ary1_adiag.f ary1_anl.f   \
ary1_annpl.f ary1_antmp.f ary1_bad.f \
ary1_bpp.f ary1_ccpy.f ary1_chacc.f	      		               \
ary1_chbpp.f ary1_chcma.f ary1_chmod.f ary1_chscn.f ary1_chsta.f       \
ary1_cln.f ary1_cmtmp.f ary1_cpy.f ary1_cpync.f ary1_crnba.f	       \
ary1_cut.f \
ary1_danl.f ary1_dbad.f ary1_dbnd.f ary1_dcpy.f ary1_dcre.f	       \
ary1_dcrep.f ary1_ddiag.f ary1_del.f ary1_dfrm.f ary1_diag.f	       \
ary1_dimp.f ary1_dmod.f ary1_dp2s.f ary1_drst.f ary1_ds2p.f	       \
ary1_dsbd.f ary1_dsbnd.f ary1_dsft.f ary1_dsta.f ary1_dstp.f	       \
ary1_dtyp.f ary1_dvfy.f ary1_eqbnd.f ary1_expid.f ary1_ffs.f	       \
ary1_dobj.f ary1_gmrb.f ary1_gtn.f ary1_defr.f ary1_dfppl.f \
ary1_hunmp.f ary1_id2ac.f ary1_imp.f ary1_impid.f	       \
ary1_imppl.f ary1_inbnd.f ary1_intyp.f ary1_iobw.f ary1_maps.f	       \
ary1_mdiag.f ary1_mpsr.f ary1_mpsw.f ary1_nel.f ary1_nxtsl.f	       \
ary1_pbnd.f ary1_ptn.f ary1_rebnd.f ary1_retyp.f ary1_rls.f ary1_sbd.f \
ary1_sbnd.f ary1_setc.f ary1_sft.f ary1_stp.f ary1_tcnam.f ary1_temp.f \
ary1_trace.f ary1_ump.f ary1_umps.f ary1_upsr.f ary1_upsw.f	       \
ary1_vbad.f ary1_vbnd.f ary1_vftp.f ary1_vmmd.f ary1_vtyp.f	       \
ary1_vzero.f ary1_xsbnd.f ary_annul.f	       \
ary_bad.f ary_base.f ary_bound.f ary_clone.f ary_cmplx.f ary_copy.f    \
ary_delet.f ary_dim.f ary_dupe.f ary_find.f ary_form.f ary_ftype.f     \
ary_imprt.f ary_isacc.f ary_isbas.f ary_ismap.f ary_istmp.f ary_map.f  \
ary_mapz.f ary_msg.f ary_ndim.f ary_new.f ary_newp.f ary_noacc.f       \
ary_offs.f ary_place.f ary_reset.f ary_same.f ary_sbad.f ary_sbnd.f    \
ary_sect.f ary_shift.f ary_size.f ary_ssect.f ary_state.f ary_stype.f  \
ary_temp.f ary_trace.f ary_type.f ary_unmap.f ary_valid.f ary_verfy.f \
ary1_cpscl.f ary1_dscl.f ary1_vscl.f ary_sctyp.f ary1_cpdlt.f \
ary_loc.f ary_delta.f ary1_dlshp.f ary_gtdlt.f ary1_gtdlt.f ary1_extyp.f

BUILT_SOURCES = $(include_MESSAGES)


# Testing

TESTS = ary_test
check_PROGRAMS = ary_test

ary_test_SOURCES = ary_test.f
# LDADD is the expansion of ary_link, with -lary replaced by libary.la
ary_test_LDADD = libary.la `hds_link` `err_link` `chr_link` `prm_link`

dist_starnews_DATA = ary.news
dist_pkgdata_DATA = LICENCE

EXTRA_DIST = ary_err.msg

CLEANFILES = ARY_ERR

.gn.f:
	cp $< $(<:.gn=.gen)
	$(FGENERIC)  -t n -u $(<:.gn=.gen)
	rm $(<:.gn=.gen)


