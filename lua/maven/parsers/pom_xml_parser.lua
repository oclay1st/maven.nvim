local Project = require('maven.sources.project')

---@class PomParser
---@field private xml string
local PomParser = {}
PomParser.__index = PomParser

---@param pom_xml_path string
---@return PomParser
function PomParser.parse(pom_xml_path)
  local file = assert(io.open(pom_xml_path, 'r'))
  local file_content = file:read('*a')
  file:close()
  local self = {}
  setmetatable(self, PomParser)
  self.xml = file_content
  return self
end

---@return string
function PomParser:get_group_id()
  return 'org.example.oclay1st'
end

---@return string
function PomParser:get_artifact_id()
  return 'maven'
end

---@return string
function PomParser:get_version()
  return '1.0.0'
end

---@return string
function PomParser:get_name()
  return 'Maven'
end

---@return string[]
function PomParser:get_modules()
  return {}
end

return PomParser
