/*--
	Example 1: Simple Jetpack
	----------------------------------
	
	Welcome to the first and most basic example of predicted movement, the Jetpack.
	Here we'll look at the fundamentals of predicted movement: Condition and Action
	
	The Condition always determines whether or not to execute the Action.
	In this example we can see that when the player is holding jump their velocity is adjusted.
	
*/

-- The arguments for the MoveType call function are:
-- MoveType( Registry, SkipCreation )

-- To stop testing this MoveType, replace the following line with:
-- local Jetpack = MoveType( _, true )

local Jetpack = MoveType( _, true )

function Jetpack:Condition( ply, mv, cmd )
	
	return cmd:KeyDown( IN_JUMP )
	
end

function Jetpack:Action( ply, mv, cmd )
	
	local Z = math.Clamp( mv:GetVelocity().z + 30, -2000, 500 )
	mv:SetVelocity( mv:GetVelocity()*Vector(1,1,0) + Vector(0,0,Z) )
	
end