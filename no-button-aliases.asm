;; no-button-aliases.asm
;; mszegedy 2022

;; options to re-enable the aliases
!enable_xy_alias = 0
!enable_ab_alias = 0

; the calculated aliasing bitmask for which bits to OR together
!mask = (!enable_ab_alias<<7)|(!enable_xy_alias<<6)

if !mask == $c0
  warn "Both things this patch does are disabled, so it will do nothing."
endif

;; sa1 compatibility
!base2 = $0000
if read1($00ffd5) == $23
  sa1rom
  !base2 = $6000
endif

org $86a8
  lda $0da4|!base2,x    ; \  copied from $86b2 thru $86b6
  sta $17               ; /

  ; replaces $86a8 thru $86b1; handles held buttons
  if !mask
    and #!mask          ; $0da4 is still in a
    ora $0da2|!base2,x
  else
    lda $0da2|!base2,x
  endif
  sta $15

  lda $0da8|!base2,x    ; \
  sta $18               ; /  copied from $86c1 thru $86c5

  ; replaces $86b7 thru $86c0; handles buttons pressed this frame
  if !mask
    and #!mask          ; $0da8 is still in a
    ora $0da6|!base2,x
  else
    lda $0da6|!base2,x
  endif
  sta $16

  ; replaces $86c6
  rts
