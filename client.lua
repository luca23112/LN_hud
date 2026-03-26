local hudVisible = true
local frameworkName = 'standalone'
local ESX, QBCore = nil, nil
local cachedPlayerData = {}

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

    local okExport, esxObj = pcall(function()
      return exports['es_extended']:getSharedObject()
    end)

    if okExport and esxObj then
      ESX = esxObj
    else
      TriggerEvent('esx:getSharedObject', function(obj)
        ESX = obj
      end)
    end

    return
  end

  if GetResourceState('qb-core') == 'started' then
    frameworkName = 'qb'
    local ok, core = pcall(function()
      return exports['qb-core']:GetCoreObject()
    end)

    if ok and core then
      QBCore = core
    end
    return
  end
end

local function syncPlayerData()
  if frameworkName == 'esx' and ESX and ESX.GetPlayerData then
    cachedPlayerData = ESX.GetPlayerData() or {}
  elseif frameworkName == 'qb' and QBCore and QBCore.Functions then
    cachedPlayerData = QBCore.Functions.GetPlayerData() or {}
  else
    cachedPlayerData = {}
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
  local localState = LocalPlayer and LocalPlayer.state or {}

  if frameworkName == 'qb' and QBCore then
    local playerData = cachedPlayerData
    local metadata = playerData.metadata or {}

    hunger = clamp(round(metadata.hunger or localState.hunger or 100), 0, 100)
    thirst = clamp(round(metadata.thirst or localState.thirst or 100), 0, 100)
    stress = clamp(round(metadata.stress or localState.stress or 0), 0, 100)

    if playerData.money then
      cash = playerData.money.cash or playerData.money['cash'] or localState.cash or 0
      bank = playerData.money.bank or playerData.money['bank'] or localState.bank or 0
    else
      cash = tonumber(localState.cash) or 0
      bank = tonumber(localState.bank) or 0
    end

    if playerData.job then
      job = playerData.job.label or playerData.job.name or playerData.job.type or job
    elseif localState.job then
      job = localState.job
    end
  elseif frameworkName == 'esx' and ESX then
    local playerData = cachedPlayerData

    if playerData.accounts then
      for _, account in pairs(playerData.accounts) do
        if account.name == 'money' then
          cash = account.money or account.count or 0
        elseif account.name == 'bank' then
          bank = account.money or account.count or 0
        end
      end
    else
      cash = tonumber(localState.cash) or 0
      bank = tonumber(localState.bank) or 0
    end

    if playerData.job then
      job = playerData.job.label or playerData.job.name or playerData.job.type or job
    elseif localState.job then
      job = localState.job
    end

    hunger = clamp(round(localState.hunger or 100), 0, 100)
    thirst = clamp(round(localState.thirst or 100), 0, 100)
    stress = clamp(round(localState.stress or 0), 0, 100)
  else
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
  syncPlayerData()

  local lastDataSync = 0

  while true do
    Wait(150)

    local now = GetGameTimer()
    if now - lastDataSync >= 1000 then
      syncPlayerData()
      lastDataSync = now
    end

    local ped = PlayerPedId()
    if ped == 0 then
      goto continue
    end

    local display = hudVisible and not IsPauseMenuActive()
    local inVehicle = GetVehiclePedIsIn(ped, false) ~= 0

    local health = clamp(GetEntityHealth(ped) - 100, 0, 100)
    local armor = clamp(GetPedArmour(ped), 0, 100)
    local stamina = clamp(round(100 - GetPlayerSprintStaminaRemaining(PlayerId())), 0, 100)

    local hunger, thirst, stress, cash, bank, job = getRPData()

    local coords = GetEntityCoords(ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local direction = getCardinalDirection(GetEntityHeading(ped))

    local speed, fuel = 0, 0
    if inVehicle then
      local vehicle = GetVehiclePedIsIn(ped, false)
      speed = round(GetEntitySpeed(vehicle) * 3.6)

      if GetResourceState('LegacyFuel') == 'started' then
        local ok, level = pcall(function()
          return exports['LegacyFuel']:GetFuel(vehicle)
        end)
        fuel = ok and clamp(round(level), 0, 100) or clamp(round(GetVehicleFuelLevel(vehicle)), 0, 100)
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
        inVehicle = inVehicle,
        health = health,
        armor = armor,
        stamina = stamina,
        hunger = hunger,
        thirst = thirst,
        stress = stress,
        speed = speed,
        fuel = fuel,
        street = streetName ~= '' and streetName or 'Unbekannte Straße',
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

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', syncPlayerData)
RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
  cachedPlayerData = data or cachedPlayerData
end)
RegisterNetEvent('esx:playerLoaded', syncPlayerData)
RegisterNetEvent('esx:setJob', function(job)
  cachedPlayerData.job = job
end)
RegisterNetEvent('esx:setAccountMoney', function(account)
  if not cachedPlayerData.accounts then cachedPlayerData.accounts = {} end
  local found = false
  for i, data in pairs(cachedPlayerData.accounts) do
    if data.name == account.name then
      cachedPlayerData.accounts[i] = account
      found = true
      break
    end
  end
  if not found then
    table.insert(cachedPlayerData.accounts, account)
  end
end)

RegisterNetEvent('QBCore:Client:OnMoneyChange', syncPlayerData)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
  if not cachedPlayerData.job then cachedPlayerData.job = {} end
  cachedPlayerData.job = job or cachedPlayerData.job
end)

RegisterCommand('hud', function()
  hudVisible = not hudVisible
  SendNUIMessage({ type = 'hud:toggle', payload = { visible = hudVisible } })
end, false)
