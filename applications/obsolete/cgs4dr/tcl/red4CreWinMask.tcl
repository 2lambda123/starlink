proc red4CreWinMask {taskname} {
#+
# Creates a dialog box for red4 action 
#-
    global env
    global Red4Widgets

# Check to see if task is busy
    set status [cgs4drCheckTask red4]
    if {$status!=0} {return}

# Create dialog box
    if {[winfo exists .red4Dialogue]} {destroy .red4Dialogue}
    set frame [dialogStart .red4Dialogue "Red4 Create Window Mask" 0 OK Cancel]
    cgs4drCursor pirate orange black
    .red4Dialogue config -cursor {arrow green black}

# Create and pack dialog box widgets
    set top [frame $frame.tt]
    set mid [frame $frame.mt]
    set bot [frame $frame.bt]
    pack $top $mid $bot -in $frame -side top

    set tlabel [label $top.lb -text "Filename"]
    set Red4Widgets(WM_ENT01) [entry $top.e0 -width 40]
    pack $tlabel $Red4Widgets(WM_ENT01) -in $top -side left

    set ilabel [label $mid.lb -text "Window"]
    set l1 [label $mid.l1 -text "Imin"]
    set Red4Widgets(WM_ENT02) [entry $mid.e1]
    set l2 [label $mid.l2 -text "Jmin"]
    set Red4Widgets(WM_ENT03) [entry $mid.e2]
    set l3 [label $mid.l3 -text "Ncols"]
    set Red4Widgets(WM_ENT04) [entry $mid.e3]
    pack $ilabel $l1 $Red4Widgets(WM_ENT02) $l2 $Red4Widgets(WM_ENT03) $l3 $Red4Widgets(WM_ENT04) -in $mid -side left -padx 2 
    $Red4Widgets(WM_ENT02) insert end 1
    $Red4Widgets(WM_ENT03) insert end 256
    $Red4Widgets(WM_ENT04) insert end 256

    set jlabel [label $bot.lb -text "Window"]
    set l4 [label $bot.l4 -text "Imax"]
    set Red4Widgets(WM_ENT05) [entry $bot.e4]
    set l5 [label $bot.l5 -text "Jmax"]
    set Red4Widgets(WM_ENT06) [entry $bot.e5]
    set l6 [label $bot.l6 -text "Nrows"]
    set Red4Widgets(WM_ENT07) [entry $bot.e6]
    pack $jlabel $l4 $Red4Widgets(WM_ENT05) $l5 $Red4Widgets(WM_ENT06) $l6 $Red4Widgets(WM_ENT07) -in $bot -side left -padx 2 
    $Red4Widgets(WM_ENT05) insert end 1
    $Red4Widgets(WM_ENT06) insert end 256
    $Red4Widgets(WM_ENT07) insert end 256

# Do the bindings
    bind $tlabel <Button-2> "red4Update red4CreWinMask ALL"
    bind $ilabel <Button-2> "red4Update red4CreWinMask ALL"
    bind $jlabel <Button-2> "red4Update red4CreWinMask ALL"
    bind $l1 <Button-2> "red4Update red4CreWinMask ALL"
    bind $l2 <Button-2> "red4Update red4CreWinMask ALL"
    bind $l3 <Button-2> "red4Update red4CreWinMask ALL"
    bind $l4 <Button-2> "red4Update red4CreWinMask ALL"
    bind $l5 <Button-2> "red4Update red4CreWinMask ALL"
    bind $l6 <Button-2> "red4Update red4CreWinMask ALL"
    bind $Red4Widgets(WM_ENT01) <Button-2> "red4Update red4CreWinMask WM_ENT01"
    bind $Red4Widgets(WM_ENT01) <Double-Button-2> "$Red4Widgets(WM_ENT01) delete 0 end"
    bind $Red4Widgets(WM_ENT02) <Button-2> "red4Update red4CreWinMask WM_ENT02"
    bind $Red4Widgets(WM_ENT02) <Double-Button-2> "$Red4Widgets(WM_ENT02) delete 0 end"
    bind $Red4Widgets(WM_ENT03) <Button-2> "red4Update red4CreWinMask WM_ENT03"
    bind $Red4Widgets(WM_ENT03) <Double-Button-2> "$Red4Widgets(WM_ENT03) delete 0 end"
    bind $Red4Widgets(WM_ENT04) <Button-2> "red4Update red4CreWinMask WM_ENT04"
    bind $Red4Widgets(WM_ENT04) <Double-Button-2> "$Red4Widgets(WM_ENT04) delete 0 end"
    bind $Red4Widgets(WM_ENT05) <Button-2> "red4Update red4CreWinMask WM_ENT05"
    bind $Red4Widgets(WM_ENT05) <Double-Button-2> "$Red4Widgets(WM_ENT05) delete 0 end"
    bind $Red4Widgets(WM_ENT06) <Button-2> "red4Update red4CreWinMask WM_ENT06"
    bind $Red4Widgets(WM_ENT06) <Double-Button-2> "$Red4Widgets(WM_ENT06) delete 0 end"
    bind $Red4Widgets(WM_ENT07) <Button-2> "red4Update red4CreWinMask WM_ENT07"
    bind $Red4Widgets(WM_ENT07) <Double-Button-2> "$Red4Widgets(WM_ENT07) delete 0 end"

# Show the dialog box
    set bv [dialogShow .red4Dialogue .red4Dialogue]
    if {$bv==0} {
      cgs4drCursor watch red white
      set mask [string trim [$Red4Widgets(WM_ENT01) get]]
      if {$mask==""} {
        cgs4drClear $taskname
        set message "red4CreWinMask error : A dataset has not been specified properly!"
        cgs4drInform $taskname $message
      } else {
        set imin [string trim [$Red4Widgets(WM_ENT02) get]]
        set imax [string trim [$Red4Widgets(WM_ENT03) get]]
        set ncol [string trim [$Red4Widgets(WM_ENT04) get]]
        set jmin [string trim [$Red4Widgets(WM_ENT05) get]]
        set jmax [string trim [$Red4Widgets(WM_ENT06) get]]
        set nrow [string trim [$Red4Widgets(WM_ENT07) get]]
        set message "Creating a new window mask in $mask"
        cgs4drInform $taskname $message
        $taskname obey cre_window_mask "mask=$mask window_imin=$imin window_imax=$imax window_jmin=$jmin window_jmax=$jmax \
          ncolumns=$ncol nrows=$nrow good=0 bad=1" -inform "cgs4drInform $taskname %V"
      }
    }

# Remove the dialog box
    cgs4drCursor arrow green black
    destroy .red4Dialogue
}
