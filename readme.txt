readme.txt

ENSE 352 Whack-a-Mole Project

Author: Evan Geissler
NSID: 200331033 
Date: December 3rd, 2018

1) WHAT THE GAME IS: 
	This LED Whack-a-mole game has 4 LEDs with 4 corresponding pushbuttons. 
	When the game is played, an LED will light up and the player will have to 
	press the corresponding pushbutton. I.e. the LEDs are the moles and the 
	pushbuttons act as the player hitting the moles with a hammer. If the player 
	presses the correct pushbutton while the LED is still on, they gain a point, 
	the LED will turn off, and after a very short interval another LED will 
	turn on. Each time a pushbutton is correctly pressed, the time an LED stays 
	on shortens. This makes the game harder the further the player gets. If the 
	player continues to pick correctly and on time, the game will run up to 15 
	times before showing the player has won. However, if the player does not press 
	the correct pushbutton in time OR presses an incorrect pushbutton, the game 
	will end and the player's score will be shown (i.e. they lost).  


2) HOW TO PLAY THE GAME: 
	a) When all 4 LEDs are flashing, press any of the pushbuttons to begin. 
	b) The 4 LEDs will turn off one by one and will stay off for a few seconds. 
	   After a very short wait, 1 random LED will turn on and the corresponding 
	   pushbutton must be pressed while the LED is on. 
	c) IF the player does this correctly, that LED will turn off and another 
	   will turn on. The player then must repeat step b). The further the 
	   player gets, the higher their score and the faster the lights turn 
	   on and off. 
	d) IF the player does NOT press the correct pushbutton, presses more than
	   one pushbutton, OR the LED turns off before being pressed then the player
	   loses the game. 
	
	LOSES) -If the player loses, the game will end and flash the player's score
	       a few times before returning to step a)
	       -It is important to note that due to the code, the player's score 
	        is represented from left to right. SO if the player makes it to round 
		3 then the LEDs will light up as ON ON OFF OFF instead of OFF OFF ON ON 
		i.e. 1100 = 11 instead of 0011 = 3. This requires flipping bits that is 
		touched on below in future expansions. 	
	
	WINS) If the player wins (gets a score of 15) then the game goes into a 
     	      won game sequence of lights and will stay in this sequence for about
	      1 minute then return to step a).

	SCORING SYSTEM) The scoring system below describes player score. This is viewed
			with the LEDs above the Pushbuttons and the pushbuttons are at
			the bottom of the discovery board. Please note that a value of 
			1 means LED ON and a value of 0 means LED OFF (For example, 
			1100 means ON ON OFF OFF):

		LED SEQUENCE	SCORE
		    	0000	    0		
		    	1000	    1
		    	0100	    2
		    	1100	    3
		    	0010	    4
		    	1010	    5
		    	0110	    6
		    	1110	    7
			0001	    8
			1001	    9	
			0101	   10
			1101	   11
			0011	   12
			1011	   13
			0111	   14
			1111	   15

	*Pressing the reset button will return the player to step a) regardless where
	 they currently are in the game.  


3) a) PROBLEMS ENCOUNTERED 
	-Overall, creating the program was fine, however I encountered problems with 
	 finding a good random seed. I was going through different RTC values (as 
	 suggested in the lab) such as RTC_CNTL with no success. Trying to use RTC
	 enabled or disabled did not seem to make any difference so I tried to use
	 other possible values such as RTC_DIV (since it seemed that a value can be 
	 obtained at anytime/instantly from this and was already readable, as opposed
	 to RTC_CNTL that was a bit unclear on readable or not.) I eventually found 
	 a number that seems to keep the LED randomness quite well. Going through a 
	 new game many times, hitting the reset button, etc. seem to have different
	 results so I have kept it the way it is. 

	-Worry/possibility of overwriting registers. To avoid this, I wrote down all 
	 the registers and explicitly stated what they can and cannot be (within 
	 reason). This helped to manage the many registers and keep my code much more
	 consistent. The registers are listed at the top of my proj.s file. 
	
b) FEATURES FAILED TO IMPLEMENT 
	-None as described in the project document 

c) EXTRA FEATURES
	-Going from "Waiting for Player" to "Normal Game Play" use cases, there is 
	 a count down of LEDs that leads into prelimWait. prelimWait then goes into 
	 normal game play as described in the UC. 

	-A sequence of lights that plays for the player upon winning (2 left, 2 right, 
	 individual LED from right to left, individual LED from left to right) and then
	 all 4 LEDs on the entire time. 

d) POSSIBLE FUTURE EXPANSIONS
	-Adding more levels/score possibilities. This could be shown by using the 
	 green and/or blue LED of the arm board. Using both of these would increase 
	 the number of levels/score possibilities from 2^4 = 16 to 2^6 = 64 

	-Adding extra LEDs to the randomness. This can be done utilizing the ARM 
	 board LEDs (either the blue OR green OR both of them) and also using the ARM 
	 button. This could be further expanded by using other inputs on the discovery 
	 board

	-Having multiple LEDs turn on at once to add an increase to difficulty
 
	-Allow input to change difficulty of the game. For example, having a switch 
	 on would allow multiple LEDs to be turned on or not. 

	-More LED sequences for different stages 

	-A chance to gain "lives" or "checkpoints" so the player can return to a certain 
	 level/proficiency 

	-Having the LCD screen output information such as score, instructions, etc. 

	-Not an expansion, but an improvement: refactoring a lot of the code to allow 
	 snippets of it to be written once instead of constantly implemented. For example,
	 having the delay loops as one sub-routine instead of being in every routine that
	 needs the delay. 

	-Not an expansion, but an improvement: have the LEDs light up the score
	 from right to left instead of left to right (to make it look like proper 
	 binary if played with the pushbuttons at the bottom). So for example, if the 
	 player gets a score of 3 then the LEDs currently light up as ON ON OFF OFF (1100) 
	 and the improvement would have them light up as OFF OFF ON ON (0011). This would 
	 make more sense comparing directly to binary

e) CONSTRAINTS/BARRIERS TO SUCCESS
	-Time 

	-Large spread power outage for an extended amount of time on Tuesday, Dec. 4th

	-Learning how to use ARM/the boards well enough to program 

	-Other classes, homework, projects, etc. along with personal commitments
	 outside of school 

f) ENVIRONMENTAL IMPACT
	a) INDIRECTLY
		-Environmental cost of creating the boards, shipping them, and
		 package them 
		-Recycling/waste impacts from plastic, paper, or rubber packing 
		 OR of the materials themselves at the end of the board's or 
	         a component's life
		-Using electricity/means of creating the electricity 

	b) DIRECTLY  
		-Any energy and materials that are used to solder the boards,
		 programming the boards (such as electricity use, computer use and
		 their environmental impact, etc.)  
		 
g) COST
	a) NEGLIGABLE 
		-Any and all costs absorbed by the UofR for power, software, computers,
		 etc. 
		-Any costs the makers of the boards, software, etc. that do not affect 
		 this game in any way. 
		-Cost of the course

	b) DIRECT COSTS
		i)  $ 25 -> ENSE 352 ARM Assembly Board 
		ii) $100 -> ENEL 384 Discovery Board
	
	TOTAL COST: $125


4) ADJUSTING PARAMETERS
	a) preLimWait: -Can be changed on line 366
		       -This value is a wait time/counter
		       -Increasing this will have the LEDs turn on slower
		       -Decreasing this will have the LEDs turn on faster

	b) ReactTime: -Can be changed on line 367
		      -This value is a wait time/counter
		      -Increasing this will have the LEDs stay on longer
		      -Decreasing this will have the LEDs stay on shorter

	c) NumCycles: -Can be changed on line 387
		      -This value is number of times run
		      -Increasing this will allow for more levels/rounds
		      -Decreasing this will allow for fewer levels/rounds

	d) WinningSignalTime: -Can be changed on line 368
			      -This value is a wait time/counter
		      	      -Increasing this will keep the player at endSuccess longer
		      	      -Decreasing this will keep the player at endSuccess shorter

	e) Num_Cycle_Win: -Can change on line 388 (this is a variable I added)
			  -This value is number of times run through the winning loop
			  -Increasing this will keep player at endSuccess longer
			  -Decreasing this will keep the player at endSuccess shorter
			***Putting this value at 0 will NOT have the 4 LEDs stay on. However
			   it will still have the initial sequence of winning lights 

	f) LosingSignalTime: -Can be changed on line 369
			     -This value is a wait time/counter
		      	     -Increasing this will keep the player at endFailure longer
		      	     -Decreasing this will keep the player at endFailure shorter


5) UPDATED USE CASES
	UC1 Turning on the system.
		1. The user performs a system boot by pressing the reset button
		2. The system enters Use Case 2 (UC2): Waiting for Player

	UC2 Waiting for Player
		1. The system goes into the startup routine. This is an LED pattern 
		   indicating that no game is in progress and the system is waiting 
		   for a player to start. This continues without stopping until:
		2. The user presses any of the four buttons. The system enters Normal Game Play (UC3).

	UC3 Normal Game Play.
**NEW**		1. All LEDs are turned on and turned off one by one in a countdown sequence.  
		2. A fixed wait time elapses: PrelimWait. 
		2. The game turns on a randomly selected LED. The game starts the ReactTime timer. 
		   (The player has to respond before this expires.) The shorter this time, the more 
	           challenging the game.
		3. The user presses the corresponding button before ReactTime expires.
		4. The ReactTime value is reduced by a certain amount to prepare for the next cycle. 
		   (So each cycle gets a bit harder.)
		5. The system goes back to step 1. After NumCycles of these successful loops complete, 
		   the game enters End Success (UC4). NumCycles may be, for instance, 16. 

	UC3 Alternate Path: ReactTime expires.
		1. During UC3 step 2 the user fails to press the correct button before ReactTime expires. 
		   Or the user presses an incorrect button
		2. The game enters End Failure (UC5). 

** NEW **	IMPORTANT TO NOTE: As is a physical whack-a-mole with a mallet and things popping up, 
				   if the user presses the button when the LED is OFF then the player
				   will NOT be penalized and the player will NOT lose the game if this
				   happens. However pressing incorrectly or pressing multiple buttons
				   at once while the LEDs are ON WILL make the player lose.

	UC4 End Success: The user has won the game.
		1. The game displays the “winning” signal, which is some sort of LED pattern indicating 
		   the person won. This signal is displayed for time WinningSignalTime.
		2. After displaying this signal, the game displays the user’s proficiency level. This 
		   display remains visible for 1 minute, after which the game returns to UC2.
		
** NEW **	IMPORTANT TO NOTE: In the UC4 step 4, the user can NOT get out of this by pressing one of
				   the pushbuttons, however reducing WinningSignalTime and Num_Cyc_Win will 
				   reduce the 1 minute the player is stuck in this loop. This was not clearly 
				   specified in the original Use cases and I had no time to work it out in
				   a nicer manner. 

	UC5 End Failure. The user has lost the game.
		1. The system displays the “losing” signal, which is a flashing display, in binary, of the 
		   number of successful cycles completed. Since this is a 4-LED display you can display any 
		   number from one to fifteen. This flashing signal is displayed for time LosingSignalTime. 
		   
** NEW **	IMPORTANT TO NOTE: If the cycles completed are less than 1 the program will still go into 
				   this use case BUT will NOT have any LEDs on. Instead, all will be off
				   for an extended amount of time. 

** NEW **	IMPORTANT TO NOTE: If the cycles completed becomes greater than 15, the LED score will wrap
				   around. In future/better implementations of the program, an additional LED
				   would be used (see future implementations above) 

** NEW **	IMPORTANT TO NOTE: The user cannot leave the end failure stage by pressing a push button. 
				   I decided NOT to have this feature in because the end failure sequence 
				   is short enough that I did not feel being able to quickly leave it was
				   needed. 

		2. After displaying this signal, the game returns to UC2, Waiting for Player.






