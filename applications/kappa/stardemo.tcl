#!/star/bin/awish
#+
#  Name:
#     stardemo.tcl
#
#  Purpose:
#     The main stardemo tcl script.
#
#  Invocation:
#     stardemo.tcl [demo] [-dir <demo_dir>] [-(no)paging] [-(no)loop]
#                         [-(no)net] [-debug]
#
#  Command Line Arguments:
#     demo: An optional name of a demonstration to be selected and run
#     automatically. If no demo name is given on the command line, all 
#     the demonstrations in the specified demo directory will be loaded 
#     and selected, but they will not be run until the "Run" button in 
#     the GUI is pressed.
#
#     -dir <demo_dir>: An optional argument giving the directory to be 
#     searched for demo scripts. If not supplied, $KAPPA_DIR is used.
#   
#     -paging: If specified, causes each step in the demo commentary to
#     be displayed until a key or mouse button is pressed. If -nopage
#     is specified, the page is displayed for a fixed time before
#     continuing automatically. Default is "-nopage".
#
#     -loop: If specified, causes the selected demonstrations to be
#     re-run immediately as soon as the last one finishes. If -noloop
#     is specified, the system becomes idle when the final demo 
#     completes, until the "Run" button is pressed. Default is "-loop".
#
#     -nonet: If specified, clicking on a text representing a remote url 
#     will not cause a web browser to be created to view the url. Use
#     this option if there is no access to the net. Access to the net is
#     assumed to be available by default.
#
#     -debug: If specified, messages are displayed on standard output
#     giving various diagnostics. This is intended to help debug demo scripts.
#
#  Copyright:
#     Copyright (C) 1999 Central Laboratory of the Research Councils
#
#  Authors:
#     DSB: David S. Berry (STARLINK)
#
#  History: 
#     22-OCT-1999 (DSB):
#        Original version.
#-

#rename proc tclproc
#tclproc proc {name args body} {
#   set newbody "puts \"Entering $name\""
#   append newbody $body
#   tclproc $name $args $newbody
#}


# Get the process id for the current process.
   set PID [pid]

# Initialise stardemo global constants.
   set BACKCOL "#c0c0c0"
   set MENUBACK "#b0b0b0"
   set WHITEBACK "#e0e0b0"
   set GWM_NAME "stardemo_$PID"
   set COLOURS 64
   set DEVICE "xw;stardemo_$PID"
   set GWMWIDTH 0.9
   set GWMHEIGHT 0.7

# Initialise stardemo global variables.
   set ABORT_DEMO 0 
   set ADAM_ERRORS ""
   set ADAM_TASKS ""
   set ATASK 0
   set ATASK_OUTPUT ""
   set BADCOL "cyan"
   set CANCEL_OP 0
   set COM ""
   set CHECK_DEMO 0
   set DEMO_INFO ""
   set DOING ""
   set ENV_VARS ""
   set F3 ""
   set F4 ""
   set HAREA 1 
   set HELP ""
   set HLAB ""
   set LINKCOL darkblue
   set IFILE 0
   set IFILE_STACK ""
   set LOGFILE_ID ""
   set LOGSPEED 0.0
   set LOOPING 1
   set NET 1
   set PACKAGE ""
   set PACKAGE_TITLE "\nStarlink\n"
   set SUN ""
   set PACKAGE_DESCRIPTION ""
   set PACKAGE_VERSION ""
   set PACKAGE_EMAIL ""
   set PACKAGE_URL ""
   set PAGING 0 
   set PAUSE_DEMO 0 
   set RUNNING_DEMO "<idle>"
   set SELECTED_DEMOS ""
   set SEQ_STOP ""
   set STOP_BLINK ""

# Get the KAPPA directory.
   if { [info exists env(KAPPA_DIR)] } {
      set KAPPA_DIR $env(KAPPA_DIR)
   } {
      set KAPPA_DIR /star/bin/kappa
   }

# At the moment, assume that the stardemo files are in KAPPA_DIR.
   set STARDEMO_DIR $KAPPA_DIR

#  Get the demo directory, and the demo to be run, from the comamnd line.
   set demodir $STARDEMO_DIR
   set autorun ""
   set LOOPING 1
   set PAGING 0
   set DEBUG 0

   set userr 0

   for {set i 0} { $i < $argc } {incr i} {
      set arg [lindex $argv $i]

      if { $arg == "-dir" } {
         incr i
         if { $i == $argc } {
            puts "No directory specified for -dir option."
            set userr 1         
         } {
            set demodir [lindex $argv $i]
            if { ![file isdirectory $demodir] } {
               puts "No such directory: \"$demodir\""
               set userr 1
            }
         }

      } elseif { $arg == "-debug" } {
         set DEBUG 1

      } elseif { $arg == "-paging" } {
         set PAGING 1

      } elseif { $arg == "-nopaging" } {
         set PAGING 0

      } elseif { $arg == "-loop" } {
         set LOOPING 1 

      } elseif { $arg == "-noloop" } {
         set LOOPING 0

      } elseif { $arg == "-net" } {
         set NET 1 

      } elseif { $arg == "-nonet" } {
         set NET 0

      } elseif { $autorun == "" } {
         set autorun $arg

      } { 
         puts "Unknown option \"$arg\"."
         set userr 1
      }

      if { $userr } { break }

   }

   if { $userr } { 
      puts {Usage: stardemo [demo] [-dir <demo_dir>] [-(no)paging] [-(no)loop]}
      exit
   }

#  Name this application (for xresources etc.)
   tk appname stardemo

# Rename the "exit" command so that it calls a procedure which cleans up,
# and then calls the built-in shut-down commands. This new exit command is 
# called even if an exceptional exit occurs.
   rename exit tcl_exit

# Define the procedures which form part of the stardemo application.
   source $STARDEMO_DIR/dialog.tcl
   source $STARDEMO_DIR/stardemo_procs.tcl

# Quit when control-c or Q is pressed.
   bind . <Control-c> {Finish 0}
   bind . <q> {Finish 0}
   bind . <Q> {Finish 0}

# Get the pixels per inch on the screen.
   set dpi [winfo fpixels . "1i"]

# Create the required fonts.

# The font command is only available in tk/tcl v8
#   set BIG_FONT [font create -weight bold -slant italic -size 18]
#   set FONT [font create -weight bold -slant roman -size 14]
#   set COM_FONT [font create -weight bold -slant roman -size 18]
#   set HLP_FONT [font create -weight medium -slant roman -size 12]
#   set B_FONT [font create -weight bold -slant roman -size 12]
#   set RB_FONT [font create -weight medium -slant roman -size 12]
#   set S_BFONT [font create -weight bold -slant roman -size 12]
#   set S_FONT [font create -weight medium -slant roman -size 12]
#   set IT_FONT [font create -weight bold -slant italic -size 18]
#   set TT_FONT [font create -family helvetica -weight medium -slant roman -size 14]



   set px180 [expr round( ( 18.0 * $dpi ) / 88.0 ) ]   
   set px140 [expr round( ( 14.0 * $dpi ) / 88.0 ) ]   
   set px120 [expr round( ( 12.0 * $dpi ) / 88.0 ) ]   
   set px100 [expr round( ( 10.0 * $dpi ) / 88.0 ) ]   

   set BIG_FONT [SelectFont "-*-times-bold-i-*-*-$px180-*-*-*-*-*-*-*"]
   set FONT [SelectFont "-*-*-bold-r-*-*-$px140-*-*-*-*-*-*-*"]
   set COM_FONT [SelectFont "-*-times-bold-r-*-*-$px180-*-*-*-*-*-*-*"]
   set HLP_FONT [SelectFont "-*-*-medium-r-*-*-$px120-*-*-*-*-*-*-*"]
   set B_FONT [SelectFont "-*-*-bold-r-*-*-$px120-*-*-*-*-*-*-*"]
   set RB_FONT [SelectFont "-*-*-medium-r-*-*-$px120-*-*-*-*-*-*-*"]
   set S_BFONT [SelectFont "-*-*-bold-r-*-*-$px120-*-*-*-*-*-*-*"]
   set S_FONT [SelectFont "-*-*-medium-r-*-*-$px120-*-*-*-*-*-*-*"]
   set IT_FONT [SelectFont "-*-times-bold-i-*-*-$px180-*-*-*-*-*-*-*"]
   set TT_FONT [SelectFont "-*-helvetica-medium-r-*-*-$px140-*-*-*-*-*-*-*"]
   set BTT_FONT [SelectFont "-*-helvetica-bold-r-*-*-$px180-*-*-*-*-*-*-*"]

# Try to stop problems with the AMS (ADAM Message System) rendevous files 
# by creating a new directory as ADAM_USER.
   if { [info exists env(ADAM_USER)] } {
      set OLD_ADAM_USER $env(ADAM_USER)
      set ADAM_USER "$OLD_ADAM_USER/stardemo_[pid]"
   } {
      set OLD_ADAM_USER ""
      set ADAM_USER "$env(HOME)/adam/stardemo_[pid]"
   }
   set env(ADAM_USER) $ADAM_USER

# Make sure this new directory exists (delete any existing version).
   if { [file exists $ADAM_USER] } {
      catch {exec rm -r -f $ADAM_USER}
   }
   catch {exec mkdir -p $ADAM_USER}

# Avoid messing up the main AGI database by using a new AGI database.
# Create it in the ADAM_USER directory created above.
   if { [info exists env(AGI_USER)] } {
      set OLD_AGI_USER $env(AGI_USER)
   } {
      set OLD_AGI_USER ""
   }
   set env(AGI_USER) $ADAM_USER


#  Create a directory in which stardemo can keep the temporary files it
#  creates. This directory will be deleted on exit. Try to put it in
#  HDS_SCRATCH, if defined, and in the current directory otherwise.
   if { [info exists env(HDS_SCRATCH)] } {
      set dir $env(HDS_SCRATCH)
   } {
      set dir [pwd]
   }
   set STARDEMO_SCRATCH "$dir/stardemo_temp_[pid]"

# Make sure this new directory exists (delete any existing version).
   if { [file exists $STARDEMO_SCRATCH] } {
      catch {exec rm -r -f $STARDEMO_SCRATCH}
   }
   catch {exec mkdir -p $STARDEMO_SCRATCH}

# Record the process id's of any existing kappa processes. All new processes
# are killed on exit, but processes active on entry are not killed.
   if { ![ catch {exec ps | grep kappa | grep -v grep | \
                  awk {{print $1}} } OLDKAPPA ] } { 
      set OLDKAPPA {}
   }

# Define Startcl procedures (this must be done after the ADAM_USER
# directory has been set up).
   source $STARDEMO_DIR/adamtask.tcl

# The adamtask.tcl file creates a binding which causes the application to
# terminate whenever any window is destroyed. Do away with it.
   bind . <Destroy> ""

# Load the required ADAM monoliths. 
   LoadTask kapview  $KAPPA_DIR/kapview_mon
   LoadTask kappa    $KAPPA_DIR/kappa_mon
   LoadTask ndfpack  $KAPPA_DIR/ndfpack_mon

# >>>>>>>>>>>>>>>>>  SET UP THE SCREEN LAYOUT <<<<<<<<<<<<<<<<<<<<

# Ensure that closing the window from the window manager is like pressing
# the Quit button in the File menu.
   wm protocol . WM_DELETE_WINDOW {Finish 0}

# Set the default colour for all backgrounds.
   . configure -background $BACKCOL
   option add *background $BACKCOL

# Set the default font.
   option add *font $FONT

# Set the default font for radiobuttons and checkbuttons.
   option add *Radiobutton.font $RB_FONT 
   option add *Checkbutton.font $RB_FONT 

# Set the default font for buttons and menus.
   option add *Button.font $B_FONT 
   option add *Menubutton.font $B_FONT 
   option add *Menu.font $B_FONT 

# Radiobuttons and Checkbuttons do not have a highlighted border.
   option add *Radiobutton.highlightThickness 0 
   option add *Checkbutton.highlightThickness 0 

# Ensure that listbox entries are white on black when selected.
   option add *Listbox.selectForeground white
   option add *Listbox.selectBackground black

# Create binding which result in the Helper procedure being called
# whenever a widget is entered, left, or destroyed. Helper stores
# the appropriate message for display in the dynamic help area.
   bind all <Enter> "+Helper"
   bind all <Leave> "+Helper"
   bind all <Destroy> "+Helper"

# Set the size and name of the top level window.
   update idletasks
   set maxsiz [wm maxsize .]
   set SCREENWID [lindex $maxsiz 0]
   set SCREENHGT [expr int(1.0*[lindex $maxsiz 1])]
   wm  geometry . "${SCREENWID}x${SCREENHGT}+0+0"
   wm  title . stardemo

# Loop round until we have succesully create a gwm canvas item. The first
# pass round this loop attempts to manage without a private colour map.
# If the gwm canvas item cannot be created, then a second pass occurs in
# which a private colour map is used. If this also fails, then the
# application exists.
   set gotgwm 0
   set usingnewcmap 0
   while { !$gotgwm } {

# Create an all encompassing frame. Give it a new colour map if requested.
# It is not packed yet, so that it does not appear on the screen. All the
# component widgets are created first, so that they can all appear together
# when $TOP is packed, rather than in dribs and drabs.
      if { $usingnewcmap } {
         set TOP [frame .top -relief raised -bd 2 -colormap new]
         wm colormapwindows . "$TOP ."
      } {
         set TOP [frame .top -relief raised -bd 2]
      }

# Create a frame which goes at the top of the screen but contains nothing. 
# X events will be directed to this window during any pauses
# (see procedure WaitFor). The window has no user controls and so is
# "safe" (i.e. it will just ignore any button presses, mouse movements, etc). 
# This ensures that new commands cannot be initiated by the user before 
# previous ones have finished.
      set SAFE [frame $TOP.dummy ]
      pack $SAFE

# Divide the top window into four horizontal frames. The top one is the
# menu bar. The next contains the GWM canvas and controls. The next displays
# commentary information. The bottom one displays dynamic help on the object
# under the cursor. Make the top two now.
      set F1 [frame $TOP.menubar -relief raised -bd 2 -background $MENUBACK ]
      set F2 [frame $TOP.main ]
      pack $F1 $F2 -padx 1m -pady 1m -fill both -expand 1

# Make the menu buttons for the menu bar.
      set file [menubutton $F1.file -text File -menu $F1.file.menu -background $MENUBACK ]
      set filemenu [menu $file.menu]
      SetHelp $file ".  Menu of commands for exiting, etc..." STARDEMO_FILE_MENU
      set HELP_TEXT(STARDEMO_FILE_MENU) "Menu of commands for exiting, and loading demonstrations from disk."

      set demo [menubutton $F1.demo -text Demo -menu $F1.demo.menu -background $MENUBACK ]
      set demomenu [menu $demo.menu]
      SetHelp $demo ".  Menu of commands for controlling demonstrations..." STARDEMO_OPTIONS_MENU
      set HELP_TEXT(STARDEMO_DEMO_MENU) "Menu of commands for controlling demonstrations. Demonstrations can be selected, removed, executed, paused, aborted, etc."
   
      set opts [menubutton $F1.opts -text Options -menu $F1.opts.menu -background $MENUBACK ]
      set OPTSMENU [menu $opts.menu]
      SetHelp $opts ".  Menu of commands to set up various options..." STARDEMO_OPTIONS_MENU
      set HELP_TEXT(STARDEMO_FILE_MENU) "Menu of commands for setting options which control how the demonstrations are run."
   
      set help [menubutton $F1.help -text Help -menu $F1.help.menu -background $MENUBACK ]
      set helpmenu [menu $help.menu]
      SetHelp $help ".  Display further help information..." STARDEMO_HELP_MENU
      set HELP_TEXT(STARDEMO_FILE_MENU) "Menu of commands for displaying help information."

# Add menu items to the Help menu.
      $helpmenu add command -label "About..." -command {ShowHelp "STARDEMO_ABOUT"}
      MenuHelp $helpmenu "About..."    ".  Display information about this demenonstration tool."

      set HELP_TEXT(STARDEMO_ABOUT) \
"This tool presents information about the Starlink package indicated in \
the yellow area towads the top-left of the main window. The package may \
have several demonstrations covering different aspects of the package. \
The demonstrations to be viewed can be selected using the \"Select\" \
button. The \"Run\" button will start the first of these rolling \
demonstrations, and the rest will follow automatically. The name of the \
currently executing demonstration is displayed below the package name \
(the string \"<idle>\" is displayed if no demonstration is currently \
being shown). If the \"Re-start when finished\" option is selected, the \
first demonstration will re-start auto-matically when the last selected \
demonstration has completed.\n\nEach step in a demonstration is typically \
accompanied by some explanatory text which is displayed below the main \
image display area. If the \"Automatic paging\" option is selected, this \
text will remain visible for a pre-determined length of time before being \
replaced by the text for the next step. Otherwise, the text will remain \
until the user presses a keyboard key or a mouse button. \n\n The best \
effect is obtained by maximising the main window using the window \
manager. This should be done while the system is idle (i.e. while no \
demonstration is running). If the window is re-sized while a \
demonstration is running the text areas will change size but the image \
display will not."

# Add menu items to the File menu.
      $filemenu add command -label "Exit        " -command {Finish 1} -accelerator "Ctrl-e"
      $filemenu add command -label "Load        " -command {LoadFromFile ""} -accelerator "Ctrl-l"
   
      MenuHelp $filemenu "Exit        " ".  Exit the application."
      MenuHelp $filemenu "Load        " ".  Load more demonstrations from disk."
   
      bind . <Control-e> {Finish 1}
      bind . <Control-l> {LoadFromFile ""}

# Add menu items to the Demo menu.
      $demomenu add command -label "Select      " -command {Select} -accelerator "Ctrl-s"
      $demomenu add command -label "Delete      " -command {Delete} -accelerator "Ctrl-d"
      $demomenu add command -label "Run         " -command {Run} -accelerator "Ctrl-r"
      $demomenu add command -label "Abort       " -command {Abort} -accelerator "Ctrl-a"
      $demomenu add command -label "Next        " -command {Next} -accelerator "Ctrl-n"
      $demomenu add command -label "Pause       " -command {PauseDemo} -accelerator "Ctrl-p"
   
      MenuHelp $demomenu "Select      " ".  Select the demonstrations to run."
      MenuHelp $demomenu "Delete      " ".  Delete demonstrations from the list of loaded demonstrations."
      MenuHelp $demomenu "Run         " ".  Start to run all the selected demonstrations running the beginning."
      MenuHelp $demomenu "Next        " ".  Start the next selected demonstration immediately."
      MenuHelp $demomenu "Abort       " ".  Abort the currently running demonstrations."
      MenuHelp $demomenu "Pause       " ".  Pause the currently running demonstration."
   
      bind . <Control-s> {Select}
      bind . <Control-d> {Delete}
      bind . <Control-r> {Run}
      bind . <Control-n> {Next}
      bind . <Control-a> {Abort}
      bind . <Control-p> {PauseDemo}

# Add menu items to options menu.
      $OPTSMENU add checkbutton -label "Auto-looping " -variable LOOPING
      $OPTSMENU add checkbutton -label "Manual paging" -variable PAGING
   
      MenuHelp $OPTSMENU "Auto-looping "  ".  Should the first selected demonstration be re-started when the final one has finished?"
      MenuHelp $OPTSMENU "Manual paging"  ".  Wait for a key to be pressed before moving on to the next step in the demonstration?"

# Pack the menu buttons.
      pack $file $demo $opts -side left 
      pack $help -side right

# Create a label to display the current package command. Put it on the menu
# bar.
      set dolab [label $F1.label -width 80 -textvariable DOING \
                              -relief sunken -bd 2 -font $S_FONT -anchor w ]
      pack $dolab -side left -anchor w -padx 20m
      SetHelp $dolab ".  Shows the package command which has just been executed." STARDEMO_DOING

# Set up the main frame (F2). It is made up from two columns arranged 
# horizontally...
      set COL1 [frame $F2.col1 -bd 1]   
      set COL2 [frame $F2.col2 -bd 1]
      pack $COL1 -side left -fill y -anchor w -ipadx 1m -ipady 1m
      pack $COL2 -side left -fill both -expand 1

# Create and pack a frame containing the demo controls.
      set con [frame $COL1.con -bd 2 -relief groove ]
      pack $con -fill both -expand 1 -ipady 2m

# Create a label showing the demo currently being run.
      set con1 [frame $con.f1 -relief raised -bd 2 -background $MENUBACK]

      set conf1 [frame $con1.f1 -background $MENUBACK]
      set label1 [label $conf1.label1 -textvariable PACKAGE_TITLE -font \
                        $BIG_FONT -relief groove -bd 2 -background $WHITEBACK -height 3]   
      SetHelp $label1 ".  The name of the package being demonstrated." STARDEMO_PACKAGE_DESC

      set package [button $conf1.pkg -text "Info" -command Info -background $MENUBACK]
      SetHelp $package ".  Click to see further information about the package being demonstrated." STARDEMO_PACKAGE
      pack $label1 -side top -pady 2m -padx 2m -ipadx 2m -ipady 1m
      pack $package -side top -pady 1m -padx 2m -pady 1m
   
      set conf2 [frame $con1.conf2 -background $MENUBACK]
      set label2 [label $conf2.label2 -text "Current demonstration:" -background $MENUBACK]   
      set label3 [label $conf2.label3 -textvariable RUNNING_DEMO -background $MENUBACK -relief groove -bd 2]   
      SetHelp $label3 ".  Displays the name of the currently running demonstration (\"<idle>\" is displayed if no demonstration is currently running). Click for more information on the demo. " STARDEMO_NAME

      bind $label3 <Button> {DemoInfo}

      pack $label2 -side top
      pack $label3 -side top -expand 1 -fill x -padx 1m
   
      pack $conf1 $conf2 -side top 
   
      pack $con1 -side top -pady 2m -padx 2m -ipady 2m -fill x -expand 1

#  Row 1 of buttons...
      set con2a [frame $con.con2a]

# Create the button which allows the user to select the demos to run.
      set SELECT [button $con2a.select -text "Select" -width 6 -relief raised -bd 2 -command Select]
      SetHelp $SELECT ".  Click to select the demonstrations to be run from amongst those currently loaded." STARDEMO_SELECT

# Create the button which allows the user to run all the selected demos.
      set RUN [button $con2a.run -text "Run" -width 6 -relief raised -bd 2 -command Run]
      SetHelp $RUN ".  Click to run all the selected demonstrations, starting with the first." STARDEMO_RUN

#  Pack row 1 of buttons...
      pack $SELECT $RUN -side left -pady 1m -padx 2m -expand 1 -fill x -anchor c

#  Row 2 of buttons...
      set con2b [frame $con.con2b]

# Create the button which starts the next demo.
      set NEXT [button $con2b.next -text "Next" -width 6 -relief raised -bd 2 -command Next -state disabled]
      SetHelp $NEXT ".  Click to start the next selected demonstration immediately." STARDEMO_NEXT

# Create the button which aborts the running demo.
      set ABORT [button $con2b.abort -text "Abort" -width 6 -relief raised -bd 2 -command Abort -state disabled]
      SetHelp $ABORT ".  Click to abort the currently running demonstrations." STARDEMO_ABORT

#  Pack row 2 of buttons...
      pack $NEXT $ABORT -side left -pady 1m -padx 2m -expand 1 -fill x -anchor c

#  Row 3 of buttons...
      set con2c [frame $con.con2c]

# Create the button which pauses the running demo.
      set PAUSE [button $con2c.pause -text "Pause" -width 6 -relief raised -bd 2 -command PauseDemo -state disabled]
      SetHelp $PAUSE ".  Click to pause the currently running demonstration." STARDEMO_PAUSE

#  Pack row 3 of buttons...
      pack $PAUSE -side left -pady 1m -padx 2m -expand 1 -fill x -anchor c
 
#  Pack all the rows of buttons.
      pack $con2a $con2b $con2c -side top -anchor n 

#  Radio buttons etc to control looping.
      set con3 [frame $con.con3 -relief groove -bd 2]

      set RB_LOOP [radiobutton $con3.loop -text "Re-start when finished" \
                    -anchor nw -value 1 -variable LOOPING ]
      SetHelp $RB_LOOP ".  Click to make the first selected demonstration automatically re-start when the final one has finished." STARDEMO_LOOP

      set RB_HALT [radiobutton $con3.noloop -text "Halt when finished" \
                    -anchor nw -value 0 -variable LOOPING ]
      SetHelp $RB_HALT ".  Click to halt when the final selected demonstration has finished." STARDEMO_HALT
   
      pack [label $con3.lbl -text "Looping:" -justify left] $RB_LOOP $RB_HALT \
           -side top -anchor nw -fill both -expand 1 -padx 2m
   
      pack $con3 -side top -ipady 1m -pady 2m -padx 2m -expand 1 -fill x

#  Radio buttons to control paging.
      set con4 [frame $con.con4 -relief groove -bd 2]

      set SPEED [scale $con4.speed -from -1.0 -to 0.5 -showvalue 0 -resolution 0.02\
                 -orient horizontal -variable LOGSPEED -command SetSpeed \
                 -width 10 -highlightthickness 0 ]
      SetHelp $SPEED ".  Drag the slider to change the time spent on each page if automatic paging is selected."
      if { $PAGING } { $SPEED configure -state disabled }

      set RB_AUTO [radiobutton $con4.auto -text "Automatic paging" \
                    -anchor nw -value 0 -variable PAGING \
                    -command "$SPEED configure -state normal"]
      SetHelp $RB_AUTO ".  Click to make the demonstration display each page for a fixed time before moving on to the next. Pressing any key will cause the next page to be displayed immediately." STARDEMO_PAGING
   
      set RB_MANUAL [radiobutton $con4.manual -text "Manual paging" \
                    -anchor nw -value 1 -variable PAGING \
                    -command "$SPEED configure -state disabled"]
      SetHelp $RB_MANUAL ".  Click to make the demonstration pause indefinitely after each page, moving on only when a key is pressed." STARDEMO_PAGING
   
      pack [label $con4.lbl -text "Paging:" -justify left] $RB_AUTO $RB_MANUAL $SPEED \
           -side top -anchor nw -fill both -expand 1 -padx 2m

      pack [label $con4.lbl2 -text "Fast" -font $S_FONT] -side left
      pack [label $con4.lbl3 -text "Slow" -font $S_FONT] -side right
      pack [label $con4.lbl4 -text "Speed" -justify center -font $S_BFONT] \
           -side right -expand 1 -fill x
   
      pack $con4 -side top -ipady 1m -padx 2m -pady 2m -expand 1 -fill x

# Create the help area.
      HelpArea

# Create the canvas in column 2...
      set CAN [canvas $COL2.can1 -background black]
      pack $CAN  -side right -anchor e -fill both -expand 1

# Pack the top level frame. This make it appear on the screen.
      pack $TOP -padx 1m -pady 1m -ipadx 1m -ipady 1m -fill both

# Create the commentary area.
      CommentaryArea

# Get the size of the canvas. 
      update 
      set CANWID [expr [winfo width $CAN] - 8]
      set CANHGT [expr [winfo height $CAN] - 8]

# Create a GWM canvas items which fills the canvas.
      if { [catch {set GWM [$CAN create gwm 4 4 -height $CANHGT \
                                 -width $CANWID -name $GWM_NAME \
                                 -mincolours $COLOURS -tags gwm]} mess] } {

# If this failed, prepare to try again with a private colour map. Destroy
# the all--encompassing frame, and set a flag to indicate that a private
# colour map should be used.
         if { !$usingnewcmap } {
            destroy $TOP
            set usingnewcmap 1 
            set F3 ""
            set F4 ""
            set HLAB ""
            set HAREA 1 

# If we failed while using a private colour map, give up.
         } {
            Message "Failed to create the image display.\n\n$mess"
            exit
         }

#  Set a flag if the GWM canvas item was created succesfully.
      } {
         set gotgwm 1
      }

   }

# Create the alpha screen.
   MakeAlpha
   Alpha off

# Load the demo files.
   LoadDemos $demodir 0

# Create a binding which calls MenuMotionBind whenever the pointer moves
# over any menu. This is used to determine the help information to display.
   bind Menu <Motion> {+MenuMotionBind %W %y}

# >>>>>>>>>>>>>>>>>  SET UP THE IMAGE DISPLAY <<<<<<<<<<<<<<<<<<<<<

# Establish the graphics and image display devices.
   Obey kapview lutable "mapping=linear coltab=grey device=$DEVICE" 1
   Obey kapview paldef "device=$DEVICE" 1
   Obey kapview gdclear "device=$DEVICE" 1
   Obey kapview gdset "device=$DEVICE" 1
   Obey kapview idset "device=$DEVICE" 1
   set DOING ""

# Re-size the image display if the top-level window is resized.
   bind . <Configure> {Resize}

   wm deiconify .

# Put the gwm canvas item on top.
   $CAN raise gwm

# Set up bindings which cause ResumeDemo to be called when any key is pressed.
   bind . <Key> ResumeDemo

   set LOGFILE_ID [open stardemo.log w]

# If an "auto-run" demo was specified on the commadn line, check it is
# available within the list of loaded demos.
   if { $autorun != "" } {
      set autorun [string tolower $autorun]
      if { ![info exist DEMO($autorun)] } {
         Message "Demonstration \"$autorun\" was specified on the command line but has not been found."
      } {
         set SELECTED_DEMOS $autorun
         Run
      }
   }

