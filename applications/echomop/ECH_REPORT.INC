*  This include file contains the parameters and variables used by
*  the ECH_REPORT routine.

      INTEGER REPORT_MODE

      INTEGER RPM_NONE
      PARAMETER	( RPM_NONE = 0 )

      INTEGER RPM_FULL
      PARAMETER	( RPM_FULL = 1 )

      INTEGER RPM_LOG
      PARAMETER	( RPM_LOG = 2 )

      INTEGER RPM_NOPAGE
      PARAMETER	( RPM_NOPAGE = 4 )

      INTEGER RPM_OPER
      PARAMETER	( RPM_OPER = 8 )

      INTEGER RPM_HISTORY
      PARAMETER	( RPM_HISTORY = 16 )

      INTEGER RPM_CALLS
      PARAMETER	( RPM_CALLS = 32 )

      INTEGER RPM_INFO
      PARAMETER	( RPM_INFO = 64 )

      INTEGER RPM_WARN
      PARAMETER	( RPM_WARN = 128 )

      INTEGER RPM_ERROR
      PARAMETER	( RPM_ERROR = 256 )

*
      INTEGER RPM_LINE
      INTEGER RPM_LINE_INDEX

      INTEGER RPM_LINDEX_SIZE
      PARAMETER ( RPM_LINDEX_SIZE = 240 )

*
      INTEGER ECH__IS_ACCESSED
      PARAMETER ( ECH__IS_ACCESSED = -1 )

      INTEGER ECH__IS_INTERNAL
      PARAMETER ( ECH__IS_INTERNAL = -2 )

      INTEGER ECH__PAR_ACCESSED
      PARAMETER ( ECH__PAR_ACCESSED = -3 )

      INTEGER ECH__NEED_RDCOBJ
      PARAMETER ( ECH__NEED_RDCOBJ = -4 )

      INTEGER ECH__BAD_VMEMORY
      PARAMETER ( ECH__BAD_VMEMORY = -5 )

      INTEGER ECH__DIM_CONFLICT
      PARAMETER ( ECH__DIM_CONFLICT = -6 )

      INTEGER ECH__ABORT_OPTION
      PARAMETER ( ECH__ABORT_OPTION = -7 )

      INTEGER ECH__ABORT_INIT
      PARAMETER ( ECH__ABORT_INIT = -7 )

      INTEGER ECH__CANT_CREATE
      PARAMETER ( ECH__CANT_CREATE = -8 )

      INTEGER ECH__CANT_UPDATE
      PARAMETER ( ECH__CANT_UPDATE = -9 )

      INTEGER ECH__NOCR_ACCESS
      PARAMETER ( ECH__NOCR_ACCESS = -10 )

      INTEGER ECH__NO_CLONE
      PARAMETER ( ECH__NO_CLONE = -11 )

      INTEGER ECH__NO_ARCSRC
      PARAMETER ( ECH__NO_ARCSRC = -12 )

      INTEGER ECH__NO_WAVEFIT
      PARAMETER ( ECH__NO_WAVEFIT = -13 )

      INTEGER ECH__BAD_ORDERNUM
      PARAMETER ( ECH__BAD_ORDERNUM = -14 )

*
      INTEGER ECH__CRE_RDCTN
      PARAMETER ( ECH__CRE_RDCTN = 1 )

      INTEGER ECH__ATV_OBJ
      PARAMETER ( ECH__ATV_OBJ = 2 )

      INTEGER ECH__MAP_OBJ
      PARAMETER ( ECH__MAP_OBJ = 3 )

      INTEGER ECH__NO_PATH
      PARAMETER ( ECH__NO_PATH = 4 )

      INTEGER ECH__GOT_DIM
      PARAMETER ( ECH__GOT_DIM = 5 )

      INTEGER ECH__NEED_ROT
      PARAMETER ( ECH__NEED_ROT = 6 )

      INTEGER ECH__BAD_XDIM
      PARAMETER ( ECH__BAD_XDIM = 7 )

      INTEGER ECH__BAD_YDIM
      PARAMETER ( ECH__BAD_YDIM = 8 )

      INTEGER ECH__NO_MOD
      PARAMETER ( ECH__NO_MOD = 9 )

      INTEGER ECH__NO_OBJ
      PARAMETER ( ECH__NO_OBJ = 10 )

      INTEGER ECH__OBJ_UNINIT
      PARAMETER ( ECH__OBJ_UNINIT = 11 )

      INTEGER ECH__TXT_INFO
      PARAMETER ( ECH__TXT_INFO = 16 )

      INTEGER ECH__ATV_WSOBJ
      PARAMETER ( ECH__ATV_WSOBJ = 12 )

      INTEGER ECH__MAP_WSOBJ
      PARAMETER ( ECH__MAP_WSOBJ = 13 )

      INTEGER ECH__FRE_WSOBJ
      PARAMETER ( ECH__FRE_WSOBJ = 14 )

      INTEGER ECH__NO_ORDERS
      PARAMETER ( ECH__NO_ORDERS = 17 )

      INTEGER ECH__NO_TRACEWID
      PARAMETER ( ECH__NO_TRACEWID = 18 )

      INTEGER ECH__NO_DATA
      PARAMETER ( ECH__NO_DATA = 19 )

      INTEGER ECH__NO_CENTRE
      PARAMETER ( ECH__NO_CENTRE = 20 )

      INTEGER ECH__TRC_LOST
      PARAMETER ( ECH__TRC_LOST = 21 )

      INTEGER ECH__CRE_OBJECT
      PARAMETER ( ECH__CRE_OBJECT = 22 )

      INTEGER ECH__BAD_TRACE
      PARAMETER ( ECH__BAD_TRACE = 23 )

      INTEGER ECH__GOOD_TRACE
      PARAMETER ( ECH__GOOD_TRACE = 24 )

      INTEGER ECH__NO_SLOPE
      PARAMETER ( ECH__NO_SLOPE = 25 )

      INTEGER ECH__RETRY_ACCESS
      PARAMETER ( ECH__RETRY_ACCESS = 26 )

      INTEGER ECH__WORKSPACE_PAR
      PARAMETER ( ECH__WORKSPACE_PAR = 27 )

      INTEGER ECH__BAD_USERPAR
      PARAMETER ( ECH__BAD_USERPAR = 28 )

      INTEGER ECH__BAD_FTRREAD
      PARAMETER ( ECH__BAD_FTRREAD = 30 )

      INTEGER ECH__BAD_FTRWRITE
      PARAMETER ( ECH__BAD_FTRWRITE = 31 )

      INTEGER ECH__META_NOSOLUTION
      PARAMETER ( ECH__META_NOSOLUTION = 32 )

      INTEGER ECH__IDORD_REJECTED
      PARAMETER ( ECH__IDORD_REJECTED = 33 )

      INTEGER ECH__IDORD_TOOFEW
      PARAMETER ( ECH__IDORD_TOOFEW = 34 )

      INTEGER ECH__BAD_DBCREATE
      PARAMETER ( ECH__BAD_DBCREATE = 35 )

      INTEGER ECH__META_OUTSPACE
      PARAMETER ( ECH__META_OUTSPACE = 36 )

      INTEGER ECH__META_TOOMANY
      PARAMETER ( ECH__META_TOOMANY = 37 )

      INTEGER ECH__SAVE_WFIT
      PARAMETER ( ECH__SAVE_WFIT = 39 )

      INTEGER ECH__QUIT_WFIT
      PARAMETER ( ECH__QUIT_WFIT = 40 )

      INTEGER ECH__RETRY_WFIT
      PARAMETER ( ECH__RETRY_WFIT = 41 )

      INTEGER ECH__ID_MANUAL
      PARAMETER ( ECH__ID_MANUAL = 42 )

      INTEGER ECH__AUTO_IDENTIFY
      PARAMETER ( ECH__AUTO_IDENTIFY = 43 )

      INTEGER ECH__PCHAR_ARRAY
      PARAMETER ( ECH__PCHAR_ARRAY = 44 )

      INTEGER ECH__ARRAY_INDEX
      PARAMETER ( ECH__ARRAY_INDEX = 45 )

      INTEGER ECH__NDF_NOID
      PARAMETER ( ECH__NDF_NOID = 46 )

      INTEGER ECH__WORKSPACE_ARRAY
      PARAMETER ( ECH__WORKSPACE_ARRAY = 47 )

      INTEGER ECH__IMAGE_LIST
      PARAMETER ( ECH__IMAGE_LIST = 48 )

      INTEGER ECH__ID_DONE
      PARAMETER ( ECH__ID_DONE = 49 )

      INTEGER ECH__CLIENT_ACTIVE
      PARAMETER ( ECH__CLIENT_ACTIVE = 50 )

      INTEGER ECH__SERVER_ACTIVE
      PARAMETER ( ECH__SERVER_ACTIVE = 51 )

      INTEGER ECH__NEXT_FITTER
      PARAMETER ( ECH__NEXT_FITTER = 52 )

      INTEGER ECH__INC_NUMCOEFF
      PARAMETER ( ECH__INC_NUMCOEFF = 53 )

      INTEGER ECH__DEC_NUMCOEFF
      PARAMETER ( ECH__DEC_NUMCOEFF = 54 )

      INTEGER ECH__IMG_SHORT
      PARAMETER ( ECH__IMG_SHORT = 55 )

      INTEGER ECH__SUPRESS_ERRORS
      PARAMETER ( ECH__SUPRESS_ERRORS = 56 )

*
      LOGICAL DIAGNOSTICS_ACTIVE
      INTEGER DIAGNOSTICS_MODE
      INTEGER DIAGNOSTICS_LUN

      CHARACTER*96 REPORT_STRING
      CHARACTER*80 RPM_BUFFER ( RPM_LINDEX_SIZE )

      CHARACTER*80 ECH__MOD_ENTRY
      PARAMETER ( ECH__MOD_ENTRY = 'Module entry' )

      COMMON / ECH_REPORT_BLK /	REPORT_MODE,
     :                          DIAGNOSTICS_ACTIVE,
     :                          DIAGNOSTICS_MODE,
     :                          DIAGNOSTICS_LUN,
     :                          RPM_LINE,
     :                          RPM_LINE_INDEX

      COMMON / ECH_REPORT_TXT / REPORT_STRING,
     :                          RPM_BUFFER
