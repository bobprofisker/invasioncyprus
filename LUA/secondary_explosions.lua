--[[
    Name:           secondary_explosions.lua
    Author:         SuumCuique
    Dependencies:   none
    Usage:          "do script file" in the mission editor. No configuration necessary
    Description:
        triggers secondary explosions if "supply vehicles" (trucks that can resupply units) are damaged or killed. The size and timing of the explosions are randomised. Supports, but does not requiere, "french asset pack"

    TODO:
    add support for statics
]]

boom ={}
--configuration
boom.debug = false
boom.threshold = 0.6
boom.big = 1000
boom.small = 750

boom.table = { --table of units that produce secondary explosions
    ["Truck Ural-375"] = boom.big,
    ["TRM-2000"] = boom.small,
    ["TRM-2000 Fuel"] = boom.small,
    ["Truck Bedford"] = boom.small,
    ["Truck GAZ-3308"] = boom.big,
    ["Truck GAZ-66"] = boom.small,
    ["Truck KAMAZ 43101"] = boom.big,
    ["Truck KrAZ-6322 6x6"] = boom.big,
    ["Truck M939 Heavy"] = boom.big,
    ["Truck Opel Blitz"] = boom.small,
    ["Refueler M978 HEMTT"] = boom.big,
    ["Truck Ural-375 Mobile C2"] = boom.big,
    ["Truck Ural-4320-31 Arm'd"] = boom.big,
    ["Truck ZIL-135"] = boom.big,
    ["Caisse de munitions"] = boom.small,
    --STATICS (not implemented)
    [".Ammunition depot"] = 1000, 
}

local function debug(message) --generic debug function. Outputs on the screen if debug mode is enabled, always outputs to the log
    local _outputString = "Debug: " .. tostring(message)
    if boom.debug == true then
        trigger.action.outText(tostring(_outputString), 5)
    end
    env.info(_outputString, false)
end

function boom.eventHandler(event)
    if event.id == 2 then --hit / S_EVENT_HIT
        if event.target then
            local target = event.target
            local category = target:getCategory()
            if category == 1 then --units

                local targetDesc = target:getDesc()
                if targetDesc.category == 2 then --groundUnit
                    if boom.table[targetDesc.displayName] then
                        local targetLifeCurrent = target:getLife()
                        local targetLifeInitial = target:getLife0()
                        if targetLifeCurrent / targetLifeInitial <= boom.threshold then
                            local targetVec3 = target:getPoint()
                            local yield = boom.table[targetDesc.displayName]
                            env.info(targetDesc.displayName .. " is exploding!", false)

                            local args = {["vec3"] = targetVec3, ["yield"] = yield }
                            timer.scheduleFunction( boom.explode , args , timer.getTime() + math.random(1, 3) )
                        end
                    end
                end

            elseif category == 3 then --structure
                --local targetDesc = target:getDesc()
                --trigger.action.outText("structure", 10) 
            end
        end
    end
end

function boom.explode(args) --dcs
    local yieldActual = math.ceil ( math.random(args.yield/3, args.yield) )
    trigger.action.explosion(args.vec3, yieldActual)
    if yieldActual >= 750 then
        trigger.action.effectSmokeBig(args.vec3 , 2 , math.random (0.3, 0.8) ) --medium smoke and fire
    elseif yieldActual >= 500 then
        trigger.action.effectSmokeBig(args.vec3 , 1 , math.random (0.3, 0.8) ) --small smoke and fire
    else
        trigger.action.effectSmokeBig(args.vec3 , 5 , math.random (0.3, 0.8) ) --small smoke NO fire
    end
    env.info("yieldActual: " .. yieldActual, false)
    return nil
end

local function protectedCall(...) --from splash_damage
    local status, retval = pcall(...)
    if not status then
        env.warning("secondary_explosions.lua script errors caught!" .. retval, false)
    end
end

boomHandler = {}
function boomHandler:onEvent(event)
    protectedCall(boom.eventHandler, event)
end

do
    world.addEventHandler(boomHandler)
    debug("secondary_explosions.lua initiated")
end