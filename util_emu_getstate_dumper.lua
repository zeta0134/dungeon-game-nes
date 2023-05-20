state = emu.getState()
skeys = {}
for k in pairs(state) do
	table.insert(skeys, k)
end
table.sort(skeys)

for _,k in ipairs(skeys) do
	emu.log(string.format("%s: %s", k, state[k]))
end