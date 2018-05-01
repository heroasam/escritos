#! /usr/bin/wish
package require Tk 
package require tile
package require pdf4tcl
package require sqlite3
ttk::style theme use clam
set dirlib [file dirname [info script]]

option add *grupo*Label*background purple
#COMENTARIOS
#17/12/10 - se agrega la busqueda de directorio para romitex.db
#esto permitira trabajar en distintos directorios tcls--db
#si el pendrive esta colocado el dir-choosen abre alli sino en 
#sistema como siempre y se activa con un enter.
#Tambien he colocado en el wm title el dirwork de la db.
#
#
#
#
#
#
#
#
#
#

#1) ATAJO PARA EVENTO VIRTUAL EN CASO DE EVENTOS DOBLES
event add <<Enter>> <Return> <KP_Enter>
event add <<ComboboxSelected>> <Return> <KP_Enter>
foreach k {a b c d e f g h i j k l m n o p q r s t u v w x y z} {
event add <<C-$k>> <Control-$k> <Control-[string toupper $k]>>}

#2) NAVEGACION DE FORMULARIOS

bind TCombobox <Up> {tk::TabToWindow [tk_focusPrev %W]}
bind Entry <<Enter>> {tk::TabToWindow [tk_focusNext %W]}
bind TEntry <<Enter>> {tk::TabToWindow [tk_focusNext %W]}
bind Entry <Down> {tk::TabToWindow [tk_focusNext %W]}
bind Entry <Up> {tk::TabToWindow [tk_focusPrev %W]}
bind TEntry <Down> {tk::TabToWindow [tk_focusNext %W]}
bind TEntry <Up> {tk::TabToWindow [tk_focusPrev %W]}
bind Button <<Enter>> {tk::TabToWindow [tk_focusNext %W]}
bind Button <Up> {tk::TabToWindow [tk_focusPrev %W]}
bind Text <Up> {tk::TabToWindow [tk_focusPrev %W]}
bind Text <Alt-j> {tk::TextSetCursor %W [tk::TextUpDownLine %W 1]}
bind Text <Alt-k> {tk::TextSetCursor %W [tk::TextUpDownLine %W -1]} 



#3) CLASE FECHA 
bind fechar <h> {%W delete 0 end;%W insert 0 [hoy];break}
bind fechar <KP_Add> {%W delete 0 end;%W insert 0 [hoy];break}
bind fechar <Right> {incrementarDia %W 1;balloon:show %W [diasem [%W get]] 5000;break}
bind fechar <Left> {incrementarDia %W -1;balloon:show %W [diasem [%W get]] 5000;break}
bind fechar <FocusOut> {ValidarFecha %W;break}
bind fechar <Control-Right> {incrementarDia %W 7;balloon:show %W [diasem [%W get]] 5000;break}
bind fechar <Control-Left> {incrementarDia %W -7;balloon:show %W [diasem [%W get]] 5000;break} 
bind fechar <Alt-Left> {incrementarDia %W -30;balloon:show %W [diasem [%W get]] 5000;break}  
bind fechar <Alt-Right> {incrementarDia %W 30;balloon:show %W [diasem [%W get]] 5000;break}  

#$ FONTS
proc fonth {tam} {
catch [font create $tam -family Helvetica -size $tam]
return $tam}

#TEXT TAGS
proc texttag {t} {
$t tag configure red -foreground red -font fh10b
$t tag configure blue -foreground blue}

#=======================================================================
#WRAPERS
#
proc grupo {pathgrupo nombregrupo campos} {
set lf  [labelframe $pathgrupo -class grupo -text $nombregrupo ]
set nombregrupo [string map {" " ""} $nombregrupo]
regexp {(\w*)$} $pathgrupo path
variable [string tolower $path]
set i 0
set row 0
set tipo campo
foreach {c w} $campos {
	set ancho [string length $c]
	if {$ancho>$i} {set i $ancho}}
	
foreach {c w} $campos {
	if [regexp {[#]$} $c] {set tipo fecha}
	if [regexp {[%]$} $c] {set tipo combobox}
	if [regexp {[&]$} $c] {set tipo memo}
	if [regexp {[@]$} $c] {set tipo boton}
	if [regexp {[?]$} $c] {set tipo check}
	set c [string map {# "" % "" & "" @ "" ? ""} $c]
	set l [label $lf.l$c -text $c -width $i -anchor e  ]
	set c [string map {" " ""} $c]
	set clo [string tolower $c]
	switch -- $tipo {
		check {set e [ttk::checkbutton $lf.$clo -variable $clo ]}
		campo {set e [entry $lf.$clo -textvariable $clo -width $w  ]}
		memo  {set e [text $lf.$clo  -height 3 -bg bisque ]}
		boton {set e [ttk::button $lf.$clo -width $w -text $c -command $clo ]
			   $l configure -text ""}
		combobox {set e [ttk::combobox $lf.$clo -textvariable $clo -width $w ]}
		fecha    {set e [ttk::entry $lf.$clo -textvariable $clo -width $w  ]
			      set b [linsert [bindtags $e] 2 fechar]
				  bindtags $e $b
				  }
	}			  
	
	grid $l -padx 5 -pady 1 -row $row -column 0
	grid $e -padx 2 -pady 1 -row $row -column 1 -s w
	incr row
	#array con nombregrupo para %W
	set [string tolower $path]($clo) $e
	#if {![string equal $tipo combobox]} {bind $e <FocusIn>  "%W configure -bg yellow"
	# bind $e <FocusOut> "%W configure -bg pink"}
	set tipo campo
	}
return $lf
}

proc grupobt {pathgrupo botones {orient h} {focus 0}} {
set f [ttk::labelframe $pathgrupo -borderwidth 1 -relief sunken]
set bot {}
foreach b $botones {
	set bf [string map {" " ""} $b]
	set bt [ttk::button $f.[string tolower $bf] -text $b -command [string tolower $bf] -takefocus $focus]
	lappend bot $bt
}
if {[string equal $orient h]} {eval pack $bot  -side left -padx 5 -pady 5 -fill x } {
	eval pack $bot  -side top -padx 5 -pady 5 -fill both -expand yes}
return $f
}	


#======================================================================
#wrappers obsoletos de libreria para retrocompatibilidad
#boton generico
proc bt {path texto comando {fondo grey}} {
button .$path -text $texto -command $comando -fg blue -bg $fondo}


#=======================================================================
# TABLELIST
#-----------------------------------------------------------------------
proc tbls {path {alto 0} {ancho 0} {scroll v} {expandir ""} {colapsar ""}} {
package require tablelist_tile
set frame [frame $path]	
set scv [ttk::scrollbar $frame.scv -orient vertical -command "$path.t yview"]
set sch [ttk::scrollbar $frame.sch -orient horizontal -command "$path.t xview"]
tablelist::tablelist $path.t -columns {}\
-stretch all  -labelcommand tablelist::sortByColumn -labelcommand2 tablelist::addToSortColumns\
-height $alto -width $ancho   -editselectedonly 1 -treestyle radiance\
-yscrollcommand [list $scv set] \
-xscrollcommand [list $sch set] -resizable yes 
if {[string length $expandir]>0} {
if {[string length $colapsar]==0} {set colapsar colapsarcmd}
$path.t configure -expandcommand $expandir -collapsecommand $colapsar }
pack $path
#binds que permiten a todo tablelist navegar como vim
bind [$path.t bodytag] <k> {tablelist::upDown [tablelist::getTablelistPath %W] -1}
bind [$path.t bodytag] <j> {tablelist::upDown [tablelist::getTablelistPath %W] 1}
bind [$path.t bodytag] <h> {tablelist::leftRight [tablelist::getTablelistPath %W] -1}
bind [$path.t bodytag] <l> {tablelist::leftRight [tablelist::getTablelistPath %W] 1}
#bind $path.t <FocusIn> {%W activate 0; %W selection set 0}

if {[string equal $scroll v]} {pack $scv -side right -fill y }
if {[string equal $scroll h]} {pack $sch -side bottom -fill x}
if {[string equal $scroll a]} {pack $scv -side right -fill y 
						   pack $sch -side bottom -fill x}
pack $path.t  -fill both -expand yes
return $path}
#-----------------------------------------------------------------------
#variante tablelist GTK THEME
proc tblst {path {alto 20} {ancho 0} {scroll v} {expandir ""} {colapsar ""}} {
package require tablelist
set frame [frame $path]	
set scv [ttk::scrollbar $frame.scv -orient vertical -command "$path.t yview"]
set sch [ttk::scrollbar $frame.sch -orient horizontal -command "$path.t xview"]
tablelist::tablelist $path.t -columns {}\
-stretch all  -labelcommand tablelist::sortByColumn -labelcommand2 tablelist::addToSortColumns\
-height $alto -width $ancho   -editselectedonly 1 -treestyle radiance\
-yscrollcommand [list $scv set] \
-xscrollcommand [list $sch set] -resizable yes  -bg #333333 -labelbg #333333 -labelfg white -labelactivebackground #702C2C -labelactiveforeground white -stripebg #CC0505 -stripefg white -fg white
$path.t configure -showseparators yes  
if {[string length $expandir]>0} {
if {[string length $colapsar]==0} {set colapsar colapsarcmd}
$path.t configure -expandcommand $expandir -collapsecommand $colapsar }
pack $path
if {[string equal $scroll v]} {pack $scv -side right -fill y }
if {[string equal $scroll h]} {pack $sch -side bottom -fill x}
if {[string equal $scroll a]} {pack $scv -side right -fill y 
						   pack $sch -side bottom -fill x}
#binds que permiten a todo tablelist navegar como vim
bind [$path.t bodytag] <k> {tablelist::upDown [tablelist::getTablelistPath %W] -1}
bind [$path.t bodytag] <j> {tablelist::upDown [tablelist::getTablelistPath %W] 1}
bind [$path.t bodytag] <h> {tablelist::leftRight [tablelist::getTablelistPath %W] -1}
bind [$path.t bodytag] <l> {tablelist::leftRight [tablelist::getTablelistPath %W] 1}
pack $path.t  -fill both -expand yes
return $path}
#-----------------------------------------------------------------------
proc llenatbls {path sel base {tree 0} {expand 1}} {
if {![$base exists $sel]} {if {[$path get 0] eq ""} {return} {$path delete 0 end;return}}
$path delete 0 end
if {[$path  columncount]>0} {$path deletecolumns 0 end}
set var [Tabule $sel $base]
set columnas [coltable $sel $base]
set columnasRedim {}
foreach c $columnas {
if {[string length $c]<=2} {lappend columnasRedim [string toupper $c]} {
	if [regexp {^(id|Id)([[:alpha:]]*)} $c i r j] {
		lappend columnasRedim Id[string totitle $j]} {
		lappend columnasRedim [string totitle $c]}
	}
}
$path configure -columns [CeroCols $columnasRedim]
$path configure -showseparators yes  -stripebackground [GetColorTbl $path $base] 
bind [$path bodytag] <Control-3> "Cambiacolor $path $base"
bind [$path bodytag] <Control-F12> "Cambiacolor $path $base"
bind [$path bodytag] <Control-F5> "$path configure -stripebg #CC0505
			   grabacolor $path $base #CC0505"

set cntcol [llength [coltable $sel $base]]
$path columnconfigure 0 -align left
foreach c [range 0 $cntcol] n [coltable $sel $base] {
$path columnconfigure $c -labelalign center	
$path columnconfigure $c -sortmode dictionary
$path columnconfigure $c -name $n
if {[string eq [datacol $sel $n $base] date]} {$path columnconfigure $c -formatcommand sf}
}
set linea [lindex $var 0]
foreach n [range 0 $cntcol] {
if {[string match \$* [lindex $linea $n]]} {$path columnconfigure $n -align right} {$path columnconfigure $n -align left} 
}
#pongo alto maximo 20 si hay mas de 20 filas
#set filas [llength $var]
#if {$filas>20} {$path configure -height 20}

if {$tree==0} {$path insertlist end $var} {
$path insertchildlist root 0 $var
foreach x [$path childkeys root] {if {$expand==1} {$path collapse $x}}
}
}

proc child {tbl row sel} {
#inserta el tablelist hijo en un tree genericamente
set var [Tabule $sel]
set var [$tbl applysorting $var]
$tbl insertchildlist $row end $var
}

proc nutbls {tbls sel base} {
#proc nutbls pone columna numeradora siempre que haya filas
set var [Tabule $sel $base]
if {[llength $var]>0} {$tbl columnconfigure 0 -showlinenumbers yes}
}

#=======================================================================
#Averigua el tipo de datos que contiene la columna
#  
#  name: datacol
#  @param el select que forma el view
#  @return el tipo de datos: fecha, currency etc. (to do)
proc datacol {sel col {base db}} {
if {[string match *pragma* $sel]} {return ""}
$base eval {drop view if exists tempview}
set view "create temp view tempview as $sel"
$base eval $view
$base eval {pragma table_info(tempview)} {
	if {$name=="$col"} {return $type}
}
}
proc tipodatocampo {tabla campo {base db}} {
set pragma "pragma table_info($tabla)"
$base eval $pragma {
	if {$name==$campo} {return $type}
}
}


proc datacolBACKUP {sel col {base db}} {
if {[string match *pragma* $sel]} {return ""}
if {![string match *where* $sel]} {append sel " where"}
if {[string match *(*where*)* $sel]} {return ""}
regexp {(.*?)where} $sel descarte newsel
$base eval {drop view if exists datac}
set cr "create temp view datac as $newsel"
$base eval $cr
set selview "select $col from datac where $col is not null limit 1"
set dato [$base onecolumn $selview]
if {[regexp {^((20|19)*([0-9]{2})-(0[1-9]|1[012])-[012][0-9]|3[01])$} $dato]} {return fecha}
}	
#=======================================================================

proc colapsarcmd {tbl row} {
$tbl delete [$tbl childkeys $row]}

proc GetColorTbl {widget {base db}} {
if {[catch [$base exist {select color from configuracion where widget=$widget}]]} {
set coloractual [$base onecolumn {select color from configuracion where widget=$widget}]} {
set coloractual green}
}

proc Cambiacolor {tablist {base db}} {
set nuevocolor [tk_chooseColor -initialcolor #ff0000]
$tablist configure -stripebackground $nuevocolor
grabacolor $tablist $base $nuevocolor
}
proc grabacolor {tablist base nuevocolor} {
if {[$base exist {select color from configuracion where widget=$tablist}]} {
$base eval {update configuracion set  color=$nuevocolor  where widget=$tablist}} {
$base eval {insert into  configuracion (color, widget) values ($nuevocolor , $tablist) }}
}

proc CeroCols {listcols} {
lappend cols 0
foreach c $listcols {
lappend cols $c
lappend cols 0}
return  [lrange $cols 0 end-1]	
}
proc coltable {selec {base db}} {
set listcols {}
eval {$base eval $selec arr {set listcols $arr(*);break}}
return $listcols}
proc coltbl {tabla {base db}} {
set sel "select * from $tabla"
return [coltable $sel $base]}

proc range {from to} {
set rg {}
for {set i $from} {$i<$to} {incr i} {
lappend rg $i}
return $rg
}

proc Tabule {selec {base db}} {
set mode [$base exist $selec]
set table {}
if {$mode==1} {
set listcols [coltable $selec $base]
eval {$base eval $selec arr {set row {}
					  foreach col $listcols {
					  lappend row $arr($col)}
					  lappend table $row}}}
return $table}
#=======================================================================
proc conecta {base {file romitex.db}} {
	set dir [file dirname [info script]]
	sqlite3 $base [file join $dir $file]
		
	$base eval {pragma recursive_triggers=1}
	$base eval {pragma foreign_keys=1}
	$base function cur curr
	$base function regexp regexp
	$base function regexpsq	 regexpsq
	$base function hf humfech
	$base function pr periodicidad
	$base function pmovto pmovto
	$base function adeuda adeuda
	$base function fechar fechar
	$base function recargos Recargos
	$base function sf sf
	$base function difhoy difhoy
	$base function difsemhoy difsemhoy
	$base function sev sev	
	$base function vto vto
	$base function diffechas diffechas
	$base function porc porc
	$base function int int 
	$base function periodosback periodosback 
	$base function mes mes
	$base function mesyear mesyear
	$base function vencido vencido
	$base function year year
	$base function novencida novencida
	$base function liqvta liqvta 
}
proc conectapadron {base} {
	global tcl_platform
	set sys $tcl_platform(platform)
	switch -- $base {
       fem    {if {[string equal $sys unix]} {
					sqlite3 fem "/home/heroasam/femenino.db"} {
						sqlite3 fem "C:\\femenino.db"}}
	   mas   {if {[string equal $sys unix]} {
					sqlite3 mas "/home/heroasam/masculino.db"} {
						sqlite3 mas "C:\\masculino.db"}}
}
}
#=======================================================================
#FUNCIONES DE USO COMUN
#
#=======================================================================
#FUNCIONES DE FECHAS
proc ValidarFecha {fecha} {
	set contfecha [$fecha get]
	if {[regexp {^[\s]*$} $contfecha]} {return}
	switch -- [fechar $contfecha] {
		1 {return}  
		0 {focus $fecha
		   $fecha selection range 0 end}
	}
}
#-----------------------------------------------------------------------
#DIFERENCIA ENTRE DOS FECHAS EN DIAS
proc diffechas {fecha1 fecha2} {
	if {[string equal $fecha1 ""]} {return 0}
	if {[string equal $fecha2 ""]} {return 0}

	return [expr ([clock scan $fecha1 -format "%Y-%m-%d"] - [clock scan $fecha2 -format "%Y-%m-%d"])/86400]
}
#-----------------------------------------------------------------------
#FECHAR fecha : verifico si la fecha dada es correcta en base a una regexp		
proc fechar {fecha} {
	return [regexp {^([012][0-9]|3[01])-(0[1-9]|1[012])-(20|19)*([0-9]{2})$} $fecha]	
}
proc esfsqlite {fecha} {
	return [regexp {^(20|19)([0-9]{2})-(0[1-9]|1[012])-([012][0-9]|3[01])$} $fecha]}
proc incrementarDia {w cnt} {
set actual [$w get]
if {[regexp {^([012][0-9]|3[01])-(0[1-9]|1[012])-([0-9]{2})$} $actual]} {set actual [clock format [clock scan $actual -format "%d-%m-%y"] -format "%d-%m-%Y"]}
if {[fechar $actual]==0}  {set actual [hoy]}
$w delete  0 end
$w insert 0 [clock format [clock scan "$cnt day" -base [clock scan $actual\
		-format "%d-%m-%Y"]] -format "%d-%m-%Y"]
}		
proc hoy {} {return [clock format [clock seconds] -format "%d-%m-%Y"]}
proc ahora {} {	return [clock format [clock seconds] -format %H:%M:%S]}
proc today {} {return [clock format [clock seconds] -format "%Y-%m-%d"]}
proc ayer {} {set a [clock scan [today] -format "%Y-%m-%d"]
set b [clock add $a -1 day]
return [clock format  $b -format "%Y-%m-%d"]}

proc liqvta {cnt} {
#proc para calcular el valor a liquidar segun cnt vtas de acuerdo a sistema vigente 2012
set liq 0
if {$cnt>20} {set sobrante [expr {$cnt-20}]
	      set liq [expr {1000+$sobrante*20}]
              return $liq} {
			    return [expr {$cnt*50}]}
}

proc difhoy {fecha} {
#como arg cualquier fecha en formato sqlite 
#retorna los meses de atraso	
	if {[string eq $fecha ""]} {set fechaseg 0} {
	set fechaseg [clock scan $fecha -format {%Y-%m-%d}]}
	return [expr int(([clock seconds]-$fechaseg)/2592000)]
}
proc difsemhoy {fecha} {
#idem difhoy pero diferencia semanal
	if {[string eq $fecha ""]} {set fechaseg 0} {
	set fechaseg [clock scan $fecha -format {%Y-%m-%d}]}
	return [expr int(([clock seconds]-$fechaseg)/604800)]
}
proc novencida {fecha} {
if {$fecha>[today]} {return 1} {return 0}
}

proc fechasqlite {fecha} {
	if {[string equal $fecha ""]} {return ""}
	return [clock format [clock scan $fecha -format "%d-%m-%Y"] -format "%Y-%m-%d"]}
proc fs {fecha} {
	if {[string equal $fecha ""]} {return ""}
	if {[regexp {(-)[0-9]{4}$} $fecha]} {return [clock format [clock scan $fecha -format "%d-%m-%Y"] -format "%Y-%m-%d"]}
	if {[regexp {(-)[0-9]{2}$} $fecha]} {return [clock format [clock scan $fecha -format "%d-%m-%y"] -format "%Y-%m-%d"]}	
}
proc fechafull {fecha} {
array set mes [list 01 enero 02 febrero 03 marzo 04 abril 05 mayo 06 junio 07 julio 08 agosto 09 setiembre 10 octubre 11 noviembre 12 diciembre]
set f [split $fecha -]
set year [lindex $f 2]
if {[string length $year]==2} {set year 20$year}
return "[lindex $f 0] de $mes([lindex $f 1]) de $year"
}
proc sqlitefecha {fecha} {
	if {[string equal $fecha ""]} {return ""}
	return [clock format [clock scan $fecha -format "%Y-%m-%d"] -format "%d-%m-%Y"]}
proc sf {fecha}	 {
	if {[string equal $fecha ""]} {return ""}
	if {[esfsqlite $fecha]} {return [clock format [clock scan $fecha -format "%Y-%m-%d"] -format "%d-%m-%Y"]} {
		return $fecha}
}		
proc sfy {fecha}	 {
	if {[string equal $fecha ""]} {return ""}
	if {[esfsqlite $fecha]} {return [clock format [clock scan $fecha -format "%Y-%m-%d"] -format "%d-%m-%y"]} {
		return $fecha}
}
#-DOY CAPACIDAD DE FECHAR EN CAMPOS
proc tipofecha {e} {
set b [linsert [bindtags $e] 2 fechar]
bindtags $e $b}


#FUNCIONES DE FORMATO

proc curr {monto} { 
if {$monto==""} {set monto 0}
if {[regexp {([^0-9.])} $monto]} {set monto 0}
set monto [string map {\, \.} $monto]
return   \$[format %0.2f $monto]}

proc porc {cnt} {
if {$cnt eq ""} {return ""}
return [format %0.2f%% $cnt]
}

proc currnozero {monto} {
if {$monto==""} {set monto 0}
if {$monto==0} {return ""}
if {[regexp {([^0-9.])} $monto]} {set monto 0}
set monto [string map {\, \.} $monto]
return   \$[format %0.2f $monto]}

#--------------------------------------------------------------------------------------------------
proc humfech {val} {
if {[string equal $val ""]} {return ""} {
return [clock format [clock scan $val] -format "%d-%m-%y"]}}
proc sev {sev} {
	if {$sev==1} {return SEVEN} {return ""}
}
proc statussev {id} {
db eval {select sev,alta,baja from clientes where id=$id} {
	if {$sev==0 && $alta!=""} {return BAJA}
	if {$sev==1} {return SEVEN} {return ""}
}
}
#FUNCIONES BOBAS
proc par {num} {
	if {[expr $num%2]==0} {return 1} {return 0}
}
#=======================================================================
#PROCEDIMIENTOS COPIADOS
#=======================================================================
#BUSQUEDA EN COMBOBOX
namespace eval ttk::combobox {}

 # Required to escape a few characters to to the string match used
 proc ttk::combobox::EscapeKey {key} {
	
     switch -- $key {
	 KP_Right     { return {6}}
	 KP_End	      { return {1}}    
         bracketleft  { return {\[} }
         bracketright { return {\]} }
         asterisk     { return {\*} }
         question     { return {\?} }
         default      { return $key }
     }
 }

 proc ttk::combobox::CompleteEntry {W key} {
set key [string map {KP_Right 6 KP_End 1 KP_Left 4 KP_Up 8 KP_Down 3 KP_Prior 9 KP_Home 7 KP_Begin 5 KP_Next 3 KP_Insert 0 KP_Enter Return} $key]
 
     if {[string length $key] > 1 && [string tolower $key] != $key} {return}

     if {[$W instate readonly]} {
         set value [EscapeKey $key]
     } else {
         set value [string map { {[} {\[} {]} {\]} {?} {\?} {*} {\*} } [$W get]]
         if {[string equal $value ""]} {return}
     }

     set values [$W cget -values]
     set x [lsearch -nocase $values $value*]
     if {$x < 0} {return}

     set index [$W index insert]
     $W set [lindex $values $x]
     $W icursor $index
     $W selection range insert end

     if {[$W instate readonly]} {
         event generate $W <<ComboboxSelected>> -when mark
     }
 }

 proc ttk::combobox::CompleteList {W key} {
     set key [EscapeKey $key]

     for {set idx 0} {$idx < [$W size]} {incr idx} {
         if {[string match -nocase $key* [$W get $idx]]} {
             $W selection clear 0 end
             $W selection set $idx
             $W see $idx
             $W activate $idx
             break
         }
     }
 }

 bind ComboboxListbox <KeyPress>   { ttk::combobox::CompleteList %W %K }
 bind TCombobox       <KeyRelease> { ttk::combobox::CompleteEntry %W %K }
 #======================================================================

proc balloon:show {w arg {time 1000}} {
	set top $w.balloon
    catch {destroy $top}
    toplevel $top -bd 1 -bg black
    wm overrideredirect $top 1
    pack [message $top.txt -aspect 10000 -bg lightyellow \
             -text $arg]
    set wmx [winfo rootx $w]
    set wmy [expr [winfo rooty $w]+[winfo height $w]]
    wm geometry $top \
      [winfo reqwidth $top.txt]x[winfo reqheight $top.txt]+$wmx+$wmy
    raise $top
 after $time destroy $top
 bind $top <Leave> {destroy %W} 
 }

#=======================================================================
#AUTOMATISMO DE MENUS

proc Menu_Setup { menubar } {
global menu
menu $menubar -bg #333333 -fg white -activebackground #702C2C  -activeforeground white -relief solid -bd 2
# Associated menu with its main window
set top [winfo parent $menubar]
$top config -menu $menubar 
set menu(menubar) $menubar
set menu(uid) 0
}
proc Menu { label } {
global menu
if [info exists menu(menu,$label)] {
error "Menu $label already defined"
}
# Create the cascade menu
set menuName $menu(menubar).mb$menu(uid)
incr menu(uid)
menu $menuName -tearoff 0  -activebackground yellow -fg blue \
		-relief solid -bd 2
$menu(menubar) add cascade -label $label -menu $menuName
# Remember the name to menu mapping
set menu(menu,$label) $menuName
}
proc MenuGet {menuName} {
global menu
if [catch {set menu(menu,$menuName)} m] {
return -code error "No such menu: $menuName"
}
return $m
}
proc Menu_Command { menuName label command } {
set m [MenuGet $menuName]
$m add command -label $label -command $command -background #333333 -foreground white -activebackground #702C2C  -activeforeground white
}
proc Menu_Check { menuName label var {command {}}} {
set m [MenuGet $menuName]
$m add check -label $label -command $command \
-variable $var
}
proc Menu_Radio {menuName label var {val {}} {command {}}} {
set m [MenuGet $menuName]
if {[string length $val] == 0} {
set val $label
}
$m add radio -label $label -command $command \
-value $val -variable $var
}
proc Menu_Separator { menuName } {
[MenuGet $menuName] add separator
}
proc Menu_Cascade { menuName label } {
global menu
set m [MenuGet $menuName]
if [info exists menu(menu,$label)] {
error "Menu $label already defined"
}
set sub $m.sub$menu(uid)
incr menu(uid)
menu $sub -tearoff 0
$m add cascade -label $label -menu $sub
set menu(menu,$label) $sub
}
proc Menu_Bind { what sequence menuName label } {
global menu
set m [MenuGet $menuName]
if [catch {$m index $label} index] {
error "$label not in menu $menuName"
}
set command [$m entrycget $index -command]
bind $what $sequence $command
$m entryconfigure $index -accelerator $sequence
}
#documento el uso del menu
if {1==3} {
Menu_Setup .m
Menu Sampler
Menu_Command Sampler Hello! {puts "Hello, World!";puts $fruit}
Menu_Check Sampler Boolean foo {puts "foo = $foo"}
Menu_Separator Sampler
Menu_Cascade Sampler Fruit
Menu_Radio Fruit apple fruit
Menu_Radio Fruit orange fruit
Menu_Radio Fruit kiwi fruit
Menu_Bind . <Control-H> Sampler Hello!
}
proc decr {int {n 1}} {
	if {[catch {uplevel incr $int -$n} err]} {return -code error "decr: $err"} 
	return [uplevel set $int]
}
#=======================================================================
#=======================================================================
#PROC COPIADOS DE LIBRERIAS.TCL PARA OPTIMIZAR EN UN FUTURO
#=======================================================================
#=======================================================================

#Funcion para sqlite3 que calcula el proximo vto on fly
proc pmovto {idvta} {
db eval {select ant,cc, ic, p, fecha, pagado, ent,condonada,primera,saldo from ventas where id=$idvta} array {
set ant $array(ant)	
set totalprecio [expr $array(ic)*$array(cc)+$array(ant)]
set totalpagado [expr $array(ent)+$array(pagado)]
set enteras [expr $totalpagado/$array(ic)]
set periodicidad $array(p)
set condo $array(condonada)
set cntcuotas $array(cc)
set saldo $array(saldo)
set fecha $array(primera)}
set enteras [expr int($enteras)]
# enteras=0 - no se termino de pagar la primer cuota, el pmovto es a 10 dias
if {$enteras==0} {
	if {$ant>0} {return [clock format [clock scan "1 month" -base [clock scan $fecha]] -format "%Y-%m-%d"]} { 
 	  	     return [clock format [clock scan $fecha] -format "%Y-%m-%d"]}
	         }
# totalpagado=totalprecio o esta condonada o sea se cancelo retorna vacio (null)
if {$saldo==0} {return {}}
if {$totalpagado==$totalprecio} {return {}} 
# en los otros casos de acuerdo a la periodicidad calculo el pmovto
if {$periodicidad==1} {if {$ant>0} {set enteras [expr $enteras+1]}
		       return [clock format [clock scan "$enteras months" -base [clock scan $fecha]] -format "%Y-%m-%d"]}
if {$periodicidad==3} {return [clock format [clock scan "$enteras weeks" -base [clock scan $fecha]] -format "%Y-%m-%d"]}
}
	
#FUNCION RECARGOS calcula el recargo de una deuda
proc Recargos {saldo vto} {
set atraso [expr ([clock seconds]-[clock scan $vto])/86460]
set recargo [expr round($atraso*$saldo*0.186/100)]
if {$recargo<0} {set recargo 0}
return $recargo
}
#PROC PERIODICIDAD
#formatea periodicidad. Se puede indicar el ancho, default 1 sale solo la inicial MENSUAL ---> M
proc periodicidad {p {ancho 3}} {
set ancho [expr $ancho -1]
switch -- $p {
  1 {return [string range MENSUAL 0 $ancho ]}
  2 {return  [string range QUINCENAL 0 $ancho ]}
  3 {return  [string range SEMANAL 0 $ancho ]}
  else {return ""}
}
}

#============================================================================
proc listasql {lista} {
lappend lis (
foreach x $lista {
lappend lis $x 
lappend lis ,
}
set lis [string range $lis 0 end-1]
lappend lis )
return $lis
}
#=======================================================================
#saco una lista de las filas seleccionadas en un tablelist-
proc listtbl {tbl {col 0}} {
set f [$tbl curselection]
set listseleccionada {}
foreach s $f {
   lappend listseleccionada [$tbl getcells $s,$col]}
return $listseleccionada}
#=======================================================================
#calculo cuotas on fly
proc ListaCuotas {cuenta} {
db eval {select * from ventas where id=$cuenta} {break}
set totalpagado [expr $ent + $pagado -$ant]
set setcuotas {}
set reccta 0
for {set i 1} {$i<=$cc} {incr i} {
  set cuota $i
  set vto [vto $fecha $i $p]
  if {$totalpagado>=$ic} {
	set pago $ic
	set totalpagado [expr $totalpagado-$ic]} {
	set pago $totalpagado
	set totalpagado 0}
  set saldo [expr $ic -$pago]
  if {$saldo!=0} {set recargo [Recargos $saldo $vto]} {set recargo 0}
  set total [expr $recargo+$saldo]
  lappend setcuotas [list  $i  $vto  $saldo  $recargo $total]
  if {[info exists ::recargos]} {set ::recargos [expr $::recargos+$recargo]}
  set reccta [expr $reccta+$recargo]
}
set ::rec($cuenta) $reccta
return $setcuotas
}
proc vto {fecha i {p 1}} {
switch -- $p {
  1 {return [clock format [clock add [clock scan $fecha] [expr $i-1] months] -format %Y-%m-%d]}
  3 {return [clock format [clock add [clock scan $fecha] [expr $i-1] weeks] -format %Y-%m-%d]}
}
}
proc ListaCuotas1 {cuenta ant cc ic ent pagado fecha periodicidad debe} {
set totalpagado [expr $ent + $pagado -$ant]
set setcuotas {}
set reccta 0
for {set i 1} {$i<=$cc} {incr i} {
  set cuota $i
  set vto [vto $fecha $i $periodicidad]
  if {$totalpagado>=$ic} {
	set pago $ic
	set totalpagado [expr $totalpagado-$ic]} {
	set pago $totalpagado
	set totalpagado 0}
  set saldo [expr $ic -$pago]
  if {$debe!=0} {set recargo [Recargos $saldo $vto]} {set recargo 0}
  set total [expr $recargo+$saldo]
  lappend setcuotas [list $cuenta $i [humfech $vto] [curr $ic] [curr $pago] [curr $saldo] [curr $recargo] [curr $total]]
  if {[info exists ::recargos]} {set ::recargos [expr $::recargos+$recargo]}
  set reccta [expr $reccta+$recargo]
}
set ::rec($cuenta) $reccta
return $setcuotas
}
proc Backup {con} {
global dirlib
set time [clock format [clock seconds] -format "%a-%d-%b-%Y-%H-%M-%S"]
set dir [file join / home heroasam Backup $time]
file mkdir $dir
db backup [file join $dir romitex.db.$time]
foreach f [glob -directory $dirlib *.tcl ] {
file copy -force $f $dir
}
foreach f [glob -directory $dirlib *.txt] {
file copy -force $f $dir
}
foreach f [glob -directory "~/.vim/view" *] {
file copy -force $f $dir
}
tk_messageBox -message "Backup realizado con exito"}

#=======================================================================
#  MANEJO DE COMBOBOX BARRIO PARA GESTION INTEGRAL DESDE EL COMBOBOX
#=======================================================================
proc cbox {cb campo} {
set tabla [string map {" " ""} [subst {$campo s}]]
set sel "select $campo from $tabla order by $campo"
$cb configure -values [db eval $sel]
variable a $cb
variable b $campo
bind $cb <3> {tk_popup .popuptbl$b %X %Y} 

set m [menu .popuptbl$b -tearoff 0 -bg black -fg yellow -activebackground\
		 yellow -activeforeground black]
$m add command -label {Filtrar Entradas} -command {Filtra $a $b}
$m add command -label {Restablece} -command {Restablece $a $b}			
$m add command -label {Agrega a la lista} -command {Agrega $a $b} \
		-activebackground red
}
proc Filtra {cbox campo} {
	set cb $cbox
	set seleccion [$cb get]
	set tabla [string map {" " ""} [subst {$campo s}]]
	set sel "select $campo from $tabla where $campo like  '%[$cb get]%'"
	$cb configure -values [db eval $sel]
	focus $cb}
proc Restablece {cbox campo} {
	set cb $cbox 
	set tabla [string map {" " ""} [subst {$campo s}]]
	set sel "select $campo from $tabla order by $campo"
	$cb configure -values [db eval $sel]}
proc Agrega {cbox campo} {
	set cb $cbox
	set nuevo [$cb get]
	set tabla [string map {" " ""} [subst {$campo s}]]
	set bus "select $campo from $tabla where $campo='$nuevo'"
	if {![db exists $bus]} {
	set sel "insert into $tabla ($campo) values ('$nuevo')"
	db eval $sel
	Restablece $cbox $campo} {
		tk_messageBox -text "Ya existe el valor"}
	}		

#=======================================================================
proc loger {smt} {
	set pwd "[pwd]-[ahora]"
	if {[regexp {(into historial)} $smt]} {break}
	if {[string match "insert into log*" $smt]} {break} {
		if {[regexp {^([i|d|u|r][n|e|p][s|l|d|p])} $smt]} {
		db eval {insert into loger (smt) values ($smt)}
		db eval {insert into log (smt,pendrive) values ($smt,$pwd)}

		#anexo logeo en un archivo .log
		set fileId log[hoy].log
		set f [open $fileId a+]
		puts $f "$smt;"
		close $f
}}
}
#=======================================================================
proc anchocol {sel} {
#dado un select entrega los anchos de columna maximos desde el segundo 
#elemento hasta el anteultimos [0 5 12 52]	
	set sel [string tolower $sel]
	set cols [coltable $sel]
	set table ""
	regexp {from[ ]*([a-z]*)} $sel r table
	set anchos {}
	foreach c $cols {
		set selec "select $c from $table where length($c)=(select max(length($c)) from $table) limit 1"
		lappend anchos [db onecolumn $selec]}
	return $anchos}
proc avgcol {sel} {
	set sel [string tolower $sel]
	set cols [coltable $sel]
	set table ""
	regexp {from[ ]*([a-z]*)} $sel r table
	set anchos {}
	foreach c $cols {
		set selec "select round(max(length($c))*0.9) from $table"
		lappend avgcols [db onecolumn $selec]}
	return $avgcols}	
#=======================================================================		
# PROTOTIPO DE IMPRESION GENERAL
proc Imprimir {sel {title IMPRESION} {espacios 1} {linea 0} {forma 0} {fecha 1} } {
#transformo el sel en una temp view
db eval {drop view if exists imprisel}
set sel "create temp view if not exists imprisel as $sel"
db eval $sel
set sel "select * from imprisel"	
set pdf [string map {" " ""} $title]
set pdf $pdf
if {$forma==1} {pdf4tcl::new $pdf -paper a4 -margin 30 -landscape 1} {
pdf4tcl::new $pdf -paper a4 -margin 30}
$pdf startPage
set ancho [lindex [$pdf getDrawableArea] 0]
set alto  [lindex [$pdf getDrawableArea] 1]
$pdf setFont 10 Helvetica
$pdf text "Pagina 1" -x $ancho -y 5 -align right
$pdf setFont 14 Helvetica
$pdf text $title -align left -x 0 -y 0
$pdf setFont 10 Helvetica
set cols [coltable $sel]
set anchocolumnas [anchocol $sel]
set anchopdfcols {}
foreach c $anchocolumnas {
	lappend anchopdfcols [$pdf getStringWidth $c]}	
set anchopdfcols [linsert $anchopdfcols 0 0 ]
set anchopdfcols [lreplace $anchopdfcols end end]
$pdf setTextPosition 40 40
set i 2
db eval $sel array {
	if {[lindex [$pdf getTextPosition] 1] >=[expr $alto -10]} {
	$pdf endPage ; $pdf startPage ;$pdf text "Pagina $i"\
	 -x $ancho -y 5 -align right;incr i; $pdf setTextPosition 40 40
	 }
	set x 30
	set y [lindex [$pdf getTextPosition] 1]
	foreach c $cols a $anchopdfcols {
		set x [expr $x + ($a+10)]
		$pdf text $array($c) -x $x -y $y}
	$pdf newLine $espacios
	if {$linea==1} {set y [expr [lindex [$pdf getTextPosition] 1] -5];  $pdf line 0 $y $ancho $y;$pdf newLine 1}
	}
		
$pdf  write -file $pdf.pdf
if {[string equal [tk windowingsystem] win32]} {
exec "C:\\Program Files\\Foxit Software\\Foxit Reader\\Foxit Reader.exe" ./$pdf.pdf} {
exec okular ./$pdf.pdf &}
$pdf  destroy
}	
	
#=======================================================================
#SISTEMA DE IMPRESION ARCHIVO DE TEXTO

proc imprimeTxt {nombre sel {orientacion portrait} {linea sin}} {
	#transformo el sel en una temp view
	db eval {drop view if exists imprisel}
	set sel "create temp view if not exists imprisel as $sel"
	db eval $sel
	set sel "select * from imprisel"	
	set filename $nombre
    set fileId [open $filename "w"]
	set anchos [avgcol $sel]
	set str "format %10s"
	foreach a $anchos {
		append str  "%-[expr int($a)+3]s"
		}
	lappend str ""	
	set basestr $str
	db eval $sel array {
		foreach c $array(*) {
			lappend str $array($c)
		}
		  puts $fileId "[eval $str]\n"
		  if {$linea=="con"} {
		  if {$orientacion=="landscape"} {puts $fileId "________________________________________________________________________________________________\n"} {
	          puts $fileId "______________________________________________________\n"}}
		  set str $basestr
    }
    close $fileId
    if {$orientacion=="landscape"} {
    exec lpr -o landscape ./$nombre & } {
	    exec lpr ./$nombre &}
}
proc imprimeList {nombre lista} {
	set filename $nombre
    set fileId [open $filename "w"]
    foreach l $lista {
		puts $fileId $l
	}
	close $fileId
	exec kwrite ./$nombre &
}

proc ImprimirFichas {ids} {
	set j 1
	set id [lindex $ids 0]
	set zona [db onecolumn {select zona from clientes where id=$id}]
	set zona [string map {" " _} $zona]
	set filename "TandaFichas_$zona"
	set fileId [open $filename "w"]

	foreach cliente $ids {
		set intimado [db onecolumn {select intimado from clientes where id=$cliente}]
		if {$intimado==0} {set sel "select id from ventas where saldo>0 and idcliente=$cliente"} {
					       set sel "select id from ventas where saldo>0 and idcliente=$cliente limit 1"}
		db eval $sel {
			generarficha $id $fileId $j
			incr j}
	}
	close $fileId
	exec lpr $filename &
}	
proc generarficha {cuenta fileId index} {
	set cctas [db onecolumn {select count(*) from ventas where saldo>0 and idcliente=(select idcliente from ventas where id=$cuenta)}]
	set dctas [db onecolumn {select count(*) from clientes where deuda>0 and calle||num=(select calle||num from clientes where id=(select idcliente from ventas where id=$cuenta))}]
		db eval {select * from clientes where id=(select idcliente from ventas where id=$cuenta)} {
		set nombre $nombre
		set calle $calle
		set num $num
		set barrio $barrio
		set acla $acla
		set plan $plan
		set fechaintim $fechaintim
		set tel $tel
		set intimado $intimado
	}
	db eval {select * from ventas where id=$cuenta} {
		set pagado $pagado
		set comprado $comprado
		set ent $ent
		set cc $cc
		set ic $ic
		set ant $ant
		set vto $vto
		set direccion [string range "$calle $num $barrio" 0 40]
		if {$ant>0} {set anticipo "Antic.[curr $ant]"} {set anticipo ""}
		if {[par $index]} {puts $fileId ".";puts $fileId "."}
		puts $fileId [format "%-30s %-40.38s"  "Resumen de Cuenta N°$id"  $nombre]
		puts $fileId [format "%-30s %-40.38s"  "Fecha de compra [sf $fecha]" $direccion]
		puts $fileId [format "%-30s %-40.38s"  "$cnt [string range $art 0 35]" $acla]
		puts $fileId "Plan de Pagos $anticipo - $cc cuotas de [curr $ic] plan [periodicidad $p 7]"
		puts $fileId "entregado al retirar [curr $ent] el [sf $fecha]"
	        puts $fileId "------------------------------------------------------------"
	}
	# Bifurcacion en funcion de si esta intimado o no
	#
	if {$intimado==0} {
		puts $fileId [format "%-12s %-8s %-10s %-10s %-10s" Fecha Recibo Pagado Recargo Cobrador]
	db eval {select fecha,rbo,imp,rec,cobr from pagos where idvta=$cuenta} {
		puts $fileId [format "%-12s %-8s %-10s %-10s %-10s" [sf $fecha] $rbo [curr $imp] [curr $rec] $cobr]
	}
	set row [db onecolumn {select count(*) from pagos where idvta=$cuenta}]
		puts $fileId "------------------------------------------------------------"
		puts $fileId "PRECIO TOTAL [curr [expr $ant+$cc*$ic]] menos SUS PAGOS de [curr [expr $ent+$pagado]] DEBE [curr [expr $comprado-$pagado-$ent]]"
		puts $fileId "------------------------------------------------------------"
		if {$vto<[fs [hoy]]} {puts $fileId "CUENTA VENCIDA EL [sf $vto]"; set row [expr $row+1]}
		if {$cctas>1} {puts $fileId "Este cliente tiene $cctas cuentas";set row [expr $row+1]}
		#if {$dctas>1} {puts $fileId "En esta direccion hay $dctas clientes deudores";set row [expr $row+1]}
		puts $fileId "."
		puts $fileId "." 
		if {[expr $ic-($pagado+$ent)]>0} {puts $fileId "              SALDO 1° CUOTA [curr [expr $ic-($pagado+$ent)]]";set row [expr $row+1]} {
			puts $fileId "              CUOTA [curr $ic]";set row [expr $row+1]}
		if {[par $index]} {set row [expr $row+1]}
		set row [expr 16-$row]
		for {set i 0} {$i<$row} {incr i} {
			puts $fileId .
		}
		puts $fileId "."
		for {set i 0} {$i<4} {incr i} {
			puts $fileId .
		}
	} {	regexp {3x\$([0-9.]+)} $plan pl inti
		set deudaintim [expr $inti*3]		
		# caso cliente intimado
		puts $fileId "CLIENTE INTIMADO el [sf $fechaintim] PLAN DE PAGOS $pl"
		puts $fileId "------------------------------------------------------------"
		puts $fileId "Pagos realizados DESPUES de la intimacion:"
		puts $fileId "------------------------------------------------------------"
		db eval {select fecha,rbo,(imp+rec) as imp,cobr from pagos where idvta=$cuenta and fecha>$fechaintim} {
			puts $fileId [format "%-12s %-8s %-10s  %-10s" [sf $fecha] $rbo [curr $imp]  $cobr]
		}
		set row [db onecolumn {select count(*) from pagos where idvta=$cuenta and fecha>$fechaintim}] 	
		if {$row==0} {set pagosint 0
			      puts $fileId "NINGUN PAGO REALIZADO"} {
		set pagosint [db onecolumn {select sum(imp+rec) from pagos where idvta=$cuenta and fecha>=$fechaintim}]}
		puts $fileId "------------------------------------------------------------"
		puts $fileId "total de pagos por la intimacion [curr $pagosint]"
		puts $fileId "------------------------------------------------------------" 
		puts $fileId "SALDO A PAGAR [curr [expr $deudaintim - $pagosint]]" 
		puts $fileId "------------------------------------------------------------" 
		if {[par $index]} {set row [expr $row+1]}
	        set row [expr 18-$row] 	
		for {set i 0} {$i<$row} {incr i} { 
			puts $fileId .
		}
       }
}
#Procedimientos para automatizar el proceso con campos  BLOB
proc cargabin {archivo} {
	set fileId [open $archivo RDONLY]
	fconfigure $fileId -translation binary 
	set contenido [read $fileId]
	close $fileId
	return $contenido
}
proc recuperabin {base tabla col id} {
	set file $tabla$id
	set chanel [$base  incrblob -readonly $tabla $col $id]
	fconfigure $chanel -translation binary
	set temp [read $chanel]
	set tempfile [open temp$file "WRONLY CREAT BINARY"]
	puts $tempfile $temp
	flush $tempfile
	return temp$file
}

#Graficador
proc graficobarras {sel title {base db}} {
variable f [toplevel .f]
wm title $f $title
package require BLT
namespace import blt::*
set b [barchart $f.b -title $title  -barmode aligned -plotbackground bisque ]
pack $b
$b legend configure -hide 1
set col [list white magenta cyan yellow blue red orange]
set matriz [Tabule $sel]
puts $matriz
set j 0
foreach row $matriz {
	set i 1
	foreach ys [lrange $row 1 end] {
		set x [sacaceros [lindex $row 0]]
		set y [lindex $row $i]
	        $b element create $j  -xdata $x -ydata $y  -foreground [lindex $col $i]
		incr i
		incr j
}
}
bind $f <1> {destroy $f}
return $f
}

proc grafico {sel title {base db}} {
variable f [toplevel .f]
wm title $f $title
set colors [list cyan magenta yellow blue red green brown]
set symbols [list circle diamond cross plus square triangle]
package require BLT
namespace import blt::*
set b [graph $f.b -title $title  -plotbackground bisque ]
pack $b
$b legend configure -hide 1
set matriz [Tabule $sel]
set rows [llength $matriz]
set cols [llength [lindex $matriz 0]]
foreach col [range 0 $cols] {
	set columna {}
	foreach row [range 0 $rows] {
		lappend columna [lindex [lindex $matriz $row] $col]
}
set data($col) $columna
}
foreach c [range 1 $cols] {
	$b element create col$c -xdata $data(0) -ydata $data($c) -symbol [lindex $symbols $c] -fill [lindex $colors $c]
puts $data($c)
} 

bind $f <1> {destroy $f}
return $f
}

proc sacaceros {value} {
	regsub ^0+(.+) $value \\1 retval
	return $retval
}	

proc ImprimirFichaListado {id} {
puts $id
set pdf $id
pdf4tcl::new $pdf -paper a4 -margin 30
set ancho [lindex [$pdf getDrawableArea] 0]
set largo [lindex [$pdf getDrawableArea] 1]
set page 0


set y 0
$pdf startPage
$pdf setFont 10 Helvetica


#SECTOR ENCABEZADO DATOS DEL CLIENTE
db eval {select nombre,calle||' '||num||' '||barrio as direccion, tel,zona,acla,cur(deuda) as deuda,ultpago,plan from clientes where id=$id} arrcl {
set nombre $arrcl(nombre)
set direccion $arrcl(direccion)
set telefono $arrcl(tel)
set zona $arrcl(zona)
set msge $arrcl(acla)
set deuda $arrcl(deuda)
set ulpa $arrcl(ultpago)
set plan $arrcl(plan)
set zona $arrcl(zona)
}

$pdf text "$zona [hoy]" -y 0 -align right -x $ancho
set y 25

$pdf setFont 14 Helvetica
set y [expr $y+15]
$pdf text $nombre -align left -x 0 -y $y
$pdf setFont 12 Helvetica
set y [expr $y+22]
$pdf text "$direccion -tel: $telefono" -align left -x 0 -y $y
set y [expr $y+12]
set largo [string length $msge]
if {$largo>0} {
set altorectangulo [expr ($largo/100+3)*10]
$pdf drawTextBox 5  $y  [expr $ancho -10] [expr $altorectangulo -5] $msge -align justify
set y [expr $y+18]}


#SECTOR CUENTAS Y CUOTAS
set y [expr $y+10]
if {$y>=650} {
$pdf endPage
set y 0
$pdf startPage
$pdf setFont 10 Helvetica
set page [expr $page+1]
$pdf text "$Zona - Pag $page" -y 0 -align right -x $ancho
$pdf line [expr $ancho-120] 5 $ancho 5
set y 25
}
# fork para ver si ESTA INTIMADO Y NO EMITO LAS CUOTAS
	
db eval {select  id, ant, cc, ic, ent, pagado, strftime('%d/%m/%Y',ultpago) as ultpago,fecha, p,cur(saldo) as saldo,substr(art,0,30) as art,idvdor from ventas where idcliente=$id and saldo>0} array {
	$pdf line 0 $y $ancho $y
	set y [expr $y+15]
	$pdf setFont 12 Helvetica
	$pdf text "$array(id)"  -x 0 -y $y
	$pdf setFont 10 Helvetica
	$pdf text "[humfech $array(fecha)] - $array(art) - Plan $array(cc) cuotas de [curr $array(ic)] - [periodicidad $array(p)] - entr: [curr $array(ent)] vdor:$array(idvdor) " -x 50 -y $y
	set y [expr $y+14]
	$pdf setFont 8 Helvetica
	set cuotas [eval [list ListaCuotas1 $array(id) $array(ant) $array(cc) $array(ic) $array(ent) $array(pagado) $array(fecha) $array(p) $array(saldo)]]
	$pdf text cuota -x 70 -y $y
	$pdf text recargo -x 110 -y $y
	$pdf text total -x 150 -y $y
	$pdf setFont 8 Helvetica
	set y [expr $y+10]
	foreach c $cuotas {
		if {![string equal [lindex $c 5]  \$0.00]} {
		$pdf text [lindex $c 1] -x 10 -y $y
		$pdf text [lindex $c 2] -x 30 -y $y
		$pdf text [lindex $c 5] -x 70 -y $y
		$pdf text [lindex $c 6] -x 110 -y $y
		$pdf text [lindex $c 7] -x 150 -y $y
		set y [expr $y+10]}
		}
	set y [expr $y+20]
	$pdf text "Pagos realizados" -x 10 -y $y
	set y [expr $y+10]
        db eval {select fecha,rbo,imp,rec,cobr from pagos where idvta=$array(id)} pago {
		$pdf text [sf $pago(fecha)] -x 10 -y $y
		$pdf text [curr $pago(imp)] -x 60 -y $y 
		$pdf text [curr $pago(rec)] -x 90 -y $y
		$pdf text $pago(rbo) -x 120 -y $y
		$pdf text $pago(cobr) -x 160 -y $y
		set y [expr $y+10]
		}
	set y [expr $y+15]
	}
set y [expr $y+16]


#termino la pagina y como esta dentro de un foreach, si el argumento del proc es una lista seguira generando paginas
#

#Determino el nombre del archivo pdf, si es una sola ficha el idcliente y si es una lista la zona

set namepdf ficha$id
$pdf  write -file $namepdf.pdf
if {[string equal [tk windowingsystem] win32]} {
exec "C:\\Program Files\\Foxit Software\\Foxit Reader\\Foxit Reader.exe"  ./$namepdf.pdf} {
exec lpr ./$namepdf.pdf &}
$pdf  destroy
}

proc SumarMontos {col} {
	global tbl 
	set suma 0
	foreach c [$tbl curselection] {
		set suma [expr $suma + [string range [$tbl getcells $c,$col] 1 end]]
	}
		balloon:show $tbl [curr $suma] 10000
	}
proc regexpsq {exp var} {
set res ""
regexp $exp $var res
return $res
}
proc unmesatras {} {
return [clock format [clock scan "-1 month" -base [clock seconds]] -format "%Y-%m-%d"]
}
proc mesatras {cnt} {
return [clock format [clock scan "-$cnt month" -base [clock seconds]] -format "%Y-%m-%d"]
}
proc int {{valor 0}} {
return [expr int($valor)]
}
proc periodosback {fecha} {
if {[esfsqlite $fecha]} {
return [expr ([clock seconds]-[clock scan $fecha])/2592000]} {
return ""}
}
#Funcion que retorna un numero en letras por ahora 1/9999
proc numletras {numero} {
if {$numero==100} {return cien}
array set numeros [list 01 uno 02 dos 03 tres 04 cuatro 05 cinco 06 seis \
07 siete 08 ocho 09 nueve 10 diez 11 once 12 doce 13 trece 14 catorce \
15 quince 16 dieciseis 17 diecisiete 18 dieciocho 19 diecinueve \
20 veinte 21 veintiuno 22 veintidos 23 veintitres 24 veinticuatro \
25 veinticinco 26 veintiseis 27 veintisiete 28 veintiocho 29 veintinueve\
30 treinta 40 cuarenta 50 cincuenta 60 sesenta 70 setenta 80 ochenta \
90 noventa 100 ciento 200 doscientos 300 trescientos 400 cuatrocientos \
500 quinientos 600 seiscientos 700 setecientos 800 ochocientos \
900 novecientos 1000 mil 2000 {dos mil} 3000 {tres mil} 4000 {cuatro mil}\
5000 {cinco mil} 6000 {seis mil} 7000 {siete mil} 8000 {ocho mil} \
9000 {nueve mil} 0 ""]

set num [split $numero {}]
set num [lreverse $num]
set unidad [lindex $num 0]
set decena [lindex $num 1]
set millar [lindex $num 3]
append dosdig $decena $unidad
set centena [lindex $num 2]
set unidad "0$unidad"
if {[string length $dosdig]==1} {set dosdig "0$dosdig"}
if {$centena ne ""} {set centena [expr $centena * 100]}
if {$centena==$numero} {return [string toupper $numeros($numero)]}
if {$decena ne ""} {set decena [expr $decena *10]}
if {$millar ne ""} {set millar [expr $millar * 1000]}
if {$dosdig<30} {append res $numeros($dosdig)} {
	if {$dosdig==$decena} {append res $numeros($dosdig)} {
	append res $numeros($decena) " y " $numeros($unidad)}}
if {$centena ne ""} {append resu $numeros($centena) " " $res;set res $resu}
if {$millar ne ""} {append resm $numeros($millar) " " $res; set res $resm}
set res [split $res]
foreach x $res {
if {$x ne ""} {lappend lnum $x}}
return [string toupper [join $lnum " "]]
}

array set diasemana [list Monday Lunes Tuesday Martes Wednesday Miercoles Thursday Jueves Friday Viernes Saturday Sabado Sunday Domingo]

proc diasem {fecha} {
global diasemana
set fecha [fs $fecha]
return $diasemana([clock format [clock scan $fecha] -format %A])
}
proc year {fecha} {
return [clock format [clock scan $fecha] -format %Y]}

proc mes {fecha} {
set f [clock format [clock scan $fecha] -format %h]
return [string map {Jan Ene Apr Abr Aug Ago Dec Dic} $f]} 

proc mesyear {fecha} {
set f [clock format [clock scan $fecha] -format "%h-%y"]
return [string map {Jan Ene Apr Abr Aug Ago Dec Dic} $f]} 

proc vencido {fecha} {
if {$fecha < [today]} {return 1} {return 0}
}
#binds generales para aumentar el tamaño de letra o reducirlo con C+ C-

bind all <Control-plus>  {font_resize %W +1}
bind all <Control-minus> {font_resize %W -1}

proc font_resize {w amount} {
    set font [$w cget -font]
    set size [expr {[lindex $font 1] + $amount}]
    $w configure -font [lreplace $font 1 1 $size]
}
proc removerdelista {lista elemento} {
set idx [lsearch $lista $elemento]
set lista [lreplace $lista $idx $idx]
return $lista
}
proc unique {{id 0}} {
incr id
proc unique "{id $id}" [info body unique]
return $id
}

proc suma {lista} {
set sum 0
foreach item $lista {
if {$item eq ""} {set item 0}
if {[string match *-* $item]} {set item 0}
if {[string match {[a-zA-Z]} $item]} {set item 0}
set sum [expr $sum+$item]}

return $sum
}
