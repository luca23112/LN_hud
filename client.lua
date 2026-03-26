local hudVisible = true
local frameworkName = 'standalone'
local ESX, QBCore = nil, nil

local function round(value)
  return math.floor(value + 0.5)
end

local function clamp(value, min, max)
  if value < min then return min end
  if value > max then return max end
  return value
end

local function detectFramework()
  if GetResourceState('es_extended') == 'started' then
    frameworkName = 'esx'
    TriggerEvent('esx:getSharedObject', function(obj)
      ESX = obj
    end)
    return
  end

  if GetResourceState('qb-core') == 'started' then
    frameworkName = 'qb'
    QBCore = exports['qb-core']:GetCoreObject()
    return
  end
end

local function getCardinalDirection(heading)
  local dirs = { 'N', 'NO', 'O', 'SO', 'S', 'SW', 'W', 'NW' }
  local normalized = heading % 360.0
  local index = math.floor((normalized + 22.5) / 45.0) % 8
  return dirs[index + 1]
end

local function getRPData()
  local hunger, thirst, stress = 100, 100, 0
  local cash = 0
  local bank = 0
  local job = 'Bürger'

  if frameworkName == 'qb' and QBCore then
    local playerData = QBCore.Functions.GetPlayerData()
    local metadata = playerData.metadata or {}

    hunger = clamp(round(metadata.hunger or 100), 0, 100)
    thirst = clamp(round(metadata.thirst or 100), 0, 100)
    stress = clamp(round(metadata.stress or 0), 0, 100)

    if playerData.money then
      cash = playerData.money.cash or 0
      bank = playerData.money.bank or 0
    end

    if playerData.job and playerData.job.label then
      job = playerData.job.label
    end
  elseif frameworkName == 'esx' and ESX then
    local playerData = ESX.GetPlayerData() or {}

    if playerData.accounts then
      for _, account in pairs(playerData.accounts) do
        if account.name == 'money' then
          cash = account.money or account.count or 0
        elseif account.name == 'bank' then
          bank = account.money or account.count or 0
        end
      end
    end

    if playerData.job and playerData.job.label then
      job = playerData.job.label
    end

    local localState = LocalPlayer and LocalPlayer.state or {}
    hunger = clamp(round(localState.hunger or 100), 0, 100)
    thirst = clamp(round(localState.thirst or 100), 0, 100)
    stress = clamp(round(localState.stress or 0), 0, 100)
  else
    local localState = LocalPlayer and LocalPlayer.state or {}
    hunger = clamp(round(localState.hunger or 100), 0, 100)
    thirst = clamp(round(localState.thirst or 100), 0, 100)
    stress = clamp(round(localState.stress or 0), 0, 100)
    cash = tonumber(localState.cash) or 0
    bank = tonumber(localState.bank) or 0
    job = localState.job or 'Bürger'
  end

  return hunger, thirst, stress, cash, bank, job
end

CreateThread(function()
  Wait(1000)
  detectFramework()

  while true do
    Wait(150)

    local ped = PlayerPedId()
    if ped == 0 then
      goto continue
    end

    local display = hudVisible and not IsPauseMenuActive()

    local health = clamp(GetEntityHealth(ped) - 100, 0, 100)
    local armor = clamp(GetPedArmour(ped), 0, 100)
    local stamina = clamp(round(100 - GetPlayerSprintStaminaRemaining(PlayerId())), 0, 100)

    local hunger, thirst, stress, cash, bank, job = getRPData()

    local coords = GetEntityCoords(ped)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local crossing = crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or nil

    local direction = getCardinalDirection(GetEntityHeading(ped))

    local inVehicle = IsPedInAnyVehicle(ped, false)
    local speed, fuel = 0, 0

    if inVehicle then
      local vehicle = GetVehiclePedIsIn(ped, false)
      speed = round(GetEntitySpeed(vehicle) * 3.6)
      if GetResourceState('LegacyFuel') == 'started' then
        fuel = clamp(round(exports['LegacyFuel']:GetFuel(vehicle)), 0, 100)
      else
        fuel = clamp(round(GetVehicleFuelLevel(vehicle)), 0, 100)
      end
    end

    local state = LocalPlayer and LocalPlayer.state or {}
    local proximity = state.proximity
    local voiceRange = 0
    if type(proximity) == 'table' and proximity.distance then
      voiceRange = round(tonumber(proximity.distance) or 0)
    elseif type(proximity) == 'number' then
      voiceRange = round(proximity)
    end

    SendNUIMessage({
      type = 'hud:update',
      payload = {
        display = display,
        health = health,
        armor = armor,
        stamina = stamina,
        hunger = hunger,
        thirst = thirst,
        stress = stress,
        speed = speed,
        fuel = fuel,
        inVehicle = inVehicle,
        street = streetName ~= '' and streetName or 'Unbekannte Straße',
        crossing = crossing,
        talking = NetworkIsPlayerTalking(PlayerId()),
        time = os.date('%H:%M'),
        direction = direction,
        cash = cash,
        bank = bank,
        job = job,
        voiceRange = voiceRange,
        id = GetPlayerServerId(PlayerId()),
        ping = GetPlayerPing(PlayerId())
      }
    })

    ::continue::
  end
end)

RegisterCommand('hud', function()
  hudVisible = not hudVisible
  SendNUIMessage({
    type = 'hud:toggle',
    payload = { visible = hudVisible }
  })
end, false)
