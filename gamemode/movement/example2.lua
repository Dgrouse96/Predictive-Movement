/*--
	Example 2: Jetpack with Fuel
	----------------------------------
	In this example, we'll expand upon the previous jetpack by adding fuel which depletes 
	when the jetpack is in use and recharges when not.
	
	In this example we should only change the timeline data if IsFirstTimePredicted() == true
	This stops the client from consuming fuel when a tick gets re-ticked, which would result in a prediction micro error.
*/


-- To start testing this MoveType, replace the following line with:
-- local Jetpack = MoveType()

local Jetpack = MoveType( _, true )

function Jetpack:Condition( ply, mv, cmd )
	
	if IsFirstTimePredicted() then
        
        local CurrentFuel = self:GetTimeline().Fuel or 1
        local Condition = cmd:KeyDown( IN_JUMP ) and !self:GetTimeline().Disabled
        local NewFuel = Either( Condition, CurrentFuel - FrameTime(), CurrentFuel + FrameTime() )
        self:GetTimeline().Fuel = math.Clamp( NewFuel, 0, 1 )
    
    end
    
    local CurrentFuel = self:GetTimeline().Fuel or 1
    
    return cmd:KeyDown( IN_JUMP ) and CurrentFuel > 0
	
end

function Jetpack:Action( ply, mv, cmd )
	
	local Z = math.Clamp( mv:GetVelocity().z + 30, -2000, 500 )
	mv:SetVelocity( mv:GetVelocity()*Vector(1,1,0) + Vector(0,0,Z) )
	
end