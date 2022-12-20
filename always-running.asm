;; always-running.asm
;; mszegedy 2022

;;; internal constants (NOT SETTINGS)
!use_lr = 0
!use_y = 1
!l_mask = $20
!r_mask = $10

;;; SETTINGS
;; two kinds of control scheme:
;; -- !use_lr: always run and grab. l cancels run, r cancels grab
;; -- !use_y:  always run and grab. y cancels both.
;; set !control_scheme to either to use that scheme.
!control_scheme = !use_lr

;;; sa1 compatibility
!sa1 = 0
!base2 = $0000
if read1($00ffd5) == $23
  sa1rom
  !sa1 = 1
  !base2 = $6000
endif

;;; macros for annoying bits (get it, bits?)
macro is_lr_not_held_to_v(bitmask)
  ;; sets v flag to 1 if one of l or r is not held, 0 if it is. call with
  ;; !l_mask as argument to check if l is held, or with !r_mask to check if
  ;; r is held.
  lda $17
  and #<bitmask>
  beq +
  clv
  bra ++
+
  sep #$40
++
endmacro

;;; actual code
if !control_scheme == !use_lr
  ;; disable l/r scrolling
  org $cdfc
    db $80

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

  ;; 01e6ce: carrying springboards
  org $01e6ce
    autoclean jsl springboard_hijack
    bra +
    nop #$e
  +

  freecode
  running_hijack:
    ldy #$00  ; recovered from rom
    %is_lr_not_held_to_v(!l_mask)
    rtl

  kicking_hijack:
    bne +  ; replaces a bne in rom
    %is_lr_not_held_to_v(!r_mask)
    rtl
  +
    ; there's a bvc between where the rtl takes us and where the bne's original
    ; destination is. setting v will turn it into a functional nop.
    sep #$40
    rtl

  springboard_hijack:
    ;; we have to recover an annoying amount of code here bc of space constraints
    lda $17   ; \
    and #$10  ;  | if r is held, don't grab
    bne +     ; /
    lda $1470|!base2  ; \  if holding enemy,
    ora $187a|!base2  ;  | or on yoshi, also don't grab
    bne +             ; /
    lda #$0b          ; \
    if !sa1           ;  | the part where you grab it. (the sta sets the sprite's
      sta $3242,x     ;  | status to grabbed, the stz puts it in front of you.)
      stz $33ce,x     ;  | the sa-1 patch completely rearranges the sprite
    else              ;  | property tables so we use completely different
      sta $14c8,x     ;  | addresses for it. (i had to look them up in the sa-1
      stz $1602,x     ;  | address remap manual.)
    endif             ; /
  +
    rtl
else
  ;; if we're just inverting the use of y then it's way easier. we just change
  ;; a bunch of bvcs into bvses, and one beq to a bne.
  org $d717    ; running
    db $70  ; bvc > bvs
  org $01a00f  ; kicking
    db $70  ; bvc > bvs
  org $01aa5c  ; carrying
    db $d0  ; beq > bne
  org $01e6d0  ; carrying springboards (why does this have its own routine?)
    db $70  ; bvc > bvs
endif

;;; catalogue of $16 uses; leaving alone for now
;; 009b24: start game? why just x/y?
;; 00d068: cape spin and... yoshi?
;; 00d08c: fire flower
;; 00db98: swimming
;; 00f26b: something to do with blocks
;; 01da2f: yoshi?
;; 01f1e5: some sprite interaction
;; 049150: enter level from overworld
;; 0ccfe6: some other confirm action
