--
-- Supported Devices
--

local dashboard_views = {
  normal = 0,
  large = 1
}

local device_groups = {
  zen34 = "zen34",
  zen37 = "zen37"
}

local association_group_fields = {
  group2 = "group2",
  group3 = "group3",
  group4 = "group4",
  group5 = "group5",
  group6 = "group6",
  group7 = "group7",
  group8 = "group8",
  group9 = "group9"
}

local devices = {
  zen34 = {
    device_group = device_groups.zen34,
    fingerprints = {
      default = { mfr_id = 0x027A, product_type = 0x7000, product_id = 0xF001 },
      zen34v1 = { mfr_id = 0x027A, product_type = 0x0004, product_id = 0xF001 }
    },
    default_profile_name = "zooz-zen34-remote-switch",
    profiles = {
      profile2 = { name = "zooz-zen34-remote-switch-2", min_firmware = 1.40 },
      profile1 = { name = "zooz-zen34-remote-switch", min_firmware = 1.0, max_firmware = 1.39 }
    },
    configuration_parameters = {
      ledMode = { parameter_number = 1, size = 1 },
      upperPaddleLedColor = { parameter_number = 2, size = 1 },
      lowerPaddleLedColor = { parameter_number = 3, size = 1 },
      remoteDimmingDuration = { parameter_number = 5, size = 1 }
    },
    association_groups = {
      associationGroupTwo = { group_id = 2, max_nodes = 5, field = association_group_fields.group2 },
      associationGroupThree = { group_id = 3, max_nodes = 5, field = association_group_fields.group3 }
    },
    configuration_options = {
      set_lifeline_association = true,
      set_default_wake_up_interval = true
    }
  },

  zen37 = {
    device_group = device_groups.zen37,
    fingerprints = {
      default = { mfr_id = 0x027A, product_type = 0x7000, product_id = 0xF003 }
    },
    default_profile_name = "zooz-zen37-wall-remote",
    profiles = {
      profile1 = { name = "zooz-zen37-wall-remote", min_firmware = 1.0 }
    },
    components = {
      button1 = "button1",
      button2 = "button2",
      button3 = "button3",
      button4 = "button4"
    },
    configuration_parameters = {
      lowBatteryAlarmReport = { parameter_number = 1, size = 1 },
      ledIndicatorColor1 = { parameter_number = 2, size = 1 },
      ledIndicatorColor2 = { parameter_number = 3, size = 1 },
      ledIndicatorColor3 = { parameter_number = 4, size = 1 },
      ledIndicatorColor4 = { parameter_number = 5, size = 1 },
      ledIndicatorBrightness = { parameter_number = 6, size = 1 },
      multilevelDuration = { parameter_number = 7, size = 1 }
    },
    association_groups = {
      associationGroupTwo = { group_id = 2, max_nodes = 10, field = association_group_fields.group2 },
      associationGroupThree = { group_id = 3, max_nodes = 10, field = association_group_fields.group3 },
      associationGroupFour = { group_id = 4, max_nodes = 10, field = association_group_fields.group4 },
      associationGroupFive = { group_id = 5, max_nodes = 10, field = association_group_fields.group5 },
      associationGroupSix = { group_id = 6, max_nodes = 10, field = association_group_fields.group6 },
      associationGroupSeven = { group_id = 7, max_nodes = 10, field = association_group_fields.group7 },
      associationGroupEight = { group_id = 8, max_nodes = 10, field = association_group_fields.group8 },
      associationGroupNine = { group_id = 9, max_nodes = 10, field = association_group_fields.group9 }
    },
    configuration_options = {
      set_lifeline_association = true,
      set_default_wake_up_interval = true
    }
  }
}

local supported_devices = {
  device_groups = device_groups,
  association_group_fields = association_group_fields,
  devices = devices,
  dashboard_views = dashboard_views
}

--- @param device  st.zwave.Device
--- @return table returns empty table if nil
function supported_devices.get_device_details(device)
  for _, deviceDetails in pairs(devices) do
    for _, fingerprint in pairs(deviceDetails.fingerprints) do
      if device:id_match(fingerprint.mfr_id, fingerprint.product_type, fingerprint.product_id) then
        return deviceDetails
      end
    end
  end
  return {}
end

--- @param firmwareVersion number
--- @param minVersion number minimum matching firmware
--- @param minVersion number maximum matching firmware
--- @param exactVersion number exact firmware match
--- @return boolean
function supported_devices.is_firmware_match(firmwareVersion, minVersion, maxVersion, exactVersion)
  if firmwareVersion ~= nil then
    local hasMinOrMaxFirmware = (minVersion ~= nil or maxVersion ~= nil)
    local aboveMinFirmware = (minVersion == nil or firmwareVersion >= minVersion)
    local belowMaxFirmware = (maxVersion == nil or firmwareVersion <= maxVersion)
    local exactFirmware = (exactVersion ~= nil and firmwareVersion == exactVersion)
    return (exactFirmware or (hasMinOrMaxFirmware and aboveMinFirmware and belowMaxFirmware))
  else
    return false
  end
end

--- @param device st.zwave.Device
--- @param firmwareVersion number
--- @return string
function supported_devices.get_profile_name(device, firmwareVersion, dashboardView)
  local details = supported_devices.get_device_details(device)
  if details.profiles ~= nil then
    for _, profile in pairs(details.profiles) do

      if supported_devices.is_firmware_match(firmwareVersion, profile.min_firmware, profile.max_firmware, profile.exact_firmware) then
        if dashboardView ~= nil and tonumber(dashboardView) == dashboard_views.large and profile.large_view_supported then
          return string.format("%s-large", profile.name)
        else
          return profile.name
        end
      end
    end
    return details.default_profile_name
  end
end

--- @param device st.zwave.Device
------ @return table returns empty table if nil
function supported_devices.get_association_groups(device)
  return supported_devices.get_device_details(device).association_groups or {}
end

--- @param device st.zwave.Device
--- @param group_id number
--- @return table
function supported_devices.get_association_group_by_group_id(device, group_id)
  if group_id ~= nil then
    local groups = supported_devices.get_association_groups(device)
    for _, group in pairs(groups) do
      if group.group_id == group_id then
        return group
      end
    end
  end
end

--- @param device st.zwave.Device
--- @return table returns empty table if nil
function supported_devices.get_components(device)
  return supported_devices.get_device_details(device).components or {}
end

--- @param device st.zwave.Device
--- @return table returns empty table if nil
function supported_devices.get_configuration_parameters(device)
  return supported_devices.get_device_details(device).configuration_parameters or {}
end

--- @param device st.zwave.Device
--- @param parameterNumber number
--- @return string
function supported_devices.get_configuration_parameter_id_by_parameter_number(device, parameterNumber)
  if parameterNumber ~= nil then
    local parameters = supported_devices.get_configuration_parameters(device)
    for id, parameter in pairs(parameters) do
      if parameter.parameter_number == parameterNumber then
        return id
      end
    end
  end
end

--- @param device st.zwave.Device
--- @param parameterNumber number
--- @return table
function supported_devices.get_configuration_parameter_by_parameter_number(device, parameterNumber)
  if parameterNumber ~= nil then
    local parameters = supported_devices.get_configuration_parameters(device)
    for _, parameter in pairs(parameters) do
      if parameter.parameter_number == parameterNumber then
        return parameter
      end
    end
  end
end

return supported_devices