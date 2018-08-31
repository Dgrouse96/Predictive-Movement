--//====================================================================
--
-- Predicted Movement 
-- by Ribbit
--
--\\====================================================================



-- A registry for move registries! (Kills existing objects)
if !MoveRegistries then MoveRegistries = {} end

-- Clear Registries
for k,v in pairs( MoveRegistries ) do
	
	v:Kill()
	v = nil
	
end
table.Empty( MoveRegistries )



/*=========================================
	MOVE REGISTRY
/*=========================================

	Holds/runs movetypes as a collection.
	
*/

MoveRegistry = {}
MoveRegistry.__index = MoveRegistry
local MoveRegID = 0


function MoveRegistry:new()
	
	MoveRegID = MoveRegID + 1
	
	local NewMoveRegistry = {
		
		ID = 0,
		MoveTypes = {},
	
	}
	
	MoveRegistries[ MoveRegID ] = NewMoveRegistry
	setmetatable( NewMoveRegistry, MoveRegistry )
	
	return NewMoveRegistry
	
end

setmetatable( MoveRegistry, { __call = MoveRegistry.new } )


-- Internal, called when a new movetype is created
function MoveRegistry:AddMoveType( NewMoveType )
	
	return table.insert( self.MoveTypes, NewMoveType )
	
end


-- Run this on predicted hooks
function MoveRegistry:RunMoves( ply, mv, cmd )
	
	for ID, MType in pairs( self.MoveTypes ) do
		
		-- Begin execution from roots
		if !MType.Parent then
			
			MType:RunMove( ply, mv, cmd )
			
		end
		
	end
	
end


-- Cleanup
function MoveRegistry:Kill()
	
	for ID,MvType in pairs( self.MoveTypes ) do
		
		MvType:Kill()
		MvType = nil
		
	end
	
	self = nil
	
end


-- Player Movement Registry, ran on GM:SetupMove()
PlayerMovement = MoveRegistry()


/*=========================================
	MOVE TYPES
/*=========================================

	Object that contains predicted logic/timelines
	
*/

-- Declare MoveType object
MoveType = {}
MoveType.__index = MoveType

-- Call function
function MoveType:new( Registry, SkipCreation )
	
	-- Stops movetype from being created/registered
	if SkipCreation then
		
		return {}
		
	end
	
	if !Registry then Registry = PlayerMovement end
	
	local NewMoveType = {
		
		Registry = Registry,
		Condition = function() return true end,
		Action = function() end,
		Children = {},
		Parent = nil,
		Timeline = {}, 	-- Timeline data
		Tick = 0, 		-- Current Tick
		Executor = nil, -- Current Player
		Cmd = nil, 		-- Current cmd
		Mv = nil, 		-- Current mv
		MaxTicks = 50,  -- Timeline storage length
		
	}
	
	NewMoveType.ID = Registry:AddMoveType( NewMoveType )
	setmetatable( NewMoveType, MoveType )
	
	return NewMoveType

end

setmetatable( MoveType, { __call = MoveType.new } )


-- Allow hook binding
function MoveType:IsValid()
	
	return true
	
end


-- Can't be ran while predicting
function MoveType:AddChild( OtherMoveType )
	
	if !istable( OtherMoveType ) then return end
	if OtherMoveType.Parent then return end
	
	OtherMoveType.Parent = self
	return table.insert( self.Children, OtherMoveType )
	
end

function MoveType:RemoveChild( OtherMoveType )
	
	if isnumber( OtherMoveType ) then
		
		if self.Children[ OtherMoveType ] then
			
			self.Children[ OtherMoveType ].Parent = nil
			table.remove( self.Children, OtherMoveType )
		
		end
		
		
	elseif istable( OtherMoveType ) then
		
		if table.HasValue( self.Children, OtherMoveType ) then
		
			OtherMoveType.Parent = nil
			table.RemoveByValue( self.Children, OtherMoveType )
			
		end
		
	end
	
end


-- Grabs Modulated Tick
function MoveType:GetTick( Offset )
	
	if !Offset then Offset = 0 end
	return (self.Tick+Offset) % self.MaxTicks
	
end


function MoveType:GetPlyTimeline()
	
	if !self.Timeline[ self.Executor:SteamID64() ] then self.Timeline[ self.Executor:SteamID64() ] = {} end
	return self.Timeline[ self.Executor:SteamID64() ]
	
end


-- Grab the current player's timeline data
function MoveType:GetTimeline( Offset )
	
	if self.Executor then
		
		local First = self:GetPlyTimeline()[ self:GetTick( Offset ) ]
		
		if !First then self:GetPlyTimeline()[ self:GetTick( Offset ) ] = {} end
		return self:GetPlyTimeline()[ self:GetTick( Offset ) ]
		
	end
	
end


-- Can be ran while predicting, uses a smart hierarchy
function MoveType:Disable( NewDisable, DisableChildren, OnlyChildren, ForceChange )

	-- We should never really update unless we're first
	if !IsFirstTimePredicted() and !ForceChange then return end 
	
	if DisableChildren then
		
		self:GetTimeline().DisabledChildren = NewDisable and !OnlyChildren
		
		for k,v in pairs( self.Children ) do
			
			v:DisabledParent( NewDisable, self.ID )
			
		end
	
	else
	
		self:GetTimeline().Disabled = NewDisable
		
	end
	
end


-- Internal
function MoveType:DisabledParent( NewDisable, ParentID )
	
	if !self:GetTimeline().DisabledParents then self:GetTimeline().DisabledParents = {} end
	if !NewDisable then NewDisable = nil end
	
	self:GetTimeline().DisabledParents[ ParentID ] = NewDisable
	
	for k,v in pairs( self.Children ) do
			
		v:DisabledParent( NewDisable, ParentID )
		
	end

end


-- Copy movements into a new registry, (Advanced users: you can use this during prediction but you shouldn't)
function MoveType:Copy( Registry, KeepParent, KeepTimeline )
	
	if !Registry then Registry = self.Registry end
	
	local CopiedMoveType = table.Copy( self )
	CopiedMoveType.ID = Registry:AddMoveType( CopiedMoveType )
	CopiedMoveType.Children = nil -- Children can only have 1 parent
	
	if !KeepParent then
	
		CopiedMoveType.Parent = nil
		
	end
	
	if !KeepTimeline then
		
		CopiedMoveType.Timeline = {}
	
	else
		
		CopiedMoveType:GetTimeline().DisabledChildren = nil
		
		if !KeepParent then
		
			CopiedMoveType:GetTimeline().DisabledParents = nil
			
		end
		
	end
	
	return CopiedMoveType
	
end


-- Called by the MoveRegistry on predicted events
function MoveType:RunMove( ply, mv, cmd )
	
	-- Setup references
	self.Executor = ply
	self.Mv = mv
	self.Cmd = cmd
	self.Tick = cmd:TickCount()
	
	
	-- Copy over last tick data
	if !self:GetPlyTimeline()[ self:GetTick() ] or ( self:GetPlyTimeline()[ self:GetTick() ].Tick and self:GetPlyTimeline()[ self:GetTick() ].Tick != self.Tick ) then
	
		self:GetPlyTimeline()[ self:GetTick() ] = table.Copy( self:GetPlyTimeline()[ self:GetTick( -1 ) ] )
		self:GetTimeline().Tick = self.Tick
		
	end
	
	
	-- Check if we can execute
	local TL = self:GetTimeline()
	
	if self:Condition( ply, mv, cmd ) and !TL.Disabled and !TL.DisabledChildren and ( !TL.DisabledParents or #TL.DisabledParents <= 0 ) then
		
		self:Action( ply, mv, cmd )
		
	end
	
end


-- Cleanup
function MoveType:Kill()
	
	table.Empty( self )
	self = nil

end


--
-- Run the default MoveRegistry (PlayerMovement)
--

function GM:SetupMove( ply, mv, cmd )
	
	if CLIENT and ply != LocalPlayer() then return end
	
	PlayerMovement:RunMoves( ply, mv, cmd )

end