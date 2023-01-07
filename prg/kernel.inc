.globalzp GameMode
.global TargetMapAddr, TargetMapBank, TargetMapEntrance, PlayfieldPpuMask
.global HitstunTimer

; fixed bank for ... y'know, it's tiny
.global wait_for_next_vblank


.global FAR_run_kernel

; kernel states; technically functions, yes, but not far-callable
.global init_engine
.global standard_gameplay_loop
.global hitstun_gameplay_loop
.global load_new_map
.global blackout_to_new_map
.global dialog_init
.global dialog_closing
.global subscreen_init
.global return_from_subscreen