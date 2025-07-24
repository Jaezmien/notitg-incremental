-- break_infinity.js by Patashu (https://github.com/Patashu/break_infinity.js)
-- partial port to Lua 5.0 by Jaezmien (https://jaezmien.com)

-- "its actually very clampicated"

local MAX_SIGNIFICANT_DIGITS = 17
local EXP_LIMIT = 9e15
local NUMBER_EXP_MAX = 308
local NUMBER_EXP_MIN = -324
local ROUND_TOLERANCE = 1e-10
local POSITIVE_INF = 1/0
local NEGATIVE_INF = -POSITIVE_INF

---@param value number
---@return boolean
local function isFinite(value)
	return value ~= POSITIVE_INF and value ~= NEGATIVE_INF
end

---@param str string
---@param sep string
---@return table
local function split(str,sep)
	sep = sep or ' '
	local fields = {}
	local pattern = string.format('([^%s]+)', sep)
	string.gsub(str, pattern, function(c) fields[table.getn(fields)+1] = c end)
	return fields
end

---@param num number
---@return number
local function sign(num)
	if num == 0 then return 0 end
	if num < 0 then return -1 end
	if num > 0 then return 1 end
	return 0 -- should not be possible but whatever
end

---@param num number
---@return number
local function round(num)
	return math.floor(num + 0.5)
end

local pow10Lookup = {}
for i=NUMBER_EXP_MIN+1, NUMBER_EXP_MAX, 1 do table.insert(pow10Lookup, tonumber("1e"..i)) end
local _indexOf0InPow10 = 323
---@param pow number
---@return number
local function powerOf10(pow) return pow10Lookup[_indexOf0InPow10 + 1 + pow] end

---@param value any
---@return boolean
local function isDecimalSource(value)
	if type(value)=='number' then return true end
	if type(value)=='string' then return true end
	if type(value)=='table' and type(value.mantissa)=='number' and type(value.exponent)=='number' then return true end
	return false
end

---@class Decimal
---@field mantissa number
---@field exponent number

---@alias PossibleDecimal number|string|Decimal

---@param t any
---@return boolean
local function isDecimal(t)
	return type(t)=='table' and t.__classID=='decimal'
end

---@param value any
---@return table
local function asDecimal(value)
	if isDecimal(value) then return value end

	if not isDecimalSource(value) then
		error('Invalid decimal: ' .. tostring(value) .. ', setting as 0')
		return decimal:Create(0)
	end

	return decimal:Create(value)
end

---@param leftDecimal any
---@param rightDecimal any
---@return number
local function cmp(leftDecimal, rightDecimal)
	if not isDecimal(leftDecimal) or not isDecimal(rightDecimal) then
		error('Attempt comparison on non-decimal number')
		return 0
	end

	if leftDecimal.mantissa==0 then
		if rightDecimal.mantissa == 0 then return  0 end
		if rightDecimal.mantissa  < 0 then return  1 end
		if rightDecimal.mantissa  > 0 then return -1 end
	end
	if rightDecimal.mantissa==0 then
		if leftDecimal.mantissa < 0 then return -1 end
		if leftDecimal.mantissa > 0 then return  1 end
	end

	if leftDecimal.mantissa>0 then
		if rightDecimal.mantissa < 0 then return 1 end

		if leftDecimal.exponent > rightDecimal.exponent then return  1 end
		if leftDecimal.exponent < rightDecimal.exponent then return -1 end
		if leftDecimal.mantissa > rightDecimal.mantissa then return  1 end
		if leftDecimal.mantissa < rightDecimal.mantissa then return -1 end

		return 0
	end

	if leftDecimal.mantissa<0 then
		if rightDecimal.mantissa > 0 then return -1 end

		if leftDecimal.exponent > rightDecimal.exponent then return -1 end
		if leftDecimal.exponent < rightDecimal.exponent then return  1 end
		if leftDecimal.mantissa > rightDecimal.mantissa then return  1 end
		if leftDecimal.mantissa < rightDecimal.mantissa then return -1 end

		return 0
	end

	error('Unreachable cmp code')
	return 0
end

decimal = class:New(
	'decimal',
	{
		--[[
		   A number (double) with absolute value between [1, 10) OR exactly 0.
		   If mantissa is ever 10 or greater, it should be normalized
		   (divide by 10 and add 1 to exponent until it is less than 10,
		   or multiply by 10 and subtract 1 from exponent until it is 1 or greater).
		   Infinity/-Infinity/NaN will cause bad things to happen.
		--]]
		mantissa = 0,

		--[[
		   A number (integer) between -EXP_LIMIT and EXP_LIMIT.
		   Non-integral/out of bounds will cause bad things to happen.
		--]]
		exponent = 0,

		clone = function(self)
			return decimal:Create({ mantissa = self.mantissa, exponent = self.exponent })
		end,

		---@param mantissa number
		---@param exponent number
		---@param normalize boolean
		setMantissaExponent = function(self, mantissa, exponent, normalize)
			self.mantissa = mantissa
			self.exponent = exponent
			if normalize then self:normalize() end
			return self
		end,

		normalize = function(self)
			if self.mantissa >= 1 and self.mantissa <= 10 then return self end
			if self.mantissa == 0 then
				self.mantissa = 0
				self.exponent = 0
				return self
			end

			local tempExponent = math.floor(math.log10(math.abs(self.mantissa)))
			self.mantissa =
				(tempExponent == NUMBER_EXP_MIN) and
					(self.mantissa * 10 / 1e-323) or
					(self.mantissa / powerOf10(tempExponent))
			self.exponent = self.exponent + tempExponent
			return self
		end,

		isFinite = function(self)
			return isFinite(self.mantissa)
		end,

		--- Compare two decimals. `0` if equal, `-1` if smaller than value, `1` if larger than value
		---@param value PossibleDecimal 
		---@return number
		compare = function(self, value) return cmp(self, asDecimal(value)) end,
		---@param value PossibleDecimal 
		---@return boolean
		eq = function(self, value) return cmp(self, asDecimal(value)) == 0 end,
		---@param value PossibleDecimal 
		---@return boolean
		neq = function(self, value) return cmp(self, asDecimal(value)) ~= 0 end,
		---@param value PossibleDecimal 
		---@return boolean
		lt = function(self, value) return cmp(self, asDecimal(value)) == -1 end,
		---@param value PossibleDecimal 
		---@return boolean
		gt = function(self, value) return cmp(self, asDecimal(value)) == 1 end,
		---@param value PossibleDecimal 
		---@return boolean
		lte = function(self, value) return cmp(self, asDecimal(value)) ~= 1 end,
		---@param value PossibleDecimal 
		---@return boolean
		gte = function(self, value) return cmp(self, asDecimal(value)) ~= -1 end,

		---@return number
		tonumber = function(self)
			if not self:isFinite() then
				return self.mantissa
			end

			if self.exponent > NUMBER_EXP_MAX then
				return self.mantissa > 0 and POSITIVE_INF or -NEGATIVE_INF
			end

			if self.exponent < NUMBER_EXP_MIN then
				return 0
			end

			if self.exponent == NUMBER_EXP_MIN then
				return self.mantissa > 0 and 5e-324 or -5e-324
			end

			local result = self.mantissa * powerOf10(self.exponent)
			if isFinite(result) or self.exponent < 0 then return result end
			local resultRounded = round(result)
			if math.abs(resultRounded - result) < ROUND_TOLERANCE then return resultRounded end
			return result
		end,

		---@return string
		tostring = function(self)
			if not self:isFinite() then
				return tostring(self.mantissa)
			end

			if self.exponent < -EXP_LIMIT or self.mantissa == 0 then
				return "0"
			end
			if self.exponent < 21 and self.exponent > -7 then
				return tostring(self:tonumber())
			end

			return tostring(self.mantissa) .. "e" .. (self.exponent >= 0 and "+" or "") .. tostring(self.exponent)
		end,

		abs = function(self) return decimal:Create():setMantissaExponent(math.abs(self.mantissa), self.exponent, false) end,
		negate = function(self) return decimal:Create():setMantissaExponent(-self.mantissa, self.exponent, false) end,
		---@return number
		sign = function(self) return sign(self.mantissa) end,
		floor = function(self)
			if not self:isFinite() then return self end

			if self.exponent < -1 then
				return sign(self.mantissa) >= 0 and decimal:Create(0) or decimal:Create(-1)
			end
			if self.exponent < MAX_SIGNIFICANT_DIGITS then
				return decimal:Create(math.floor(self:tonumber()))
			end
			return self
		end,
		ceil = function(self)
			if self.exponent < -1 then
				return sign(self.mantissa) > 0 and decimal:Create(1) or decimal:Create(0)
			end
			if self.exponent < MAX_SIGNIFICANT_DIGITS then
				return decimal:Create(math.ceil(self:tonumber()))
			end
			return self
		end,

		---@param value PossibleDecimal
		add = function(self, value)
			if not self:isFinite() then return self end

			local valueDecimal = asDecimal(value)

			if not valueDecimal:isFinite() then return valueDecimal end

			if self.mantissa == 0 then return valueDecimal end
			if valueDecimal.mantissa == 0 then return self end

			local biggerDecimal
			local smallerDecimal
			if self.exponent >= valueDecimal.exponent then
				biggerDecimal = self
				smallerDecimal = valueDecimal
			else
				biggerDecimal = valueDecimal
				smallerDecimal = self
			end

			if biggerDecimal.exponent - smallerDecimal.exponent > MAX_SIGNIFICANT_DIGITS then
				return biggerDecimal
			end

			local mantissa = round(1e14 * biggerDecimal.mantissa +
				1e14 * smallerDecimal.mantissa * powerOf10(smallerDecimal.exponent - biggerDecimal.exponent))

			return decimal:Create():setMantissaExponent(mantissa, biggerDecimal.exponent - 14, true)
		end,
		---@param value PossibleDecimal
		subtract = function(self, value)
			return self:add(asDecimal(value):negate())
		end,
		---@param value PossibleDecimal
		multiply = function(self, value)
			if type(value)=='number' then
				if value < 1e307 and value > -1e307 then
					return decimal:Create():setMantissaExponent(self.mantissa * value, self.exponent, true)
				end

				return decimal:Create():setMantissaExponent(self.mantissa * 1e-307 * value, self.exponent + 307)
			end

			local d = asDecimal(value)
			return decimal:Create():setMantissaExponent(self.mantissa * d.mantissa, self.exponent * d.exponent, true)
		end,
		reciprocal = function(self)
			return decimal:Create():setMantissaExponent(1 / self.mantissa, -self.exponent)
		end,
		---@param value PossibleDecimal
		divide = function(self, value)
			return self:multiply(asDecimal(value):reciprocal())
		end,
	},
	function(self, value)
		if value == nil then return end

		if not isDecimalSource(value) then
			error('[Decimal] Invalid source value')
			return
		end

		if type(value)=='string' then
			value = string.lower(value)
			if string.find(value, 'e') ~= nil then
				local parts = split(value, "e")
				if table.getn(parts) == 2 then
					self.mantissa = tonumber(parts[1])
					if self.mantissa == nil then self.mantissa = 1 end
					self.exponent = tonumber(parts[2])
					self:normalize()
					return
				end
			end
			value = tonumber(value)
		end

		if type(value)=='number' then
			if not isFinite(value) then
				self.mantissa = value
				self.exponent = 0
				return
			end

			if value == 0 then
				self.mantissa = 0
				self.exponent = 0
				return
			end

			self.exponent = math.floor(math.log10(math.abs(value)))
			self.mantissa =
				(self.exponent == NUMBER_EXP_MIN) and
					(value * 10 / 1e-323) or
					(value / powerOf10(self.exponent))
			self:normalize()
			return
		end

		if type(value)=='table' then
			self.mantissa = value.mantissa
			self.exponent = value.exponent
		end
	end
)
