#+
#  Name:
#     GaiaVOCatCone

#  Type of Module:
#     [incr Tcl] class

#  Purpose:
#     Query a Cone Search server for a catalogue.

#  Description:
#     Extends the GaiaVOCat class to query a given Cone Search server for 
#     any objects it contains in a given region of sky. The objects are
#     described as a row in a catalogue.

#  Invocations:
#
#        GaiaVOCatCone object_name [configuration options]
#
#     This creates an instance of a GaiaVOCatCone object. The return is
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

#  Copyright:
#     Copyright (C) 2009 Science and Technology Facilities Council
#     All Rights Reserved.

#  Licence:
#     This program is free software; you can redistribute it and/or
#     modify it under the terms of the GNU General Public License as
#     published by the Free Software Foundation; either version 2 of the
#     License, or (at your option) any later version.
#
#     This program is distributed in the hope that it will be
#     useful, but WITHOUT ANY WARRANTY; without even the implied warranty
#     of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
#     02111-1307, USA

#  Authors:
#     PWD: Peter Draper (JAC, Durham University)
#     {enter_new_authors_here}

#  History:
#     13-JAN-2009 (PWD):
#        Original version.
#     {enter_further_changes_here}

#-

#.

itk::usual GaiaVOCatCone {}

itcl::class gaiavo::GaiaVOCatCone {

   #  Inheritances:
   #  -------------
   inherit gaiavo::GaiaVOCat

   #  Constructor:
   #  ------------
   constructor {args} {
      eval itk_initialize $args
   }

   #  Destructor:
   #  -----------
   destructor {
   }

   #  Methods:
   #  --------

   #  Add additional menu items. Nameserver.
   public method init {} {
      GaiaVOCat::init

      #  Override title.
      wm title $w_ "Query VO Cone Search server"

      set m [add_menubutton Options "Options menu"]

      #  Change the plot symbols.
      add_menuitem $m command "Set plot symbols..." \
         {Set the symbol (color, size, etc.) to use to plot objects} \
         -command [code $this set_plot_symbols]

      #  Add the standard name servers.
      set ns_menu [menu $m.ns]
      add_menuitem $m cascade "Set Name Server" \
         {Select the name server used to resolve astronomical object names} \
         -menu $ns_menu

      if { [catch {set list [$w_.cat info namesvr]} msg] } {
         error_dialog $msg $w_
         return
      }

      foreach namesvr $list {
         $ns_menu add radiobutton \
            -label $namesvr \
            -command [code $this set_namesvr $namesvr] \
            -variable [scope itk_option(-namesvr)]
      }

      if { ![info exists namesvr] } {
         error_dialog "No default name server found for astronomical objects"
         return
      }

      #  And set the default name server.
      set_namesvr $namesvr

      #  Plot symbols button. XXX position this to the left.
      itk_component add plot {
         button $itk_component(buttons).plot \
            -text "Plot" \
            -command [code $this plot]
      }
      pack $itk_component(plot) -side left -expand 1 -pady 2m
      add_short_help $itk_component(plot) {Plot positions over image}

      #  Set names for the canvas tags used for all symbols. This defined
      #  in the imgplot command.
      set tag_ $w_.cat
      set object_tag_ $tag_.objects
      set label_tag_ $tag_.labels

      #  Add bindings for symbols.
      $canvas_ bind $object_tag_  <1> [code $this select_symbol current 0]
      $canvas_ bind $object_tag_  <Shift-1> \
                                  [code $this select_symbol current 1]
      $canvas_ bind $object_tag_  <Control-1> \
                                  [code $this select_symbol current 1]
      $canvas_ bind $object_tag_  <Any-Enter> "$canvas_ config -cursor tcross"
      $canvas_ bind $object_tag_  <Any-Leave> "$draw_ reset_cursor"

      #  Button release selects symbols for selected rows.
      bind $itk_component(results).listbox <ButtonRelease-1> \
         [code $this select_result_row]
   }

   #  Set the name server used, pass to other components.
   public method set_namesvr {name} {
      configure -namesvr $name
      if { [info exists itk_component(cone)] } {
         $itk_component(cone) configure -namesvr $name
      } else {
         puts "skipped component(cone)"
      }
   }

   #  Add the component that will control the query.
   protected method add_query_component_ {} {

      itk_component add cone {
         gaiavo::GaiaVOConeSearch $w_.cone \
            -accessURL $itk_option(-accessURL) \
            -shortname $itk_option(-shortname) \
            -feedbackcommand  [code $this set_feedback] \
            -astrocat [code $w_.cat] \
            -command [code $this query_done] \
            -namesvr $itk_option(-namesvr) \
            -gaiactrl [$itk_option(-gaia) get_image]
      }
      pack $itk_component(cone) -side top -fill x
      add_short_help $itk_component(cone) \
         {Controls for querying Cone Search server}

      set query_component_ $itk_component(cone)
   }

   #  New catalogue, set default plot symbol.
   public method query_done {status result} {
      GaiaVOCat::query_done $status $result
      set_default_plot_symbol_
   }

   #  Open a service, "args" is a list of values from a row of the current
   #  table. 
   protected method open_service_ {args} {
      # XXX what to do with this? Offer extended view of the row?
      puts "nothing done with open_service_"
   }

   #  Extract the accessURL for the Cone Search service from a list of headers
   #  and the associated data row.
   public proc getAccessURL {headers row} {
      eval lassign "$row" $headers
      if { [info exists accessURL] } {
         return $accessURL
      }
      return {}
   }

   #  Extract a name for Cone Search service from a list of headers
   #  and the associated data row.
   public proc getName {headers row} {
      eval lassign "$row" $headers
      if { [info exists shortName] && $shortName != {} } {
         return $shortName
      }
      if { [info exists title] } {
         return $title
      }
      return {}
   }

   #  Plot the RA and Dec positions on the image using the defined symbols.
   public method plot {} {

      #  Clear any existing positions.
      clear_plot

      #  Do the plot.
      if {[catch {$w_.cat imgplot $rtdimage_ $info_ $equinox_ $headings_} msg]} {
         error_dialog $msg
      }
   }

   #  Clear the plot of any existing symbols.
   public method clear_plot {} {
      catch {$canvas_ delete $tag_}
   }

   #  Set the catalogue plotting symbol to the default.
   protected method set_default_plot_symbol_ {} {
      set symbol [list {} [list circle red {} {} {} {}] [list {4.0} {}]]
      $w_.cat symbol $symbol
   }

   #  Pop up a dialog to set the plot symbols to use for this catalogue.
   public method set_plot_symbols {} {
      set columns $headings_
      if {[llength $columns] == 0} {
         info_dialog \
            "Please make a query first so that the column names are known" $w_
         return
      }
      utilReUseWidget cat::SymbolConfig $w_.symconf \
         -catalog $itk_option(-catalog) \
         -astrocat [code $w_.cat] \
         -columns $columns \
         -command [code $this plot]
   }

   #  Select a symbol, given the canvas id and optional row number 
   #  in the table listing. If $toggle is 0, deselect all other symbols 
   #  first, otherwise toggle the selection of the items given by $id.
   public method select_symbol {id toggle {rownum -1}} {
      set tag [lindex [$canvas_ gettags $id] 0]

      if {$rownum < 0} {
         set rownum [get_table_row $id]
         if {$rownum < 0} {
            return
         }
      }
        
      if {$toggle} {
         if {[$draw_ item_has_tag $tag $w_.selected]} {
            deselect_symbol $tag
            $itk_component(results) deselect_row $rownum
            return
         } 
      } else {
         deselect_symbol $w_.selected
      }

      if {"$rownum" >= 0} {
         $itk_component(results) select_row $rownum [expr !$toggle]
         $itk_component(results) select_result_row
      }
      
      foreach i [$canvas_ find withtag $tag] {
         set width [$canvas_ itemcget $i -width]
         $canvas_ itemconfig $i -width [expr $width+2]
      }
      $canvas_ addtag $w_.selected withtag $tag
      $canvas_ raise $tag $rtdimage_
   }

   #  Return the table row index corresponding the given symbol canvas id.
   #  Note: The imgplot subcommand adds a canvas tag "row#$rownum" that we can
   #  use here.  Also: cat$id is first tag in the tag list for each object.
   public method get_table_row {id} {

      set tags [$canvas_ gettags $id]
      #  Look for row#tag (but only if not sorted!)
      if {[llength [$w_.cat sortcols]] == 0} {
         foreach tag $tags {
            if {[scan $tag "row#%d" rownum] == 1} {
               return $rownum
            }
         }
      }

      #  Search for $id in query results (slow way).
      set tag [lindex $tags 0]
      set rownum -1
      foreach row [$itk_component(results) get_contents] {
         incr rownum
         set id [lindex $row [$w_.cat id_col]]
         if { "cat$id" == "$tag" } {
            return $rownum
         }
      }

      #  Not found.
      return -1
   }

   #  Deselect the given symbol, given its canvas tag or id.
   public method deselect_symbol {tag} {
      foreach i [$canvas_ find withtag $tag] {
         set width [$canvas_ itemcget $i -width]
         $canvas_ itemconfig $i -width [expr $width-2]
      }
      $canvas_ dtag $tag $w_.selected
   }

   #  Called when a row in the table is selected.
   protected method select_result_row {} {
      $itk_component(results) select_result_row

      #  Clear symbol selection
      deselect_symbol $w_.selected

      #  Select symbols matching selected rows
      foreach row [$itk_component(results) get_selected_with_rownum] {
         lassign $row rownum row
         set id [lindex $row [$w_.cat id_col]]
         if {"$id" == ""} {
            continue
         }
         select_symbol cat$id 1 $rownum
      }
   }

   #  Configuration options: (public variables)
   #  ----------------------

   #  The shortname of the service.
   itk_option define -shortname shortname ShortName {}

   #  The accessURL for the Cone Search server.
   itk_option define -accessURL accessURL AccessURL {}

   #  Instance of GAIA to display the catalogue.
   itk_option define -gaia gaia Gaia {} {
      set rtdctrl_ [$itk_option(-gaia) get_image]
      set rtdimage_ [$rtdctrl_ get_image]
      set canvas_ [$rtdctrl_ get_canvas]
      set draw_ [$rtdctrl_ component draw]
   }

   #  The name server.
   itk_option define -namesvr namesvr NameSvr {}

   #  Protected variables: (available to instance)
   #  --------------------

   #  Various elements from the GAIA instance.
   protected variable rtdctrl_ {}
   protected variable rtdimage_ {}
   protected variable canvas_ {}
   protected variable draw_ {}

   #  Equinox for VO catalogues. Really ICRS but J2000 (=FK5/J2000).
   protected variable equinox_ "J2000"

   #  Various tags associated with the positions when plotted. These
   #  are defined by imgplot method.
   protected variable tag_ {}
   protected variable object_tag_ {}
   protected variable label_tag_ {}

   #  Common variables: (shared by all instances)
   #  -----------------

}
