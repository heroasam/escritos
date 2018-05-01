#! /usr/bin/wish 
set dir [file dirname [info script]]
puts $dir
set diario dia.db
if {$argc>0} {set diario $argv}
package require des
package require base64
source [file join $dir labelentry.tcl]
source [file join $dir tbls.tcl]	
bind Entry <Return> {tk::TabToWindow [tk_focusNext %W]}

conecta tre [file join [file dirname [info script]] $diario]
wm title . "Diario $diario"
foreach  key 12345678 r 0 u 0 y 0 g 0 hint default break 
set flagclave 1
set fontstbl [list ubuntu courier monospace serif helvetica verdana]
set fontstblflag 0



set fr1 [fra] 
set fr2 [fra] 
set filtro ""
set sel "select id,fecha,hint,titulo from bitacora where titulo like '%${filtro}%' order by id desc"


set f [lentry Fecha fecha -fecha 1 -setfocus 1 -wl x] 
set t [lentry "Titulo" titulo -w 65 -wl x]
set i [lentry Id id -w 4 -focus 0 -wl x]
set filtre [lentry Filtro filtro -w 15 -focus 0 -wl x]
set baseused [label .bas -text $diario -bg #333333 -fg yellow -width 30]

set d [ltext -side top -w 100 -scroll 1 -h 25 -bg bisque -font {Ubuntu 13}]

bind $d.t <Control-j> {$d.t yview scroll -1 units ;break}
bind $d.t <Control-k> {$d.t yview scroll 1 units ;break}

#
#TAGS DE COLORES
#============================================================================================== 

set ntag 0
set tags {green red blue pink brown purple}
foreach ctag $tags {
    $d.t tag configure $ctag -foreground $ctag -font {ubuntu 13 bold}}


bind $d.t <Alt-l> {foreach t [$d.t tag names [list insert -1c wordstart]] {
    		   $d.t tag remove $t [list insert -1c wordstart] [list insert -1c wordend]
		   }
		   $d.t tag add [lindex $tags $ntag] [list insert -1c wordstart] [list insert -1c wordend]
    	           incr ntag
		   if {$ntag>=[llength $tags]} {set ntag 0}
}
bind $d.t <Alt-m> {foreach t [$d.t tag names [list insert -1c wordstart]] {
    		   $d.t tag remove $t [list insert -1c wordstart] end
		   }
		   $d.t tag add [lindex $tags $ntag] [list insert -1c wordstart] end 
    	           incr ntag
		   if {$ntag>=[llength $tags]} {set ntag 0}
}
bind $d.t <Alt-M> {foreach t [$d.t tag names [list insert -1c wordstart]] {
    		        $d.t tag remove $t [list insert -1c wordstart] end
		        }}

bind $d.t <<C-i>> {if {[$d.t cget -fg] eq "white"} {$d.t configure -bg bisque -fg black} {$d.t configure -bg #333333 -fg white}}

#
#FIN TAGS DE COLORES
#============================================================================================== 


set k [lentry Contraseña key -focus 0 -wl x]
set tok [lentry Token token -focus 0 -wl x]
$tok.e configure -show *
bind . <Alt-t> {focus $tok.e}
bind . <Alt-f> {focus $filtre.e}
$k.e configure  -show * -validate focusout -vcmd {regexp {^[\w=]{8}$} %P} -invalidcommand {%W delete 0 end;focus %W; balloon:show %W "solo 8 caracteres" 500}
bind $k.e <Control-k> {%W delete 0 end; %W insert 0 12345678}
bind $k.e <FocusIn> {%W selection range 0 end;%W configure -show {}}
bind $k.e <Return> {%W configure -show *; focus $h.e} 
set h [lentry Hint hint -w 8 -wl x -focus 0]
bind . <Alt-i> {focus $h.e}
set tt [tblsf -sel $sel -base tre -sbg darkorange -ancho 120 -alto 25]
set tbl $tt.t
bind . <Alt-k> {focus $k.e}
bind . <Alt-g> {guardar} 
bind . <F11> {guardar} 
bind [$tbl bodytag] <V> {levantar [$tbl getcells active,id]}
bind [$tbl bodytag] <v> {leer [$tbl getcells active,id]}
bind [$tbl bodytag] <n> {pack forget $tt; pack $fr1 -fill x;pack $d -fill both -expand yes;pack $fr2 -fill x;focus $d.t}

bind [$tbl bodytag] <Delete> {set del "delete from bitacora where id=[$tbl getcells active,id]"
			      tre eval $del
			      recalcula$tbl $tbl
			      $tbl activate 0
			      $tbl selection set 0
			      }


#bind [$tbl bodytag] <FocusIn> {cambiatext 10}
proc cambiatext {w} {
global d
$d.t configure -height $w
}

pack $fr1 -fill x 
pack  $f $t  -in $fr1 -side left 
pack $i -in $fr1 -side right
pack $d   -fill both -expand yes
pack $fr2 -fill x
pack $h $k $tok $baseused $filtre  -in $fr2  -side left 
bind .  <u> {pack forget $tt;pack $fr1 -fill x;pack $d}
bind $filtre.e <<Enter>> [subst -nocommand {recalcula$tbl $tbl "select id,fecha,hint,titulo from bitacora where titulo like '%%\${filtro}%%' order by id desc"}]


proc guardar {} {
global f fecha titulo d tbl key id k hint fr2 fr1 tt
if {$key==""} {tk_messageBox -message "No especifico clave";focus $k.e} {
set fechasql [fs $fecha]
set escrito [::base64::encode [$d.t dump -text 1.0 end]]
set escritocodificado [DES::des -mode cbc -dir encrypt -key $key $escrito]
set dump [$d.t dump -tag 1.0 end] 
set imagenes [$d.t dump -image 1.0 end]
if {$id>0} {set ins "replace into bitacora(id,fecha,titulo,des,tag,images,hint) values($id,'$fechasql','$titulo', @escritocodificado,'$dump','$imagenes','$hint')" } {set ins "insert into bitacora(fecha,titulo,des,tag,images,hint) values ('$fechasql','$titulo', @escritocodificado,'$dump','$imagenes','$hint')"}
puts $dump
tre eval $ins
recalcula$tbl $tbl
if {$id eq ""} {set ::id [tre last_insert_rowid]}
balloon:show $f.e "Guardado [$d.t count -lines 1.0 end] lines" 5000
}
#reseteando flag modified
$d.t edit modified 0
}

proc vertabla {} {
global d fr1 fr2 tt tbl
pack forget $d
pack forget $fr1
pack $fr2 -fill x
pack $tt  -fill x
focus $tbl
$tbl activate 0
$tbl selection set 0
}

proc preguntoguardar {accion} {
global d
if {[$d.t edit modified]} {if {[tk_messageBox -message "¿Desea guardar los cambios primero?" -type yesno]==yes} {guardar;$accion} {$accion}} {$accion}
}


proc levantar {id} {
global d key k fr2 fr1 tt
tre eval {select id,fecha,titulo,des,tag,images,hint from bitacora where id=$id} {
	set ::id $id
	set ::fecha [sf $fecha]
	set ::titulo $titulo
	set ::hint $hint
	set chanel [tre incrblob bitacora des $id]
	fconfigure $chanel -translation binary 
        set desdesenc [read $chanel]
	set desdesenc [DES::des -mode cbc -dir decrypt -key $key $desdesenc]
	set desdesenc [::base64::decode $desdesenc]	
	$d.t delete 1.0 end
	desdumptext $desdesenc $d.t
	desdumpimage $images $d.t
	desdump $tag $d.t
}
pack forget $tt
pack $fr1 -fill x
pack $d -fill both -expand yes
focus $d.t
#bind $d.t <Up> {tk::TextSetCursor %W [tk::TextScrollPages %W -1];break}
#bind $d.t <Up> {tk::TextSetCursor %W [tk::TextPrevPara %W insert];break}
$d.t edit modified 0
}

proc leer {id} {
global d token key k fr2 fr1 tt flagclave
set top [tk::toplevel .[unique]]
puts $top
bind $top <q> "destroy $top"
set dtext [ltext -parent $top -side top -w 100 -scroll 1 -h 26 -bg white -fg blue -font {ubuntu 13}]
$dtext.t tag configure resaltar -foreground red -background yellow
$dtext.t tag configure green -foreground green4 
$dtext.t tag configure greenbold -foreground green -font {ubuntu 13 bold}
$dtext.t tag configure red -foreground red
$dtext.t tag configure redbold -foreground red -font {ubuntu 13 bold}
$dtext.t tag configure blue -foreground blue
$dtext.t tag configure bluebold -foreground blue -font {ubuntu 13 bold}
$dtext.t tag configure negrita -font {Verdana 12 bold} -underline yes 
$dtext.t tag configure grande -font {Verdana 15 bold}   
bind $dtext.t <j> "$dtext.t yview scroll 1 units ;break"
bind $dtext.t <J> "$dtext.t yview scroll 1 pages ;break" 
bind $dtext.t <k> "$dtext.t yview scroll -1 units ;break"
bind $dtext.t <K> "$dtext.t yview scroll -1 pages ;break"
bind $dtext.t <g> "$dtext.t yview 1.0 ;break"
bind $dtext.t <G> "$dtext.t yview end ;break"

#prototipo de cambio de fuente 
bind $dtext.t <Control-f> {set font [%W cget -font]
set nuevafont [lindex $::fontstbl $::fontstblflag]
%W configure -font [lreplace $font 0 0 $nuevafont]
incr fontstblflag; if {$::fontstblflag==6} {set ::fontstblflag 0}
balloon:show %W $nuevafont 9000}
#fin prototipo cambio fuente

tre eval {select id,fecha,titulo,des,tag,images,hint from bitacora where id=$id} {
	set id $id
	set fecha [sf $fecha]
	set titulo $titulo
	set hint $hint
	if {$hint eq "default"} {set key 12345678}
	if {$hint eq "plus"} {set key $token=tj19}
	if {$hint eq "full"} {set key $token=tj18}
	set chanel [tre incrblob bitacora des $id]
	fconfigure $chanel -translation binary 
        set desdesenc [read $chanel]
	set desdesenc [DES::des -mode cbc -dir decrypt -key $key $desdesenc]
	set desdesenc [::base64::decode $desdesenc]	
	desdumptext $desdesenc $dtext.t
	desdumpimage $images $dtext.t
	desdump $tag $dtext.t
}
if {$flagclave eq 1} {
wm title $top "$fecha $titulo"
pack $dtext -fill both -expand yes
focus $dtext.t} {
wm title $top "Clave erronea"
}
}

proc limpiar {} {
global fecha titulo d id f
set id "";set fecha ""; set titulo ""; $d.t delete 1.0 end;focus $f.e
$d.t edit modified 0
}

	
proc desdump {dump t} {
if {[llength $dump]>0} {
while {[llength $dump]>0} {
append listtags([lindex $dump 1]) "[lindex $dump 2] "
set dump [lreplace $dump 0 2] 
}
foreach tagname [array names listtags] {
	eval $t tag add $tagname $listtags($tagname)
}
}
}
proc desdumptext {dump t} {
set ::flagclave 1
if {[lindex $dump 0] ne "text"} {set ::flagclave 0;focus $::k.e;return}
while {[llength $dump]>0} {
$t insert [lindex $dump 2] [lindex $dump 1]
set dump [lreplace $dump 0 2]
}
}
proc desdumpimage {dump t} {
if {[llength $dump]>0} {
while {[llength $dump]>0} {
regexp {^(\w)+} [lindex $dump 1] img
$t image create [lindex $dump 2] -image $img
set dump [lreplace $dump 0 2]
}
}
}


#
#CREACION DE BULLETS
#============================================================================================== 
proc img2str {imggif} {
set str [::base64::encode [[image create photo -file $imggif] data -format gif]]
set f [open [file rootname $imggif].txt w]
puts $f $str
close $f
}

set cuadradito {R0lGODdhCQAJAJEAAAAAAP///////////ywAAAAACQAJAAACCISPqcvtDw8pADs=}
image create photo cuadradito -data $cuadradito
bind $d.t <Control-j> {%W image create insert -image cuadradito}

set bul {R0lGODdhCQAJAKIAAAAAAHIAANYAAPgAAOoAAPoAAPkAANgAACwAAAAACQAJAAADIAgQMhIKkEIpWcVUHU79x/BVgzcWR5BtBTR9l8I4EJAAADs=}
image create photo bul -data $bul
bind $d.t <Control-J> {%W image create insert -image bul}

set uncheck {R0lGODdhCwALAJEAAH9/f////////////ywAAAAACwALAAACFISPFsus3R5cclZ4I5hu85B1SVIAADs=}
image create photo uncheck -data $uncheck
bind $d.t <Control-k> {%W image create insert -image uncheck}

set ok {R0lGODlhCQAKAKIAANnZ2ZrpiH3iZmDcRCbPAIvld8Xyu6jsmSH5BAEAAAAALAAAAAAJAAoAAAMdCLoavGI8IMhwKxBLStuEsQkHeACg+YHY2i6H8CQAOw==}
image create photo ok -data $ok
bind $d.t <Control-K> {%W image create insert -image ok}

set okbis {R0lGODlhCQAKAKIAANnZWumIfeJmYNxEJs8Ai+V3xfK7qOyZIfkEAQAAAAAsAAAAAAkACgAAAyoIuhq8SAZBV2gwAAACiYYKEIKIDInklPAASfcAMIiIAkEhiDAQdE9WUQIAOw==}
image create photo okbis -data $okbis
bind $d.t <Control-l> {%W image create insert -image okbis}




#
#MENU CONTEXTUAL 
#============================================================================================== 

set m [menu .popuptags -tearoff 0 -bg black -fg yellow -activebackground\
yellow -activeforeground black]

bind $d.t <Menu> {tk_popup .popuptags %X %Y}

$m add command -label {Letra Grande} -command {if {$y==0} {$d.t tag add grande [list insert -1c wordstart] end;set y 1 } {$d.t tag remove grande [list insert -1c wordend] end;set y 0}}
$m add command -label {Resaltado} -command {if {$r==0} {$d.t tag add resaltar [list insert -1c wordstart] end;set r 1 } {$d.t tag remove resaltar [list insert -1c wordend] end;set r 0}}
$m add command -label {Negrita Subrayado} -command {if {$u==0} {$d.t tag add negrita [list insert -1c wordstart] end;set u 1 } {$d.t tag remove negrita [list insert -1c wordend] end;set u 0}}

#
#BIND GENERALES
#============================================================================================== 

bind . <Alt-n> {preguntoguardar limpiar}
bind . <Alt-q> {preguntoguardar exit}
bind $f.e <t> {preguntoguardar vertabla}
bind . <Control-t> {preguntoguardar vertabla;break}
bind $d.t <Up> {tk::TextSetCursor %W [tk::TextUpDownLine %W -1];break}

