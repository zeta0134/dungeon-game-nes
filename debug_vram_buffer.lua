-- execution events that we want to track
local nmi_vector_addr = emu.getLabelAddress("nmi").address & 0xFFFF
local vram_enter_addr = emu.getLabelAddress("vram_zipper").address & 0xFFFF
local vram_transfer_start_addr = emu.getLabelAddress("vram_section_loop").address & 0xFFFF
local vram_transfer_end_addr = emu.getLabelAddress("vram_done_with_transfer").address & 0xFFFF
local vram_exit_addr = emu.getLabelAddress("done_with_vram_zipper").address & 0xFFFF
local nmi_soft_disable_addr = emu.getLabelAddress("nmi_soft_disable").address & 0xFFFF

local vram_table_entries_addr = 0x100
local vram_table_index_addr = 0x101
local vram_table_start = 0x108

local vram_table = {}
local vram_current_index = 0
local nmi_start_cycle = 0
local oam_start_cycle = 0
local nmi_danger_zone_cycle = 0

function nmi_routine_entered()
	nmi_start_cycle = emu.getState()["masterClock"]
end

function oam_dma_start()
	oam_start_cycle = emu.getState()["masterClock"] - nmi_start_cycle
end

function read_vram_table()
	num_entries = emu.read(vram_table_entries_addr, emu.memType.nesDebug)
	if num_entries == 0 then
		return {}
	end
	working_table = {}
	current_addr = vram_table_start
	for i = 1, num_entries do
		local ppu_high = emu.read(current_addr, emu.memType.nesDebug)
		current_addr = current_addr + 1
		local ppu_low = emu.read(current_addr, emu.memType.nesDebug)
		current_addr = current_addr + 1
		local header = emu.read(current_addr, emu.memType.nesDebug)
		current_addr = current_addr + 1
		local direction = "row"
		if header & 0x80 ~= 0 then
			direction = "col"
		end
		local length = 64 - ((header & 0x7F) >> 1)
		local ppuaddr = (ppu_high << 8) | ppu_low
		current_addr = current_addr + length
		entry = {ppuaddr=ppuaddr,direction=direction,length=length}
		table.insert(working_table, entry)
	end
	return working_table
end

function vram_routine_entered()
	vram_table = read_vram_table()
	vram_current_index = 1
end

function vram_transfer_started()
	vram_table[vram_current_index].startCycle = (emu.getState()["masterClock"] - nmi_start_cycle)
end

function vram_transfer_ended()
	vram_table[vram_current_index].endCycle = (emu.getState()["masterClock"] - nmi_start_cycle)
	vram_current_index = vram_current_index + 1
end

function transfer_type(address, direction)
	if address >= 0x3F00 then
		return "pal"
	end
	if (address & 0x03FF) > 0x03C0 then
		return "att"
	end
	if address >= 0x2000 then
		return direction
	end
	return "chr"
end

function draw_vram_table_text()
	-- just dump the whole list as ugly formatted strings
	for index, entry in ipairs(vram_table) do
		local tt = transfer_type(entry.ppuaddr, entry.direction)
		text = string.format("%s[%04X] Length: %s, Start: %s, End: %s",
			tt, entry.ppuaddr, entry.length, entry.startCycle, entry.endCycle)
		emu.drawString(10, 40 + index * 9, text, 0x00FFFFFF, 0x40200020)
	end
end

function cycle_coordinate(cycle, startx, width)
	local vblank_length = 2273
	local scaled_cycle = (cycle * width) / vblank_length
	return scaled_cycle + startx
end

function draw_timing_rectangle(start_cycle, end_cycle, color)
	local startx = cycle_coordinate(start_cycle, 11, 234)
	local endx = cycle_coordinate(end_cycle, 11, 234)
	emu.drawRectangle(startx, 31, endx - startx, 8, color, true)
end

function vram_entry_color(entry)
	tt = transfer_type(entry.ppuaddr, entry.direction)
	if tt == "row" then
		return 0x00FF0000
	end
	if tt == "col" then
		return 0x000000FF
	end
	if tt == "att" then
		return 0x00FFFF00
	end
	if tt == "pal" then
		return 0x00FF00FF
	end
end

function draw_vram_timings_graph()
	local vblank_length = 2270
	emu.drawRectangle(10, 30, 236, 10, 0x40000000, true)
	emu.drawRectangle(10, 30, 236, 10, 0x00000000, false)
	
	draw_timing_rectangle(oam_start_cycle, oam_start_cycle+514, 0x80FFFF80)
	for _, entry in ipairs(vram_table) do
		color = vram_entry_color(entry)
		draw_timing_rectangle(entry.startCycle, entry.endCycle, color)
	end
	draw_timing_rectangle(nmi_danger_zone_cycle, 2273, 0x80FFFFFF)
end

function vram_processing_done()
	nmi_danger_zone_cycle = emu.getState()["masterClock"] - nmi_start_cycle
	-- draw this stupid thing :D
	draw_vram_timings_graph()
	-- draw_vram_table_text()
end

emu.addMemoryCallback(nmi_routine_entered, emu.callbackType.exec, nmi_vector_addr)
emu.addMemoryCallback(vram_routine_entered, emu.callbackType.exec, vram_enter_addr)
emu.addMemoryCallback(vram_transfer_started, emu.callbackType.exec, vram_transfer_start_addr)
emu.addMemoryCallback(vram_transfer_ended, emu.callbackType.exec, vram_transfer_end_addr)
emu.addMemoryCallback(vram_processing_done, emu.callbackType.exec, nmi_soft_disable_addr)

emu.addMemoryCallback(oam_dma_start, emu.callbackType.write, 0x4014)

