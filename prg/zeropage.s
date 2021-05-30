        .setcpu "6502"
        .exportzp GameloopCounter, LastNmi
        .exportzp R0,R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12,R13,R14,R15
        .zeropage
; General purpose registers, used as sort of a quick stack alternative.
; Clobbered frequently.
R0: .byte $00
R1: .byte $00
R2: .byte $00
R3: .byte $00
R4: .byte $00
R5: .byte $00
R6: .byte $00
R7: .byte $00
R8: .byte $00
R9: .byte $00
R10: .byte $00
R11: .byte $00
R12: .byte $00
R13: .byte $00
R14: .byte $00
R15: .byte $00
; Gameplay and graphics globals
GameloopCounter: .byte $00
LastNmi: .byte $00
