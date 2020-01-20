
;  include "ulm-init.s"
  include "mini-init.s"
; warning: this code is very rough
; but it gets the e-clock thing done
; don't try to use it to open lower border, it's burning all CPU
; in a loop to wait for the switch position, so it will desync before
screen:
  jsr print
  dc.b 27,"H"   ; home
  dc.b 27,"c2"  ; color
  dc.b "syncexplorer by Gunstick/ULM 2020/1/20",13,10
  dc.b "cursor keys to move",13,10
  dc.b "L-shift: fast",13,10
  dc.b "Return: toggle switch on/off",13,10
  dc.b "Esc: 50/60 vs Lo/Hi",13,10
  dc.b "Tab: shift e-clock jitter adjust",13,10
  dc.b 0 
  even
  ; wait for a vbl
  stop #$2300
  ; now detect the wobble
  ; typical pattern is 4,0,2,0,2
woblen equ 4
  moveq #woblen,d1    ; the wobble repeats every x
  lea wobble,a0
  moveq #-1,d3     ; smallest value
.wd:
  stop #$2300
  move.w #$a80,d0    ; approx distance from VBL start's the normal screen
.ws:
  dbf d0,.ws
  ; read low byte of screen counter
  move.b $ffff8209.w,d2
  cmp.b d2,d3    ; is it smaller
  blo.s .big
  move.b d2,d3
.big:
  move.b d2,(a0)+
  dbf d1,.wd
  move.b d3,wobmin
  ; debug printout the detected wobble
  moveq #woblen,d1
  moveq #0,d0
  lea wobble,a0
  move.b wobmin,d2
.pw:
  sub.b d2,(a0)+    ; remove max
;  move.b (a0),d0
;  bsr printhexd0
;  bsr print
;  dc.b 13,10,0
  even
  dbf d1,.pw
 
  bra.s intodemo
                lea     $ffff8209.w,a0                  ;Hardsync
                moveq   #127,d1                         ;
.sync:          tst.b   (a0)                            ;
                beq.s   .sync                           ;
                move.b  (a0),d2                         ;
                sub.b   d2,d1                           ;
                lsr.l   d1,d1                           ;
wobmin
  dc.b 0
  even
wobble:
  rept woblen
  dc.b 0
  endr
  dc.b 0
  even
intodemo:
   move.w #$777,$ffff8240.w   ; unblack screen
  moveq #0,d0
loop:
  move.b wobble+0,d0
  move.b wobble+1,wobble+0
  move.b wobble+2,wobble+1
  move.b wobble+3,wobble+2
  move.b wobble+4,wobble+3
  move.b d0,wobble+4
skip_wobble:
  move.b #4,d1 
  sub.b d0,d1
  stop #$2300
  lsl.b d1,d1
  move.w top_border_dbf,d0
  move.w d0,d1
  and.w #$f,d1
  lsr.w #4,d0
  ; d1 contains low 4 bits
  add.w d1,d1
  lsl.w d1,d1
dbfperline equ $80
.w1:
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  dbf d0,.w1
patch_colsw equ *+2
  move.w #$050,$ffff8240.w
opener1 equ *+2
  move.b  #2,$ffff820a.w    ; open top border (60Hz, default: no)
opener2 equ *+2
  move.b  #2,$ffff820a.w    ; end top border (back to 50hz)
  move.w #$555,$ffff8240.w
  not.w $ffff8240.w
  rept 199
  nop
  endr
  rept 15
  not.w $ffff8240.w
  endr

  ; KEYBOARD ROUTINE
  ; exit on space (scancode 57)
  move.b $fffffc02.w,d0
  tst.b shift_toggle
  bne.s fastmove
  cmp.b prevkey,d0
  beq no_repeat
  move.b d0,prevkey
fastmove:
  cmpi.b  #57,d0
  beq     end_of_screen
  cmpi.b  #75,$fffffc02.w   ; cursor left
  bne   .n75
  sub.w #1,top_border_dbf
  bra print_value
.n75:
  cmpi.b  #77,d0   ; cursor right
  bne   .n77
  add.w #1,top_border_dbf
  bra print_value
.n77:
  cmpi.b  #72,d0   ; cursor up
  bne.s .n72
  sub.w #dbfperline,top_border_dbf
  bra print_value
.n72:
  cmpi.b  #80,d0   ; cursor down
  bne.s .n80
  add.w #dbfperline,top_border_dbf
  bra print_value
.n80:
  cmpi.b  #28,d0   ; return: toggle opener
  bne.s .n28
  eor.w #2,opener1
  eor.w #$700,patch_colsw
  bra.s print_value
.n28:
  cmpi.b  #1,d0   ; esc: toggle switch type (hi vs 60hz)
  bne.s .n1
  eor.w #$7,patch_colsw
  move.l instr1,d2   ; load other instruction move.b #xx,xxx.w
  move.l opener1,instr1 ; save current one
  move.l d2,opener1
  move.l instr2,d2   ; load other instruction move.b #xx,xxx.w
  move.l opener2,instr2 ; save current one
  move.l d2,opener2
  bra.s print_value
.n1:
  cmpi.b  #$f,d0   ; return: toggle opener
  bne.s .nf
  moveq #0,d0
  bra skip_wobble
.nf:
  cmpi.b  #$2a,d0   ; shift: fast
  bne.s .n2a
  move.b #-1,shift_toggle
  bra.s print_value
.n2a:
  cmpi.b  #$aa,d0   ; shift: fast
  bne.s .naa
  move.b #0,shift_toggle
  bra.s print_value
.naa:
  nop
no_repeat:
next_vbl:
  bra loop

print_value:
  move.w top_border_dbf,d0
  bsr printhexd0
  bra loop

end_of_screen:
  jmp back
instr1 equ *+2
  move.b  #0,$ffff8260.w    ; hi rez on (default: no)
instr2 equ *+2
  move.b  #0,$ffff8260.w    ; hi rez off
prevkey:
  dc.b 0
shift_toggle:
  dc.b 0
  even
; a dumb print routine which prints the inline string after the jsr call until \0
print:
 movem.l d0-d7/a0-a6,-(a7)
 move.l $3c(a7),a5    ; get ret adress = text adress
 move.l a5,-(a7)
 move.w #9,-(a7)      ; cconws
 trap #1              ; GEMDOS
 addq.l #6,a7
printloop:
 tst.b (a5)+
 bne.s printloop   ; if not 0 then get next
 move.l a5,$3c(a7) ; write end of string adress = ret adress
 movem.l (a7)+,d0-d7/a0-a6
 btst #0,3(a7)     ; test lsb of ret adress
 beq.s printstringok  ; 0 => even adress , OK
 addq.l #1,(a7)    ; set to next even adress
printstringok:
 rts

bind0tohexa6:
  ; converts d0 to 8 chars stating at a6
  ; is used by printhexd0
  movem.l d0/d1/d2/a6,-(sp)
  moveq #7,d2
.nextchar:
  rol.l #4,d0        ; rotate topmost nibble at bottom
  move.b d0,d1  ; low byte
  and.b #$0f,d1   ; mask nibble
  add.b #$30,d1   ; convert to number 
  cmp.b #$3a,d1   ; compare with >9
  blt .isdigit
.ischar:
  add.b #7,d1     ; make into char
.isdigit:
  move.b d1,(a6)+
  dbf d2,.nextchar
  movem.l (sp)+,d0/d1/d2/a6
  rts
; convert d0 to hex ascii and print to screen
printhexd0:
  movem.l d0-d3/a0-a3/a6,-(sp)
  lea .hexstring,a6     ; temp work space
  bsr bind0tohexa6
  move.l #.hexstring,-(sp) ; address of text to print
  move.w #9,-(sp)        ; gemdos cconws 
  trap #1                ; call gemdos
  addq.l #6,sp           ; correct stack
  movem.l (sp)+,d0-d3/a0-a3/a6
  rts
.hexstring:
  dc.b "        ",13,0
  even


pal:
  dc.w $000,$555,$555,$555,$555,$555,$555,$555,$555,$555,$555,$555,$555,$555,$555,$555
top_border_dbf:
  dc.w ($595+40)*4
