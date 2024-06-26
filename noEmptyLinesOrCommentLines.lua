local rch = require(game:GetService("ServerScriptService").RaycastHitbox) -- this gets the raycast module im using
local repStr = game:GetService("ReplicatedStorage")
local tween = game:GetService("TweenService") -- you know what this does
local damagemodule = require(game.ReplicatedStorage.DamageMod) -- this gets my damage module
local swingEvent = game.ReplicatedStorage.Events.Swing -- gets event
local unblockEvent = game.ReplicatedStorage.Events.Unblock -- unblock event
local blockEvent = game.ReplicatedStorage.Events.BlockEv -- block event
function fSpawn(func, ...)
	local thread = coroutine.create(func)
	coroutine.resume(thread, ...)
	return thread
end
function Knockback(hum,AttackCFrame,intensity)
	local bodyPos = hum.Parent.HumanoidRootPart:FindFirstChildOfClass("BodyPosition")
	local vectorInstance = repStr.Weapons:FindFirstChild("VectorForce")
	local torso 
	local attFrame
	local cframe
	local direction
	local vf
	local att
	local function DestroyVf()
		if (vf ~= nil) then
			vf:Destroy()
		end
	end
	local function PlatformStand()
		hum.PlatformStand = true
	end
	local function SetVector(attachment)
		vf.Parent = torso
		vf.Attachment0 = attachment
		vf.Force = (direction + Vector3.new(0,.2,0)) * 200
	end
	if (not bodyPos) then -- will not run with a body pos already there	
		PlatformStand() -- causes the character to not stand so that they can get knocked back
		torso = hum.Parent.HumanoidRootPart
		attFrame = CFrame.new(AttackCFrame.Position,hum.Parent.PrimaryPart.CFrame.Position) -- where the attack is coming from so the knockback can be applied accordingly
		cframe = CFrame.new(attFrame.Position + Vector3.new(0,intensity[1],0)) + attFrame.LookVector * intensity[2] -- this will use the intensity to create the knockback in te direction that the attack is facing
		direction = cframe.Position - torso.Position
		vf = vectorInstance:Clone()
		att = Instance.new("Attachment",torso)
		SetVector(att)
		delay(0.2,DestroyVf)
	end
end
local function Swing(plr,Type,count) -- type is the type of swing, count is which animation is playing
	local effect = script:FindFirstChild(Type).Slash:Clone()
	local char = plr.Character
	local torso = char.HumanoidRootPart
	local angles = CFrame.Angles(0,0,0) -- creates an angle instance
	local direction = 1 -- controls the direction that the swing VFX is in
	local Y = .8 -- this is just a variable that sets position of the swing effect later
	local EffectAngles = {
		CFrame.Angles(math.rad(-15),math.rad(50),math.rad(20)),
		CFrame.Angles(math.rad(-10),math.rad(-90),math.rad(-7.5)),
		CFrame.Angles(math.rad(0),math.rad(50),math.rad(0)),
		CFrame.Angles(math.rad(-10),math.rad(-90),math.rad(-7.5)),
		CFrame.Angles(math.rad(-15),math.rad(50),math.rad(20))
	}
	local function Swing()
		effect.Swing:Play()
	end
	local function SwingParticle()
		effect.Fire:Play()
	end
	local function DestroyEffect(inst)
		effect:Destroy()
	end
	local function PlaySounds()
		if (count % 2 ==0 ) then
			SwingParticle() -- Creates particles on even swings
		else
			Swing() -- plays sounds on odd swings
		end
	end
	local function EffectCFrameWhileLoop()
		while effect do
			effect.CFrame = effect.CFrame * CFrame.Angles(0,math.rad(direction * 5.75),0) -- the direction defined previously will determien the orientation. Direction is defined as +/- 1 according to which animation is being played.
			effect.Position = torso.Position + Vector3.new(0,Y,0) + torso.CFrame.LookVector*-.5
			_G.WaitTik()
		end
	end
	local function EmitParticles()
		for i,v in pairs(effect:GetChildren()) do
			if v:IsA("Attachment") then
				for _,parti in pairs(v:GetChildren()) do
					if parti:IsA("ParticleEmitter") then
						parti:Emit(parti.Rate)
					end
				end
			end
		end
	end
	local function AnimateEffect()
		local sizeTween = tween:Create(effect.Mesh,TweenInfo.new(1),{Scale = Vector3.new(effect.Mesh.Scale.X*1.5,effect.Mesh.Scale.Y,effect.Mesh.Scale.Z*1.5)}) 
		local effectChildren = effect:GetChildren()

		local function CreateTranspTween(inst)
			return tween:Create(inst,TweenInfo.new(tonumber(inst.Name * .1) * .5),{Transparency = 1}) -- Reads the name of the decal and will create a tween for transparency with an according length
		end
		for i,v in pairs(effectChildren) do
			if (v:IsA("Decal")) then
				CreateTranspTween(v):Play() -- tweens the transparency of the decal VFX to 0
			end
		end
		sizeTween:Play() -- tweens the size
	end
	local function FuncEffectAngles()
		angles = EffectAngles[count] -- Will call the angle that lines up with count's value in the index.

		if (count % 2 == 0) then 
			direction = 1 -- Direction will be positive 1 during even swings
		else
			direction = -1 -- Direction will be negative 1 during odd swings
		end
	end
	local function Execute()
		task.wait(.15) -- waits 1.5 seconds, can you believe that?
		effect.CFrame = CFrame.new(torso.Position + Vector3.new(0,Y,0) + torso.CFrame.LookVector*-.5)
		effect.CFrame = CFrame.new(effect.CFrame.Position,-1 * (torso.CFrame.LookVector * 500)) * angles
		effect.Parent = workspace
		fSpawn(EffectCFrameWhileLoop)
		fSpawn(EmitParticles,effect)
		fSpawn(PlaySounds)
		FuncEffectAngles()
		AnimateEffect()
		task.delay(3,DestroyEffect)

	end
	fSpawn(Execute)
end
function WeaponServer(plr,count,damage,blade,delaytime,Type)
	local char = plr.Character
	local hrp = char.HumanoidRootPart
	local animsfold = game.ReplicatedStorage.SwordAnims
	local char = plr.Character
	local hitbox = rch:Initialize(blade,{char})
	local hum = char:FindFirstChild('Humanoid')
	local hitConnection -- Blank declare
	local load -- Blank declare
	local anims = {
		animsfold["1"],
		animsfold["2"],
		animsfold["3"],
		animsfold["4"],
		animsfold["5"],
	}
	local function LoadAnim()
		return hum:LoadAnimation(anims[count]) -- Gets the animation based on which swing it is
	end
	local function OnHit(hit,human)
		if (count == 5) then
			Knockback(human,plr.Character.Torso,{1,30}) -- the final hit (5'th swing) applies knockback
		end
		fSpawn(damagemodule.Damage,damage,human,"Blade",true,plr.Character.Torso,false)
	end
	local function StartHitBox()
		hitConnection = hitbox.OnHit:Connect(OnHit) -- Connects onHit to the thing. so that when you hit, you do the onHit function. 	
		hitbox:HitStart()	
	end
	local function EndHitBox()
		hitbox:HitStop()
	end
	load = LoadAnim() -- gets the anim based on what swing we're doing
	load:AdjustSpeed(2) 
	load.Priority = Enum.AnimationPriority.Action -- obviously imma do action 🗣️🔥
	blade = plr.Character:FindFirstChildOfClass("Tool").Blade
	Swing(plr,Type,count) -- This calls the swing function, which creates the visual effects
	StartHitBox()
	task.delay(delaytime,EndHitBox)
	hitbox:DebugMode(false)
	load:Play()
end
function Block(plr,t,block)
	local char = plr.Character
	local human = char:FindFirstChild('Humanoid')
	local load = human:LoadAnimation(game.ReplicatedStorage.SwordAnims:FindFirstChild(block)) -- gets the animation
	local Unblockconnection ={}
	local function disconnectUnblockFunctions()
		for i = 1,#Unblockconnection do
			Unblockconnection[i]:Disconnect() --[[
			I needa disconnect these things because they'll drive me crazy. I know i technically dont need to disconnect. 
			But its an obsessivly compulsive habbit of mine where I need to disconnect every connection i make in a function.]]
		end
	end
	local function Unblock(player)
		if (player == plr) then
			load:Stop()
			char.Block.Value = false
		end
		disconnectUnblockFunctions()
	end
	load.Looped = true
	load:Play() -- plays
	char.Block.Value = true -- sets the block value to true
	Unblockconnection[#Unblockconnection == 0 and 1 or #Unblockconnection] = unblockEvent.OnServerEvent:Connect(Unblock) -- adds the connection to the table, indexing it as 1 if there are 0 items in it.
end
swingEvent.OnServerEvent:Connect(WeaponServer)
blockEvent.OnServerEvent:Connect(Block)
