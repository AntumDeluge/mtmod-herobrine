-- NPC max walk speed
local walk_limit = 2

-- Player animation speed
local animation_speed = 30

-- Player animation blending
-- Note: This is currently broken due to a bug in Irrlicht, leave at 0
local animation_blend = 0

-- Default player appearance
local default_model = "character.x"
local available_npc_textures = {
	texture_1 = {"jordan4ibanez.png", },
	texture_2 = {"zombie.png", },
	texture_3 = {"celeron55.png", },
	texture_4 = {"steve.png", }
}


-- Frame ranges for each player model
local function player_get_animations(model)
	if model == "character.x" then
		return {
		stand_START = 0,
		stand_END = 79,
		sit_START = 81,
		sit_END = 160,
		lay_START = 162,
		lay_END = 166,
		walk_START = 168,
		walk_END = 187,
		mine_START = 189,
		mine_END = 198,
		walk_mine_START = 200,
		walk_mine_END = 219
		}
	end
end

local player_model = {}
local player_anim = {}
local player_sneak = {}
local ANIM_STAND = 1
local ANIM_SIT = 2
local ANIM_LAY = 3
local ANIM_WALK  = 4
local ANIM_WALK_MINE = 5
local ANIM_MINE = 6

function player_update_visuals(self)
	--local name = get_player_name()

	player_anim = 0 -- Animation will be set further below immediately
	--player_sneak[name] = false
	prop = {
		mesh = default_model,
		textures = available_npc_textures["texture_"..math.random(1,4)],
		visual_size = {x=1, y=1},
	}
	self.object:set_properties(prop)
end

NPC_ENTITY = {
	physical = true,
	collisionbox = {-0.3,-1.0,-0.3, 0.3,0.8,0.3},
	visual = "mesh",
	mesh = "character.x",
	textures = {"character.png"},
	player_anim = 0,
	timer = 0,
	turn_timer = 0,
	vec = 0,
	yaw = 0,
	yawwer = 0,
	state = 1,
	jump_timer = 0,
	door_timer = 0,
	attacker = "",
	attacking_timer = 0,
}

NPC_ENTITY.on_activate = function(self)
	player_update_visuals(self)
	self.anim = player_get_animations(default_model)
	self.object:set_animation({x=self.anim.stand_START,y=self.anim.stand_END}, animation_speed_mod, animation_blend)
	self.player_anim = ANIM_STAND
	self.object:setacceleration({x=0,y=-10,z=0})
	self.state = 1
end

NPC_ENTITY.on_punch = function(self, puncher)
	for  _,object in ipairs(minetest.env:get_objects_inside_radius(self.object:getpos(), 5)) do
		if not object:is_player() then
			if object:get_luaentity().name == "herobrine:npc" then
				object:get_luaentity().state = 3
				object:get_luaentity().attacker = puncher:get_player_name()
			end
		end
	end
	if self.state ~= 3 then
		self.state = 3
		self.attacker = puncher:get_player_name()
	end
end

NPC_ENTITY.on_step = function(self, dtime)
	self.timer = self.timer + 0.01
	self.turn_timer = self.turn_timer + 0.01
	self.jump_timer = self.jump_timer + 0.01
	self.door_timer = self.door_timer + 0.01
	self.attacking_timer = self.attacking_timer + 0.01
	
	--collision detection prealpha
	--[[
	for  _,object in ipairs(minetest.env:get_objects_inside_radius(self.object:getpos(), 2)) do
		if object:is_player() then
			compare1 = object:getpos()
			compare2 = self.object:getpos()
			newx = compare2.x - compare1.x
			newz = compare2.z - compare1.z
			print(newx)
			print(newz)
			self.object:setacceleration({x=newx,y=self.object:getacceleration().y,z=newz})
		elseif not object:is_player() then
			if object:get_luaentity().name == "herobrine:npc" then
				print("moo")
			end
		end
	end
	]]--
	--set npc to hostile in night, and revert npc back to peaceful in daylight 
	if minetest.env:get_timeofday() >= 0 and minetest.env:get_timeofday() < 0.25 and self.state ~= 4 then
		self.state = 4
	elseif minetest.env:get_timeofday() > 0.25 and self.state == 4 then
		self.state = 1
	end
	--if mob is not in attack or hostile mode, set mob to walking or standing
	if self.state < 3 then
		if self.timer > math.random(1,20) then
			self.state = math.random(1,2)
			self.timer = 0
		end
	end
	--STANDING
	if self.state == 1 then
		self.yawwer = true
		for  _,object in ipairs(minetest.env:get_objects_inside_radius(self.object:getpos(), 3)) do
			if object:is_player() then
				self.yawwer = false
				NPC = self.object:getpos()
				PLAYER = object:getpos()
				self.vec = {x=PLAYER.x-NPC.x, y=PLAYER.y-NPC.y, z=PLAYER.z-NPC.z}
				self.yaw = math.atan(self.vec.z/self.vec.x)+math.pi^2
				if PLAYER.x > NPC.x then
					self.yaw = self.yaw + math.pi
				end
				self.yaw = self.yaw - 2
				self.object:setyaw(self.yaw)
			end
		end
		
		if self.turn_timer > math.random(1,4) and yawwer == true then
			self.yaw = 360 * math.random()
			self.object:setyaw(self.yaw)
			self.turn_timer = 0
		end
		self.object:setvelocity({x=0,y=self.object:getvelocity().y,z=0})
		if self.player_anim ~= ANIM_STAND then
			self.anim = player_get_animations(default_model)
			self.object:set_animation({x=self.anim.stand_START,y=self.anim.stand_END}, animation_speed_mod, animation_blend)
			self.player_anim = ANIM_STAND
		end
	end
	--WALKING
	if self.state == 2 then
		if self.direction ~= nil then
			self.object:setvelocity({x=self.direction.x,y=self.object:getvelocity().y,z=self.direction.z})
		end
		if self.turn_timer > math.random(1,4) then
			self.yaw = 360 * math.random()
			self.object:setyaw(self.yaw)
			self.turn_timer = 0
			self.direction = {x = math.sin(self.yaw)*-1, y = -10, z = math.cos(self.yaw)}
			--self.object:setvelocity({x=self.direction.x,y=self.object:getvelocity().y,z=direction.z})
			--self.object:setacceleration(self.direction)
		end
		if self.player_anim ~= ANIM_WALK then
			self.anim = player_get_animations(default_model)
			self.object:set_animation({x=self.anim.walk_START,y=self.anim.walk_END}, animation_speed_mod, animation_blend)
			self.player_anim = ANIM_WALK
		end
		--open a door [alpha]
		if self.direction ~= nil then
			if self.door_timer > 2 then
				local is_a_door = minetest.env:get_node({x=self.object:getpos().x + self.direction.x,y=self.object:getpos().y,z=self.object:getpos().z + self.direction.z}).name
				if is_a_door == "doors:door_wood_t_1" then
					minetest.env:punch_node({x=self.object:getpos().x + self.direction.x,y=self.object:getpos().y-1,z=self.object:getpos().z + self.direction.z})
					self.door_timer = 0
				end
				local is_in_door = minetest.env:get_node(self.object:getpos()).name
				if is_in_door == "doors:door_wood_t_1" then
					minetest.env:punch_node(self.object:getpos())
				end
			end
		end
		--jump
		if self.direction ~= nil then
			if self.jump_timer > 0.3 then
				if minetest.env:get_node({x=self.object:getpos().x + self.direction.x,y=self.object:getpos().y-1,z=self.object:getpos().z + self.direction.z}).name ~= "air" then
					self.object:setvelocity({x=self.object:getvelocity().x,y=5,z=self.object:getvelocity().z})
					self.jump_timer = 0
				end
			end
		end
	end
	--ATTACKING
	if self.state == 3 then
		if self.attacking_timer > 0.25 then
			for  _,object in ipairs(minetest.env:get_objects_inside_radius(self.object:getpos(), 2)) do
				if object:is_player() then
					if object:get_player_name() == self.attacker then
						if object:get_hp() > 0 then					
							object:punch(object, 1.0, {
								full_punch_interval=1.0,
								groupcaps={
									fleshy={times={[1]=1, [2]=1, [3]=1}},
									snappy={times={[1]=1, [2]=1, [3]=1}},
								}
							}, nil)
							self.attacking_timer = 0
						elseif object:get_hp() <= 0 then
							self.state = 1
							self.attacker = ""
						end
					end
				end
			end
		end
		for  _,object in ipairs(minetest.env:get_objects_inside_radius(self.object:getpos(), 10)) do
			if object:is_player() then
				if object:get_player_name() == self.attacker then
					if self.player_anim ~= ANIM_WALK then
						self.anim = player_get_animations(default_model)
						self.object:set_animation({x=self.anim.walk_START,y=self.anim.walk_END}, animation_speed_mod, animation_blend)
						self.player_anim = ANIM_WALK
					end
					NPC = self.object:getpos()
					PLAYER = object:getpos()
					self.vec = {x=PLAYER.x-NPC.x, y=PLAYER.y-NPC.y, z=PLAYER.z-NPC.z}
					self.yaw = math.atan(self.vec.z/self.vec.x)+math.pi^2
					if PLAYER.x > NPC.x then
						self.yaw = self.yaw + math.pi
					end
					self.yaw = self.yaw - 2
					self.object:setyaw(self.yaw)
					self.direction = {x = math.sin(self.yaw)*-1, y = 0, z = math.cos(self.yaw)}
					if self.direction ~= nil then
						self.object:setvelocity({x=self.direction.x*2.5,y=self.object:getvelocity().y,z=self.direction.z*2.5})
					end
					--jump over obstacles
					if self.jump_timer > 0.3 then
						if minetest.env:get_node({x=self.object:getpos().x + self.direction.x,y=self.object:getpos().y-1,z=self.object:getpos().z + self.direction.z}).name ~= "air" then
							self.object:setvelocity({x=self.object:getvelocity().x,y=5,z=self.object:getvelocity().z})
							self.jump_timer = 0
						end
					end
					if self.direction ~= nil then
						if self.door_timer > 2 then
							local is_a_door = minetest.env:get_node({x=self.object:getpos().x + self.direction.x,y=self.object:getpos().y,z=self.object:getpos().z + self.direction.z}).name
							if is_a_door == "doors:door_wood_t_1" then
								minetest.env:punch_node({x=self.object:getpos().x + self.direction.x,y=self.object:getpos().y-1,z=self.object:getpos().z + self.direction.z})
								self.door_timer = 0
							end
							local is_in_door = minetest.env:get_node(self.object:getpos()).name
							if is_in_door == "doors:door_wood_t_1" then
								minetest.env:punch_node(self.object:getpos())
							end
						end
					end
					return
				elseif object:get_player_name() ~= self.attacker then
					self.state = 1
					self.attacker = ""
					return
				end
			elseif not object:is_player() then
				self.state = 1
				self.attacker = ""
			end
		end
	end
	--WANDERING CONSTANTLY AT NIGHT
	if self.state == 4 then
		if self.player_anim ~= ANIM_WALK then
			self.anim = player_get_animations(default_model)
			self.object:set_animation({x=self.anim.walk_START,y=self.anim.walk_END}, animation_speed_mod, animation_blend)
			self.player_anim = ANIM_WALK
		end
		if self.attacking_timer > 0.25 then
			for  _,object in ipairs(minetest.env:get_objects_inside_radius(self.object:getpos(), 2)) do
				if object:is_player() then
					if object:get_hp() > 0 then					
						object:punch(object, 1.0, {
							full_punch_interval=1.0,
							groupcaps={
								fleshy={times={[1]=1, [2]=1, [3]=1}},
								snappy={times={[1]=1, [2]=1, [3]=1}},
							}
						}, nil)
						self.attacking_timer = 0
					elseif object:get_hp() <= 0 then
						self.state = 1
						self.attacker = ""
					end
				end
			end
		end
		for  _,object in ipairs(minetest.env:get_objects_inside_radius(self.object:getpos(), 12)) do
			if object:is_player() then
				if object:get_hp() > 0 then
					NPC = self.object:getpos()
					PLAYER = object:getpos()
					self.vec = {x=PLAYER.x-NPC.x, y=PLAYER.y-NPC.y, z=PLAYER.z-NPC.z}
					self.yaw = math.atan(self.vec.z/self.vec.x)+math.pi^2
					if PLAYER.x > NPC.x then
						self.yaw = self.yaw + math.pi
					end
					self.yaw = self.yaw - 2
					self.object:setyaw(self.yaw)
					self.direction = {x = math.sin(self.yaw)*-1, y = 0, z = math.cos(self.yaw)}
					if self.direction ~= nil then
						self.object:setvelocity({x=self.direction.x*2.5,y=self.object:getvelocity().y,z=self.direction.z*2.5})
					end
					--jump over obstacles
					if self.jump_timer > 0.3 then
						if minetest.env:get_node({x=self.object:getpos().x + self.direction.x,y=self.object:getpos().y-1,z=self.object:getpos().z + self.direction.z}).name ~= "air" then
							self.object:setvelocity({x=self.object:getvelocity().x,y=5,z=self.object:getvelocity().z})
							self.jump_timer = 0
						end
					end
					if self.direction ~= nil then
						if self.door_timer > 2 then
							local is_a_door = minetest.env:get_node({x=self.object:getpos().x + self.direction.x,y=self.object:getpos().y,z=self.object:getpos().z + self.direction.z}).name
							if is_a_door == "doors:door_wood_t_1" then
								minetest.env:punch_node({x=self.object:getpos().x + self.direction.x,y=self.object:getpos().y-1,z=self.object:getpos().z + self.direction.z})
								self.door_timer = 0
							end
							local is_in_door = minetest.env:get_node(self.object:getpos()).name
							if is_in_door == "doors:door_wood_t_1" then
								minetest.env:punch_node(self.object:getpos())
							end
						end
					end
				--return
				end
			elseif not object:is_player() then
				self.state = 1
				self.attacker = ""
			end
		end
		if self.direction ~= nil then
			self.object:setvelocity({x=self.direction.x,y=self.object:getvelocity().y,z=self.direction.z})
		end
		if self.turn_timer > math.random(1,4) then
			self.yaw = 360 * math.random()
			self.object:setyaw(self.yaw)
			self.turn_timer = 0
			self.direction = {x = math.sin(self.yaw)*-1, y = -10, z = math.cos(self.yaw)}
		end
		if self.player_anim ~= ANIM_WALK then
			self.anim = player_get_animations(default_model)
			self.object:set_animation({x=self.anim.walk_START,y=self.anim.walk_END}, animation_speed_mod, animation_blend)
			self.player_anim = ANIM_WALK
		end
		--open a door [alpha]
		if self.direction ~= nil then
			if self.door_timer > 2 then
				local is_a_door = minetest.env:get_node({x=self.object:getpos().x + self.direction.x,y=self.object:getpos().y,z=self.object:getpos().z + self.direction.z}).name
				if is_a_door == "doors:door_wood_t_1" then
					--print("door")
					minetest.env:punch_node({x=self.object:getpos().x + self.direction.x,y=self.object:getpos().y-1,z=self.object:getpos().z + self.direction.z})
					self.door_timer = 0
				end
				local is_in_door = minetest.env:get_node(self.object:getpos()).name
				--print(dump(is_in_door))
				if is_in_door == "doors:door_wood_t_1" then
					minetest.env:punch_node(self.object:getpos())
				end
			end
		end
		--jump
		if self.direction ~= nil then
			if self.jump_timer > 0.3 then
				--print(dump(minetest.env:get_node({x=self.object:getpos().x + self.direction.x,y=self.object:getpos().y-1,z=self.object:getpos().z + self.direction.z})))
				if minetest.env:get_node({x=self.object:getpos().x + self.direction.x,y=self.object:getpos().y-1,z=self.object:getpos().z + self.direction.z}).name ~= "air" then
					self.object:setvelocity({x=self.object:getvelocity().x,y=5,z=self.object:getvelocity().z})
					self.jump_timer = 0
				end
			end
		end
	end
end

minetest.register_entity("herobrine:npc", NPC_ENTITY)

minetest.register_node("herobrine:spawnegg", {
	description = "spawnegg",
	image = "mobspawnegg.png",
	inventory_image = "mobspawnegg.png",
	wield_image = "mobspawnegg.png",
	paramtype = "light",
	tiles = {"spawnegg.png"},
	is_ground_content = true,
	drawtype = "glasslike",
	groups = {crumbly=3},
	selection_box = {
		type = "fixed",
		fixed = {0,0,0,0,0,0}
	},
	sounds = default.node_sound_dirt_defaults(),
	on_place = function(itemstack, placer, pointed)
		pos = pointed.above
		pos.y = pos.y + 1
		minetest.env:add_entity(pointed.above,"herobrine:npc")
	end
})
--[[
This causes mobs to cluster together DONTA JLAFGJKAS USE IRT
--use pilzadam's spawning algo
npcs = {}
npcs.spawning_mobs = {}
	function npcs:register_spawn(name, nodes, max_light, min_light, chance, mobs_per_30_block_radius, max_height)
		npcs.spawning_mobs[name] = true
		minetest.register_abm({
		nodenames = nodes,
		neighbors = nodes,
		interval = 30,
		chance = chance,
		action = function(pos, node)
			if not npcs.spawning_mobs[name] then
				return
			end
			pos.y = pos.y+1
			if not minetest.env:get_node_light(pos) then
				return
			end
			if minetest.env:get_node_light(pos) > max_light then
				return
			end
			if minetest.env:get_node_light(pos) < min_light then
				return
			end
			if pos.y > max_height then
				return
			end
			if minetest.env:get_node(pos).name ~= "air" then
				return
			end
			pos.y = pos.y+1
			if minetest.env:get_node(pos).name ~= "air" then
				return
			end

			local count = 0
			for _,obj in pairs(minetest.env:get_objects_inside_radius(pos, 30)) do
				if obj:is_player() then
					return
				elseif obj:get_luaentity() and obj:get_luaentity().name == name then
					count = count+1
				end
			end
			if count > mobs_per_30_block_radius then
				return
			end

			if minetest.setting_getbool("display_mob_spawn") then
				minetest.chat_send_all("[NPCs] Add "..name.." at "..minetest.pos_to_string(pos))
			end
			minetest.env:add_entity(pos, name)
		end
	})
end

npcs:register_spawn("herobrine:npc", {"default:dirt_with_grass"}, 16, -1, 500, 10, 31000)
]]--
