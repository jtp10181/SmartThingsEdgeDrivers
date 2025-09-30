--
-- Zooz Common
--

--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version = 1 })
--- @type st.zwave.CommandClass.Version
local Version = (require "st.zwave.CommandClass.Version")({ version = 1 })
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version = 2 })

local capabilities = require "st.capabilities"

local supported_devices = require "supported_devices"
local zooz_associations = require "zooz_associations"
local zooz_utils = require "zooz_utils"
local zooz_common = {}

zooz_common.DEFAULT_WAKE_UP_INTERVAL = 43200 --12 hours

zooz_common.fields = {
  FIRMWARE_VERSION = "firmwareVersion",
  INITIALIZED = "initialized",
  PROFILE_NAME = "profileName",
  TEST_MODE = "testMode"
}

--- @param device st.zwave.Device
--- @param parameterNumber number
--- @return number
function zooz_common.get_stored_configuration_parameter_value(device, parameterNumber)
  local id = supported_devices.get_configuration_parameter_id_by_parameter_number(device, parameterNumber)
  if id ~= nil then
    local value = device:get_field(id)
    if value ~= nil then
      return tonumber(value)
    end
  end
end

--- @param device st.zwave.Device
--- @param parameterNumber number
--- @param value number
function zooz_common.store_configuration_parameter_value(device, parameterNumber, value)
  local id = supported_devices.get_configuration_parameter_id_by_parameter_number(device, parameterNumber)
  if id ~= nil then
    device:set_field(id, value, { persist = true })
  end
end

--- @param device st.zwave.Device
function zooz_common.change_configuration_parameter_value(device, parameter, value)
  local id = supported_devices.get_configuration_parameter_id_by_parameter_number(device, parameter.parameter_number)
  if value ~= nil then
    zooz_utils.logMessage("CHANGING %s(#%s) to %s", id, parameter.parameter_number, value)
    device:send(Configuration:Set({ parameter_number = parameter.parameter_number, size = parameter.size, configuration_value = value }))
    device:send(Configuration:Get({ parameter_number = parameter.parameter_number }))
  end
end

--- @param device st.zwave.Device
function zooz_common.request_configuration_parameter_value(device, parameter)
  if parameter ~= nil then
    device:send(Configuration:Get({ parameter_number = parameter.parameter_number }))
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function zooz_common.refresh_handler(driver, device, cmd)
  zooz_utils.logMessage("common_refresh_handler...")

  if device:get_field(zooz_common.fields.FIRMWARE_VERSION) == nil then
    device:send(Version:Get({}))
    zooz_associations.refresh_associations(device, supported_devices.get_association_groups(device))
  end

  device:default_refresh()
end

--- @param device st.zwave.Device
function zooz_common.change_profile_if_needed(device, firmwareVersion)
  local profileName = supported_devices.get_profile_name(device, firmwareVersion, device.preferences["dashboardView"])

  if device:get_field(zooz_common.fields.PROFILE_NAME) ~= profileName then
    device:try_update_metadata({ profile = profileName })
    device:set_field(zooz_common.fields.PROFILE_NAME, profileName, { persist = true })
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Version.Report
function zooz_common.version_report_handler(driver, device, cmd)
  zooz_utils.logMessage("common_version_report_handler...")
  local version = (cmd.args.application_version + (cmd.args.application_sub_version / 100))
  local fmtFirmwareVersion = string.format("%d.%02d", cmd.args.application_version, cmd.args.application_sub_version)
  device:set_field(zooz_common.fields.FIRMWARE_VERSION, version, { persist = true })
  device:emit_event(capabilities.firmwareUpdate.currentVersion({ value = fmtFirmwareVersion }))
  zooz_common.change_profile_if_needed(device, version)
end

--- @param device st.zwave.Device
local function sync_configuration_parameter(device, preferenceValue, parameter)
  local storedValue = zooz_common.get_stored_configuration_parameter_value(device, parameter.parameter_number)
  if storedValue ~= nil and preferenceValue ~= nil then

    if parameter.max_range_value ~= nil and preferenceValue > parameter.max_range_value and preferenceValue ~= parameter.max_value then
      zooz_utils.logMessage("Parameter #%s - replacing %s with %s because it's above the maximum range value", parameter.parameter_number, preferenceValue, parameter.max_range_value)
      preferenceValue = parameter.max_range_value

    elseif parameter.min_range_value ~= nil and preferenceValue < parameter.min_range_value and preferenceValue ~= parameter.min_value then
      zooz_utils.logMessage("Parameter #%s - replacing %s with %s because it's below the minimum range value", parameter.parameter_number, preferenceValue, parameter.min_range_value)
      preferenceValue = parameter.min_range_value
    end

    if (tonumber(preferenceValue) ~= storedValue) then
      preferenceValue = zooz_utils.convert_to_signed_integer(tonumber(preferenceValue), parameter.size)
      zooz_common.change_configuration_parameter_value(device, parameter, preferenceValue)
    end
  else
    zooz_common.request_configuration_parameter_value(device, parameter)
  end
end

--- @param device st.zwave.Device
local function sync_association_group(device, preferenceValue, group)
  local sentChanges = zooz_associations.sync_association_group(device, preferenceValue, group)
  if not sentChanges and not device:get_field(zooz_common.fields.TEST_MODE) then
    local latestState = device:get_field(group.field)
    if latestState == nil then
      device:send(Association:Get({ grouping_identifier = group.group_id }))
    end
  end
end

--- @param device st.zwave.Device
function zooz_common.sync_preferences(device)
  zooz_utils.logMessage("sync_preferences...")

  if device:get_field(zooz_common.fields.FIRMWARE_VERSION) == nil then
    device:send(Version:Get({}))
  end

  local parameters = supported_devices.get_configuration_parameters(device)
  local groups = supported_devices.get_association_groups(device)

  for prefName, prefValue in pairs(device.preferences) do
    local parameter = parameters[prefName]
    if parameter ~= nil then
      sync_configuration_parameter(device, prefValue, parameter)
    else
      local group = groups[prefName]
      if group ~= nil then
        sync_association_group(device, prefValue, group)
      end
    end
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Configuration.Report
function zooz_common.configuration_report_handler(driver, device, cmd)
  local parameterNumber = cmd.args.parameter_number
  local value = cmd.args.configuration_value

  local id = supported_devices.get_configuration_parameter_id_by_parameter_number(device, parameterNumber)
  if id ~= nil then
    value = zooz_utils.convert_from_signed_integer(value, cmd.args.size)
    zooz_utils.logMessage("%s(#%s) = %s", id, parameterNumber, value)
    zooz_common.store_configuration_parameter_value(device, parameterNumber, value)
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Association.Report
function zooz_common.association_report_handler(driver, device, cmd)
  zooz_utils.logMessage("common_association_report_handler...")

  local group = supported_devices.get_association_group_by_group_id(device, cmd.args.grouping_identifier) or {}
  if group ~= nil then
    local hexValue = zooz_associations.concat_association_node_id_field(cmd.args.node_ids)
    device:set_field(group.field, hexValue, { persist = true })
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function zooz_common.initialize(driver, device)
  local initialized = device:get_field(zooz_common.fields.INITIALIZED)
  if initialized ~= true then
    zooz_utils.logMessage("initialize...")

    device:set_field(zooz_common.fields.INITIALIZED, true, { persist = true })

    local deviceDetails = supported_devices.get_device_details(device)
    if deviceDetails ~= nil then
      device:set_field(zooz_common.fields.PROFILE_NAME, deviceDetails.default_profile_name, { persist = true })
    end

    if not device:get_field(zooz_common.fields.TEST_MODE) then
      device:refresh()
    end
  end
end

return zooz_common
