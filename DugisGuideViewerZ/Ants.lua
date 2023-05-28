if not IsAddOnLoaded("TomTom") then return end
if not Ants then
Ants = {}
local mapAnts, miniAnts = {}, {}    -- store ants displayed on minimap and world map
local speed = 0.7 -- shift to make every 0.1 sec
local space = 20  -- space between ants
local x_shift, y_shift = {}, {}  -- actual shift of ants (moving effect)
local d, rx, ry, lx, ly, count, wx, wy -- needed for calculating move vector of ants 
local mapVisible = false -- store if map is actually visible 
local point, relativeTo, relativePoint, x, y -- store waypoint position in UI
local mapLayer       -- frame to draw above world map
local lastTGWaypoint -- store last waypoint added by TG
local lastLocation   -- store location of last waypoint
local points = {}
local show = false   -- if trails should be visible
local worldmap = false
local radtodeg = 57.295779513082320876798154814105
local k = 0
local minimapShow = false  -- if trails should be visible on minimap
local checkdistance = true
local last_count = {}
local numonmap = 0
local Astrolabe = DongleStub("Astrolabe-0.4") 
mapLayer = CreateFrame("Frame", "MapOverlay", WorldMapDetailFrame)
mapLayer:SetAllPoints(true)
local minimapTo   = CreateFrame("Frame", nil, Minimap)
local minimapFrom   = CreateFrame("Frame", nil, Minimap)
local waypointTo     = CreateFrame("Frame", nil, mapLayer)
local waypointZoomTo  = CreateFrame("Frame", nil, mapLayer)
local waypointZoomFrom  = CreateFrame("Frame", nil, mapLayer)
local waypointFrom   = CreateFrame("Frame", nil, mapLayer)
--Public Functions
function Ants:hideallants()
local j, i
for j = 1 , #mapAnts do mapAnts[j].hide = true for i = 1, #mapAnts[j] do mapAnts[j][i]:Hide() end end
end
function Ants:ClearShift()
local i
for i = 1, #DugisGuideViewer.coords do
x_shift[i], y_shift[i] = 0,0
end
end
function Ants:removeAllPoints()
Ants:hideallants()
table.wipe(last_count)
Ants:deleteAllCoords()
end 
function Ants:deleteAllCoords()
DugisGuideViewer.coords = {}
end
local function RemoveCoord(uid)
TomTom:RemoveWaypoint(uid)
Ants:hideallants()
deleteant(uid, mapAnts)
deletecoord(uid)
end
function Ants:Debugz()
local i, j
DebugPrint("***********Debug***************")
for i = 1, #DugisGuideViewer.coords do
local c, z, x, y, uid, desc = unpack(DugisGuideViewer.coords[i])
DebugPrint("DugisGuideViewer.coords "..i.." C:"..c.." Z:"..z.." X:"..(x*100).." Y:"..(y*100).."uid:"..uid.."desc"..desc)
end
DebugPrint("SIZE OF MAPANTS:"..#mapAnts)
for j = 1 , #mapAnts do
if j == 1 then DebugPrint("PLAYER -> POINT 1") else DebugPrint("POINT"..(j-1).." ->"..j) end
for i = 1, #mapAnts[j] do
point, relativeTo, relativePoint, wx, wy = mapAnts[j][i]:GetPoint() --added i
x = ((wx/mapLayer:GetWidth())*100)
y = ((wy/mapLayer:GetHeight()*100))
DebugPrint("MapANTS["..j.."]".."["..i.."]".." ("..string.format("%.2f", x)..","..string.format("%.2f", y)..")")--
end
DebugPrint("x_shift:"..x_shift[j].."y_shift:"..y_shift[j])
end
for j = 1 , #mapAnts do 
if mapAnts[j].hide == true then DebugPrint("Ant#"..j.." hidden") else DebugPrint("Ant#"..j.." shown") end
end
DebugPrint("***********End Debug***************")
end
--[[-------------------------
Local Functions
---------------------------]]
local function getPlayerPosition() 
return GetCurrentMapContinent(), GetCurrentMapZone(), GetPlayerMapPosition("player")
end
--Return x, y in game yards
local function getxyfromicon(icon)
local x, y
x, y = select(4, icon:GetPoint())
x = (x/mapLayer:GetWidth())
y = (y/mapLayer:GetHeight()) * -1
return x, y
end
local function getCoords(index)
local c, z, x, y, uid, desc 
if DugisGuideViewer.coords[index] then
c, z, x, y, uid, desc = unpack(DugisGuideViewer.coords[index])
end
return c, z, x, y, uid, desc 
end
local function getxy(index)
local x, y = select ( 3, unpack(DugisGuideViewer.coords[index]))
return x, y
end
local function getcont(index)
local c
if DugisGuideViewer.coords[index] then c = select ( 1, unpack(DugisGuideViewer.coords[index])) end
return c
end
local function getzone(index)
local z 
if DugisGuideViewer.coords[index] then z = select ( 2, unpack(DugisGuideViewer.coords[index])) end
return z
end
local function getuid(index)
local uid
if DugisGuideViewer.coords[index] then uid = select ( 5, unpack(DugisGuideViewer.coords[index])) end
return uid
end
local function getdesc(index)
local desc = select ( 6, unpack(DugisGuideViewer.coords[index]))
return desc
end
local function getindex(uid)
local i, v
for i, v in pairs(DugisGuideViewer.coords) do
if v[5] == uid then return i end 
end
end
local function hideants(index)
local j
if mapAnts[index] then 
for j = 1 , #mapAnts[index] do mapAnts[index][j]:Hide() end 
mapAnts[index].hide = true
end
end
local function showants(index)
if mapAnts[index] then 
mapAnts[index].hide = false
end
end
local function showallants(ant)
local j, i
for j = 1 , #ant do ant[j].hide = false for i = 1, #ant[j] do ant[j][i]:Show() end end
end
local function deleteallants(ant)
local i
for i in ipairs(x_shift) do
x_shift[i], y_shift[i] = 0,0
end
wipe(ant)
end
function deleteant(uid, ant)
local i, index
index = getindex(uid)
if index then
for i = index, #ant-1 do
ant[i] = ant[i+1]
last_count[i] = last_count[i+1] 
end
tremove(ant)
tremove(last_count)
end
end
function deletecoord(uid)
local i, index
index = getindex(uid)
if index then
for i = index, #DugisGuideViewer.coords-1 do
DugisGuideViewer.coords[i] = DugisGuideViewer.coords[i+1]
end
tremove(DugisGuideViewer.coords)
end
end
local function distance(p1 ,p2) return sqrt(p1*p1 + p2*p2) end
--Calculate the angle for ants when a point is not in the current map zoom
local function PlaceIconOffMap(fc, fz, fx, fy, dir, d)
local xmax, ymax = 99.9, 99.9 
local x_coord, y_coord, deltay, deltax
local ZERO = 0.01 --Astrolabe doesn't like 0
angle = (radtodeg * dir)%360 --Convert from radians to degrees
px = fx
py = fy
px = px*100
py = py*100
--Determine which map edge the point will hit
--Use tan = x/y --> y = x/tan
if angle <= 90 then --First Quadrant (NW)
deltay = px/tan(angle)
if deltay < py then 
x_coord = ZERO
y_coord = py - deltay
else 
x_coord = px - ((px/deltay)*py)
y_coord = ZERO 
end
if d then DebugPrint("Q1") end
elseif angle <= 180 then--Second Quadrant (SW)
deltay = px/tan(180-angle)
if (deltay + py) < ymax then 
x_coord = ZERO 
y_coord = deltay + py 
else
deltax = px/deltay * (deltay-py)
x_coord = deltax
y_coord = ymax
end  
if d then DebugPrint("Q2") end
elseif angle <= 270 then--Third Quadrant (SE)
deltax = xmax - px
deltay = deltax/tan(angle-180)
if (deltay + py) > ymax then
--x_coord = (deltax/deltay * py) + px
x_coord = (deltax/deltay * (ymax-py)) + px
y_coord = ymax
else
y_coord = deltay + py
x_coord = xmax
end
if d then DebugPrint("Q3") end
else--Fourth Quadrant (NE)
deltay = (xmax-px)/tan(360-angle) 
if (deltay + py) < ymax then 
x_coord = xmax
y_coord = py - deltay 
else 
x_coord = px + ((xmax-px)/deltay) * py
y_coord = ZERO 
end
if d then DebugPrint("Q4") end
end
if y_coord > ymax then y_coord = ymax end
if x_coord > xmax then x_coord = xmax end
if d then
if DugisGuideViewer.coords[1].zoomonepoint == true then text = "true" else text = "false" end
DebugPrint("x_coord:"..string.format("%.2f", x_coord).." y_coord:"..string.format("%.2f", y_coord).." deltay:"..string.format("%.2f",deltay).." angle (deg):"..string.format("%.2f",angle).." x:"..string.format("%.2f",fx).." y:"..string.format("%.2f",fy).."pc"..fc.."pz"..fz)
end
return fc, fz, x_coord/100, y_coord/100
  end
local function createAnt(map)
local ant = CreateFrame("Frame", nil, map and mapLayer or Minimap)
ant:SetHeight(8)
ant:SetWidth(8)
ant.icon = ant:CreateTexture("BACKGROUND")
ant.icon:SetTexture("Interface\\AddOns\\DugisGuideViewerZ\\Artwork\\Ant")
ant.icon:SetPoint("CENTER", 0, 0)
ant.icon:SetAlpha(0.5)
ant.icon:SetHeight(6)
ant.icon:SetWidth(6)
return ant
end
local function updateAnts(x,y, tab, xx, yy, onMap, indx)
xx, yy = xx or 0, yy or 0
d = distance(x, y) 
rx, ry  = (space * x / d), (space * y / d)
x_shift[indx] = x_shift[indx] + (speed * x / d)
y_shift[indx] = (y * x_shift[indx]) / x
lx, ly  = x_shift[indx], y_shift[indx]
count, dd = 1, 0
if tab[indx] == nil then tab[indx] = {} end
while dd < d and d > space do
  tab[indx][count] = tab[indx][count] or createAnt(onMap)
  tab[indx][count]:SetPoint(point, relativeTo, relativePoint, lx + xx, ly + yy)
  if tab[indx].hide then tab[indx][count]:Hide() else tab[indx][count]:Show() end
  lx = lx + rx 
  ly = ly + ry 
  dd = sqrt(lx*lx + ly*ly)
  --DebugPrint("Count:"..count.."x:"..((lx+xx)/mapLayer:GetWidth() *100).."y:"..((ly+yy)/mapLayer:GetHeight()*100))
  count = count + 1  
end
for i = count, #tab[indx] do
if tab[indx] then 
if tab[indx][i] then tab[indx][i]:Hide() end 
end
end 
if distance(x_shift[indx], y_shift[indx]) > space then x_shift[indx] = x_shift[indx] - rx end
last_count[indx] = count
end
local function updateMinimapAnts(i)
point, relativeTo, relativePoint, wx, wy = minimapTo:GetPoint() --added i
local px, py = select(4, minimapFrom:GetPoint())
if not wx then return end
x, y = wx - px, wy - py
updateAnts(x, y, miniAnts, nil, nil, nil, i)
end
local function updateMapAnts(i)
local px, py
if DugisGuideViewer.coords[1].zoomonepoint == true then
point, relativeTo, relativePoint, wx, wy = waypointZoomTo:GetPoint() 
px, py = select(4, waypointZoomFrom:GetPoint())
else
point, relativeTo, relativePoint, wx, wy = waypointTo[i]:GetPoint() 
px, py = select(4, waypointFrom[i]:GetPoint())
end
if not wx then return DebugPrint("Error, no to waypoint, i="..i) end
--DebugPrint("Destination for indx:"..i.."wx"..((wx/mapLayer:GetWidth())*100).."wy"..((wy/mapLayer:GetHeight())*100).."px"..((px/mapLayer:GetWidth())*100).."py"..((py/mapLayer:GetHeight())*100))
if not px then return end
x, y = wx - px, wy - py
--DebugPrint("Destination for indx:"..i.."x"..((x/mapLayer:GetWidth())*100).."y"..((y/mapLayer:GetHeight())*100).."px"..((px/mapLayer:GetWidth())*100).."py"..((py/mapLayer:GetHeight())*100))
updateAnts(x, y, mapAnts, px, py, true, i)
end
local function SetWaypointNextPoint()
local uid = getuid(1)
if uid then 
TomTom:SetCrazyArrow(uid, TomTom.profile.arrow.arrival, getdesc(getindex(uid)) )
end
end
local function DidPlayerReachWaypoint()
local i, j
for i, j in ipairs(DugisGuideViewer.coords) do
local uid = getuid(i)
local dist = TomTom:GetDistanceToWaypoint(uid) 
if uid and dist and dist < 15 then 
--[[if #DugisGuideViewer.coords > 1 then
RemoveCoord(uid) 
SetWaypointNextPoint()
end--]]
return uid 
end
end
end
--[[local function hook_RemoveWayPoint(self, ...)
if Ants then
DebugPrint("remove waypoint")
if DidPlayerReachWaypoint() == nil then --If player is manually removing a waypoint
DebugPrint("remove waypoint2")
Ants:removeAllPoints()
end
end
end
hooksecurefunc(TomTom, "RemoveWaypoint", hook_RemoveWayPoint)
--]]
local function ZoomedInMax()
if DugisGuideViewer.coords[1] then
local cont = getcont(1)
local zone = getzone(1)
if cont == GetCurrentMapContinent() and zone == GetCurrentMapZone() then return true end
end
end
local function HideAntsOffMap(d)
local c, z, x, y, dir
if mapupdated == true then 
--xPos, yPos = Astrolabe:TranslateWorldMapPosition( C, Z, xPos, yPos, nC, nZ )
Ants:hideallants()
if waypointFrom[1]:IsVisible() and waypointTo[1]:IsVisible() then
DebugPrint("BOTH ON MAP")
numonmap = 2
elseif (not waypointFrom[1]:IsVisible()) and (not waypointTo[1]:IsVisible()) then 
DebugPrint("BOTH OFF MAP")
numonmap = 0
else-- waypointZoom:IsVisible() then --(not waypointFrom[1]:IsVisible() and waypointTo[1]:IsVisible()) or   (waypointFrom[1]:IsVisible() and not waypointTo[1]:IsVisible())  then
if waypointFrom[1]:IsVisible() then DebugPrint("WAYPOINT FROM VISIBLE") end
if waypointTo[1]:IsVisible() then DebugPrint("WAYPOINT TO VISIBLE") end
if waypointZoomTo and waypointZoomTo:IsVisible() then DebugPrint("WAYPOINT ZOOM to VISIBLE") end
if waypointZoomFrom and waypointZoomFrom:IsVisible() then DebugPrint("WAYPOINT ZOOM from VISIBLE") end
numonmap = 1
end
if numonmap == 2 then
DugisGuideViewer.coords[1].zoomonepoint = false 
if printonce then DebugPrint("both ON map") end
--if ZoomedInMax() then showallants(mapAnts) end
showallants(mapAnts)
elseif numonmap == 0 then
DugisGuideViewer.coords[1].zoomonepoint = false 
if printonce then DebugPrint("both waypoints off map") end
elseif numonmap ==1 then
showants(1)
if DugisGuideViewer.coords[1].zoomonepoint == false then 
for i = 1, #DugisGuideViewer.coords do
x_shift[i], y_shift[i] = 0,0
end
end
DugisGuideViewer.coords[1].zoomonepoint = true
if printonce then DebugPrint("one waypoint off map") end
if waypointFrom[1]:IsVisible() then 
--fc, fz, fx, fy = getPlayerPosition() 
c, z, x, y = Astrolabe:GetCurrentPlayerPosition()
dir = TomTom:GetDirectionToWaypoint(getuid(1))
if dir then
local nc, nz, nx, ny = PlaceIconOffMap(c, z, x, y, dir, d)
DugisGuideViewer.coords[1].zoomcoordsfrom = {c, z, x, y} 
DugisGuideViewer.coords[1].zoomcoordsto = {nc, nz, nx, ny} 
end
else
--xPos, yPos = Astrolabe:TranslateWorldMapPosition( C, Z, xPos, yPos, nC, nZ )
--C, Z, x, y = Astrolabe:GetCurrentPlayerPosition()
dir = TomTom:GetDirectionToWaypoint(getuid(1)) 
c, z, x, y = unpack(DugisGuideViewer.coords[1])
if dir then 
dir = dir + 3.14
local nc, nz, nx, ny = PlaceIconOffMap(c, z, x, y, dir, d)
--c, z, x, y = Astrolabe:GetCurrentPlayerPosition() 
DugisGuideViewer.coords[1].zoomcoordsfrom = {nc, nz, nx, ny}
DugisGuideViewer.coords[1].zoomcoordsto =  {c, z, x, y}
end
end
--if d then DebugPrint("one waypoint off map. x:"..fx.."y:"..fy.."c:"..fc.."z:"..fz.." dir:"..(radtodeg * dir)) end
end
end--if map updated
printonce = false
end
local frame = CreateFrame("Frame")
frame:Show()
frame:RegisterEvent("WORLD_MAP_UPDATE")
frame:SetScript("OnEvent", function(self, event, ...)
if event == "WORLD_MAP_UPDATE" then
   mapVisible = WorldMapFrame:IsVisible()   
   mapupdated = true
   Ants:hideallants()
   show = true
   --deleteallants(mapAnts) 
if GetCurrentMapContinent() == -1 then --world map view 
Ants:hideallants() 
show = false
end
if IsInInstance() then show = false end
end
end)
frame.SinceLastUpdate = 0;
frame:SetScript("OnUpdate", function(self, elapsed)
local tc, tz, tx, ty, i, fc, fz, fx, fy
self.SinceLastUpdate = self.SinceLastUpdate + elapsed; 
if (self.SinceLastUpdate > 0.1) then
  self.SinceLastUpdate = 0
  if show then 
  if mapVisible and DugisGuideViewer.coords[1] then 
for i = 1, #DugisGuideViewer.coords do
if not waypointFrom[i] then waypointFrom[i] = CreateFrame("Frame", nil, mapLayer) end
if not waypointTo[i] then waypointTo[i] = CreateFrame("Frame", nil, mapLayer) end
if DugisGuideViewer.coords[1].zoomonepoint == true and DugisGuideViewer.coords[1].zoomcoordsfrom and DugisGuideViewer.coords[1].zoomcoordsto and mapupdated == false then
fc, fz, fx, fy   =  unpack(DugisGuideViewer.coords[1].zoomcoordsfrom)
tc, tz, tx, ty =  unpack(DugisGuideViewer.coords[1].zoomcoordsto)
Astrolabe:PlaceIconOnWorldMap(mapLayer, waypointZoomFrom, fc, fz, fx, fy)
Astrolabe:PlaceIconOnWorldMap(mapLayer, waypointZoomTo,  tc, tz, tx, ty)
elseif i == 1 then
fc, fz, fx, fy   = getPlayerPosition()
tc, tz, tx, ty =  unpack(DugisGuideViewer.coords[i])
Astrolabe:PlaceIconOnWorldMap(mapLayer, waypointFrom[i], fc, fz, fx, fy)
Astrolabe:PlaceIconOnWorldMap(mapLayer, waypointTo[i],  tc, tz, tx, ty)
else
fc, fz, fx, fy   =  unpack(DugisGuideViewer.coords[i-1])
tc, tz, tx, ty =  unpack(DugisGuideViewer.coords[i])
Astrolabe:PlaceIconOnWorldMap(mapLayer, waypointFrom[i], fc, fz, fx, fy)
Astrolabe:PlaceIconOnWorldMap(mapLayer, waypointTo[i],  tc, tz, tx, ty)
end
if k > 10 then
--DebugPrint("index:"..i.." fx:"..fx.." fy:"..fy.." fc:"..fc.." fz:"..fz.." tc:"..tc.." tz:"..tz.." tx:"..tx.." ty:"..ty)
k = 0
end
k = k + 1
updateMapAnts(i)
HideAntsOffMap()
mapupdated = false
end
end 
local plc, plz, plx, ply = getPlayerPosition()
local c, z, x, y, uid, desc = getCoords(1) 
if plc and plz and plx and ply and c and z and x and y and uid and desc then
Astrolabe:PlaceIconOnMinimap(minimapFrom, plc, plz, plx, ply )
--Astrolabe:PlaceIconOnMinimap(minimapTo, c, z, x, y, uid, desc)
Astrolabe:PlaceIconOnMinimap(minimapTo, getCoords(1))
updateMinimapAnts(1)
end
end --If show
ret = DidPlayerReachWaypoint()
if ret then
RemoveCoord(ret) 
SetWaypointNextPoint()
end
end
end)
end
