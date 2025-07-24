ITEM_4TH  = 1
ITEM_8TH  = 2
ITEM_12TH = 3
ITEM_16TH = 4
ITEM_32ND = 5

max = {}
max[ITEM_4TH]  = 8*1
max[ITEM_8TH]  = 8*2
max[ITEM_12TH] = 8*3
max[ITEM_16TH] = 8*4
max[ITEM_32ND] = 8*5

items = {}
items.notes = 0
-- items.notes = 8*1 + 8*2 + 8*3 + 8*4 + 8*5

items.notesBuffMult = 1
items.stepBuffMult = 1
items.bpm = 60

function items.quantifyNotes()
	local count = {
		[ITEM_4TH] = 0,
		[ITEM_8TH] = 0,
		[ITEM_12TH] = 0,
		[ITEM_16TH] = 0,
		[ITEM_32ND] = 0,
	}

	if items.notes == 0 then return count end

	local idx = {ITEM_4TH, ITEM_8TH, ITEM_12TH, ITEM_16TH, ITEM_32ND}

	local a = items.notes
	while a > 0 do
		for _,i in ipairs(idx) do
			if count[i] < max[i] then
				count[i] = count[i] + 1
				break
			end
		end

		a = a - 1
	end

	return count
end

local noteItemBeats = {
	[ITEM_4TH] = 0,
	[ITEM_8TH] = 0,
	[ITEM_12TH] = 0,
	[ITEM_16TH] = 0,
	[ITEM_32ND] = 0,
}
update_hooks{'item update', function()
	local inventory = items.quantifyNotes()

	local noteSteps = 0
	for i in pairs(noteItemBeats) do
		local maxBeat = i
		if i == ITEM_32ND then maxBeat = 8 end
		maxBeat = 1 / maxBeat

		noteItemBeats[i] = noteItemBeats[i] - (delta_time * (items.bpm/60))

		while noteItemBeats[i] <= 0 do
			if items.notes > 0 and inventory[i] > 0 then
				local s = inventory[i]
				while s > 0 do
					noteSteps = noteSteps + 1
					s = s - 1
				end
			end

			noteItemBeats[i] = noteItemBeats[i] + maxBeat
		end
	end
	game.incrementSteps(noteSteps * items.notesBuffMult)

	fg('Game')('BPM'):settext('BPM: ' .. round2(items.bpm))
end}
