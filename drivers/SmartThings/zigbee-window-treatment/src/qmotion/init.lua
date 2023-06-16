-- Copyright 2022 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local capabilities = require "st.capabilities"
local utils = require "st.utils"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local windowShadeDefaults = require "st.zigbee.defaults.windowShade_defaults"
local windowShadeLevelDefaults = require "st.zigbee.defaults.windowShadeLevel_defaults"
local windowShadePresetDefaults = require "st.zigbee.defaults.windowShadePreset_defaults"
--local log = require "log"
local WindowCovering = zcl_clusters.WindowCovering
local Level = zcl_clusters.Level

-- QMOTION WINDOW SHADES BEHAVIOR
-- 1. Open/Close/Pause commands are invoked normally. Position Percentage value is inverted.
-- 2. When shades are moving there is no current position update
-- 3. When shades stops, a new position update is sent with the new lift position

local ZIGBEE_WINDOW_SHADE_FINGERPRINTS = {
    { mfr = "QMotion", model = "Rollershade Hard Wired" }
}

-- UTILS to check manufacturer details
local is_zigbee_window_shade = function(opts, driver, device)
  for _, fingerprint in ipairs(ZIGBEE_WINDOW_SHADE_FINGERPRINTS) do
      if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
          return true
      end
  end
  return false
end

-- ATTRIBUTE HANDLER FOR CurrentPositionLiftPercentage
local function current_position_attr_handler(driver, device, value, zb_rx)
  windowShadeDefaults.default_current_lift_percentage_handler(driver, device, {value = 100 - value.value}, zb_rx)
end

-- ATTRIBUTE HANDLER FOR CurrentLevel
local function current_level_attr_handler(driver, device, value, zb_rx)
  --device:send(WindowCovering.attributes.CurrentPositionLiftPercentage:read(device))
  windowShadeDefaults.default_current_lift_percentage_handler(driver, device, {value = utils.round((value.value/255.0) * 100)}, zb_rx)
end

-- COMMAND HANDLER for SetLevel
local function window_shade_set_level_handler(driver, device, command)
  command.args.shadeLevel = 100 - command.args.shadeLevel
  windowShadeLevelDefaults.window_shade_level_cmd(driver, device, command)
end

-- COMMAND HANDLER for PresetPosition
local function window_shade_preset_handler(driver, device, command)
  command.args.shadeLevel = 100 - command.args.shadeLevel
  windowShadePresetDefaults.window_shade_preset_cmd(driver, device, command)
end

-- DRIVER HANDLER CONFIGURATION
local qmotion_handler = {
  NAME = "QMotion Zigbee Window Shades",
  capability_handlers = {
    [capabilities.windowShadeLevel.ID] = {
      [capabilities.windowShadeLevel.commands.setShadeLevel.NAME] = window_shade_set_level_handler
    },
    -- [capabilities.windowShade.ID] = {
    --   [capabilities.windowShade.commands.open.NAME] = window_shade_open_handler,
    --   [capabilities.windowShade.commands.close.NAME] = window_shade_close_handler,
    --   [capabilities.windowShade.commands.pause.NAME] = window_shade_pause_handler,
    -- },
    [capabilities.windowShadePreset.ID] = {
      [capabilities.windowShadePreset.commands.presetPosition.NAME] = window_shade_preset_handler
    },
  },
  zigbee_handlers = {
    attr = {
      [WindowCovering.ID] = {
        [WindowCovering.attributes.CurrentPositionLiftPercentage.ID] = current_position_attr_handler
      },
      [Level.ID] = {
        [Level.attributes.CurrentLevel.ID] = current_level_attr_handler
      }
    }
  },
  can_handle = is_zigbee_window_shade,
}

return qmotion_handler
