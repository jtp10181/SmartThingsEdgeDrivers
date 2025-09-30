--
-- Zooz Associations
--

--- @type st.utils
local utils = require "st.utils"
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version = 2 })

local zooz_utils = require "zooz_utils"
local zooz_associations = {}

--- @param value string comma separated value with hex nodeIds
--- @return table numeric nodeIds
function zooz_associations.split_association_node_id_field(value)
  value = zooz_utils.string_trim(value)

  local nodeIds = {}
  for _, hexNodeId in pairs(zooz_utils.string_split(value, ",")) do
    local nodeId = zooz_utils.hex_to_number(hexNodeId)
    if nodeId ~= nil then
      table.insert(nodeIds, nodeId)
    end
  end
  return nodeIds
end

--- @param value table numeric nodeIds
--- @return string comma separated value with hex nodeIds
function zooz_associations.concat_association_node_id_field(value)
  local hexNodeIds = {}
  for _, nodeId in pairs(value) do
    table.insert(hexNodeIds, zooz_utils.number_to_hex(nodeId))
  end
  return table.concat(hexNodeIds, ",")
end

--- @param device st.zwave.Device
--- @param group table association group
--- @param preferenceNodeIds table numeric nodeIds parsed from preference value
--- @param storedNodeIds table numeric nodeIds parsed from stored value
--- @return boolean true if sent Association Remove command
function zooz_associations.remove_old_association_node_ids(device, group, preferenceNodeIds, storedNodeIds)
  local oldNodeIds = {}
  for _, nodeId in pairs(storedNodeIds) do
    if zooz_utils.find_key_by_value(preferenceNodeIds, nodeId) == nil then
      table.insert(oldNodeIds, nodeId)
    end
  end
  if utils.table_size(oldNodeIds) > 0 then
    device:send(Association:Remove({ grouping_identifier = group.group_id, node_ids = oldNodeIds }))
    return true
  else
    return false
  end
end

--- @param device st.zwave.Device
--- @param group table association group {group_id, max_nodes}
--- @param preferenceNodeIds table numeric nodeIds parsed from preference value
--- @param storedNodeIds table numeric nodeIds parsed from stored value
--- @return boolean true if sent Association Set command
function zooz_associations.add_new_association_node_ids(device, group, preferenceNodeIds, storedNodeIds)
  local synced = true
  local nodeCount = 0

  local newNodeIds = {}
  for _, nodeId in pairs(preferenceNodeIds) do
    if zooz_utils.find_key_by_value(storedNodeIds, nodeId) == nil then
      synced = false
    end
    nodeCount = nodeCount + 1
    if group.max_nodes ~= nil and nodeCount <= group.max_nodes then
      table.insert(newNodeIds, nodeId)
    end
  end

  if synced == false and nodeCount > 0 then
    device:send(Association:Set({ grouping_identifier = group.group_id, node_ids = newNodeIds }))
    return true
  else
    return false
  end
end

--- @param device st.zwave.Device
--- @param preferenceValue string hex node ids separated by commas
--- @param group table association group {group_id, max_nodes, field}
--- @return boolean returns false if associations were already synced
function zooz_associations.sync_association_group(device, preferenceValue, group)
  if preferenceValue ~= nil then
    local preferenceNodeIds = zooz_associations.split_association_node_id_field(preferenceValue)
    local storedNodeIds = zooz_associations.split_association_node_id_field(device:get_field(group.field))

    local removedNodeIds = zooz_associations.remove_old_association_node_ids(device, group, preferenceNodeIds, storedNodeIds)
    local addedNodeIds = zooz_associations.add_new_association_node_ids(device, group, preferenceNodeIds, storedNodeIds)
    if removedNodeIds or addedNodeIds then
      device:send(Association:Get({ grouping_identifier = group.group_id }))
    end
  end
end

--- @param device st.zwave.Device
--- @param groups table device's association groups {{group_id }}
function zooz_associations.refresh_associations(device, groups)
  if groups ~= nil then
    for _, group in pairs(groups) do
      device:send(Association:Get({ grouping_identifier = group.group_id }))
    end
  end
end

return zooz_associations