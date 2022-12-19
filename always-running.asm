;; always-running.asm
;; mszegedy 2022

;; sa1 compatibility
!base2 = $0000
if read1($00ffd5) == $23
  sa1rom
  !base2 = $6000
endif

macro is_l_not_held_to_z()
  ;; sets z flag to 1 if l is not held, 0 if it is
  lda $17
  eor #$ff
  and #$20
endmacro

macro is_l_not_held_to_v()
  ;; sets v flag to 1 if l is not held, 0 if it is
  lda $17
  and #$20
  beq +
  clv
  bra ++
+
  sep #$40
++
endmacro

macro is_r_not_held_to_v()
  ;; sets v flag to 1 if r is not held, 0 if it is
  lda $17
  and #$10
  beq +
  clv
  bra ++
+
  sep #$40
++
endmacro

;;; disable l/r scrolling
org $cdfc
  db $80

;;; $15 uses; leaving alone for now
;; 00d715: running
org $d713
  autoclean jsl running_hijack

;; 00d85b: unused powerup; not gonna hijack

;; 01a00d: kicking stuff
org $01a00b
  autoclean jsl kicking_hijack

;; 01aa58: carrying stuff
org $01aa58
  ; nintendo made this routine 2 bytes longer than they needed to, so we don't
  ; need to jsl out! hooray!
  lda $17
  and $10
  db $d0  ; change a beq to a bne

;; 01e6ce: carrying stuff while springboarding
org $01e6ce
  autoclean jsl springboard_hijack
  bra $01e6e2

freecode
running_hijack:
  ldy #$00  ; recovered from rom
  %is_l_not_held_to_v()
  rtl

kicking_hijack:
  bne +  ; replaces a bne in rom
  %is_r_not_held_to_v()
  rtl
+
  ; there's a bvc between where the rtl takes us and where the bne's original
  ; destination is. setting v will turn it into a functional nop.
  sep #$40
  rtl

springboard_hijack:
  lda $17
  and $10
  bne +
  lda $1470|!base2
  ora $187a|!base2
  bne +
  lda #$0b
  sta $14c8|!base2,x
  stz $1602|!base2,x
+
  rtl

;;; $16 uses; leaving alone for now
;; 009b24: start game? why just x/y?
;; 00d068: cape spin and... yoshi?
;; 00d08c: fire flower
;; 00db98: swimming
;; 00f26b: something to do with blocks
;; 01da2f: yoshi?
;; 01f1e5: some sprite interaction
;; 049150: enter level from overworld
;; 0ccfe6: some other confirm action
