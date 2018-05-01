#! /usr/bin/wish 
package require sqlite3

proc unique {{id 0}} {
incr id
proc unique "{id $id}" [info body unique]
return $id
}

proc tblsn {path args} {
array set conf {-selectmode browse \
		-alto 20 \
                -ancho 0 \
                -scroll v \
                -expandir ""\
                -colapsar "" \
		-takefocus 1\
		-font fh10
                -stripebg red}
array set conf $args
package require tablelist
set frame [frame $path -bg #333333]	
set scv [ttk::scrollbar $frame.scv -orient vertical -command "$path.t yview"]
set sch [ttk::scrollbar $frame.sch -orient horizontal -command "$path.t xview"]

set tbl [tablelist::tablelist $path.t \
					-columns {} \
					-stretch all \
                                        -labelcommand tablelist::sortByColumn \
                                        -labelcommand2 tablelist::addToSortColumns\
					-height $conf(-alto) \
					-width $conf(-ancho) \
					-font $conf(-font) \
					-editselectedonly 1 \
                                        -treestyle radiance \
                                        -yscrollcommand [list $scv set] \
					-xscrollcommand [list $sch set] \
					-resizable yes  \
					-bg #333333 \
					-fg white \
					-labelbg #333333 \
					-labelfg white \
					-labelactivebackground #702C2C \
					-labelactiveforeground white \
					-stripebg $conf(-stripebg) \
					-stripefg white \
					-selectmode $conf(-selectmode)\
					-takefocus $conf(-takefocus)\
					-showseparators yes]
 puts "stripebg [ $path.t cget -stripebg]"
if {[string length $conf(-expandir)]>0} {
	if {[string length $conf(-colapsar)]==0} {set colapsar colapsarcmd}
	$tbl configure -expandcommand $conf(-expandir) -collapsecommand $conf(-colapsar) }
#pack $path
if {[string equal $conf(-scroll) v]} {pack $scv -side right -fill y }
if {[string equal $conf(-scroll) h]} {pack $sch -side bottom -fill x}
if {[string equal $conf(-scroll) a]} {pack $scv -side right -fill y 
	                	   pack $sch -side bottom -fill x}

#binds que permiten a todo tablelist navegar como vim
bind [$tbl bodytag] <k> {tablelist::upDown [tablelist::getTablelistPath %W] -1}
bind [$tbl bodytag] <j> {tablelist::upDown [tablelist::getTablelistPath %W] 1}
bind [$tbl bodytag] <h> {tablelist::leftRight [tablelist::getTablelistPath %W] -1}
bind [$tbl bodytag] <l> {tablelist::leftRight [tablelist::getTablelistPath %W] 1}
bind [$tbl bodytag] <q> {exit}
bind [$tbl bodytag]  <Escape> {$tbl selection clear 0 end}
pack $tbl  -fill both -expand yes
return $path}



proc llenatblsn {tbl sel args} {
array set options {-base db \
		   -tree 0 \
                   -expand 1 \
		   -sumacolumna 0\
		   -editables {} \
		   -sbg ""}
array set options $args 
array set options [list -sel $sel] 

if {$options(-sumacolumna)>0} {bind $tbl <<TablelistSelect>> "SumarCols $tbl $options(-sumacolumna)"}
$tbl delete 0 end
if {[$tbl  columncount]>0} {$tbl deletecolumns 0 end}
set var [Tabule $options(-sel) $options(-base)]
set columnas [coltable $options(-sel) $options(-base)]
set columnasRedim {}
foreach c $columnas {
	if {[string length $c]<=2} {lappend columnasRedim [string toupper $c]} {
		if [regexp {^(id|Id)([[:alpha:]]*)} $c i r j] {
			lappend columnasRedim Id[string totitle $j]} {
			lappend columnasRedim [string totitle $c]}
		}
	}
$tbl configure -columns [CeroCols $columnasRedim]
$tbl configure -showseparators yes  
$tbl configure -stripebg $options(-sbg)
if {[llength $options(-editables)]>0} {
foreach c $options(-editables) {
	$tbl columnconfigure $c -editable 1}
}

set cntcol [llength [coltable $options(-sel) $options(-base)]]
$tbl columnconfigure 0 -align left
foreach c [range 0 $cntcol] n [coltable $options(-sel) $options(-base)] {
$tbl columnconfigure $c -labelalign center	
$tbl columnconfigure $c -sortmode dictionary
$tbl columnconfigure $c -name $n
if {[string eq [datacol $options(-sel) $n $options(-base)] date]} {$tbl columnconfigure $c -formatcommand sf}
}
set linea [lindex $var 0]
foreach n [range 0 $cntcol] {
if {[string match \$* [lindex $linea $n]]} {$tbl columnconfigure $n -align right} {$tbl columnconfigure $n -align left} 
}

if {$options(-tree)==0} {$tbl insertlist end $var} {
	$tbl insertchildlist root 0 $var
	foreach x [$tbl childkeys root] {if {$options(-expand)==1} {$tbl collapse $x}}
	}
}

proc coltable {sel base} {
set listcols {}
eval {$base eval $sel arr {set listcols $arr(*);break}}
return $listcols}
proc CeroCols {listcols} {
lappend cols 0
foreach c $listcols {
	lappend cols $c
	lappend cols 0}
return  [lrange $cols 0 end-1]	
}
proc datacol {sel col base} {
	if {[string match *pragma* $sel]} {return ""}
	$base eval {drop view if exists tempview}
	set view "create temp view tempview as $sel"
	$base eval $view
	$base eval {pragma table_info(tempview)} {
		if {$name=="$col"} {return $type}
	}
}
proc Tabule {selec base} {
set mode [$base exist $selec]
set table {}
if {$mode==1} {
set listcols [coltable $selec $base]
eval {$base eval $selec arr {set row {}
		       	  foreach col $listcols {
			  lappend row $arr($col)}
			  lappend table $row}}}
return $table}

proc SumarCols {tbl col} {
	set valor ""
	set suma 0
	foreach c [$tbl curselection] {
		set valor [$tbl getcells $c,$col]	
		if {[regexp {\$} $valor]} {
		set suma [expr $suma + [string range $valor 1 end]]} {
		set suma [expr $suma + $valor]}
	}
		if {[regexp {\$} $valor]} {balloon:show $tbl [curr $suma] 10000} {
				           balloon:show $tbl $suma 10000}
	}

proc ::SumCol {tbl colname} {
set suma 0
foreach x [range 0 [$tbl size]] {
set valor [$tbl getcells $x,$colname]	
	if {[regexp {\$} $valor]} {
	set suma [expr $suma + [string range $valor 1 end]]} {
	set suma [expr $suma + $valor]}
}
puts $suma
}

proc childn {tbl row sel} {
#inserta el tablelist hijo en un tree genericamente
set var [Tabule $sel $options(-base)]
set var [$tbl applysorting $var]
$tbl insertchildlist $row end $var
}


proc tblsf {args} {
array set options {-selectmode browse \
		-parent . \
		-alto 20 \
                -ancho 0 \
                -scroll v \
                -expandir ""\
                -colapsar "" \
		-font fh10 \
		-base db \
		-tree 0 \
                -expand 1 \
		-sumacolumna 0\
		-editendcommand editdefault\
		-tablaeditar ""\
		-editstartcommand ""\
		-editables {} \
		-delete 0 \
		-totales {}\
		-currency ""\
		-sbg red}

array set options $args
regexp {from ([a-z]+)} $options(-sel) des tabla
array set options [list -tabla $tabla]
array set ::options [array get options]

if {[string eq $options(-parent) .]} {set path $options(-parent)frtbl[unique]} {
set path $options(-parent).frtbl[unique]}
package require tablelist
set frame [frame $path -bg #333333]	
set scv [ttk::scrollbar $frame.scv -orient vertical -command "$path.t yview"]
set sch [ttk::scrollbar $frame.sch -orient horizontal -command "$path.t xview"]

set tbl [tablelist::tablelist $path.t \
					-columns {} \
					-stretch all \
                                        -labelcommand tablelist::sortByColumn \
                                        -labelcommand2 tablelist::addToSortColumns\
					-height $options(-alto) \
					-width $options(-ancho) \
					-font $options(-font) \
					-editselectedonly 1 \
                                        -treestyle radiance \
                                        -yscrollcommand [list $scv set] \
					-xscrollcommand [list $sch set] \
					-resizable yes  \
					-bg #333333 \
					-fg white \
					-labelbg #333333 \
					-labelfg white \
					-labelactivebackground #702C2C \
					-labelactiveforeground white \
					-selectbackground yellow \
					-stripebg $options(-sbg) \
					-stripefg white \
					-selectmode $options(-selectmode)\
					-editendcommand $options(-editendcommand)\
					-editstartcommand $options(-editstartcommand)\
					-showseparators yes]
  
if {[string length $options(-expandir)]>0} {
	if {[string length $options(-colapsar)]==0} {set colapsar colapsarcmd}
	$tbl configure -expandcommand expandir -collapsecommand $options(-colapsar) }
if {[string equal $options(-scroll) v]} {pack $scv -side right -fill y }
if {[string equal $options(-scroll) h]} {pack $sch -side bottom -fill x}
if {[string equal $options(-scroll) a]} {pack $scv -side right -fill y 
	                	   pack $sch -side bottom -fill x}

#binds que permiten a todo tablelist navegar como vim
bind [$tbl bodytag] <k> {tablelist::upDown [tablelist::getTablelistPath %W] -1}
bind [$tbl bodytag] <j> {tablelist::upDown [tablelist::getTablelistPath %W] 1}
bind [$tbl bodytag] <h> {tablelist::leftRight [tablelist::getTablelistPath %W] -1}
bind [$tbl bodytag] <l> {tablelist::leftRight [tablelist::getTablelistPath %W] 1}
bind [$tbl bodytag] <g> {$tbl see 0;$tbl activate 0}
bind [$tbl bodytag] <G> {$tbl see end;$tbl activate end} 
bind [$tbl bodytag] <q> {exit}
bind [$tbl bodytag]  <Escape> {$tbl selection clear 0 end}
pack $tbl  -fill both -expand yes

if {$options(-sumacolumna)>0} {bind $tbl <<TablelistSelect>> "SumarCols $tbl $options(-sumacolumna)"}

if {[$tbl  columncount]>0} {$tbl deletecolumns 0 end}
set var [Tabule $options(-sel) $options(-base)]
set columnas [coltable $options(-sel) $options(-base)]
set columnasRedim {}
foreach c $columnas {
	if {[string length $c]<=2} {lappend columnasRedim [string toupper $c]} {
		if [regexp {^(id|Id)([[:alpha:]]*)} $c i r j] {
			lappend columnasRedim Id[string totitle $j]} {
			lappend columnasRedim [string totitle $c]}
		}
	}
$tbl configure -columns [CeroCols $columnasRedim]
if {[llength $options(-editables)]>0} {
foreach c $options(-editables) {
	$tbl columnconfigure $c -editable 1}
}

set cntcol [llength [coltable $options(-sel) $options(-base)]]
$tbl columnconfigure 0 -align left
foreach c [range 0 $cntcol] n [coltable $options(-sel) $options(-base)] {
$tbl columnconfigure $c -labelalign center	
$tbl columnconfigure $c -sortmode dictionary
$tbl columnconfigure $c -name $n
if {[string eq [datacol $options(-sel) $n $options(-base)] date]} {$tbl columnconfigure $c -formatcommand sf -align center}
if {[string eq [datacol $options(-sel) $n $options(-base)] currency]} {$tbl columnconfigure $c -formatcommand curr -align right} 
if {[string eq [datacol $options(-sel) $n $options(-base)] real]} {$tbl columnconfigure $c -formatcommand curr -align right} 
if {[string eq [datacol $options(-sel) $n $options(-base)] percent]} {$tbl columnconfigure $c -formatcommand porc -align right} 
}
if {$options(-currency) ne ""} {foreach c $options(-currency) {
					$tbl columnconfigure $c -formatcommand curr -align right}}
set linea [lindex $var 0]
foreach n [range 0 $cntcol] {
#if {[string match \$* [lindex $linea $n]]} {$tbl columnconfigure $n -align right} {$tbl columnconfigure $n -align left} 
}

if {$options(-tree)==0} {$tbl insertlist end $var} {
	$tbl insertchildlist root 0 $var
	foreach x [$tbl childkeys root] {if {$options(-expand)==1} {$tbl collapse $x}}
	}

#FILA TOTAL
proc totales$tbl {tbl} {
if {[llength $::options(-totales)]>0} {
$tbl insert end {}
$tbl rowconfigure end -bg bisque
foreach col $::options(-totales) {
if {$col>=[$tbl columncount]} {continue}
	if {$col>[$tbl columncount]} {continue}
	set suma 0
	foreach row [range 0 [$tbl size]] {
		set valor [$tbl getcells $row,$col]	
		if {[string eq $valor ""]} {set valor 0}
		if {[regexp {[[:alpha:]]+} $valor]} {set valor 0}
		if {[$tbl depth $row]>1} {set valor 0}
		if {[regexp {^($)} $valor]} {
		set suma [expr $suma + [string range $valor 1 end]]} {
		set suma [expr $suma + $valor]}
}
$tbl cellconfigure $row,$col -text  $suma -fg red -bg bisque 
}
}
}
			
#EXPANSION AUTOMATICA TREE

if {![string eq $options(-expandir) ""]} {
proc expandir {tbl row} {
$tbl delete [$tbl childkeys $row]
global options
set nodo [$tbl getcells $row,0]
set sel [subst $options(-expandir)]
puts $sel
set var [Tabule $sel $options(-base)]
set var [$tbl applysorting $var]
$tbl insertchildlist $row end $var
foreach x [$tbl childkeys $row] {
	$tbl rowconfigure $x -bg bisque -fg #333333}
}	
}

proc recalcula$tbl {tbl {sel 0}} {
if {$sel!=0} {array set ::options [list -sel $sel]}
$tbl delete 0 end
set var [Tabule $::options(-sel) $::options(-base)]
if {$::options(-tree)==0} {$tbl insertlist end $var} {
	$tbl insertchildlist root 0 $var
	foreach x [$tbl childkeys root] {if {$::options(-expand)==1} {$tbl collapse $x}}
	}
}
proc deleterow {tbl} {
set tabla $::options(-tabla)
set id [$tbl getcells active,id]
set del "delete from $tabla where id=$id"
$::options(-base) eval $del
$tbl rowconfigure active -bg yellow -fg red
recalcula$tbl $tbl
}
bind [$tbl bodytag] <F9> "recalcula[subst $tbl] [subst $tbl]"
if {$options(-delete)==1} {
bind [$tbl bodytag] <Delete> {deleterow $tbl}
bind [$tbl bodytag] <d> {deleterow $tbl}} 
bind [$tbl bodytag] <t> {totales$tbl $tbl}
return $path

}
proc editdefault {tbl row col text} {
set id [$tbl getcells active,0]
set campo [$tbl columncget $col -name]
set tabla $::options(-tablaeditar)
if {[tipodatocampo $tabla $campo]=="date"} {if {![esfsqlite $text]} {set text [fs $text]}}
set upd "update $tabla set $campo='$text' where id=$id"
$::options(-base) eval $upd
return $text
}
