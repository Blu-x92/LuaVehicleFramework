AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Ammo Refil Balloon"
ENT.Author = "Luna"
ENT.Information = "Refils Ammo on Vehicles"
ENT.Category = "[LVS]"

ENT.Spawnable		= true
ENT.AdminOnly		= false

ENT.RenderGroup = RENDERGROUP_BOTH

if SERVER then
	function ENT:SpawnFunction( ply, tr, ClassName )
		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal )
		ent:Spawn()
		ent:Activate()

		return ent
	end

	function ENT:OnTakeDamage( dmginfo )
	end

	function ENT:Initialize()
		self:SetModel( "models/balloons/hot_airballoon.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:DrawShadow( false )
		self:SetTrigger( true )
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )

		local pObj = self:GetPhysicsObject()

		if not IsValid( pObj ) then
			self:Remove()

			print("LVS: missing model. Balloon terminated.")

			return
		end

		pObj:SetMass( 1000 )
		pObj:EnableMotion( true )
		pObj:EnableDrag( false )

		self:StartMotionController()

		self:PhysWake()
	end

	function ENT:PhysicsSimulate( phys, deltatime )
		phys:Wake()

		local StartPos = self:LocalToWorld( self:OBBCenter() )
		local traceUp = util.TraceLine( {
			start = StartPos,
			endpos = StartPos + Vector(0,0,50000),
			filter = self,
			mask = MASK_SOLID
		} )
		local traceDown = util.TraceLine( {
			start = StartPos,
			endpos = StartPos - Vector(0,0,50000),
			filter = self,
			mask = MASK_SOLID
		} )

		local Force = (traceUp.HitPos + traceDown.HitPos) * 0.5 - StartPos

		local ForceLinear, ForceAngle = phys:CalculateForceOffset( Force, phys:LocalToWorld( phys:GetMassCenter() + Vector(0,0,1) ) )

		ForceLinear = ForceLinear - phys:GetVelocity()
		ForceAngle = ForceAngle - phys:GetAngleVelocity()

		return ForceAngle, ForceLinear, SIM_GLOBAL_ACCELERATION
	end

	function ENT:Refil( entity )
		if not IsValid( entity ) then return end

		if not entity.LVS then return end

		if entity:WeaponRestoreAmmo() then
			entity:EmitSound("items/ammo_pickup.wav")
		end

		entity:OnMaintenance()
		hook.Run( "LVS_OnVehicleMaintenance", entity, self )
	end

	function ENT:StartTouch( entity )
		self:Refil( entity )
	end

	function ENT:EndTouch( entity )
		self:Refil( entity )
	end

	function ENT:Touch( entity )
	end

	function ENT:Think()
		return false
	end
end

if CLIENT then
	local WhiteList = {
		["weapon_physgun"] = true,
		["weapon_physcannon"] = true,
		["gmod_tool"] = true,
	}

	local SpriteColor = Color( 255, 150, 0, 255 )
	local mat = Material( "models/wireframe" )
	local FrameMat = Material( "lvs/3d2dmats/frame.png" )
	local RepairMat = Material( "lvs/3d2dmats/refil.png" )

	function ENT:Draw()
	end

	function ENT:DrawTranslucent()
		local ply = LocalPlayer()
		local Small = false

		if IsValid( ply ) and not IsValid( ply:lvsGetVehicle() ) then
			self:DrawModel()

			Small = true

			if GetConVarNumber( "cl_draweffectrings" ) == 0 then return end

			local ply = LocalPlayer()
			local wep = ply:GetActiveWeapon()

			if not IsValid( wep ) then return end

			local weapon_name = wep:GetClass()

			if not WhiteList[ weapon_name ] then
				return
			end
		end

		local Pos = self:LocalToWorld( self:OBBCenter() )

		if Small then
			for i = 0, 180, 180 do
				cam.Start3D2D( Pos, self:LocalToWorldAngles( Angle(0,i,90) ), 1 )
					surface.SetDrawColor( 255, 150, 0, 255 )

					surface.SetMaterial( FrameMat )
					surface.DrawTexturedRect( -512, -512, 1024, 1024 )

					surface.SetMaterial( RepairMat )
					surface.DrawTexturedRect( -256, 0, 512, 512 )
				cam.End3D2D()
			end
		else
			for i = 0, 180, 180 do
				cam.Start3D2D( Pos, self:LocalToWorldAngles( Angle(0,i,90) ), 0.75 )
					surface.SetDrawColor( 255, 150, 0, 255 )

					surface.SetMaterial( FrameMat )
					surface.DrawTexturedRect( -512, -512, 1024, 1024 )

					surface.SetMaterial( RepairMat )
					surface.DrawTexturedRect( -512, -512, 1024, 1024 )
				cam.End3D2D()
			end
		end
	end

	function ENT:OnRemove()
		if IsValid( self._RepairMDL ) then
			self._RepairMDL:Remove()
		end
	end
end