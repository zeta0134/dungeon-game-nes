entity_table = emu.getLabelAddress("entity_table")
ENTITY_SIZE = 16

struct_members = {
  {name="UpdateFunc",size="word",offset=0},
  {name="PositionX",size="word",offset=2},
  {name="PositionY",size="word",offset=4},
  {name="PositionZ",size="word",offset=6},
  {name="Data[SpeedX]",size="byte",offset=8},
  {name="Data[SpeedY]",size="byte",offset=9},
  {name="Data[SpeedZ]",size="byte",offset=10},
  {name="GroundLevel",size="byte",offset=11},
  {name="MetaSpriteIndex",size="byte",offset=12},
  {name="ShadowSpriteIndex",size="byte",offset=13},
  {name="Data[CollisionMask]",size="byte",offset=14},
  {name="Data[CollisionResponse]",size="byte",offset=15},
  {name="Data[Flags0]",size="byte",offset=16},
  {name="Data[Flags1]",size="byte",offset=17},
  {name="Data[Flags2]",size="byte",offset=18},
  {name="Data[Flags3]",size="byte",offset=19},
  {name="Data[Flags4]",size="byte",offset=20},
}

y_offset = 10

function draw_parameter(label, value)
  parameter_string = string.format("%s: %s", label, value)
  emu.drawString(10, y_offset, parameter_string, 0x00FFFFFF, 0x40200020)
  y_offset = y_offset + 9
end

function word_value(address)
  local low_byte = emu.read(address, emu.memType.cpuDebug)
  local high_byte = emu.read(address + 1, emu.memType.cpuDebug)
  local combined_byte = (high_byte << 8) | low_byte
  return string.format("$%04X", combined_byte)
end

function byte_value(address)
  local byte = emu.read(address, emu.memType.cpuDebug)
  return string.format("$%02X", byte)
end

function draw_entity_labels(entity_index)
  y_offset = 10
  for i,v in ipairs(struct_members) do
    address = entity_table + (entity_index * ENTITY_SIZE) + v.offset
    value = "invalid size"
    if v.size == "word" then
        value = word_value(address)
    end
    if v.size == "byte" then
        value = byte_value(address)
    end
    draw_parameter(v.name, value) 
  end
end

buttons_held_addr = emu.getLabelAddress("ButtonsHeld")
buttons_down_addr = emu.getLabelAddress("ButtonsDown")
buttons_up_addr = emu.getLabelAddress("ButtonsUp")

function draw_input_vars()
  y_offset = 160
  local buttons_held = byte_value(buttons_held_addr)
  local buttons_down = byte_value(buttons_down_addr)
  local buttons_up = byte_value(buttons_up_addr)
  draw_parameter("InputButtonsHeld", buttons_held)
  draw_parameter("InputButtonsDown", buttons_down) 
  draw_parameter("InputButtonsUp", buttons_up) 
end

function draw()
    draw_entity_labels(0)
    --draw_input_vars()
end

emu.addEventCallback(draw, emu.eventType.nmi)