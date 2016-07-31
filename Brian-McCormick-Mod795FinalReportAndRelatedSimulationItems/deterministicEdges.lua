require "split"

edgeInfo = {}

function ReadEdgeInfo()
  file, err = io.open("edgeInfo.txt", "r")

  if err then
    print("file doesn't exist")
    return
  end

  while true do
    line = file:read()

    if line == nil then break end

    --split the line and store the key/value pairs
    local myTable = Split(line, " ")
    key = myTable[1] .. "_" .. myTable[2]
    edgeInfo[key] = myTable[3]
  end
end

function EdgeIsVisible(vertexId1, vertexId2)
  key=vertexId1 .. "_" .. vertexId2
  return edgeInfo[key]
end


