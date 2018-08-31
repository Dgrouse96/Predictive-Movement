--
--	Predictive Movement by Ribbit
--


Intro
------

	When making predictive movement, it almost always ends up as nightmare spaghetti code, this addon aims to remove that problem by
	simplifying repetitive code and creating a solid ground methodology for tackling this difficult and often confusing task.
	
	This addon can easily make simple movements, but also has the functionality to create very complex, state-safe systems that will
	never become spaghetti code (as long as you go with the grain). This is achieved through movetype parenting/children.
	
	You'll learn everything by reading this, and following each example.
	
	
The Problem:
-------------

	It is important to note that the client will run the same tick multiple times (and not in order after the first predicted tick)
	Here's what the tick execution looks like at different pings, the numbers represent the current cmd:TickCount()
	
	0 Ping:
		SERVER: 1,2,3,4,5
		CLIENT: 1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4,4,4,4,4,5,5,5,5,5
	
	100 Ping:
		SERVER: 1,2,3,4,5
		CLIENT: 1,1,1,2,1,2,1,2,2,3,3,2,3,3,3,4,4,5,4,5,4,4,5,5,5
		
	200 Ping:
		SERVER: 1,2,3,4,5
		CLIENT: 1,2,1,2,3,1,1,2,3,2,1,4,3,3,2,4,5,4,3,4,5,5,4,5,5
		
	- Notice how jumbled those ticks get!
	- Another important note: The ticks will (almost) never skip a tick, eg 1,3,2...
	
	
The Solution:
--------------
	
	To counter this problem, we arrage our Condition logic in a magical table called the "Timeline".
	Each KEY in the Timeline is a tick, and each VALUE is another table where we store data.
	
	Right before the system tests our Condition function, it copies over the last tick's timeline data into the current tick,
	self:GetTimeline() will get the the current tick's data, so you can safely adjust it or reference contextually.
	
	
A neat trick:
--------------

	self:GetTimeline( -1 ) -- get the last tick
	self:GetTimeline( -2 ) -- get the tick before that... etc
	self:GetTimeline( 1 ) -- get the next tick, ( yes you can set variables for future ticks, but only if they already exist )

	
Large Movement systems
-----------------------

	