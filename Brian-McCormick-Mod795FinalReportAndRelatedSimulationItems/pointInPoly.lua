require "struct"

struct.Point2d {
  x_=0.0;
  y_=0.0;
}

struct.Vec2d {
  x_=0.0;
  y_=0.0;
}

function CrossProduct(v1, v2)
  val = v1.x_ * v2.y_ - v1.y_ * v2.x_
  return val
end

function SegmentsIntersect(p1, p2, q1, q2)
  local r_dx = p2.x_ - p1.x_
  local r_dy = p2.y_ - p1.y_
  local r = Vec2d{x_=r_dx, y_=r_dy}

  local s_dx = q2.x_ - q1.x_
  local s_dy = q2.y_ - q1.y_
  local s = Vec2d{x_=s_dx, y_=s_dy}

  local crossValue = CrossProduct(r, s)
  if (math.abs(crossValue) < 1.0e-5) then
    return false
  end
  
  local q1MinusP1_dx = q1.x_ - p1.x_
  local q1MinusP1_dy = q1.y_ - p1.y_
  local q1MinusP1 = Vec2d{x_=q1MinusP1_dx, y_=q1MinusP1_dy}
  
  local t = CrossProduct(q1MinusP1, s)/crossValue
  local u = CrossProduct(q1MinusP1, r)/crossValue
  
  if (t < 0.0 or t > 1.0 or u < 0.0 or u > 1.0) then
    return false
  end
  
  return true
end

function PointInPoly(numPoints, area2d, q1, q2)
  local numIntersections = 0
  
  for i=1, numPoints-1 do
    local p1 = area2d[i]
    local p2 = area2d[i+1]
  
    local v = SegmentsIntersect(p1, p2, q1, q2)
	if (v == true) then
	  numIntersections = numIntersections + 1
    end
  end
  
  if (numIntersections % 2 == 1) then
    return true
  else
    return false
  end
end
