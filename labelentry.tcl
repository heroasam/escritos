#! /usr/bin/wish 
set dir [file dirname [info script]]
source [file join $dir lib.tcl]
font create fh10 -family Verdana -size 12 


proc unique {{id 0}} {
incr id
proc unique "{id $id}" [info body unique]
return $id
}

proc lentry {textlabel var args} {
array set option {-parent . -font fh10 -w 12 -fecha 0 -justify left -focus 1 -setfocus 0 -wl 10 -bg #333333 }
array set option $args
if {$option(-wl) eq "x"} {array set option [list -wl [string length $textlabel]]}
set f [frame $option(-parent)frame[unique] -bg $option(-bg) -bd 0 -class lentry]
label $f.l -width $option(-wl) -text $textlabel -bg $option(-bg) -fg white -font $option(-font)  -anchor e
entry $f.e -textvariable $var -bg #702C2C -fg white -font $option(-font) -width $option(-w) -highlightcolor red -highlightbackground #333333 -relief ridge -justify $option(-justify) -selectbackground orange -takefocus $option(-focus)
pack $f.l $f.e -side left -padx 4
if {$option(-fecha)==1} {
$f.e configure -width 10 -justify center
set b [linsert [bindtags $f.e] 2 fechar]
bindtags $f.e $b
}
if {$option(-setfocus)==1} {focus $f.e}

return $f
}

proc lbutton {text command args} {
array set option {-parent .  -justify left  -w 0 -font fh10}
array set option $args
set f [frame $option(-parent)frame[unique] -bg #333333 -bd 0 -class lbutton]
button $f.b -text $text -bg #333333 -fg white -highlightbackground #702C2C -highlightcolor #702C2C -activebackground #702C2C -activeforeground white -font $option(-font) -width $option(-w) -command $command 
pack $f.b -anchor center 
return $f
}


proc lcombo {args} {
array set option {-parent . -db db -label "" -font fh10 -var var  -w 12 -justify left -wl 10}
array set option $args
if {$option(-wl) eq "x"} {array set option [list -wl [string length $option(-label)]]}
set f [ttk::frame $option(-parent)frame[unique] -class ltcombo -padding 2 -style ltcombo.TFrame]
ttk::style configure ltcombo.TFrame -background #333333
label $f.l -text $option(-label) -bg #333333 -fg white -font $option(-font) -width $option(-wl) -anchor e
ttk::combobox $f.cb -textvariable $option(-var) -width $option(-w) -justify $option(-justify)  -style ltcombo.TCombobox -font fh10
ttk::style configure ltcombo.TCombobox -fieldbackground #702C2C -fieldforeground white -background #333333 -foreground white -fieldhighlightcolor red -highlightbackground #333333 -relief solid -selectborderw 1 -hightlightcolor red -selectbackground orange -listbackground #333333 -highlightthickness 1 
pack $f.l $f.cb -padx 4 -side left
if {[info exists option(-sel)]} {
$f.cb configure -values [$option(-db) eval $option(-sel)]
}
if {[info exists option(-values)]} {
$f.cb configure -values $option(-values)
}
return $f
}
proc ltext {args} {
array set option {-parent .  -label "" -font fh10 -var var  -w 120 -h 10 -justify left -bg bisque -fg black -side left -wl 10 -state normal}
array set option $args
if {$option(-wl) eq "x"} {array set option [list -wl [string length $option(-label)]]}
set f [frame $option(-parent).frame[unique] -bg #333333 -bd 0 -class ltext]
label $f.l -text $option(-label) -bg #333333 -fg white -font $option(-font) -width $option(-wl) -anchor e 
text $f.t -width $option(-w) -height $option(-h)  -font $option(-font) -bg $option(-bg) -fg $option(-fg) -undo 1 -maxundo 5 -autoseparators yes -wrap word -state $option(-state)


if {$option(-label) ne ""} {
pack $f.l -side $option(-side) -anchor w -padx 4}
if {[info exists option(-scroll)]} {
	set scv [ttk::scrollbar $f.scv -orient vertical -command "$f.t yview"]
	$f.t configure -yscrollcommand [list $scv set]
	pack $scv -side right -fill y -pady 5}	 
pack $f.t -side right -pady 5
return $f
}
proc campos {tabla {tipo all}} {
set pragma "pragma table_info($tabla)"
set lcampos {}
foreach row [Tabule $pragma db] {
	switch -- $tipo {
		all {lappend lcampos [lindex $row 1]}
		date {if {[lindex $row 2]=="date"} {lappend lcampos [lindex $row 1]}}
		currency {if {[lindex $row 2]=="currency"} {lappend lcampos [lindex $row 1]}}
}
}
return $lcampos
}
proc tablas {{base db}} {
set sel "select name from sqlite_master where type='table' and name not like 'sqlite%' order by name"
return [Tabule $sel db]
}
proc views {{base db}} {
set sel "select name from sqlite_master where type='view' and name not like 'sqlite%' order by name"
return [Tabule $sel db]
}
proc fra {{border 0}} {
return [frame .[unique] -bg #333333 -bd $border -relief groove]
}
proc tope {w} {
return [frame .[unique] -bg #333333 -w $w]
}
