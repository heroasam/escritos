#! /usr/bin/wish 

package require des
package require base64
set dir [file dirname [info script]]
source [file join $dir i.tcl]

conecta dia [file join $dir dia.db]
bind . <Alt-Q> {exit}
bind . <Control-T> {contenidos}

#campo ww Label textvariable opciones (foco, nofoco, w??, u?)
#foco: focus inicial nofoco: takefocus 0 w12 ancho del entry u0 posision del hotkey label
#style: nombre del widget dos letras para evitar la confucion de variables de una letra
campo fe Fecha fecha fecha nofoco u1 
campo ti Titulo titulo w80 nofoco u1
campo hi Hint hint w8 u0 nofoco
campo ke Key key w8 u0 nofoco
campo to Token token w4 u0 nofoco
campo fi Filtro filtro w10 u0 nofoco
not1 n 1000 600
pac {fe ti} {hi ke to fi} n

#Las re-configuraciones complejas de un widget mejor hacerlas directo obteniendo el valor del 
#widget con [ww me-e]
#[ke me-e] configure -validate focusout -validatecommand {expr {[string length %P]==8}} -invcmd {ke resaltar;ke foco} -show *
#o version alternativa:
ke conf {validate focusout validatecommand {regexp {^\w{8}$} %P} invcmd {balloon:show [ke me] "Maximo 8 caracteres" 5000; ke resaltar; ke foco} show *}
to conf {validate focusout validatecommand {regexp {^\w{3}$} %P} invcmd {balloon:show [to me] "Maximo 3 caracteres" 5000;to resaltar; to foco} show *}

proc contenidos {} {
    set sel "select id,fecha,hint,titulo from bitacora order by id desc"
	set t [tbl dia_t 0 110 a foco]
	$t col {id fecha hint titulo}
    	$t negro orange
	$t llena $sel dia
	n add $t {Contenidos} 0
	$t bindear v {ver [dia_t active id]}
bind [dia_t me-t] <1> {ver [dia_t active id]}
}
contenidos


proc ver {id} {
global  token key 
set t [texto #auto 1000 600]
$t conf {-font {ubuntu 13}}
n add $t "$id" 
set tx [$t me]


dia eval {select id,fecha,titulo,des,tag,images,hint from bitacora where id=$id} {
	set fecha [sf $fecha]
	if {$hint eq "default"} {set key 12345678}
	if {$hint eq "plus"} {set key $token=tj19}
	if {$hint eq "full"} {set key $token=tj18}
	
	$t desdumptext [leeblobencr dia bitacora des $id $key] 
	$t desdumpimage $images 
	$t desdumptags $tag 
}
focus $tx
}

proc leeblobencr {base tabla campo id clave} {
    set chanel [$base incrblob $tabla $campo $id]
	fconfigure $chanel -translation binary
	set d [read $chanel]
	set d [DES::des -mode cbc -dir decrypt -key $clave $d]
	set d [::base64::decode $d]	
	return $d
}
