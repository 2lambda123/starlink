      SUBROUTINE SPD_CZPHR( INFO, VARUSE, KMAX, XNK, DTYPE, ATYPE,
     :   INDF, ONDF, LMAX, XL, XNDF, STATUS )
*+
*  Name:
*     SPD_CZPH{DR}

*  Purpose:
*     Set up output NDF for RESAMP in cube mode.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL SPD_CZPHR( INFO, VARUSE, KMAX, XNK, DTYPE, ATYPE, INDF, ONDF,
*        LMAX, XL, XNDF, MESSAG, STATUS )

*  Description:
*     This routine sets up the n-dimensional output NDF for the
*     Specdre appliciation RESAMP. (This does not include creating
*     the output NDF by propagation.) Based on a given array of pixel
*     positions it enquires from the ADAM parameter system the linear
*     array of pixel positions for the output. The routine will then
*     -  shape the output NDF,
*     -  create or update the Specdre Extension in the output,
*     -  create the COVRS (covariance row sums) component in the Specdre
*        Extension,
*     -  map and set the output pixel positions.
*
*     This routine returns an NDF identifier, which must be annulled
*     by the calling routine after use.

*  Arguments:
*     INFO = LOGICAL (Given)
*        If true, information about the abscissa grid found in the NDF
*        is issued.
*     VARUSE = LOGICAL (Given)
*        If false, the COVRS component in the Specdre Extension is not
*        created.
*     KMAX = INTEGER (Given)
*        The size of the XNK array. This number is offered as prompt
*        value for the number of output pixels.
*     XNK( KMAX ) = REAL (Given)
*        The array of input pixel positions. The first and last values
*        are offered as prompt values for the output start and end
*        coordinates.
*     DTYPE = CHARACTER * ( * ) (Given)
*        The HDS data type to be used for output data values, data
*        variances and covariance row sums.
*     ATYPE = CHARACTER * ( * ) (Given)
*        The HDS data type to be used for output pixel positions.
*     INDF = INTEGER (Given)
*        The identifier of the input NDF from which to propagate
*        auxiliary information.
*     ONDF = INTEGER (Given)
*        The identifier of the output NDF.
*     LMAX = INTEGER (Returned)
*        The first dimension of the output NDF. This is also the size
*        of the array to which XL points.
*     XL = INTEGER (Returned)
*        The pointer to the output pixel position array.
*     XNDF = INTEGER (Returned)
*        The identifier of the .MORE.SPECDRE.COVRS NDF in the Specdre
*        Extension of the output NDF.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     This routine recognises the Specdre Extension v. 0.7.

*  Authors:
*     hme: Horst Meyerdierks (UoE, Starlink)
*     acc: Anne Charles (RAL, Starlink)
*     {enter_new_authors_here}

*  History:
*     02 Feb 1993 (hme):
*        Original version adapted from SPAAB{DR}.
*        Must do the NDF_PROP at a higher level, i.e. before the template
*        axis 1 is mapped.
*     17 May 1993 (hme):
*        Use MSG_SETR rather than always the one for real.
*     17 Sep 1993 (hme):
*        Abort, if start and end are equal or step is zero.
*     26 Jan 1995 (hme):
*        Renamed from SPACZx.
*     15 Oct 1997 (acc):
*        Change name RESAMPLE to RESAMP due to clash of names with FIGARO.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! Standard DAT constants
      INCLUDE 'NDF_PAR'          ! Standard NDF constants
      INCLUDE 'SPD_EPAR'         ! Specdre Extension parameters

*  Arguments Given:
      LOGICAL INFO
      LOGICAL VARUSE
      INTEGER KMAX
      REAL XNK( KMAX )
      CHARACTER * ( * ) DTYPE
      CHARACTER * ( * ) ATYPE
      INTEGER INDF
      INTEGER ONDF

*  Arguments Returned:
      INTEGER LMAX
      INTEGER XL
      INTEGER XNDF

*  Status:
      INTEGER STATUS             ! Global status

*  Local constants.
      REAL ZEROR                 ! Itself
      PARAMETER ( ZEROR = 0. )
      DOUBLE PRECISION ZEROD     ! Itself
      PARAMETER ( ZEROD = 0D0 )

*  Local Variables:
      LOGICAL EXIST              ! True if a component exists
      LOGICAL EXIST2             ! True if a component exists
      LOGICAL ISBAS              ! True if NDF is base NDF
      INTEGER I, J               ! Loop indices
      INTEGER SPAXIS             ! Inherited spectroscopic axis number
      INTEGER IDUMMY             ! Dummy returned integer
      INTEGER PLACE              ! NDF placeholder
      INTEGER RNDF               ! NDF identifier for results
      INTEGER TNDF               ! NDF identifier for copy thereof
      INTEGER RPNTR( 2 )         ! Pointers to result data and variance
      INTEGER TPNTR( 2 )         ! Pointers to their copies
      INTEGER RNELM              ! Size of new result NDF
      INTEGER TNELM              ! Size of sectioned old result NDF
      INTEGER NDIM               ! Number of axes of NDF
      INTEGER DNDIM              ! Number of axes of NDF
      INTEGER RNDIM              ! Number of axes of NDF
      INTEGER LBND( NDF__MXDIM ) ! Lower bounds of NDF
      INTEGER UBND( NDF__MXDIM ) ! Upper bounds of NDF
      INTEGER DLBND( NDF__MXDIM ) ! Lower bounds of NDF
      INTEGER RLBND( NDF__MXDIM ) ! Lower bounds of NDF
      INTEGER DUBND( NDF__MXDIM ) ! Upper bounds of NDF
      INTEGER RUBND( NDF__MXDIM ) ! Upper bounds of NDF
      REAL XSTART              ! First pixel position
      REAL XSTEP               ! Pixel position increment
      REAL XEND                ! Last pixel position
      CHARACTER * ( DAT__SZLOC ) XLOC ! Locator of .MORE.SPECDRE
      CHARACTER * ( NDF__SZTYP ) TYPE ! Stored type of result NDF

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Get start, end and size of input NDF. Report it to the user.
      XSTART = MIN( XNK(1), XNK(KMAX) )
      XEND   = MAX( XNK(1), XNK(KMAX) )
      IF ( INFO ) THEN
         CALL MSG_SETR( 'SPD_CZPHR_T01', XSTART )
         CALL MSG_SETR( 'SPD_CZPHR_T02', XEND   )
         CALL MSG_SETI( 'SPD_CZPHR_T03', KMAX   )
         CALL MSG_OUT(  'SPD_CZPHR_M01', 'Abscissa grid in first ' //
     :      'input row is from ^SPD_CZPHR_T01 ' //
     :      'to ^SPD_CZPHR_T02 in ^SPD_CZPHR_T03 pixels.', STATUS )
      END IF

*  Use the grid found as default.
      XSTEP  = ( XEND - XSTART ) / FLOAT( KMAX - 1 )
      CALL PAR_DEF0R( 'START', XSTART, STATUS )
      CALL PAR_DEF0R( 'STEP',  XSTEP,  STATUS )
      CALL PAR_DEF0R( 'END',   XEND,   STATUS )

*  Get values for output start and end coordinates and for output size.
      CALL PAR_GET0R( 'START', XSTART, STATUS )
      CALL PAR_GET0R( 'STEP',  XSTEP,  STATUS )
      CALL PAR_GET0R( 'END',   XEND,   STATUS )

*  Work out size, correct END.
      IF ( ( XEND - XSTART ) * XSTEP .EQ. ZEROR ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'SPD_CZPH_E01', 'RESAMP: Error: ' //
     :      'Output grid has zero extent or zero step.', STATUS )
         GO TO 500
      END IF
      IF ( ( XEND - XSTART ) * XSTEP .LT. ZEROR ) XSTEP = -XSTEP
      LMAX = INT( ( XEND - XSTART ) / XSTEP + 0.5 ) + 1
      XEND = XSTART + ( LMAX - 1 ) * XSTEP

*  Shape the output NDF.
      CALL NDF_BOUND( INDF, NDF__MXDIM, LBND, UBND, NDIM, STATUS )
      LBND(1) = 1
      UBND(1) = LMAX
      CALL NDF_SBND( NDIM, LBND, UBND, ONDF, STATUS )
      CALL NDF_STYPE( DTYPE, ONDF, 'DATA,VARIANCE', STATUS )
      CALL NDF_ASTYP( ATYPE, ONDF, 'CENTRE', 1, STATUS )

*  Check status.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'SPD_CZPH_E02',
     :     'RESAMP: Error creating output NDF.', STATUS )
         GO TO 500
      END IF

*  Update the Specdre Extension in a general sense and get its HDS
*  locator. If the Extension exists already (has been propagated in
*  complete by NDF_PROP), then some components have to be deleted.
*  We don't consider the covariance row sums now, but do that
*  separately below.
      CALL NDF_XSTAT( ONDF, XNAME, EXIST, STATUS )
      IF ( EXIST ) THEN

*     Get the locator.
         CALL NDF_XLOC( ONDF, XNAME, 'UPDATE', XLOC, STATUS )

*     Depending on how the inherited spectroscopic axis number compares
*     to the number of the retained axis, certain components of the
*     Specdre Extension will be deleted, retained, or reshaped.
         CALL SPD_EABA( ONDF, .TRUE., SPAXIS, STATUS )

*     The output is certain to have the first axis as spectroscopic axis.
*     We can delete any inherited SPECAXIS.
         CALL DAT_THERE( XLOC, XCMP1, EXIST2, STATUS )
         IF ( EXIST2 ) CALL DAT_ERASE( XLOC, XCMP1, STATUS )

*     The spectroscopic values must be deleted. For one, such a
*     structure is redundant in the output. Secondly,
*     the axis centres are changed by the resampling.
         CALL DAT_THERE( XLOC, XCMP6, EXIST2, STATUS )
         IF ( EXIST2 ) CALL DAT_ERASE( XLOC, XCMP6, STATUS )

*     The spectroscopic widths must be deleted. For one, such a
*     structure is redundant in the output. Secondly,
*     the axis centres are linear after resampling.
         CALL DAT_THERE( XLOC, XCMP7, EXIST2, STATUS )
         IF ( EXIST2 ) CALL DAT_ERASE( XLOC, XCMP7, STATUS )

*     How to deal with the other components depends on whether the
*     original spectroscopic axis was retained.
         IF ( SPAXIS .NE. 1 ) THEN

*        All structures depend more or less on which is the
*        spectroscopic axis. So if the spectroscopic axis has changed,
*        then these structures must be deleted.
            CALL DAT_THERE( XLOC, XCMP2, EXIST2, STATUS )
            IF ( EXIST2 ) CALL DAT_ERASE( XLOC, XCMP2, STATUS )
            CALL DAT_THERE( XLOC, XCMP3, EXIST2, STATUS )
            IF ( EXIST2 ) CALL DAT_ERASE( XLOC, XCMP3, STATUS )
            CALL DAT_THERE( XLOC, XCMP4, EXIST2, STATUS )
            IF ( EXIST2 ) CALL DAT_ERASE( XLOC, XCMP4, STATUS )
            CALL DAT_THERE( XLOC, XCMP5, EXIST2, STATUS )
            IF ( EXIST2 ) CALL DAT_ERASE( XLOC, XCMP5, STATUS )
            CALL DAT_THERE( XLOC, XCMP9, EXIST2, STATUS )
            IF ( EXIST2 ) CALL DAT_ERASE( XLOC, XCMP9, STATUS )
         ELSE

*        If the spectroscopic axis has been retained, it is logical to
*        keep the relevant part of the result structure. Thus we have to
*        get a corresponding subset from the result structure. If the
*        input NDF is a base NDF, then no subsetting is necessary.
            CALL DAT_THERE( XLOC, XCMP9, EXIST2, STATUS )
            CALL NDF_ISBAS( INDF, ISBAS, STATUS )
            IF ( EXIST2 .AND. ( .NOT. ISBAS ) .AND.
     :           STATUS .EQ. SAI__OK ) THEN

*           Find out the bounds of the inherited result NDF. The bounds
*           of the first two axes remain the same.
               CALL NDF_FIND( XLOC, XCMP9, RNDF, STATUS )
               CALL NDF_BOUND( RNDF, NDF__MXDIM, RLBND, RUBND, RNDIM,
     :            STATUS )

*           Find out the bounds of INDF, which indicate the section
*           taken to make it from its base NDF.
               CALL NDF_BOUND( INDF, NDF__MXDIM, DLBND, DUBND, DNDIM,
     :            STATUS )

*           Convert this to the sectioning bounds to be applied to the
*           inherited result NDF. Fortunately the NDF's extension needs
*           not sectioning. Also, the resampling along the spectroscopic
*           axis does not affect us, since the spectroscopic axis does
*           not exist in the result NDF anyway. We have the parameter
*           axis instead, which needs no change.
               J = 2
               DO 1 I = 1, DNDIM
                  IF ( I .NE. SPAXIS ) THEN
                     J = J + 1
                     RLBND(J) = DLBND(I)
                     RUBND(J) = DUBND(I)
                  END IF
 1             CONTINUE
               CALL NDF_SBND( RNDIM, RLBND, RUBND, RNDF, STATUS )

*           The content of the result NDF is ok now, but the boundaries
*           do not match those of the output NDF.
*           We now copy the result NDF into a temporary NDF.
               CALL NDF_TEMP( PLACE, STATUS )
               CALL NDF_COPY( RNDF, PLACE, TNDF, STATUS )

*           Now change the bounds of the result NDF to match the output
*           NDF.
               CALL NDF_SBND( 2, RLBND, RUBND, RNDF, STATUS )

*           Map the copy and the reshaped result NDF.
               CALL NDF_TYPE( RNDF, 'DATA,VARIANCE', TYPE, STATUS )
               IF ( TYPE .NE. '_DOUBLE' ) TYPE = '_REAL'
               CALL NDF_MAP(  RNDF, 'DATA,VARIANCE', TYPE, 'WRITE/BAD',
     :            RPNTR, RNELM, STATUS )
               CALL NDF_MAP(  TNDF, 'DATA,VARIANCE', TYPE, 'READ',
     :            TPNTR, TNELM, STATUS )

*           Copy back the contents from the copy into the reshaped NDF.
               IF ( TYPE .EQ. '_DOUBLE' ) THEN
                  CALL VEC_DTOD( .TRUE., RNELM, %VAL(TPNTR(1)),
     :               %VAL(RPNTR(1)), I, J, STATUS )
                  CALL VEC_DTOD( .TRUE., RNELM, %VAL(TPNTR(2)),
     :               %VAL(RPNTR(2)), I, J, STATUS )
               ELSE
                  CALL VEC_RTOR( .TRUE., RNELM, %VAL(TPNTR(1)),
     :               %VAL(RPNTR(1)), I, J, STATUS )
                  CALL VEC_RTOR( .TRUE., RNELM, %VAL(TPNTR(2)),
     :               %VAL(RPNTR(2)), I, J, STATUS )
               END IF

*           Annul the result and temporary NDFs.
               CALL NDF_ANNUL( TNDF, STATUS )
               CALL NDF_ANNUL( RNDF, STATUS )

*           If something went wrong in updating the result NDF, then it
*           is deleted, and the error annulled.
               IF ( STATUS .NE. SAI__OK ) THEN
                  CALL ERR_ANNUL( STATUS )
                  CALL DAT_ERASE( XLOC, XCMP9, STATUS )
               END IF
            END IF
         END IF
      ELSE
         CALL NDF_XNEW( ONDF, XNAME, XTYPE, 0, 0, XLOC, STATUS )
      END IF

*  Check status.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'SPD_CZPH_E03',
     :     'RESAMP: Error updating output Specdre Extension.',
     :     STATUS )
         GO TO 500
      END IF

*  Does .MORE.SPECDRE.COVRS exist?
      CALL DAT_THERE( XLOC, XCMP8, EXIST, STATUS )

*  If COVRS exists and should exist, import and shape it.
      IF ( EXIST .AND. VARUSE ) THEN
         CALL NDF_FIND( XLOC, XCMP8, XNDF, STATUS )
         CALL NDF_SBND( NDIM, LBND, UBND, XNDF, STATUS )
         CALL NDF_STYPE( DTYPE, XNDF, 'DATA', STATUS )

*  Else if COVRS should exist (but does not), create it.
      ELSE IF ( VARUSE ) THEN
         CALL NDF_PLACE( XLOC, XCMP8, PLACE, STATUS )
         CALL NDF_NEW( DTYPE, NDIM, LBND, UBND, PLACE, XNDF, STATUS )

*  Else if COVRS exists (but should not), delete it.
      ELSE IF ( EXIST ) THEN
         CALL NDF_FIND( XLOC, XCMP8, XNDF, STATUS )
         CALL NDF_DELET( XNDF, STATUS )

*  Else (COVRS does not exist and should not), set identifier invalid.
      ELSE
         XNDF = NDF__NOID
      END IF

*  We can annul the HDS locators now.
      CALL DAT_ANNUL( XLOC, STATUS )

*  Check status.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'SPD_CZPH_E04',
     :      'RESAMP: Error accessing COVRS in Specdre Extension.',
     :      STATUS )
         GO TO 500
      END IF

*  Map output pixel positions and fill it linearly with values.
      CALL NDF_AMAP( ONDF, 'CENTRE', 1, ATYPE, 'WRITE', XL, IDUMMY,
     :   STATUS )
      CALL SPD_UAAJR( XSTART, XEND, LMAX, %VAL(XL), STATUS )

*  Ensure that output NDF does not have inherited widths in first axis.
      CALL NDF_AREST( ONDF, 'WIDTH', 1, STATUS )

*  Tidy up.
 500  CONTINUE
      END
