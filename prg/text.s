        .include "dialog.inc"
        .include "text.inc"

        .segment "UTILITIES_A000"

test_message:
        ;     |0123456789012345678901|
        ;     |     safe width       |
        ;     |----------------------|
        .byte D_PORTRAIT, 16, 0
        .byte D_TIMBRE, $1
        .byte "Hello world!"
        .byte D_WAIT, D_CLEAR
        .byte "Several screens!"
        .byte D_WAIT, D_CLEAR
        .byte "Several lines of", D_LF
        .byte "text, separated by", D_LF
        .byte "line breaks."
        .byte D_WAIT, D_EXIT

lorem_ipsum:
        .byte D_PORTRAIT, 16, 0
        .byte D_TIMBRE, $0
        ;     |----------------------|
        .byte "Lorem ipsum dolor sit", D_LF
        .byte "amet, consectetur", D_LF
        .byte "adipiscing elit, sed"
        .byte D_WAIT, D_CLEAR
        ;     |----------------------|
        .byte "do eiusmod tempor", D_LF
        .byte "incididunt ut labore", D_LF
        .byte "et dolore magna"
        .byte D_WAIT, D_CLEAR
        ;     |----------------------|
        .byte "aliqua."
        .byte D_WAIT, D_CLEAR

        .byte D_PORTRAIT, 16, 18
        .byte D_TIMBRE, $1
        ;     |----------------------|
        .byte "Ut enim ad minim", D_LF
        .byte "veniam, quis nostrud", D_LF
        .byte "exercitation ullamco"
        .byte D_WAIT, D_CLEAR
        ;     |----------------------|
        .byte "laboris nisi ut", D_LF
        .byte "aliquip ex ea commodo", D_LF
        .byte "consequat."
        .byte D_WAIT, D_EXIT

sign_test_dialog:
        ;     |0123456789012345678901|
        ;     |     safe width       |
        ;     |----------------------|
        .byte D_PORTRAIT, 16, 0
        .byte D_TIMBRE, $1
        .byte "This sign has some", D_LF
        .byte "text on it. Isn't that", D_LF
        .byte "neat?"
        .byte D_WAIT, D_EXIT

