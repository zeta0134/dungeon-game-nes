﻿performance_counters = {}
last_color_emphasis = 0
last_cycle_count = 0

color_names = {
  [0]="none",
  [1]="red",
  [2]="green",
  [3]="yellow",
  [4]="blue",
  [5]="magenta",
  [6]="cyan",
  [7]="dark"
}

function ppumask_write(address, value)
  local emu_state = emu.getState() 
  local new_emphasis_bits = ((value & 0xE0) >> 5)
  local duration = emu_state.cpu.cycleCount - last_cycle_count
  last_cycle_count = emu_state.cpu.cycleCount
  
  performance_counters[last_color_emphasis] = duration
  last_color_emphasis = new_emphasis_bits
end

y_offset = 0

function draw_parameter(label, value)
  parameter_string = string.format("%s: %s", label, value)
  emu.drawString(10, y_offset, parameter_string, 0x00FFFFFF, 0x40200020)
  y_offset = y_offset + 9
end

function draw_performance_counters()
  y_offset = 10
  for k,v in pairs(performance_counters) do
    draw_parameter(color_names[k], v)
  end
end

function frame_start()
  draw_performance_counters()
  --now reset performance counters for the next frame
  performance_counters = {}
end


emu.addEventCallback(frame_start, emu.eventType.nmi)
emu.addMemoryCallback(ppumask_write, emu.memCallbackType.cpuWrite, 0x2001)