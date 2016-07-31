require "struct"

file = 0

--build up graph hierarchy below
struct.Edge {
  vertexStartId_=-1;
  vertexStopId_=-1;
}

function Vertex(id, x, y, selected, required)
  local this = { id_ = id,
                 x_ = x,
		         y_ = y,
                 selected_ = selected,
				 required_ = required,
		         edgeList_ = {},
                 numEdges_ = 0 }

  local getId = function()
                  return this.id_
                end

  local getX = function() 
                 return this.x_
               end

  local getY = function()
                 return this.y_
               end
			   
  local getRequired = function()
                        return this.required_
				      end

  local setSelected = function(v)
                        this.selected_ = v
                      end

  local getSelected = function()
                        return this.selected_
                      end

  local distanceTo = function(inVertex)
                       dx = inVertex.getX() - this.x_;
                       dy = inVertex.getY() - this.y_;
                       return math.sqrt(dx*dx + dy*dy)
                     end

  local distanceSqrdTo = function(inVertex)
                           dx = inVertex.getX() - this.x_;
                           dy = inVertex.getY() - this.y_;
                           return dx*dx + dy*dy
                         end

  local getNumEdges = function()
                        return this.numEdges_
                      end

  local addNeighbor = function(addVertexId)
                        edge = Edge {vertexStartId_=this.id_, vertexStopId_=addVertexId}
                        table.insert(this.edgeList_, edge)
                        this.numEdges_ = this.numEdges_ + 1
                      end

  local removeNeighbor = function(removeVertexId)
                           for k, e in pairs(this.edgeList_) do
                             if (removeVertexId == e.vertexStopId_) then
                               table.remove(this.edgeList_, k)
                               this.numEdges_ = this.numEdges_ - 1
                               return
                             end
                           end
                         end

  local isNeighbor = function(vertexId)
                       for k, e in pairs(this.edgeList_) do
                         if (vertexId == e.vertexStopId_) then
                           return true
                         end
                       end
                       return false
                     end

  local getNeighborList = function()
                            neighborVertexIdList = {}
                            for k, e in pairs(this.edgeList_) do
                              table.insert(neighborVertexIdList, e.vertexStopId_)
                            end
                            return neighborVertexIdList
                          end

  local getFirstNeighborVertexId = function()
                                     vertexId = this.edgeList_[1].vertexStopId_
                                     return vertexId
                                   end

  local displayEdges = function()
                         for k, e in pairs(this.edgeList_) do
                           file:write("vertex start id = ", e.vertexStartId_, "\n")
			               file:write("vertex stop id = ", e.vertexStopId_, "\n")
                         end
                       end

  local displayLocation = function()
                            file:write("x = ", this.x_, "\n")
                            file:write("y = ", this.y_, "\n")
                          end

  return {
    getId = getId,
    getX = getX,
    getY = getY,
	getRequired = getRequired,
    setSelected = setSelected,
    getSelected = getSelected,
    distanceTo = distanceTo,
    distanceSqrdTo = distanceSqrdTo,
    getNumEdges = getNumEdges,
    addNeighbor = addNeighbor,
    removeNeighbor = removeNeighbor,
    isNeighbor = isNeighbor,
    getNeighborList = getNeighborList,
    getFirstNeighborVertexId = getFirstNeighborVertexId,
    displayEdges = displayEdges,
    displayLocation = displayLocation
  }
end

function Graph()
  local this = { vertexList_ = {},
                 numVertices_ = 0 }

  local addVertex = function(newVertex)
                      table.insert(this.vertexList_, newVertex)
                      this.numVertices_ = this.numVertices_ + 1
                    end

  local getNumVertices = function()
                           return this.numVertices_
                         end

  local getSumOfSqrdDistanceToNonNeighbors = function(inVertex)
                                               sumOfSqrdDistance = 0.0
                                               for k, v in pairs(this.vertexList_) do
                                                 if (inVertex.getId() ~= v.getId()) then
                                                   if (inVertex.isNeighbor(v.getId()) == false) then
                                                     distanceSqrd = inVertex.distanceSqrdTo(v)
                                                     sumOfSqrdDistance = sumOfSqrdDistance + distanceSqrd
                                                   end
                                                 end
                                               end
                                               return sumOfSqrdDistance
                                             end

  local getVertexWithMostEdges = function()
                                   maxEdges = -1
                                   returnVertex = Vertex(-1, -1, -1)
                                   tieBreakDistance = 1e100
                                   for k, v in pairs(this.vertexList_) do
                                     numEdges = v.getNumEdges()
                                     sumOfSqrdDistance = getSumOfSqrdDistanceToNonNeighbors(v)
                                     if (numEdges > maxEdges) then
                                       tieBreakDistance = sumOfSqrdDistance
                                       maxEdges = numEdges
                                       returnVertex = v
                                     elseif (numEdges == maxEdges and sumOfSqrdDistance < tieBreakDistance) then
                                       if (sumOfSqrdDistance < tieBreakDistance) then
                                         tieBreakDistance = sumOfSqrdDistance
                                         returnVertex = v
                                       end
                                     end
                                   end
                                   return returnVertex
                                 end

  local removeEdgesPointingAtVertex = function(vertexId)
                                        for k, v in pairs(this.vertexList_) do
                                          v.removeNeighbor(vertexId)
                                        end
                                      end

  local getIncreaseOfDistanceForInsertingVertex = function(startVertex, insertVertex, endVertex)
                                                    distanceStart = startVertex.distanceTo(endVertex)
                                                    distance1 = startVertex.distanceTo(insertVertex)
                                                    distance2 = insertVertex.distanceTo(endVertex)
                                                    return distance1 + distance2 - distanceStart
                                                  end

  local getEndVertex = function(startVertex)
                         endVertexId = startVertex.getFirstNeighborVertexId()
                         endVertex = Vertex(-1, -1, -1)
                         for k, v in pairs(this.vertexList_) do
                           if (v.getId() == endVertexId) then
                             endVertex = v
                             break                             
                           end
                         end
                         return endVertex
                       end

  local getVerticesForInsertion = function(insertVertex)
                                    minDistanceIncrease = 1e100
                                    startVertex = Vertex(-1, -1, -1)
                                    stopVertex = Vertex(-1, -1, -1)
                                    for k, v in pairs(this.vertexList_) do
                                      if (v.getSelected() == true) then
                                        endVertex = getEndVertex(v)
                                        distanceIncrease = getIncreaseOfDistanceForInsertingVertex(v, insertVertex, endVertex)
                                        if (distanceIncrease < minDistanceIncrease) then
                                          minDistanceIncrease = distanceIncrease
                                          startVertex = v
                                          stopVertex = endVertex
                                        end
                                      end
                                    end
                                    return startVertex, stopVertex
                                  end

  local selectVertexToAddEdgesFor = function()
                                      maxAverageDistance = -1.0
                                      returnVertex = Vertex(-1, -1, -1)
                                      for k, v in pairs(this.vertexList_) do
                                        if (v.getSelected() == false) then
                                          cnt = 0
                                          totalDistance = 0.0
                                          for kInner, vInner in pairs(this.vertexList_) do
                                            if (vInner.getSelected() == true) then
                                              totalDistance = totalDistance + v.distanceTo(vInner)
                                              cnt = cnt + 1
                                            end
                                          end
                                          aveDistance = totalDistance/cnt
                                          file:write("aveDistance = ", aveDistance, "\n")
                                          if (aveDistance > maxAverageDistance) then
                                            maxAverageDistance = aveDistance
                                            returnVertex = v
                                          end
                                        end
                                      end
                                      return returnVertex
                                    end

  local hasEdges = function()
                     for k, v in pairs(this.vertexList_) do
                       if (v.getNumEdges() > 0) then
                         return true
                       end
                     end
                     return false
                   end
				   
  local getNumEdges = function()
					    numEdges = 0
					    for k, v in pairs(this.vertexList_) do
					      numEdges = numEdges + v.getNumEdges()
					    end
						return numEdges
					  end

  local display = function()
                    for k, v in pairs(this.vertexList_) do
                      file:write("vertex id = ", v.getId(), "\n")
                      v.displayEdges()
                    end
                  end

  return {
    addVertex = addVertex,
    getNumVertices = getNumVertices,
    getSumOfSqrdDistanceToNonNeighbors = getSumOfSqrdDistanceToNonNeighbors,
    getVertexWithMostEdges = getVertexWithMostEdges,
    removeEdgesPointingAtVertex = removeEdgesPointingAtVertex,
    getIncreaseOfDistanceForInsertingVertex = getIncreaseOfDistanceForInsertingVertex,
    getEndVertex = getEndVertex,
    getVerticesForInsertion = getVerticesForInsertion,
    selectVertexToAddEdgesFor = selectVertexToAddEdgesFor,
    hasEdges = hasEdges,
	getNumEdges = getNumEdges,
    display = display
  }
end

function ComputeOrderedVertices(vertices, initialLat, initialLon, fileIn)
  file = fileIn

  local graph1 = Graph()
  local graph2 = Graph()

  --add vertices to graph1
  for k, v in pairs(vertices) do
    graph1.addVertex(v)
  end

  --graph1.display()

  --algorithm below is for computing the set of way points
  while (graph1.hasEdges()) do
    local numEdges = graph1.getNumEdges()
	file:write("numEdges = ", numEdges, "\n")
	
    local vertexWithMostEdges = graph1.getVertexWithMostEdges()
    file:write("vertexWithMostEdges = ", vertexWithMostEdges.getId(), "\n")

    --store this way point into another graph for upcoming ordering algorithm
    graph2.addVertex(vertexWithMostEdges)

    --remove all edges pointing at this vertex
    graph1.removeEdgesPointingAtVertex(vertexWithMostEdges.getId())

    --remove all edges pointing to this vertex's neighbors
    local vertexIdList = vertexWithMostEdges.getNeighborList()

    for k, v in pairs(vertexIdList) do
      graph1.removeEdgesPointingAtVertex(v)
    end
  
    --graph1.display()
  end

  --algorithm below is for ordering the set of way points
  local numWaypointsToOrder = graph2.getNumVertices()
  file:write("numWaypointsToOrder = ", numWaypointsToOrder, "\n")

  --add start point to graph, this is first way point selection as well
  vertex0 = Vertex(0, initialLon, initialLat, true, true)
  graph2.addVertex(vertex0)

  for i=1, numWaypointsToOrder do
    local vertexToAddEdgesFor = graph2.selectVertexToAddEdgesFor()
    file:write("vertexToAddEdgesFor = ", vertexToAddEdgesFor.getId(), "\n")

    --add second vertex to graph in a way which will generate a Hamiltonian circuit
    if (i == 1) then
      vertex0.addNeighbor(vertexToAddEdgesFor.getId())
      vertexToAddEdgesFor.addNeighbor(vertex0.getId())

      vertexToAddEdgesFor.setSelected(true)

    --add other vertices in a way which minimizes the growth of the graph length
    else
      vertexStart, vertexStop = graph2.getVerticesForInsertion(vertexToAddEdgesFor)
      --file:write("vertexStartId = ", vertexStart.getId(), "\n")
      --file:write("vertexStopId = ", vertexStop.getId(), "\n")
    
      vertexStart.removeNeighbor(vertexStop.getId())
      vertexStart.addNeighbor(vertexToAddEdgesFor.getId())
      vertexToAddEdgesFor.addNeighbor(vertexStop.getId())

      vertexToAddEdgesFor.setSelected(true)
    end

    --graph2.display()
  end

  --print vertices in order of traversal
  orderedWaypointList = {}
  file:write("ordered point list", "\n")
  local vertexTmp = vertex0
  file:write(vertexTmp.getId(), "\n")

  for i=1, numWaypointsToOrder do
    table.insert(orderedWaypointList, vertexTmp)
    local nextVertexId = vertexTmp.getFirstNeighborVertexId()
    file:write(nextVertexId, "\n")
    vertexTmp = graph2.getEndVertex(vertexTmp)
  end

  return orderedWaypointList
end

