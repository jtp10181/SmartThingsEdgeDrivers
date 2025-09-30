local capabilities = require "st.capabilities"
--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
--- @type st.zwave.CommandClass.CentralScene
local CentralScene = (require "st.zwave.CommandClass.CentralScene")({ version = 1 })

local supported_devices = require "supported_devices"
local zooz_common = require "zooz_common"
local zooz_utils = require "zooz_utils"

local sceneKeyAttributeButtonAttributes = {
  [CentralScene.key_attributes.KEY_PRESSED_1_TIME] = capabilities.button.button.pushed,
  [CentralScene.key_attributes.KEY_HELD_DOWN] = capabilities.button.button.held,
  [CentralScene.key_attributes.KEY_RELEASED] = capabilities.button.button.up_hold,
  [CentralScene.key_attributes.KEY_PRESSED_2_TIMES] = capabilities.button.button.pushed_2x,
  [CentralScene.key_attributes.KEY_PRESSED_3_TIMES] = capabilities.button.button.pushed_3x,
  [CentralScene.key_attributes.KEY_PRESSED_4_TIMES] = capabilities.button.button.pushed_4x,
  [CentralScene.key_attributes.KEY_PRESSED_5_TIMES] = capabilities.button.button.pushed_5x
}
local supportedButtonValues = { "pushed", "held", "up_hold", "pushed_2x", "pushed_3x", "pushed_4x", "pushed_5x" }

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function can_handle_zooz_zen37(opts, driver, device, ...)
  return (supported_devices.get_device_details(device).device_group == supported_devices.device_groups.zen37)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function central_scene_notification_handler(driver, device, command)
  zooz_utils.logMessage("central_scene_notification_handler...")

  if command.args.sequence_number ~= device:get_field("lastSeqNum") then
    device:set_field("lastSeqNum", command.args.sequence_number)

    local event
    local buttonAttribute = sceneKeyAttributeButtonAttributes[command.args.key_attributes]
    if buttonAttribute ~= nil then
      event = buttonAttribute({ state_change = true })
    end

    if event ~= nil then
      local component = string.format("button%d", command.args.scene_number)
      device:emit_component_event(device.profile.components[component], event)
    end
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function added_handler(driver, device)
  zooz_utils.logMessage("added_handler")
  for _, componentName in pairs(supported_devices.get_components(device)) do
    device:emit_component_event(device.profile.components[componentName], capabilities.button.numberOfButtons({ value = 1 }))
    device:emit_component_event(device.profile.components[componentName], capabilities.button.supportedButtonValues({ value = supportedButtonValues }))
    device:emit_component_event(device.profile.components[componentName], capabilities.button.button.pushed())
  end
end

local driver_zen37 = {
  NAME = "Zooz ZEN37 Wall Remote",
  can_handle = can_handle_zooz_zen37,

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
return driver_zen37
