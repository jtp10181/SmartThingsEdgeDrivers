local capabilities = require "st.capabilities"
--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
--- @type st.zwave.Driver
local ZwaveDriver = require "st.zwave.driver"
--- @type st.zwave.defaults
local defaults = require "st.zwave.defaults"
--- @type st.zwave.CommandClass.Version
local Version = (require "st.zwave.CommandClass.Version")({ version = 1 })
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version = 1 })
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version = 2 })
--- @type st.zwave.CommandClass.WakeUp
local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 1 })

local supported_devices = require "supported_devices"
local zooz_common = require "zooz_common"
local zooz_utils = require "zooz_utils"

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function update_preferences(driver, device, args)
  zooz_utils.logMessage("default_update_preferences...")
  zooz_common.sync_preferences(device)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function info_changed(driver, device, event, args)
  zooz_utils.logMessage("default_info_changed...")
  if not device:is_cc_supported(cc.WAKE_UP) then
    zooz_common.sync_preferences(device)
  end

  zooz_common.change_profile_if_needed(device, device:get_field(zooz_common.fields.FIRMWARE_VERSION))
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function do_configure(driver, device)
  local configOptions = supported_devices.get_device_details(device).configuration_options

  if configOptions.set_lifeline_association then
    zooz_utils.logMessage("Setting Lifeline Association")
    device:send(Association:Set({
      grouping_identifier = 1,
      node_ids = { driver.environment_info.hub_zwave_id }
    }))
  end

  if configOptions.set_default_wake_up_interval and device:is_cc_supported(cc.WAKE_UP) then
    zooz_utils.logMessage("Setting Wake Up Interval to %s", zooz_common.DEFAULT_WAKE_UP_INTERVAL)
    device:send(WakeUp:IntervalSet({
      seconds = zooz_common.DEFAULT_WAKE_UP_INTERVAL,
      node_id = driver.environment_info.hub_zwave_id
    }))
  end

  if configOptions.sync_preferences then
    zooz_common.sync_preferences(device)
  end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function device_init(driver, device)
  zooz_utils.logMessage("default_device_init...")

  zooz_common.initialize(driver, device)

  if device:is_cc_supported(cc.WAKE_UP) then
    device:set_update_preferences_fn(update_preferences)
  end
end

local function added_handler(driver, device)
  zooz_utils.logMessage("added_handler (default)")
end

local driver_template = {
  zwave_handlers = {
    [cc.VERSION] = {
      [Version.REPORT] = zooz_common.version_report_handler
    },
    [cc.CONFIGURATION] = {
      [Configuration.REPORT] = zooz_common.configuration_report_handler
    },
    [cc.ASSOCIATION] = {
      [Association.REPORT] = zooz_common.association_report_handler
    },
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = zooz_common.refresh_handler
    }
  },
  supported_capabilities = {
    capabilities.button,
    capabilities.battery
  },
  sub_drivers = {
    require("zooz-zen34"),
    require("zooz-zen37")
  },
  lifecycle_handlers = {
    added = added_handler,
    init = device_init,
    infoChanged = info_changed,
    doConfigure = do_configure
  }
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local ZoozRemoteButton = ZwaveDriver("zooz-remote-button", driver_template)
ZoozRemoteButton:run()
