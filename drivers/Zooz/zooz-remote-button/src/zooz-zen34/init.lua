local capabilities = require "st.capabilities"
--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
--- @type st.zwave.CommandClass.CentralScene
local CentralScene = (require "st.zwave.CommandClass.CentralScene")({ version = 1 })

local supported_devices = require "supported_devices"
local zooz_common = require "zooz_common"
local zooz_utils = require "zooz_utils"

local map_key_attribute_to_capability = {
  [1] = {
    [CentralScene.key_attributes.KEY_PRESSED_1_TIME] = capabilities.button.button.up,
    [CentralScene.key_attributes.KEY_HELD_DOWN] = capabilities.button.button.up_hold,
    --[CentralScene.key_attributes.KEY_RELEASED] = capabilities.button.button.up_released,
    [CentralScene.key_attributes.KEY_PRESSED_2_TIMES] = capabilities.button.button.up_2x,
    [CentralScene.key_attributes.KEY_PRESSED_3_TIMES] = capabilities.button.button.up_3x,
    [CentralScene.key_attributes.KEY_PRESSED_4_TIMES] = capabilities.button.button.up_4x,
    [CentralScene.key_attributes.KEY_PRESSED_5_TIMES] = capabilities.button.button.up_5x
  },
  [2] = {
    [CentralScene.key_attributes.KEY_PRESSED_1_TIME] = capabilities.button.button.down,
    [CentralScene.key_attributes.KEY_HELD_DOWN] = capabilities.button.button.down_hold,
    --[CentralScene.key_attributes.KEY_RELEASED] = capabilities.button.button.down_released,
    [CentralScene.key_attributes.KEY_PRESSED_2_TIMES] = capabilities.button.button.down_2x,
    [CentralScene.key_attributes.KEY_PRESSED_3_TIMES] = capabilities.button.button.down_3x,
    [CentralScene.key_attributes.KEY_PRESSED_4_TIMES] = capabilities.button.button.down_4x,
    [CentralScene.key_attributes.KEY_PRESSED_5_TIMES] = capabilities.button.button.down_5x
  }
}
local supportedButtonValues = { "down", "down_hold", "down_2x", "down_3x", "down_4x", "down_5x", "up", "up_hold", "up_2x", "up_3x", "up_4x", "up_5x" }

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function can_handle_zooz_zen34(opts, driver, device, ...)
  return (supported_devices.get_device_details(device).device_group == supported_devices.device_groups.zen34)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function central_scene_notification_handler(driver, device, command)
  zooz_utils.logMessage("central_scene_notification_handler...")

  if command.args.sequence_number ~= device:get_field("lastSeqNum") then
    device:set_field("lastSeqNum", command.args.sequence_number)

    local capability_attribute
    local scene_attributes = map_key_attribute_to_capability[command.args.scene_number]
    if scene_attributes ~= nil then
      capability_attribute = scene_attributes[command.args.key_attributes]
    end

    local event
    if capability_attribute ~= nil then
      event = capability_attribute({ state_change = true })
    end

    if event ~= nil then
      device:emit_event(event)
    end
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function added_handler(driver, device)
  zooz_utils.logMessage("added_handler")
  device:emit_event(capabilities.button.numberOfButtons({ value = 1 }))
  device:emit_event(capabilities.button.supportedButtonValues({ value = supportedButtonValues }))
  device:emit_event(capabilities.button.button.up())
end

local driver_zen34 = {
  NAME = "Zooz ZEN34 Remote Switch",
  can_handle = can_handle_zooz_zen34,

  supported_capabilities = {},

  zwave_handlers = {
    [cc.CENTRAL_SCENE] = {
      [CentralScene.NOTIFICATION] = central_scene_notification_handler
    }
  },

  capability_handlers = {},

  lifecycle_handlers = {
    added = added_handler,
  }
}

--defaults.register_for_default_handlers(driver_zen37, driver_zen37.supported_capabilities)
return driver_zen34
