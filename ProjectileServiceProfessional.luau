local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local PSP = {}
local modes: {[string]: Mode} = {}
local projectiles: {[string]: Projectile} = {}

export type Mode = {
  Events: {
    Hit: (projectile: Projectile, result: RaycastResult) -> (),
    Stopped: (projectile: Projectile) -> (),
    Update: (projectile: Projectile, old: vector, new: vector) -> (),
  },

  Name: string,
}

export type Projectile = {
  Bound: BasePart,
  RayParams: RaycastParams,
  Direction: vector,
  Position: vector,
  Speed: number,
  Gravity: number,
  Lifetime: number,
  Lived: number,
  Active: boolean,

  Mode: Mode,
  Id: string,
}

function PSP.Init(): ()
  RunService.Heartbeat:Connect(function(dt: number): ()
    for _, p in pairs(projectiles) do
      if not p.Active then continue end
      local t = os.clock() - p.Lived
      if t > p.Lifetime then
        p.Mode.Events.Stopped(p)
        PSP.DeactivateProjectile(p)
        continue 
      end

      local old_position = p.Position
      local velocity = p.Direction * p.Speed
      local grav = vector.create(0, -(workspace.Gravity * p.Gravity) * math.clamp(t, 1, p.Lifetime), 0)
      p.Position += (velocity + grav) * dt

      p.Mode.Events.Update(p, old_position, p.Position)
      local result = workspace:Raycast(old_position, p.Position - old_position, p.RayParams)
      if result then
        p.Mode.Events.Hit(p, result)
      end
    end
  end)
end

function PSP.MakeMode(): Mode
  local mode = {} :: Mode
  mode.Events = {}
  mode.Events.Hit = function() end
  mode.Events.Stopped = function() end
  mode.Events.Update = function() end

  mode.Name = "NewMode"

  return mode
end

function PSP.AddMode(mode: Mode, override: boolean?): ()
  if modes[mode.Name] and (override or true) then
    modes[mode.Name] = mode
  elseif not modes[mode.Name] then
    modes[mode.Name] = mode
  end
end

function PSP.RemoveMode(mode: string): ()
  modes[mode] = nil
end

function PSP.BindMode(projectile: Projectile, mode: string): ()
  projectile.Mode = modes[mode]
end

function PSP.GetMode(mode: string): Mode?
  return modes[mode]
end

function PSP.MakeProjectile(): Projectile
  local projectile = {} :: Projectile
  projectile.Direction = vector.zero
  projectile.Position = vector.zero
  projectile.Speed = 50
  projectile.Lifetime = 10
  projectile.Lived = 0
  projectile.Gravity = 0.1
  projectile.Active = false
  projectile.Mode = PSP.MakeMode()
  projectile.Id = HttpService:GenerateGUID(false)
  projectile.RayParams = RaycastParams.new()

  return projectile
end

function PSP.ActivateProjectile(projectile: Projectile): ()
  projectile.Lived = os.clock()
  projectile.Active = true

  projectiles[projectile.Id] = projectile
end

function PSP.DeactivateProjectile(projectile: Projectile): ()
  projectile.Active = false

  projectiles[projectile.Id] = nil
end

return PSP