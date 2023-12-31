      SUBROUTINE {ROUTINE_NAME}( PSID, HINT, DATA, STATUS )
*+
*  Name:
*     {ROUTINE_NAME}

*  Purpose:
*     {routine_purpose}

*  Language:
*     {routine_language}

*  Invocation:
*     CALL {ROUTINE_NAME}( PSID, HINT, DATA, STATUS )

*  Description:
*     Returns psf hint value, otherwise raises an error

*  Arguments:
*     PSID = INTEGER (given)
*        ADI identifier of psf storage object
*     HINT = CHARACTER*(*) (given)
*        Hint name
*     DATA[] = BYTE (returned)
*        Hint data bytes. Number set depends on hint
*     STATUS = INTEGER (given and returned)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  Pitfalls:
*     {pitfall_description}...

*  Notes:
*     {routine_notes}...

*  Prior Requirements:
*     {routine_prior_requirements}...

*  Side Effects:
*     {routine_side_effects}...

*  Algorithm:
*     {algorithm_description}...

*  Accuracy:
*     {routine_accuracy}

*  Timing:
*     {routine_timing}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     {routine_references}...

*  Keywords:
*     {routine_keywords}...

*  Copyright:
*     Copyright (C) University of Birmingham, {year}

*  Authors:
*     {author_identifier}: {authors_name} ({affiliation})
*     {enter_new_authors_here}

*  History:
*     {date} ({author_identifier}):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE '{global_constants_file}' ! [global_constants_description]

*  Global Variables:
      INCLUDE '{global_variables_file}' ! [global_variables_description]
*        {global_name}[dimensions] = {data_type} ({global_access_mode})
*           [global_variable_purpose]

*  Arguments Given:
      INTEGER                   PSID
      CHARACTER*(*)		HINT

*  Arguments Returned:
      BYTE			DATA(*)

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      [external_declaration]
      {data_type} {external_name} ! [external_description]

*  Local Constants:
      {data_type} {constant_name} ! [constant_description]
      PARAMETER ( {constant_name} = {cons} )

*  Local Variables:
      {data_type} {name}[dimensions] ! [local_variable_description]

*  Internal References:
      {data_type} {internal_name} ! [internal_description]
      [internal_definition_statement]...

*  Local Data:
      DATA {data_elm} / {data_values}... /
      [data_stmt]...

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) THEN
        CALL AST_REXIT( '{ROUTINE_NAME}', STATUS )
      END IF

      END
