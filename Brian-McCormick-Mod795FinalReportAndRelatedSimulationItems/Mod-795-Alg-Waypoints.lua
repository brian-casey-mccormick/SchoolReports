-- This script template has each of the script entry point functions.
-- They are described in detail in VR-Forces Configuration Guide.

-- Some basic VRF Utilities defined in a common module.
require "vrfutil"
require "graph"
require "pointInPoly"

-- Global Variables. Global variables get saved when a scenario gets checkpointed.
-- They get re-initialized when a checkpointed scenario is loaded.
features = 0
computed = 0
minLonDegrees = 1e10
maxLonDegrees = -1e10
minLatDegrees = 1e10
maxLatDegrees = -1e10
route = 0
routeTask = 0
DTOR = math.pi/180.0
RTOD = 180.0/math.pi
file = 0
validSurfaceTypes = 0
validFeatureTypes = 0
numBoundaryPoints2d = 0
area2d = {}
area3d = {}
vertexId = 0
vertices = {}

function inTable(tbl, item)
   for key, value in pairs(tbl) do
     if (value == item) then
       return true
     end
   end
   return false
end

function getLocation3DFromAGL(latDegrees, lonDegrees, alt)
   terrainElevation, valid, surfaceType = vrf:getTerrainAltitude(latDegrees*DTOR, lonDegrees*DTOR)
   local location3DInAGL = Location3D(latDegrees*DTOR, lonDegrees*DTOR, terrainElevation+alt)
   return location3DInAGL, surfaceType
end

function attemptToAddVertex(point, northDelta, eastDelta)
   local point1 = point:addVector3D(Vector3D(northDelta, eastDelta, 0.0))
   local point2, surfaceType = getLocation3DFromAGL(point1:getLat()*RTOD, point1:getLon()*RTOD, 0.0)

   local isInTable = inTable(validSurfaceTypes, surfaceType)
   if (isInTable == true) then
     vertexId = vertexId + 1
     local vertex = Vertex(vertexId, point2:getLon()*RTOD, point2:getLat()*RTOD, false, true)
     table.insert(vertices, vertex)
   end
   
   return isInTable
end

-- Called when the task first starts. Never called again.
function init()
   printInfo("init() called")
   
   math.randomseed( os.time() )

   -- Set the tick period for this script.
   vrf:setTickPeriod(0.1)
   
   -- Set valid surface types for vehicles
   validSurfaceTypes = {"Grass", "CultivatedFields", "DirtRoad", "MuddyRoad", 
                                   "DryGround", "WetGround", "IcyGround", "SnowGround", 
				   "GravelRoad", "PavedRoad",  "AsphaltOrOtherHardSurface",
				   "Sand"}
				   
   --Set feature types for important points
   validFeatureTypes = {"House", "Trees", "Control Tower", "Hangar", "Palace"}
   
   local simObject = vrf:getSimObjectByName("Route 1")
   local locs = simObject:getLocations3D()
   for index, loc in pairs(locs) do
     numBoundaryPoints2d = numBoundaryPoints2d + 1

     local point2d = Point2d{x_=loc:getLon()*RTOD, y_=loc:getLat()*RTOD}
     local point3d = getLocation3DFromAGL(loc:getLat()*RTOD, loc:getLon()*RTOD, 0.0)
     
     table.insert(area2d, point2d)
     table.insert(area3d, point3d)
     
     minLonDegrees = math.min(minLonDegrees, loc:getLon()*RTOD)
     maxLonDegrees = math.max(maxLonDegrees, loc:getLon()*RTOD)
     
     minLatDegrees = math.min(minLatDegrees, loc:getLat()*RTOD)
     maxLatDegrees = math.max(maxLatDegrees, loc:getLat()*RTOD)
   end
   
   for index, loc in pairs(locs) do
     numBoundaryPoints2d = numBoundaryPoints2d + 1
     local point2d = Point2d{x_=loc:getLon()*RTOD, y_=loc:getLat()*RTOD}
     table.insert(area2d, point2d)
     break
   end
   
   features = vrf:getFeaturesWithinArea(area3d, {islinear=true, isareal=true, ispoint=true})
end

-- Called each tick while this task is active.
function tick()
   if (features:isLoaded() and computed == 0) then
     computed = 1

     --create unique file name for the run here and create file in results directory
     local dateString = os.date()
     dateString = string.gsub(dateString, "/", "")
     dateString = string.gsub(dateString,":", "")
     dateString = string.gsub(dateString," ", "-")
     local fileName = "data-" .. dateString .. ".out"
     file = io.open(fileName, "w")
     
     --generate evenly spaced grid points in map region of interest
     local numPointsEachDirection = 10
     local deltaLonDegrees = (maxLonDegrees - minLonDegrees)/(numPointsEachDirection-1)
     local deltaLatDegrees = (maxLatDegrees - minLatDegrees)/(numPointsEachDirection-1)
     
     for row=0, numPointsEachDirection-1 do
       for col=0, numPointsEachDirection-1 do
         vertexId = row*numPointsEachDirection + col + 1
	 
	 local lonDegrees = minLonDegrees + deltaLonDegrees*row
	 local latDegrees= minLatDegrees + deltaLatDegrees*col
	 
	 --test location to ensure it is within map region of interest
	 local q1 = Point2d{x_=lonDegrees, y_=latDegrees}
	 local q2 = Point2d{x_=maxLonDegrees+0.01, y_=maxLatDegrees+0.01}
	 local inPolyFlag = PointInPoly(numBoundaryPoints2d, area2d, q1, q2)
	
	 if (inPolyFlag == true) then
	   local vertex = Vertex(vertexId, lonDegrees, latDegrees, false, false)
	   gridLocation, surfaceType = getLocation3DFromAGL(latDegrees, lonDegrees, 0.0)
	 
	   local isInTable = inTable(validSurfaceTypes, surfaceType)
	   if (isInTable == true) then
	     table.insert(vertices, vertex)
	   end
	 end
       end
     end
     
     --analyze features and create important point(s) for each relevant feature
     for i = 1, features:getFeatureCount() do
       file:write("featureType = ", features:getFeatureType(i),  "\n")
	
       local featureAttributeValue = 0
       local featureAttributeNames = features:getFeatureAttributeNames(i)

       for index, featureAttributeName in ipairs(featureAttributeNames) do
         featureAttributeValue = features:getFeatureAttributeValue(i, featureAttributeName)
         break
       end

       local isInTable = inTable(validFeatureTypes, featureAttributeValue)
       if (isInTable == true) then
         file:write("recognized feature attribute value = ", featureAttributeValue, "\n")
         local locations = features:getLocations3D(i)
         for pointIndex, point in ipairs(locations) do
	   local addedVertex1 = attemptToAddVertex(point, -10.0, -10.0)
	   local addedVertex2 = attemptToAddVertex(point, 10.0,  10.0)
	   
	   if (addedVertex1 == false and addedVertex2 == false) then
	       file:write("did not add an important point", "\n")
	   end
         end
       end
     end

     --compute edges using visibility information
     local startAlt = 2.5
     local stopAlt = 1.0
     
     for k1, v1 in pairs(vertices) do
       for k2, v2 in pairs(vertices) do
         if (v1.getId() ~= v2.getId()) then
	   local pt1 = getLocation3DFromAGL(v1.getY(), v1.getX(), startAlt)
           local pt2 = getLocation3DFromAGL(v2.getY(), v2.getX(), stopAlt)
           isBlocked, valid = vrf:doesChordHitTerrain(pt1, pt2)
           if (valid == false) then
             file:write("doesChordHitTerrain returned invalid intersection results", "\n")
           elseif (isBlocked == false) then
             v1.addNeighbor(v2.getId())
           end
	 end
       end
     end

     --must add self as neighbor for important points to ensure visibility
     for k3, v3 in pairs(vertices) do
       if (v3.getRequired() == true) then
         v3.addNeighbor(v3.getId())
       end
     end
     
     --compute ordered vertices for friendly vehicle to follow and create route for them
     local origLocation = this:getLocation3D()
									     
     local orderedLocations = {}
     local orderedVertices = ComputeOrderedVertices(vertices, this:getLocation3D():getLat()*RTOD, 
                                                                             this:getLocation3D():getLon()*RTOD, file)
								     
     this:setLocation3D(origLocation)
     
     for k4, v4 in pairs(orderedVertices) do
       local location3D = getLocation3DFromAGL(v4.getY(), v4.getX(), 0.0)
       table.insert(orderedLocations, location3D)
     end
     
     local route = vrf:createRoute({object_name="PR", locations=orderedLocations})
     
     --create and randomly place 20 hostile ground vehicles
     local cnt=0
     while (cnt < 20) do
       local randomLatDegrees = minLatDegrees + math.random()*(maxLatDegrees - minLatDegrees)
       local randomLonDegrees = minLonDegrees + math.random()*(maxLonDegrees - minLonDegrees)
       
       --test location to ensure it is within map region of interest
       local q1 = Point2d{x_=randomLonDegrees, y_=randomLatDegrees}
       local q2 = Point2d{x_=maxLonDegrees+0.01, y_=maxLatDegrees+0.01}
       local inPolyFlag = PointInPoly(numBoundaryPoints2d, area2d, q1, q2)
	
       if (inPolyFlag == true) then
         entityLocation, surfaceType = getLocation3DFromAGL(randomLatDegrees, randomLonDegrees, 0.0)
	 
         local isInTable = inTable(validSurfaceTypes, surfaceType)
         if (isInTable == true) then
           local entity = vrf:createEntity({force="opposing", entity_type="1:1:222:6:1:0:0", location=entityLocation})
	   cnt = cnt + 1
         end
       end
     end

     --randomly place the friendly ground vehicle
     local foundLocation=false
     while (foundLocation == false) do
       local randomLatDegrees = minLatDegrees + math.random()*(maxLatDegrees - minLatDegrees)
       local randomLonDegrees = minLonDegrees + math.random()*(maxLonDegrees - minLonDegrees)
       
       --test location to ensure it is within map region of interest
       local q1 = Point2d{x_=randomLonDegrees, y_=randomLatDegrees}
       local q2 = Point2d{x_=maxLonDegrees+0.01, y_=maxLatDegrees+0.01}
       local inPolyFlag = PointInPoly(numBoundaryPoints2d, area2d, q1, q2)
	
       if (inPolyFlag == true) then
         entityLocation, surfaceType = getLocation3DFromAGL(randomLatDegrees, randomLonDegrees, 0.0)
	 
         local isInTable = inTable(validSurfaceTypes, surfaceType)
         if (isInTable == true) then
           this:setLocation3D(entityLocation)
	   foundLocation = true
         end
       end
     end
     
     --start friendly vehicle along route
     local routeTask = vrf:startSubtask("move-along", {route=route:getName(), start_at_closest_point=true})
   end
   
   --record hostile contact for post-processing
   local contacts = this:getObservedHostileContacts()
   for k5, v5 in pairs(contacts) do
     file:write(v5:getUUID(), "\n")
   end
end

-- Called when this task is being suspended, likely by a reaction activating.
function suspend()
end

-- Called when this task is being resumed after being suspended.
function resume()
end

-- Called immediately before a scenario checkpoint is saved when
-- this task is active.
-- It is typically not necessary to add code to this function.
function saveState()
end

-- Called immediately after a scenario checkpoint is loaded in which
-- this task is active.
-- It is typically not necessary to add code to this function.
function loadState()
end

-- Called when this task is ending, for any reason.
-- It is typically not necessary to add code to this function.
function shutdown()
end

-- Called whenever the entity receives a text report message while
-- this task is active.
--   message is the message text string.
--   sender is the SimObject which sent the message.
function receiveTextMessage(message, sender)
end
