---@param a number
---@param b number
---@param t number
---@return number
function lerp(a,b,t) return a+(b-a)*t end

---@param a number
---@param b number
---@param t number
---@param p number?
---@return number
function clerp(a,b,t,p)
	p = p or 2
	local precision = 1 / math.pow(10, p)

	local v = lerp(a,b,t)
	if math.abs(b-v) <= precision then return b end
	return v
end

---@param value number
---@param decimals number?
---@return number
function round2(value, decimals)
	decimals = math.max(0, decimals or 0)
	if decimals == 0 then return math.floor(value) end

	local amt = math.pow(10, decimals)
	value = value * amt
	value = math.floor(value)
	value = value / amt

	return value
end

function getValueReadableText(d)
	local m = d.mantissa
	local e = d.exponent

	-- ones, tens, hundreds, thousands
	if e < 6 then return d:tostring() end

	local r = {
		'million',
		'billion',
		'trillion',
		'quadrillion',
		'quintillion',
		'sextillion',
		'septillion',
		'octillion',
		'nonillion',
		'decillion',
		'undecillion',
		'duodecillion',
		'tredecillion',
		'quattuordecillion',
		'quindecillion',
		'sexdecillion',
		'septendecillion',
		'octodecillion',
		'novemdecillion',
		'vigintillion',
		'centillion'
	}
	for i=1, table.getn(r) do
		local rangeMin = 6 + (i-1) * 3
		local rangeMax = rangeMin + 2

		if e >= rangeMin and e <= rangeMax then
			if e >= rangeMin+1 then m = m*10 end
			if e >= rangeMin+2 then m = m*10 end

			return string.format('%.3f %s', round2(m,3), r[i])
		end
	end

	return 'Infinity'
end
