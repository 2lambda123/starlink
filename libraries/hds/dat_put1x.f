*+ DAT_PUT1C - Write vector object values
      subroutine dat_put1C(loc, nval, values, status)
*    Description :
*     Write the values into a vector primitive object.
*     There is a routine for each access type,
*
*        DAT_PUT1D    DOUBLE PRECISION
*        DAT_PUT1R    REAL
*        DAT_PUT1I    INTEGER
*        DAT_PUT1L    LOGICAL
*        DAT_PUT1C    CHARACTER[*n]
*
*     If the object data type differs from the access type, then
*     conversion is performed.
*    Invocation :
*     CALL DAT_PUT1C(LOC, NVAL, VALUES; STATUS)
*    Parameters :
*     LOC=CHARACTER*(DAT__SZLOC)
*           Variable containing a locator associated with a primitive
*           data object.
*     NVAL=INTEGER
*           Expression specifying the number of values that are to be
*           written.   This must match the object size.
*     VALUES(NVAL)=CHARACTER*(*)
*           Array containing the values to be written into the object.
*     STATUS=INTEGER
*           Variable holding the status value. If this variable is not
*           SAI__OK on input, the routine will return without action.
*           If the routine fails to complete, this variable will be
*           set to an appropriate error number.
*    Method :
*     Use DAT_SIZE and DAT_PUTC.
*     Be careful to conform to Fortran 77 standard, with regard to passing
*     arrays to subprograms.
*    Authors :
*     Jack Giddings (UCL::JRG)
*     Sid Wright (UCL::SLW)
*    History :
*     3-JAN-1983:  Original.  (UCL::JRG)
*     31-Aug-1983:  Standardise.  (UCL::SLW)
*     05.11.1984:   Remove calls to error system (REVAD::BDK)
*     15-APR-1987:  Improved prologue layout (RAL::AJC)
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'DAT_ERR'
*    Import :
      character*(*) loc			! Object Locator
      integer nval			! Number of values to be written
      CHARACTER*(*) values(*)			! Vector to supply values
*    Status return :
      integer status			! Status Return
*    Local variables :
      integer ndim
      integer dims(1)
*    Local data :
      data ndim/1/
*-

      if (status .eq. SAI__OK) then
         call dat_size(loc, dims(1), status)
         if (nval .ne. dims(1)) then
            status = DAT__BOUND
         else
            call dat_putC(loc, 1, dims(1), values, status)
         endif
      endif

      end
*+ DAT_PUT1D - Write vector object values
      subroutine dat_put1D(loc, nval, values, status)
*    Description :
*     Write the values into a vector primitive object.
*     There is a routine for each access type,
*
*        DAT_PUT1D    DOUBLE PRECISION
*        DAT_PUT1R    REAL
*        DAT_PUT1I    INTEGER
*        DAT_PUT1L    LOGICAL
*        DAT_PUT1C    CHARACTER[*n]
*
*     If the object data type differs from the access type, then
*     conversion is performed.
*    Invocation :
*     CALL DAT_PUT1D(LOC, NVAL, VALUES; STATUS)
*    Parameters :
*     LOC=CHARACTER*(DAT__SZLOC)
*           Variable containing a locator associated with a primitive
*           data object.
*     NVAL=INTEGER
*           Expression specifying the number of values that are to be
*           written.   This must match the object size.
*     VALUES(NVAL)=DOUBLE PRECISION
*           Array containing the values to be written into the object.
*     STATUS=INTEGER
*           Variable holding the status value. If this variable is not
*           SAI__OK on input, the routine will return without action.
*           If the routine fails to complete, this variable will be
*           set to an appropriate error number.
*    Method :
*     Use DAT_SIZE and DAT_PUTD.
*     Be careful to conform to Fortran 77 standard, with regard to passing
*     arrays to subprograms.
*    Authors :
*     Jack Giddings (UCL::JRG)
*     Sid Wright (UCL::SLW)
*    History :
*     3-JAN-1983:  Original.  (UCL::JRG)
*     31-Aug-1983:  Standardise.  (UCL::SLW)
*     05.11.1984:   Remove calls to error system (REVAD::BDK)
*     15-APR-1987:  Improved prologue layout (RAL::AJC)
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'DAT_ERR'
*    Import :
      character*(*) loc			! Object Locator
      integer nval			! Number of values to be written
      DOUBLE PRECISION values(*)			! Vector to supply values
*    Status return :
      integer status			! Status Return
*    Local variables :
      integer ndim
      integer dims(1)
*    Local data :
      data ndim/1/
*-

      if (status .eq. SAI__OK) then
         call dat_size(loc, dims(1), status)
         if (nval .ne. dims(1)) then
            status = DAT__BOUND
         else
            call dat_putD(loc, 1, dims(1), values, status)
         endif
      endif

      end
*+ DAT_PUT1I - Write vector object values
      subroutine dat_put1I(loc, nval, values, status)
*    Description :
*     Write the values into a vector primitive object.
*     There is a routine for each access type,
*
*        DAT_PUT1D    DOUBLE PRECISION
*        DAT_PUT1R    REAL
*        DAT_PUT1I    INTEGER
*        DAT_PUT1L    LOGICAL
*        DAT_PUT1C    CHARACTER[*n]
*
*     If the object data type differs from the access type, then
*     conversion is performed.
*    Invocation :
*     CALL DAT_PUT1I(LOC, NVAL, VALUES; STATUS)
*    Parameters :
*     LOC=CHARACTER*(DAT__SZLOC)
*           Variable containing a locator associated with a primitive
*           data object.
*     NVAL=INTEGER
*           Expression specifying the number of values that are to be
*           written.   This must match the object size.
*     VALUES(NVAL)=INTEGER
*           Array containing the values to be written into the object.
*     STATUS=INTEGER
*           Variable holding the status value. If this variable is not
*           SAI__OK on input, the routine will return without action.
*           If the routine fails to complete, this variable will be
*           set to an appropriate error number.
*    Method :
*     Use DAT_SIZE and DAT_PUTI.
*     Be careful to conform to Fortran 77 standard, with regard to passing
*     arrays to subprograms.
*    Authors :
*     Jack Giddings (UCL::JRG)
*     Sid Wright (UCL::SLW)
*    History :
*     3-JAN-1983:  Original.  (UCL::JRG)
*     31-Aug-1983:  Standardise.  (UCL::SLW)
*     05.11.1984:   Remove calls to error system (REVAD::BDK)
*     15-APR-1987:  Improved prologue layout (RAL::AJC)
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'DAT_ERR'
*    Import :
      character*(*) loc			! Object Locator
      integer nval			! Number of values to be written
      INTEGER values(*)			! Vector to supply values
*    Status return :
      integer status			! Status Return
*    Local variables :
      integer ndim
      integer dims(1)
*    Local data :
      data ndim/1/
*-

      if (status .eq. SAI__OK) then
         call dat_size(loc, dims(1), status)
         if (nval .ne. dims(1)) then
            status = DAT__BOUND
         else
            call dat_putI(loc, 1, dims(1), values, status)
         endif
      endif

      end
*+ DAT_PUT1L - Write vector object values
      subroutine dat_put1L(loc, nval, values, status)
*    Description :
*     Write the values into a vector primitive object.
*     There is a routine for each access type,
*
*        DAT_PUT1D    DOUBLE PRECISION
*        DAT_PUT1R    REAL
*        DAT_PUT1I    INTEGER
*        DAT_PUT1L    LOGICAL
*        DAT_PUT1C    CHARACTER[*n]
*
*     If the object data type differs from the access type, then
*     conversion is performed.
*    Invocation :
*     CALL DAT_PUT1L(LOC, NVAL, VALUES; STATUS)
*    Parameters :
*     LOC=CHARACTER*(DAT__SZLOC)
*           Variable containing a locator associated with a primitive
*           data object.
*     NVAL=INTEGER
*           Expression specifying the number of values that are to be
*           written.   This must match the object size.
*     VALUES(NVAL)=LOGICAL
*           Array containing the values to be written into the object.
*     STATUS=INTEGER
*           Variable holding the status value. If this variable is not
*           SAI__OK on input, the routine will return without action.
*           If the routine fails to complete, this variable will be
*           set to an appropriate error number.
*    Method :
*     Use DAT_SIZE and DAT_PUTL.
*     Be careful to conform to Fortran 77 standard, with regard to passing
*     arrays to subprograms.
*    Authors :
*     Jack Giddings (UCL::JRG)
*     Sid Wright (UCL::SLW)
*    History :
*     3-JAN-1983:  Original.  (UCL::JRG)
*     31-Aug-1983:  Standardise.  (UCL::SLW)
*     05.11.1984:   Remove calls to error system (REVAD::BDK)
*     15-APR-1987:  Improved prologue layout (RAL::AJC)
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'DAT_ERR'
*    Import :
      character*(*) loc			! Object Locator
      integer nval			! Number of values to be written
      LOGICAL values(*)			! Vector to supply values
*    Status return :
      integer status			! Status Return
*    Local variables :
      integer ndim
      integer dims(1)
*    Local data :
      data ndim/1/
*-

      if (status .eq. SAI__OK) then
         call dat_size(loc, dims(1), status)
         if (nval .ne. dims(1)) then
            status = DAT__BOUND
         else
            call dat_putL(loc, 1, dims(1), values, status)
         endif
      endif

      end
*+ DAT_PUT1R - Write vector object values
      subroutine dat_put1R(loc, nval, values, status)
*    Description :
*     Write the values into a vector primitive object.
*     There is a routine for each access type,
*
*        DAT_PUT1D    DOUBLE PRECISION
*        DAT_PUT1R    REAL
*        DAT_PUT1I    INTEGER
*        DAT_PUT1L    LOGICAL
*        DAT_PUT1C    CHARACTER[*n]
*
*     If the object data type differs from the access type, then
*     conversion is performed.
*    Invocation :
*     CALL DAT_PUT1R(LOC, NVAL, VALUES; STATUS)
*    Parameters :
*     LOC=CHARACTER*(DAT__SZLOC)
*           Variable containing a locator associated with a primitive
*           data object.
*     NVAL=INTEGER
*           Expression specifying the number of values that are to be
*           written.   This must match the object size.
*     VALUES(NVAL)=REAL
*           Array containing the values to be written into the object.
*     STATUS=INTEGER
*           Variable holding the status value. If this variable is not
*           SAI__OK on input, the routine will return without action.
*           If the routine fails to complete, this variable will be
*           set to an appropriate error number.
*    Method :
*     Use DAT_SIZE and DAT_PUTR.
*     Be careful to conform to Fortran 77 standard, with regard to passing
*     arrays to subprograms.
*    Authors :
*     Jack Giddings (UCL::JRG)
*     Sid Wright (UCL::SLW)
*    History :
*     3-JAN-1983:  Original.  (UCL::JRG)
*     31-Aug-1983:  Standardise.  (UCL::SLW)
*     05.11.1984:   Remove calls to error system (REVAD::BDK)
*     15-APR-1987:  Improved prologue layout (RAL::AJC)
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'DAT_ERR'
*    Import :
      character*(*) loc			! Object Locator
      integer nval			! Number of values to be written
      REAL values(*)			! Vector to supply values
*    Status return :
      integer status			! Status Return
*    Local variables :
      integer ndim
      integer dims(1)
*    Local data :
      data ndim/1/
*-

      if (status .eq. SAI__OK) then
         call dat_size(loc, dims(1), status)
         if (nval .ne. dims(1)) then
            status = DAT__BOUND
         else
            call dat_putR(loc, 1, dims(1), values, status)
         endif
      endif

      end
