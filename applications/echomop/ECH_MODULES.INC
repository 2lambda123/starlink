*  Include file to define the major modules of the ECHOMOP package
*  and their data dependencies.

      INTEGER MAX_NUM_DEFAULTS
      PARAMETER ( MAX_NUM_DEFAULTS = 95 )

      INTEGER MAX_CHAR_DEFAULTS
      PARAMETER ( MAX_CHAR_DEFAULTS = 31 )

      INTEGER MAX_MODULES
      PARAMETER ( MAX_MODULES = 80 )

      INTEGER MAX_REQUIRED_OBJECTS
      PARAMETER ( MAX_REQUIRED_OBJECTS = 400 )

      REAL VALUE_DEFAULTS( 0:MAX_NUM_DEFAULTS )
      REAL VALUE_MAXS( 0:MAX_NUM_DEFAULTS )
      REAL VALUE_MINS( 0:MAX_NUM_DEFAULTS )

      CHARACTER*48 WS_DIMENSIONS( MAX_REQUIRED_OBJECTS )
      CHARACTER*32 REQUIRED_OBJECTS( MAX_REQUIRED_OBJECTS )
      CHARACTER*16 REQUIRED_TYPE( MAX_REQUIRED_OBJECTS )
      CHARACTER*48 MODULE_NAME( MAX_MODULES )
      CHARACTER*32 UNITS_STRINGS( 0: MAX_NUM_DEFAULTS )
      CHARACTER*16 STRING_DEFAULTS( 0: MAX_CHAR_DEFAULTS )
      CHARACTER*48 CURRENT_MODULE

      INTEGER OBJECT_SWITCH( MAX_REQUIRED_OBJECTS )
      INTEGER DEFAULTS_INDICES( MAX_REQUIRED_OBJECTS )
      INTEGER WS_DIMEN_MULT( MAX_REQUIRED_OBJECTS )
      INTEGER CURRENT_MODULE_INDEX

      LOGICAL IN_RDCTN_FILE( MAX_REQUIRED_OBJECTS )
      LOGICAL EXPECT_IN_DATAFILE( MAX_REQUIRED_OBJECTS)
      LOGICAL IS_WORKSPACE( MAX_REQUIRED_OBJECTS )
      LOGICAL FORCE_UPPERCASE( MAX_REQUIRED_OBJECTS )
      LOGICAL BOOLEAN_DEFAULTS( 0:1 )

      BYTE MODULE_PROPERTIES( MAX_REQUIRED_OBJECTS, MAX_MODULES )

*  A default_indices() entry which is negative
*  denotes that the routine ECH_ADAPTIVE_DEFAULTS
*  will be called to set the appropriate values at runtime.
*  The ABS value of the index is used to index the arrays
*  value_defaults,value_maxs,value_mins,units_strings & string_defaults.

      COMMON / MODULE_OBJECTS_TXT / MODULE_NAME,
     :       REQUIRED_OBJECTS, REQUIRED_TYPE,
     :       STRING_DEFAULTS, UNITS_STRINGS,
     :       WS_DIMENSIONS, CURRENT_MODULE

      COMMON / MODULE_OBJECTS_B / MODULE_PROPERTIES

      COMMON / MODULE_OBJECTS_N /
     :       VALUE_DEFAULTS, VALUE_MINS, VALUE_MAXS

      COMMON / MODULE_OBJECTS_I /
     :       DEFAULTS_INDICES, OBJECT_SWITCH, WS_DIMEN_MULT,
     :       CURRENT_MODULE_INDEX

      COMMON / MODULE_OBJECTS_L /
     :       BOOLEAN_DEFAULTS, IN_RDCTN_FILE,
     :       IS_WORKSPACE, EXPECT_IN_DATAFILE,
     :       FORCE_UPPERCASE
