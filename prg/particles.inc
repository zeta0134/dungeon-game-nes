.global NextParticleIndex, particle_table
.global update_particles, draw_particles

MAX_PARTICLES = 8

PARTICLE_STANDARD = %00000000 ; no special behaviors
PARTICLE_GRAVITY  = %00000001

.struct ParticleState
        PositionX .word ; Most entities will have a position, but if not needed, these can be repurposed
        PositionY .word
        SpeedX .byte
        SpeedY .byte
        TileIndex .byte
        AttributeByte .byte
        Behavior .byte
        Lifetime .byte
.endstruct

; spawn a particle relative to an entity
; assumes the entity has its index in X
; clobbers Y for its own purposes
.macro spawn_basic_particle xoff, yoff, xspeed, yspeed, tile_index, behavior, lifetime
.scope
        ldy NextParticleIndex
        clc
        lda entity_table + EntityState::PositionX, x
        adc #<xoff
        sta particle_table + ParticleState::PositionX, y
        lda entity_table + EntityState::PositionX+1, x
        adc #>xoff
        sta particle_table + ParticleState::PositionX+1, y

        clc
        lda entity_table + EntityState::PositionY, x
        adc #<yoff
        sta particle_table + ParticleState::PositionY, y
        lda entity_table + EntityState::PositionY+1, x
        adc #>yoff
        sta particle_table + ParticleState::PositionY+1, y

        lda xspeed
        sta particle_table + ParticleState::SpeedX, y
        lda yspeed
        sta particle_table + ParticleState::SpeedY, y
        lda tile_index
        sta particle_table + ParticleState::TileIndex, y
        lda behavior
        sta particle_table + ParticleState::Behavior, y
        lda lifetime
        sta particle_table + ParticleState::Lifetime, y
        
        clc
        lda #.sizeof(ParticleState)
        adc NextParticleIndex
        cmp #(.sizeof(ParticleState) * MAX_PARTICLES)
        bne done
        lda #0
done:
        sta NextParticleIndex
.endscope
.endmacro