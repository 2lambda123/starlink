#+
#  Name:
#     AstColours

#  Type of Module:
#     [incr Tcl] class

#  Purpose:
#     Static class for locating and querying AST colours.

#  Description:
#     This is a static class that offers access to the names and
#     indices of the "standard" AST colours and allows this set to be
#     globally extended (that is over the complete application) by
#     adding new colours with specified indices (these may not
#     overwrite the standard set).

#  Invocations:
#
#        AstColours object_name [configuration options]
#
#     This creates an instance of a AstColours object. The return is
#     the name of the object.
#
#        object_name configure -configuration_options value
#
#     Applies any of the configuration options (after the instance has
#     been created).
#
#        object_name method arguments
#
#     Performs the given method on this object.

#  Configuration options:

#  Methods:

#  Inheritance:
#     This object inherits no other classes.

#  Authors:
#     PWD: Peter Draper (STARLINK - Durham University)
#     {enter_new_authors_here}

#  History:
#     05-APR-2001 (PWD):
#        Original version.
#     {enter_further_changes_here}

#-

#.

itcl::class gaia::AstColours {

   #  Inheritances:
   #  -------------

   #  Nothing

   #  Constructor:
   #  ------------
   private constructor {menu args} {
   }

   #  Destructor:
   #  -----------
   private destructor  {
   }
   
   #  Procs:
   #  ------

   #  Return the number of standard colours.
   public proc standard_count {} {
      return $standard_count_
   }

   #  Add a new colour. Ignored if an attempt to overwrite a standard
   #  colour is made. Set index to -1 for automatic chosing of index
   #  (this is returned). The image argument should be any rtdimage
   #  available. Maximum colour index is 63 (i.e. 64 colours).
   public proc add_custom_colour {image index colour} {
      if { $index == -1 } { 
         set index $count_
      }
      if { $index > 63 } {
         set index 63
      }
      if { $index >= $standard_count_ } {
         set colours_($index) $colour
         set indices_($colour) $index
         
         #  If have an rtdimage then need to add this colour.
         if { $image != {} } {
            $image astaddcolour $index $colour
         }

         #  If index is outside of current colour range then make this
         #  the top value.
         if { $index >= $count_ } {
            set count_ [expr $index + 1]
         }
      }
      return $index
   }

   #  Lookup a colour by its index value. Returns first colour
   # (white), if unknown.
   public proc lookup_colour {index} {
      if { $index < $count_ && [info exists colours_($index)] } {
         return $colours_($index)
      }
      return $colours_(0)
   }

   #  Lookup an index by its colour. Returns 0, if unknown.
   public proc lookup_index {colour} {
      if { [info exists indices_($colour)] } {
         return $indices_($colour)
      }
      return 0
   }

   #  Return a description of any custom colours. This is a list of
   #  index versus colour pairs and can be restored using the
   #  complementary procedure restore_custom.
   public proc describe_custom {} {
      set result ""
      if { $count_ > $standard_count_ } {
         for {set i $standard_count_} {$i < $count_} {incr i} {
            append result "$i $colours_($i) "
         }
      }
      return $result
   }

   #  Restore a set of custom colours. This is a list of index versus
   #  colour pairs probably created by the describe_custom procedure.
   #  The image is any rtdimage reference.
   public proc restore_custom {image spec} {
      if { $spec != {} } {
         foreach {index colour} "$spec" {
            add_custom_colour $image $index $colour
         }
      }
   }

   #  Common variables:
   #  -----------------

   #  The available colours and their indices.
   common colours_

   #  The available indices and their colours.
   common indices_

   #  Add the "standard" colours and the inverse indices mapping.
   set colours_(0) "\#fff"
   set colours_(1) "\#000"
   set colours_(2) "\#f00"
   set colours_(3) "\#0f0"
   set colours_(4) "\#00f"
   set colours_(5) "\#0ff"
   set colours_(6) "\#f0f"
   set colours_(7) "\#ff0"
   set colours_(8) "\#f80"
   set colours_(9) "\#8f0"
   set colours_(10) "\#0f8"
   set colours_(11) "\#08f"
   set colours_(12) "\#80f"
   set colours_(13) "\#f08"
   set colours_(14) "\#512751275127"
   set colours_(15) "\#a8b4a8b4a8b4"

   set indices_(\#fff) 0
   set indices_(\#000) 1
   set indices_(\#f00) 2
   set indices_(\#0f0) 3
   set indices_(\#00f) 4
   set indices_(\#0ff) 5
   set indices_(\#f0f) 6
   set indices_(\#ff0) 7
   set indices_(\#f80) 8
   set indices_(\#8f0) 9
   set indices_(\#0f8) 10
   set indices_(\#08f) 11
   set indices_(\#80f) 12
   set indices_(\#f08) 13
   set indices_(\#512751275127) 14
   set indices_(\#a8b4a8b4a8b4) 15

   #  Highest count of colour indices.
   common count_ 16

   #  Number of standard colours available.
   common standard_count_ 16
}
