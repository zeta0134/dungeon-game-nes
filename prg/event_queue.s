        .setcpu "6502"

        .include "event_queue.inc"
        .include "far_call.inc"
        .include "input.inc"
        .include "kernel.inc"
        .include "nes.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "RAM"
event_current: .res 1
event_next: .res 1
event_count: .res 1

events_type:  .res ::MAX_EVENTS
events_pos_x: .res ::MAX_EVENTS
events_pos_y: .res ::MAX_EVENTS
events_id:    .res ::MAX_EVENTS
events_data0: .res ::MAX_EVENTS
events_data1: .res ::MAX_EVENTS
events_data2: .res ::MAX_EVENTS
events_data3: .res ::MAX_EVENTS
events_data4: .res ::MAX_EVENTS


        .segment "PRGFIXED_8000"

; To use: first write all event data into events_N,x with X set to event_next
; Then call this function, and the relevant pointers are adjusted
.proc add_event
        inc event_next
        lda event_next
        and #EVENT_INDEX_MASK
        sta event_next
        inc event_count
        ; TODO: if count is now >= MAX_EVENTS we should probably crash on purpose
        rts
.endproc

; After reading the data in events_N,x indexed by event_current, call this function
; to advance the pointers and counters
.proc consume_event
        inc event_current
        lda event_current
        and #EVENT_INDEX_MASK
        sta event_current
        dec event_count
        rts
.endproc

