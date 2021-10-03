

--[[
2 October 2020
FrozenDroid:
- Added error handling to all event handler and scheduled functions. Lua script errors can no longer bring the server down.
- Added some extra checks to which weapons to handle, make sure they actually have a warhead (how come S-8KOM's don't have a warhead field...?)
28 October 2020
FrozenDroid: 
- Uncommented error logging, actually made it an error log which shows a message box on error.
- Fixed the too restrictive weapon filter (took out the HE warhead requirement)
--]]

mPlier = 5

explTable = {
	["FAB_100"]	=	45*mPlier ,
	["FAB_250"]	=	100*mPlier ,
	["FAB_250M54TU"]=	100*mPlier ,
	["FAB_500"]	=	213*mPlier ,
	["FAB_1500"]	=	675*mPlier ,
	["BetAB_500"]	=	98*mPlier ,
	["BetAB_500ShP"]=	107*mPlier ,
	["KH-66_Grom"]	=	108*mPlier ,
	["M_117"]	=	201*mPlier ,
	["Mk_81"]	=	60*mPlier ,
	["Mk_82"]	=	118*mPlier ,
	["AN_M64"]	=	121*mPlier ,
	["Mk_83"]	=	274*mPlier ,
	["Mk_84"]	=	582*mPlier ,
	["MK_82AIR"]	=	118*mPlier ,
	["MK_82SNAKEYE"]=	118*mPlier ,
	["GBU_10"]	=	582*mPlier ,
	["GBU_12"]	=	118*mPlier ,
	["GBU_16"]	=	274*mPlier ,
	["KAB_1500Kr"]	=	675*mPlier ,
	["KAB_500Kr"]	=	213*mPlier ,
	["KAB_500"]	=	213*mPlier ,
	["GBU_31"]	=	582*mPlier ,
	["GBU_31_V_3B"]	=	582*mPlier ,
	["GBU_31_V_2B"]	=	582*mPlier ,
	["GBU_31_V_4B"]	=	582*mPlier ,
	["GBU_32_V_2B"]	=	202*mPlier ,
	["GBU_38"]	=	118*mPlier ,
	["AGM_62"]	=	400*mPlier ,
	["GBU_24"]	=	582*mPlier ,
	["X_23"]	=	111*mPlier ,
	["X_23L"]	=	111*mPlier ,
	["X_28"]	=	160*mPlier ,
	["X_25ML"]	=	89*mPlier ,
	["X_25MP"]	=	89*mPlier ,
	["X_25MR"]	=	140*mPlier ,
	["X_58"]	=	140*mPlier ,
	["X_29L"]	=	320*mPlier ,
	["X_29T"]	=	320*mPlier ,
	["X_29TE"]	=	320*mPlier ,
	["AGM_84E"]	=	488*mPlier ,
	["AGM_88C"]	=	89*mPlier ,
	["AGM_122"]	=	15*mPlier ,
	["AGM_123"]	=	274*mPlier ,
	["AGM_130"]	=	582*mPlier ,
	["AGM_119"]	=	176*mPlier ,
	["AGM_154C"]	=	305*mPlier ,
	["S-24A"]	=	24*mPlier ,
	--["S-24B"]	=	123*mPlier ,
	["S-25OF"]	=	194*mPlier ,
	["S-25OFM"]	=	150*mPlier ,
	["S-25O"]	=	150*mPlier ,
	["S_25L"]	=	190*mPlier ,
	["S-5M"]	=	1*mPlier ,
	["C_8"]		=	4*mPlier ,
	["C_8OFP2"]	=	3*mPlier ,
	["C_13"]	=	21*mPlier ,
	["C_24"]	=	123*mPlier ,
	["C_25"]	=	151*mPlier ,
	["HYDRA_70M15"]	=	2*mPlier ,
	["Zuni_127"]	=	5*mPlier ,
	["ARAKM70BHE"]	=	4*mPlier ,
	["BR_500"]	=	118*mPlier ,
	["Rb 05A"]	=	217*mPlier ,
	["HEBOMB"]	=	40*mPlier ,
	["HEBOMBD"]	=	40*mPlier ,
	["MK-81SE"]	=	60*mPlier ,
	["AN-M57"]	=	56*mPlier ,
	["AN-M64"]	=	180*mPlier ,
	["AN-M65"]	=	295*mPlier ,
	["AN-M66A2"]	=	536*mPlier ,
}

local weaponDamageEnable = 1
WpnHandler = {}
tracked_weapons = {}
refreshRate = 0.1

local function getDistance(point1, point2)
  local x1 = point1.x
  local y1 = point1.y
  local z1 = point1.z
  local x2 = point2.x
  local y2 = point2.y
  local z2 = point2.z
  local dX = math.abs(x1-x2)
  local dZ = math.abs(z1-z2)
  local distance = math.sqrt(dX*dX + dZ*dZ)
  return distance
end

local function getDistance3D(point1, point2)
  local x1 = point1.x
  local y1 = point1.y
  local z1 = point1.z
  local x2 = point2.x
  local y2 = point2.y
  local z2 = point2.z
  local dX = math.abs(x1-x2)
  local dY = math.abs(y1-y2)
  local dZ = math.abs(z1-z2)
  local distance = math.sqrt(dX*dX + dZ*dZ + dY*dY)
  return distance
end

local function vec3Mag(speedVec)

	mag = speedVec.x*speedVec.x + speedVec.y*speedVec.y+speedVec.z*speedVec.z
	mag = math.sqrt(mag)
	--trigger.action.outText("X = " .. speedVec.x ..", y = " .. speedVec.y .. ", z = "..speedVec.z, 10)
	--trigger.action.outText("Speed = " .. mag, 1)
	return mag

end

local function lookahead(speedVec)

	speed = vec3Mag(speedVec)
	dist = speed * refreshRate * 1.5 
	return dist

end

local function track_wpns()
--  env.info("Weapon Track Start")
	for wpn_id_, wpnData in pairs(tracked_weapons) do   
		if wpnData.wpn:isExist() then  -- just update speed, position and direction.
			wpnData.pos = wpnData.wpn:getPosition().p
			wpnData.dir = wpnData.wpn:getPosition().x
			wpnData.speed = wpnData.wpn:getVelocity()
      --wpnData.lastIP = land.getIP(wpnData.pos, wpnData.dir, 50)
		else -- wpn no longer exists, must be dead.
--      trigger.action.outText("Weapon impacted, mass of weapon warhead is " .. wpnData.exMass, 2)
			local ip = land.getIP(wpnData.pos, wpnData.dir, lookahead(wpnData.speed))  -- terrain intersection point with weapon's nose.  Only search out 20 meters though.
			local impactPoint
			if not ip then -- use last calculated IP
				impactPoint = wpnData.pos
	--      	trigger.action.outText("Impact Point:\nPos X: " .. impactPoint.x .. "\nPos Z: " .. impactPoint.z, 2)
			else -- use intersection point
				impactPoint = ip
	--        trigger.action.outText("Impact Point:\nPos X: " .. impactPoint.x .. "\nPos Z: " .. impactPoint.z, 2)
			end
			--env.info("Weapon is gone") -- Got to here -- 
			--trigger.action.outText("Weapon Type was: ".. wpnData.name, 20)
			if explTable[wpnData.name] then
					--env.info("triggered explosion size: "..explTable[wpnData.name])
					trigger.action.explosion(impactPoint, explTable[wpnData.name])
					--trigger.action.smoke(impactPoint, 0)
			end
			tracked_weapons[wpn_id_] = nil -- remove from tracked weapons first.         
		end
	end
--  env.info("Weapon Track End")
end

function onWpnEvent(event)
  if event.id == world.event.S_EVENT_SHOT then
    if event.weapon then
      local ordnance = event.weapon
      local weapon_desc = ordnance:getDesc()
      if (weapon_desc.category ~= 0) and event.initiator then
		if (weapon_desc.category == 1) then
			if (weapon_desc.MissileCategory ~= 1 and weapon_desc.MissileCategory ~= 2) then
				tracked_weapons[event.weapon.id_] = { wpn = ordnance, init = event.initiator:getName(), pos = ordnance:getPoint(), dir = ordnance:getPosition().x, name = ordnance:getTypeName(), speed = ordnance:getVelocity() }
			end
		else
			tracked_weapons[event.weapon.id_] = { wpn = ordnance, init = event.initiator:getName(), pos = ordnance:getPoint(), dir = ordnance:getPosition().x, name = ordnance:getTypeName(), speed = ordnance:getVelocity() }
		end
      end
    end
  end
end

local function protectedCall(...)
  local status, retval = pcall(...)
  if not status then
    env.warning("Splash damage script error... gracefully caught! " .. retval, true)
  end
end


function WpnHandler:onEvent(event)
  protectedCall(onWpnEvent, event)
end

if (weaponDamageEnable == 1) then
  timer.scheduleFunction(function() 
      protectedCall(track_wpns)
      return timer.getTime() + refreshRate
    end, 
    {}, 
    timer.getTime() + refreshRate
  )
  world.addEventHandler(WpnHandler)
end
