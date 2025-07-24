local noteRingLookup = {'4th', '8th', '12th', '16th', '32nd'}
local function drawNoteRing(self)
	local baseRadius = 100

	for ring, count in pairs(items.quantifyNotes()) do
		local radius = baseRadius + (64 * (ring - 1))
		local beat = ring
		if ring == ITEM_32ND then beat = 8 end
		radius = radius + math.abs(math.sin(game.time * math.pi * beat)) * 8

		local maxCount = max[ring]
		local opacity = 1 - ((ring-1) / 4.5)
		local note = self(noteRingLookup[ring])
		for i=1,count do
			local t = (i-1) / maxCount

			note:x(math.sin(t * math.pi * 2) * radius)
			note:y(-math.cos(t * math.pi * 2) * radius)
			note:rotationz(t * 360)
			note:diffusealpha(opacity)
			note:Draw()
		end
	end
end
fg('Game')('Note Ring'):SetDrawFunction(drawNoteRing)

local receptorZoom = 2
IH:OnInput(IH.TYPE_STEP, 'render step', function(_, pn)
	if pn == 1 then
		receptorZoom = 1.5
		return
	end
end)

update_hooks{'render update', function()
	receptorZoom = clerp(receptorZoom, 2, delta_time * 8)

	fg('Game')('Receptor'):rotationz(math.mod(game.time * 64,360))
	fg('Game')('Receptor'):zoom(receptorZoom)
end}
