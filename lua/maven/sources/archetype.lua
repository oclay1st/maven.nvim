---@class Archetype
---@field artifact_id string
---@field group_id string
---@field versions string []
---@field description? string
local Archetype = {}
Archetype.__index = Archetype

--- Create a new Archetype
--- @param artifact_id string
--- @param group_id string
--- @param versions string[]
--- @param description? string
function Archetype.new(artifact_id, group_id, versions, description)
  return setmetatable({
    artifact_id = artifact_id,
    group_id = group_id,
    versions = versions or {},
    description = description,
  }, Archetype)
end

return Archetype
