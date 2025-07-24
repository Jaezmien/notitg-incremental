MAX_NOTES = 8*1 + 8*2 + 8*3 + 8*4 + 8*5

shop = {}

shop.menuOpen = false
shop.cursorIndex = 1

function shop.areNotesAvailable()
	return items.notes + 1 <= MAX_NOTES
end
function shop.getNextAvailableNoteTiming()
	local note = items.notes + 1
	if note <= 8*1 then return ITEM_4TH end
	if note <= 8*2 then return ITEM_8TH end
	if note <= 8*3 then return ITEM_12TH end
	if note <= 8*4 then return ITEM_16TH end
	return ITEM_32ND
end
function shop.getNextNotePrice()
	local baseNotePrice = 50
	local notePriceIncrease = 20

	local price = decimal:Create(baseNotePrice)
	for _=1, items.notes do
		price = price:add(baseNotePrice + notePriceIncrease)
		baseNotePrice = math.floor(baseNotePrice * 1.25)
		notePriceIncrease = math.floor(notePriceIncrease * 1.01)
	end

	return price
end

shop.items = {
	{
		name = "Double Step",
		description = "Increase every player-made step by 2x",
		purchased = false,
		price = decimal:Create(100),
		effect = function() items.stepBuffMult = items.stepBuffMult * 2 end,
	},
	{
		name = "Crossover",
		description = "Increase every player-made step by 2x",
		purchased = false,
		price = decimal:Create(500),
		effect = function() items.stepBuffMult = items.stepBuffMult * 2 end,
	},
	{
		name = "Jack",
		description = "Increase every player-made step by 2x",
		purchased = false,
		price = decimal:Create(1000),
		effect = function() items.stepBuffMult = items.stepBuffMult * 2 end,
	},
	{
		name = "BPM Increase",
		description = "Increase the BPM by 5",
		purchased = false,
		price = decimal:Create(1500),
		effect = function() items.bpm = items.bpm + 5 end,
	},
	{
		name = "BPM Increase",
		description = "Increase the BPM by 5",
		purchased = false,
		price = decimal:Create(2000),
		effect = function() items.bpm = items.bpm + 5 end,
	},
	{
		name = "BPM Increase",
		description = "Increase the BPM by 5",
		purchased = false,
		price = decimal:Create(2500),
		effect = function() items.bpm = items.bpm + 5 end,
	},
	{
		name = "BPM Increase",
		description = "Increase the BPM by 5",
		purchased = false,
		price = decimal:Create(3000),
		effect = function() items.bpm = items.bpm + 5 end,
	},
	{
		name = "BPM Increase",
		description = "Increase the BPM by 5",
		purchased = false,
		price = decimal:Create(3500),
		effect = function() items.bpm = items.bpm + 5 end,
	},
}

function shop.getAvailableItems()
	local i = {}

	if shop.areNotesAvailable() then
		local label = {"4th Note", "8th Note", "12th Note", "16th Note", "32nd Note"}
		table.insert(i, {
			name = label[shop.getNextAvailableNoteTiming()],
			description = "An arrow for your receptor!\nEach beat produces a step.",
			purchased = false,
			price = shop.getNextNotePrice(),
			effect = function() items.notes = items.notes + 1 end,
		})
	end

	local stepExponent = game.steps.exponent

	for _,v in ipairs(shop.items) do
		local canPurchase = not v.purchased
		local priceVisibility = stepExponent >= v.price.exponent
		if canPurchase and priceVisibility then
			table.insert(i, v)
		end
	end

	return i
end

function shop.clampCursorIndex()
	if shop.cursorIndex < 1 then shop.cursorIndex = 1 end

	local shopItems = shop.getAvailableItems()
	local shopItemsCount = table.getn(shopItems)
	if shop.cursorIndex > shopItemsCount then shop.cursorIndex = table.getn(shopItems) end
end


IH:OnInput(IH.TYPE_STEP, 'menu step', function(col, pn)
	if pn == 1 then return end

	if col == IH.PLAYER_LEFT then
		shop.menuOpen = not shop.menuOpen
		return
	end

	if not shop.menuOpen then return end

	if col == IH.PLAYER_UP then
		shop.cursorIndex = shop.cursorIndex - 1
		shop.clampCursorIndex()
		return
	end
	if col == IH.PLAYER_DOWN then
		shop.cursorIndex = shop.cursorIndex + 1
		shop.clampCursorIndex()
		return
	end

	if col == IH.PLAYER_RIGHT then
		local shopItems = shop.getAvailableItems()
		if table.getn(shopItems) == 0 then return end

		local shopItem = shopItems[shop.cursorIndex]
		local canPurchase = game.steps:gte(shopItem.price)
		if not canPurchase then return end

		shopItem.effect()
		shopItem.purchased = true

		game.steps = game.steps:subtract(shopItem.price)

		shop.clampCursorIndex()
	end
end)

local menuPadding = 0
local function drawMenu(self)
	local shopItems = shop.getAvailableItems()
	if table.getn(shopItems) == 0 then return end

	local itemY = -menuPadding
	local itemWidth = 275
	local itemHeight = 75
	local itemPadding = 5

	local actorHighlight = self('Highlight')
	actorHighlight:horizalign('left')
	actorHighlight:vertalign('top')

	local actorText = self('Text')

	for i,v in ipairs(shopItems) do
		if shop.cursorIndex == i then
			actorHighlight:diffuse(1,1,1,0.2)
		else
			actorHighlight:diffuse(0,0,0,0.4)
		end
		actorHighlight:y(itemY)
		actorHighlight:zoomx(itemWidth)
		actorHighlight:zoomy(itemHeight)
		actorHighlight:Draw()

		local canPurchase = game.steps:gte(v.price)
		if canPurchase then
			actorText:diffuse(1,1,1,1)
		else
			actorText:diffuse(0.6,0.6,0.6,1)
		end

		-- Name
		actorText:settext(v.name)
		actorText:x(10)
		actorText:y(itemY + 10)
		actorText:horizalign('left')
		actorText:zoom(0.75)
		actorText:Draw()

		-- Description
		actorText:settext(v.description)
		actorText:wrapwidthpixels(itemWidth * 2)
		actorText:x(10)
		actorText:y(itemY + 35)
		actorText:horizalign('left')
		actorText:zoom(0.5)
		actorText:Draw()
		actorText:wrapwidthpixels(SCREEN_WIDTH)

		-- Price
		actorText:settext(getValueReadableText(v.price))
		actorText:x(itemWidth - 5)
		actorText:y(itemY + itemHeight - 20)
		actorText:horizalign('right')
		actorText:zoom(0.75)
		actorText:Draw()

		itemY = itemY + itemHeight + itemPadding
	end
end
fg('Shop')('Shop Contents'):SetDrawFunction(drawMenu)

update_hooks{'shop update', function()
	shop.clampCursorIndex()

	local shopItems = shop.getAvailableItems()
	local shopItemsCount = table.getn(shopItems)

	if shopItemsCount > 4 then
		if shop.cursorIndex > 3 and shop.cursorIndex < shopItemsCount-2 then
			-- middle
			menuPadding = clerp(menuPadding, (shop.cursorIndex-3)*(80), delta_time*8)
		elseif shop.cursorIndex >= shopItemsCount-2 then
			-- bottom
			menuPadding = clerp(menuPadding, (shopItemsCount-5)*(80), delta_time*8)
		else
			-- top
			menuPadding = clerp(menuPadding, 0, delta_time*8)
		end
	else
		menuPadding = clerp(menuPadding, 0, delta_time*8)
	end

	if shop.menuOpen then
		fg('Game'):x( clerp(fg('Game'):GetX(), -SCREEN_CENTER_X*0.5, delta_time * 6) )
		fg('Shop'):x( clerp(fg('Shop'):GetX(), SCREEN_CENTER_X*1.0, delta_time * 10) )
	else
		fg('Game'):x( clerp(fg('Game'):GetX(), 0, delta_time * 6) )
		fg('Shop'):x( clerp(fg('Shop'):GetX(), SCREEN_WIDTH, delta_time * 10) )
	end
end}
