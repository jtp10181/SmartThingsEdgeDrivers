--
-- Zooz Utils
--

local log = require "log"
local zooz_utils = {}
zooz_utils.tests = {}

--- @param messageFormatstring string message can be format string for additional parameters
function zooz_utils.logMessage(messageFormatstring, ...)
  local message = string.format(messageFormatstring, ...)
  log.warn(string.format("***MESSAGE*** %s", message))
end

--- @param value boolean assert throws exception and displays message when value is false
--- @param messageFormatstring string message can be format string for additional parameters
function zooz_utils.tests.custom_assert(value, messageFormatstring, ...)
  local message = string.format(messageFormatstring, ...)
  assert(value, string.format("\n\n***ASSERT FAILED*** %s\n", message))
end

--- @param device st.zwave.Device
--- @param name string Identifier for the code being executed
--- @param rateLimitSeconds number  Default value is 1 Second
--- @return boolean True if enough time hasn't past since the code was last executed".
function zooz_utils.execution_rate_limit_exceeded(device, name, rateLimitSeconds)
  if rateLimitSeconds == nil then
    rateLimitSeconds = 1
  end

  local field = string.format("%s_last_executed", name)
  local lastExecuted = device:get_field(field)
  if (lastExecuted == nil or os.difftime(lastExecuted, os.time()) < (rateLimitSeconds * -1)) then
    device:set_field(field, os.time(), { persist = true })
    return false
  else
    return true
  end
end

--- @param t table
--- @param value
function zooz_utils.find_key_by_value(t, value)
  for id, val in pairs(t) do
    if val == value then
      return id
    end
  end
  return nil
end

--- @param value string
--- @param separator string
--- @return table returns empty table if nil
function zooz_utils.string_split(value, separator)
  local values = {}
  if separator == nil then
    separator = ","
  end

  if value ~= nil and (string.len(value) > 0) then
    for str in string.gmatch(value, "([^" .. separator .. "]+)") do
      table.insert(values, str)
    end
  end
  return values
end

--- @param value string
--- @return string
function zooz_utils.string_trim(value)
  if value ~= nil then
    return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
  end
end

--- @param value number
--- @param size number optional byte size for leading 0s
--- @return string
function zooz_utils.number_to_hex(value, size)
  value = (value ~= nil and value or 0)
  if size ~= nil then
    local hexFormat = string.format("%%0%sx", size * 2)
    return string.upper(string.format(hexFormat, value))
  else
    local hexValue = string.upper(string.format("%x", value))
    if (string.len(hexValue) % 2) ~= 0 then
      hexValue = string.format("0%s", hexValue)
    end
    return hexValue
  end
end

--- @param value string
--- @param default number optional return value when nil
--- @return number
function zooz_utils.hex_to_number(value, default)
  local numberValue = tonumber(value, 16)
  return (numberValue ~= nil and numberValue or default)
end

--- @param value number
--- @param size number
--- @return number
function zooz_utils.convert_to_signed_integer(value, size)
  if value ~= nil and size ~= nil then
    local size_factor = math.floor(256 ^ size)
    if value >= (size_factor / 2) then
      return math.floor(value - size_factor)
    end
  end
  return value
end

--- @param value number
--- @param size number
--- @return number
function zooz_utils.convert_from_signed_integer(value, size)
  if value ~= nil and size ~= nil then
    local size_factor = math.floor(256 ^ size)
    if value < 0 then
      return math.floor(value + size_factor)
    end
  end
  return value
end

return zooz_utils