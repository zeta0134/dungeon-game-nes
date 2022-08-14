        .setcpu "6502"
        .include "branch_util.inc"
        .include "camera.inc"
        .include "particles.inc"
        .include "physics.inc" ; needed for gravity
        .include "scrolling.inc"
        .include "sprites.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

        .segment "RAM"
NextParticleIndex: .res 1

particle_table:
        .repeat MAX_PARTICLES
        .tag ParticleState
        .endrepeat

        .segment "PRGFIXED_E000"

.proc update_particles
CurrentParticleIndex := R0
ScratchSpeed := R1
        ldx #0
        stx CurrentParticleIndex
loop:
        ldx CurrentParticleIndex
        lda particle_table + ParticleState::Lifetime, x
        beq done_with_this_particle
        dec particle_table + ParticleState::Lifetime, x
        ; all particles begin by applying constant speed
constant_speed:
        lda particle_table + ParticleState::SpeedX, x
        sta ScratchSpeed
        sadd16x particle_table + ParticleState::PositionX, ScratchSpeed
        lda particle_table + ParticleState::SpeedY, x
        sta ScratchSpeed
        sadd16x particle_table + ParticleState::PositionY, ScratchSpeed
        ; now particles might have special behavior
        lda particle_table + ParticleState::Behavior, x
        cmp #PARTICLE_GRAVITY
        bne no_gravity

        accelerate particle_table + ParticleState::SpeedY, #($FF-STANDARD_GRAVITY_ACCEL)
        max_speed particle_table + ParticleState::SpeedY, #($FF-STANDARD_TERMINAL_VELOCITY)
no_gravity:
        lda particle_table + ParticleState::Behavior, x
        cmp #PARTICLE_TILE_ANIM
        bne no_tile_animation

        dec particle_table + ParticleState::TileCounter, x
        bne no_tile_animation
        inc particle_table + ParticleState::TileIndex, x
        inc particle_table + ParticleState::TileIndex, x
        lda particle_table + ParticleState::TileDelay, x
        sta particle_table + ParticleState::TileCounter, x

no_tile_animation:
done_with_this_particle:
        lda CurrentParticleIndex
        clc
        adc #.sizeof(ParticleState)
        cmp #(.sizeof(ParticleState) * MAX_PARTICLES)
        beq done
        sta CurrentParticleIndex
        jmp loop
done:
        rts
.endproc

.proc draw_particles
CurrentParticleIndex := R0
ScratchX := R1
ScratchY := R3
        ldx #0
        stx CurrentParticleIndex
loop:
        ldx CurrentParticleIndex
        ; skip inactive particles
        lda particle_table + ParticleState::Lifetime, x
        jeq skip_particle
        ; skip every other particle, based on the parity between
        ; their index and the gameloop counter
        txa
        eor GameloopCounter
        and #%00000001
        jeq skip_particle

        ; convert the particle world coordinates into screen space
        lda particle_table + ParticleState::PositionX, x
        sta ScratchX
        lda particle_table + ParticleState::PositionX+1, x
        sta ScratchX+1
        lda particle_table + ParticleState::PositionY, x
        sta ScratchY
        lda particle_table + ParticleState::PositionY+1, x
        sta ScratchY+1
        .repeat 4
        lsr ScratchX+1
        ror ScratchX
        lsr ScratchY+1
        ror ScratchY
        .endrepeat

        ; now apply the camera, the same way sprites do
        sec
        lda ScratchX
        sbc CameraScrollPixelsX
        sta ScratchX
        lda ScratchX+1
        sbc CameraScrollPixelsX+1
        sta ScratchX+1

        sec
        lda ScratchY
        sbc CameraScrollPixelsY
        sta ScratchY
        lda ScratchY+1
        sbc CameraScrollPixelsY+1
        sta ScratchY+1

        ; the Y coordinate must additionally be offset by 8px to account for the
        ; top segment of the screen, which is blanked
        ; TODO: If we make this user configurable, we should use that value here
        clc
        add16 ScratchY, #8

        ; if the result is actually onscreen (high byte is 0)
        lda ScratchX+1
        bne skip_particle
        lda ScratchY+1
        bne skip_particle

        ; draw this particle :D (we probably need OAM state)
        ldy OAMEntryIndex
        lda ScratchX
        sta SHADOW_OAM + OAM_X_POS, y
        lda ScratchY
        sta SHADOW_OAM + OAM_Y_POS, y
        lda particle_table + ParticleState::TileIndex, x
        sta SHADOW_OAM + OAM_TILE, y
        lda particle_table + ParticleState::AttributeByte, x
        sta SHADOW_OAM + OAM_ATTRIBUTES, y

        tya
        clc
        adc #4
        sta OAMEntryIndex

skip_particle:
        lda CurrentParticleIndex
        clc
        adc #.sizeof(ParticleState)
        cmp #(.sizeof(ParticleState) * MAX_PARTICLES)
        beq done
        sta CurrentParticleIndex
        jmp loop
done:
        rts
.endproc
