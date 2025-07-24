game = {}
game.time = 0
game.steps = decimal:Create(0)

---@param value number
function game.incrementSteps(value)
	if value ~= 0 then
		game.steps = game.steps:add(round2(value))
	end
	fg('Game')('Steps'):settext(getValueReadableText(game.steps))
end
game.incrementSteps(0)

IH:OnInput(IH.TYPE_STEP, 'game step', function(_, pn)
	if pn == 1 then
		game.incrementSteps(1 * items.stepBuffMult)
		fg('Game')('Receptor'):playcommand('Step')

		return
	end
end)

update_hooks{'game update', function()
	game.time = game.time + delta_time
end}
