proc red4OpenLog {taskname} {
#+
# Creates a dialog box for red4 action 
#-
    global env

# Check to see if task is busy
    set status [cgs4drCheckTask red4]
    if {$status!=0} {return}

# Do it
    set message "Opening engineering log file $env(CGS4_ENG)/dr$env(CGS4_DATE).log"
    cgs4drInform $taskname $message
    $taskname obey open_log "" -inform "cgs4drInform $taskname %V"
}
