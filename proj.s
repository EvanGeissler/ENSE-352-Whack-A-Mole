; ENSE 352 Whack-a-Mole Project
;
; DATE: December 5th, 2018
;
; DESCRIPTION:
;   GENERAL NOTES:
;       -ENEL 384 Pushbuttons: SW2(Red): PB8, SW3(Black): PB9, SW4(Blue): PC12, SW5(Green): PA5
;       -ENEL 384 board LEDs: D1 - PA9, D2 - PA10, D3 - PA11, D4 - PA12
;       -LEDs and buttons are active low
;       -All routines have the steps listed easily below. HOWEVER Required, Promise, Notes, and
;        modifactions are all directly above the routine itself
;       -At any time the entire board can be restarted by pressing the black restart button
;
;   REGISTER NOTES:
;       -I have designed program to only affect the regsiters in certain ways.
;        Below is a break down of the registers and what values I put in for the program:
;                       REGISTER:       PURPOSE:            DOES REGISTER CHANGE:
;                           R0:         LDR GPIOA_ODR       No, it should not change
;                           R1:         Time Delay          Yes, but only holds delay times
;                           R2:         GPIOA_IDR           No, it should not change
;                           R3:         GPIOB_IDR           No, it should not change
;                           R4:         GPIOC_IDR           No, it should not change
;                           R5:         Random value        Yes, typically the value to store in memory
;                           R6:         Random value        Yes, typically mask or value to store
;                           R7:         Random value        Yes, typically mask or value to store
;                           R8:         General Counter     Yes, counter for loops
;                           R9:         Level Counter       Yes, counts player progress only
;                           R10:        Initial values      Yes, used to load addresses to enable clocks/ports
;                           R11:        Clock/other info    Yes, used for RTC and randomness
;                           R12:        Clock/other info    Yes, used for RTC and randomness
;
;    GPIO_ClockInit:
;               -Sets clocks for ports A, B, and C (Page 91/713)
;               -General steps below, but further information is above sub routine function
;
;                   Step 1) Load address of RCC_APB2ENR
;                   Step 2) Get value at that address
;                   Step 3) AND R5 with 0x0000001C to get rid of any junk/mask the desired bits
;                   Step 4) ORR R5 with 0x1c to set desired bits/ports
;                   Step 5) Store value R5 into address of RCC_APB2ENR to enable ports
;                   Step 6) Branch back to main
;
;
;    GPIO_init:
;               -Enables the GPIO for ports A & C to allow LED's (Page 111/713)
;               -Keeps LEDs off to start
;               -Port A pins 9-12 as outputs, max speed 50MHz (11), GPO push-pull (00)
;               -Steps below, but further information is above function
;
;                Initilize GPIOA_CRH (Port A)
;                   Step 1) Get masks for R6 and R7
;                   Step 2) Load address of GPIOA_CRH and store it in R10
;                   Step 3) Store the value at that address and store it in R5
;                   Step 4) AND R5 with R6 to get rid of any junk values
;                   Step 5) ORR R5 with R7 to set desired bits. I.e. #0x33330
;                   Step 6) Store the value of R5 in memory at location R10, i.e. GPIOA_CRH
;
;               Turn off LEDs
;                   Step 7) Load address of GPIOA_ODR and store it in R0
;                   Step 8) Set desired LED bits and move it into R5 i.e. #0x1E00
;                   Step 9) Store this in memory to have LEDs turned off
;                   Step 10) Branch back to main
;
;    WaitingForPlayer:
;               -Flashs all four LEDs on and off at the same time indefiniatly
;                until the player touches at least one of the pushbuttons
;               -Once a button is pressed the program will automatically go into
;                the next stage (PrelimWait/normalGamePlay).
;               -Steps below, but further information is above function
;
;                   Step 1) Load addresses and variables for:
;                       i) GPIOA_ODR (LEDs)
;                       ii) SHORT_DELAYTIME for flashing
;                       iii) GPIOX_IDR for A-C for pushbutton input
;                   Step 2) Enter delay
;                   Step 3) Push R1
;                   Step 4) Enter counter for delay
;                   Step 5) Reset R6 to reset input check
;                   Step 6) Check if any pushbuttons have been pressed
;                       6a) Load Value at IDR address, store into R5
;                       6b) AND R5 by mask to get desired input bit
;                       6c) ORR R6 and R5 to save any input changes **Repeat steps 6a-6c for all inputs**
;                       6d) Check if an input caused R6 to NOT equal 0x1320
;                           -If NOT equal then one or more inputs were pressed
;                           -Return back to main loop if NOT equal
;                           -if EQUAL then continue to step 7)
;                   Step 7) Check if delay timer is 0
;                       7a) Push R1 if finished
;                       7a-else) If NOT finished, decrement R1 counter
;                       7b-else) Loop back to counter loop
;                   Step 8) Go into alternate lights being on or off sub
;                   Step 9) Check if lights are on, turn them off if they are.
;                           If lights are off, turn them on.
;                   Step 10) Store new value/output of LEDs into memory at GPIOA_ODR
;                   Step 11) Repeat back to delay until a button is pressed
;
;
;    normalGamePlay:
;     			-Will initiate an intro sequence so the player is ready to
;		 		 play the game. normalGamePlay will randomize which LED to 
;		 		 light up and will give the player a short amount of time 
;		 		 to press the correct pushbutton
;				-IF the player incorrectly presses a button or if the time 
;		 		 runs out, then it will branch back to main function
;				-IF the player correctly presses a pushbutton, the difficulty 
;				 will increase and the game will get faster. This will continue
;		 		 until the player correctly presses 15 times OR loses and will 
;		 		 branch back to main upon winning
;               -Steps below, but further information is above function
;
;     				Step 1) Ensure LEDs are off:
;						1a) Get LED OFF code
;						1b) Store OFF code into R0
;    				Step 2) Get Delay time
;     				Step 3) Initilize Counters
;						3a) Prelim LED sequence
;						3b) Reset level/score counter
;    				Step 4) Enter PrelimWait Loop
;     				Step 5) Push R1 onto stack 
;     				Step 6) Enter counter/delay for lights loop
;     				Step 7) Check if counter time has run out. Loop if not, continue if yes
;             			7a) Pop R1 if finished
;             			7a-else) Decrement time counter if not finished
;             			7b-else) Loop again
;     				Step 8) Enter fewer LED, this has all 4 LEDs ON and turns them off
;							one by one and then holds all OFF before going into the main game
;					Step 9) Check value of R8 to a number
;						9a) If equal, Mov LED code into R7*
;						*Do this for compares below
;						This lets the LEDs do an intro to the game sequence. The sequence
;						is the following:
;							i) ALL LEDs on
;							ii) LEDs 1,2,3 on; 4 off
;							iii) LEDs 1 and 2 on; 3 and 4 off
;							iv) LEDs 1 on; 2,3,4 off
;							v) ALL LEDs off
;					Step 10) Store new code into GPIOA_ODR
;					Step 11) Check if counter/sequence is finished
;						11a) If NOT finished, increase counter	
;						11b) If NOT finished, loop back to PrelimWait
;					Step 12) Enter main game loop
;					Step 13) Get hardset random X seed
;					Step 14) Get memory address to store X
;					Step 15) Store seed address X at X_STORAGE
;					Step 16) Get the react time for user
;					Step 17) Branch to get random number generator*
;							*Jump to Step 30)
;					Step 18) Enter delay game loop
;					Step 19) Push R1 onto stack
;					Step 20) Enter counter for delay
;					Step 21) Reset R6 check value
;					Step 22) Check if any pushbuttons are pressed
;				 		22a) Load value at R4/GPIOC_IDR
;				 		22b) Get rid of any junk
;						22c) Set desired bits
;						22d) Check if any inputs change
;							i) Pop R1
;							ii) Increase score/level counter
;							iii) Branch to changeLights to turn on next light
;					Step 23) Check if multiple buttons are pressed
;				 		23a) If multiple pressed, mov 0 into R1 delay counter
;					Step 24) Check if counter time = 0. Loop if not, continue if yes
;						24a) Pop R1 if finished
;				 		24a-else) Decrement counter if not finished
;				 		24b-else) Loop again 
;				 		24b) IF R1 = 0 then go back to main 
;					Step 25) Push R1
;					Step 26) Double amount delay time
;				 		26a) Mov 2 into R5 as a scalar constant 
;				 		26b) Multiply R1 delay time by 2
;					Step 27) Enter LED OFF delay 
;					Step 28) Store OFF code into GPIOA_ODR
;	 				Step 29) Check if counter time has run out. Loop if not, continue if yes
;             			29a) Pop R1 if finished
;             			29a-else) Decrement time counter if not finished
;             			29b-else) Loop again
;					Step 30) Enter Random Number Generator 
;					Step 31) Get address of X_Storage
;					Step 32) Get value at X_Storage
;					Step 33) Load variables in 
;				 		33a) Load multiplier A value
;			     		33b) Load addition C value
;					Step 34) Get new random number
;				 		34a) Multiple X by A (A*X)
;			     		34b) Add C (A*X + C)
;			     		34c) Store new X value in memory
;					Step 35) Shift X over by 30 bits to get the 2 left most bits
;				 			 that will allow to give 1, 2, 3, or 4 to turn on a 
;				 			 corresponding LED
;					Step 36) Mask to get desired bits 
;					Step 37) Check shifted X for which LED to turn on
;				 		37a) If equal, set proper LED code
;				 		37b) If equal, set pushbutton code
;				 		Below are the pushbutton codes (i.e. which should be pressed)
;							i) 		RED: 	0x1220
;				 			ii) 	BLACK: 	0x1120
;				 			iii) 	BLUE: 	0x0320
;				 			iv) 	GREEN: 	0x1300
;					Step 38) Store LED code into GPIOA_ODR
;					Step 39) Decrement delay/on time of the LEDs to make it harder
;				 		39a) Load the difficulty modifier
;						39b) Subtract it from time delay 
;				Step 40) Check if maximum number of cycles 
;				 		40a) Load total number of cycles
;				 		40b) Check if score is less than 
;				 		40b-true) Branch to delay if less than
;				Step 41) Shut off LEDs
;				 		40a) Get LED OFF code
;				 		40b) Store this code into GPIOA_ODR
;				Step 42) Branch back to main function 
;
;
;    EndSuccess:
;               -When a player wins the game, the LEDs will flash in
;                patterns showing that the player has one.
;               -When the sequence is finished, all 4 LEDs will light
;                up for 1 minute indicating a win/level 15 was passed.
;               -The player CANNOT leave this stage and must wait until
;                the light sequence and 1 minute display is finished.
;               -Steps below, but further information is above function
;
;                   Step 1) Load delay time into R1
;                   Step 2) Initilize loop Counter
;                   Step 3) Enter delay loop
;                   Step 4) Push R1/Delay time
;                   Step 5) Enter counter for delay
;                   Step 6) Check if counter time has run out. Loop if not, continue if yes
;                           6a) Pop R1 if finished
;                           6a-else) Decrement time counter if not finished
;                           6b-else) Loop again
;                   Step 7) Enter light sequence sub
;                   Step 8) Initiate first LED sequence (Alternate sets of 2 LEDs)
;                           8a) Check if R8 = 0
;                           8b) If EQ, set R5 to turn on right 2 LEDs
;                           8c) Check if R8 = 1
;                           8d) If EQ, set R5 to turn on left 2 LEDs
;                   Step 9) Initiate second LED sequence (1 LED at a time in order)
;                           9a) Check if R8 = 2
;                           9b) If EQ, set R5 to turn on LED 1 on
;                           9c) Check if R8 = 3
;                           9d) If EQ, set R5 to turn on LED 2 on
;                           9e) Check if R8 = 4
;                           9f) If EQ, set R5 to turn on LED 3 on
;                           9g) Check if R8 = 5
;                           9h) If EQ, set R5 to turn on LED 4 on
;                   Step 10) Initiate third LED sequence (1 LED at a time in reverse order)
;                           10a) Check if R8 = 6
;                           10b) If EQ, set R5 to turn on LED 3 on
;                           10c) Check if R8 = 7
;                           10d) If EQ, set R5 to turn on LED 2 on
;                           10e) Check if R8 = 8
;                           10f) If EQ, set R5 to turn on LED 1 on
;                   Step 11) Initiate fourth LED sequence (all 4 LEDs on for 1 minute)
;                           11a) Check if R8 > 8
;                           11b) Keep all 4 LEDs on if EQ
;                   Step 12) Store LED bit pattern in memory
;                   Step 13) Check R8 if it has looped for 1 minute
;                            To get 1min = 60 000ms with delay = 500ms -> Loop held for 120* more times
;                            *This has been timed and works well
;                           13a) If NE, increment loop counter
;                           13b) Store new bit pattern in memory
;                   Step 14) Set bit pattern of R5 to turn off all lights
;                   Step 15) Store new bit pattern in memory
;                   Step 16) Branch back to main
;
;
;    EndFailure:
;               -Will indicate the player's progress (what level they got to)
;                and then return to waitForPlayer routine.
;               -The level indication will be represented by the 4 LEDs on
;                the board and will flash on and off a predefined amount of times
;               -Steps below, but further information is above function
;
;                   Step 1) Load the delay time into R1
;                   Step 2) EOR R9 with #0xF since current value will have LEDs off when we want them on.
;                   Step 3) Shift R9 from 000...0 XXXX bit format to 000...0X XXX0 0000 0000 format
;                           Shift amount is 9 bits left. Will use logical shift left.
;                   Step 4) Initilize counters:
;                           i) R8: Number of times lights have flashed
;                           ii) R7: Set to 0 for bi state of lights
;                   Step 5) Enter delay loop
;                   Step 6) Push R1/Delay time
;                   Step 7) Enter delay counter loop
;                   Step 8) Check if counter time has run out. Loop if not, continue if yes
;                           8a) Pop R1 if finished
;                           8a-else) Decrement counter if R1/delay != 0
;                           8b-else) Loop again
;                   Step 9) Enter Alternate sub to alternate on/off of LEDs
;                   Step 10) Check if R7 = 0. If EQ, have level lights on. If NE, have all lights off
;                           10a) If EQ, make R5 = R9 -> Level lights on vavlue
;                           10b) If EQ, R7 = 1
;                           10a-else) Set R5 = #0x1E00 -> All lights off value
;                           10b-else) Set R7 = 0
;                   Step 11) Store R5 into memory GPIOA_ODR
;                   Step 12) Check R8 to see if lights have flashed enough
;                           12a) If not, increase R8
;                           12b) If not, loop back to sub_delay_fail
;                   Step 13) Turn all LEDs off
;                   Step 14) Branch back to main
;
;
; AUTHOR: Evan Geissler SID: 200331033
; GPIO Test program - Dave Duguid, 2011
; Modified Trevor Douglas 2014

;;; Directives
		PRESERVE8
		THUMB


;;; Equates

INITIAL_MSP    EQU        0x20001000    ; Initial Main Stack Pointer Value

;PORT A GPIO - Base Addr: 0x40010800
GPIOA_CRL    EQU        0x40010800    ; (0x00) Port Configuration Register for Px7 -> Px0
GPIOA_CRH    EQU        0x40010804    ; (0x04) Port Configuration Register for Px15 -> Px8
GPIOA_IDR    EQU        0x40010808    ; (0x08) Port Input Data Register
GPIOA_ODR    EQU        0x4001080C    ; (0x0C) Port Output Data Register
GPIOA_BSRR   EQU        0x40010810    ; (0x10) Port Bit Set/Reset Register
GPIOA_BRR    EQU        0x40010814    ; (0x14) Port Bit Reset Register
GPIOA_LCKR   EQU        0x40010818    ; (0x18) Port Configuration Lock Register

;PORT B GPIO - Base Addr: 0x40010C00
GPIOB_CRL    EQU        0x40010C00    ; (0x00) Port Configuration Register for Px7 -> Px0
GPIOB_CRH    EQU        0x40010C04    ; (0x04) Port Configuration Register for Px15 -> Px8
GPIOB_IDR    EQU        0x40010C08    ; (0x08) Port Input Data Register
GPIOB_ODR    EQU        0x40010C0C    ; (0x0C) Port Output Data Register
GPIOB_BSRR   EQU        0x40010C10    ; (0x10) Port Bit Set/Reset Register
GPIOB_BRR    EQU        0x40010C14    ; (0x14) Port Bit Reset Register
GPIOB_LCKR   EQU        0x40010C18    ; (0x18) Port Configuration Lock Register

;The onboard LEDS are on port C bits 8 and 9
;PORT C GPIO - Base Addr: 0x40011000
GPIOC_CRL    EQU        0x40011000    ; (0x00) Port Configuration Register for Px7 -> Px0
GPIOC_CRH    EQU        0x40011004    ; (0x04) Port Configuration Register for Px15 -> Px8
GPIOC_IDR    EQU        0x40011008    ; (0x08) Port Input Data Register
GPIOC_ODR    EQU        0x4001100C    ; (0x0C) Port Output Data Register
GPIOC_BSRR   EQU        0x40011010    ; (0x10) Port Bit Set/Reset Register
GPIOC_BRR    EQU        0x40011014    ; (0x14) Port Bit Reset Register
GPIOC_LCKR   EQU        0x40011018    ; (0x18) Port Configuration Lock Register

;Registers for configuring and enabling the clocks
;RCC Registers - Base Addr: 0x40021000
RCC_CR          EQU        0x40021000    ; Clock Control Register
RCC_CFGR        EQU        0x40021004    ; Clock Configuration Register
RCC_CIR         EQU        0x40021008    ; Clock Interrupt Register
RCC_APB2RSTR    EQU        0x4002100C    ; APB2 Peripheral Reset Register
RCC_APB1RSTR    EQU        0x40021010    ; APB1 Peripheral Reset Register
RCC_AHBENR      EQU        0x40021014    ; AHB Peripheral Clock Enable Register

RCC_APB2ENR     EQU        0x40021018    ; APB2 Peripheral Clock Enable Register  -- Used

RCC_APB1ENR     EQU        0x4002101C    ; APB1 Peripheral Clock Enable Register
RCC_BDCR        EQU        0x40021020    ; Backup Domain Control Register
RCC_CSR         EQU        0x40021024    ; Control/Status Register
RCC_CFGR2       EQU        0x4002102C    ; Clock Configuration Register 2


; Times for delay routines
DBL_DELAYTIME   EQU    3200000       ; (400 ms/24MHz PLL)
DELAYTIME       EQU    1600000       ; (200 ms/24MHz PLL)
HALF_DELAYTIME  EQU    800000        ; (100 ms/24MHz PLL)
SHORT_DELAYTIME EQU    200000        ; (25 ms/24MHz PLL)
	
PRELIMWAIT		EQU	   800000        ; (100 ms/24MHz PLL)
REACT_TIME		EQU    600000	
WINNING_TIME	EQU	   800000	
LOSING_TIME		EQU    800000	
	
INC_DIFF		EQU    0x00008500 	 ; Value to subtract from time to increase difficulty 	
;Real Time Clock Register
RTC_DIVH		EQU 	0x40002810
RTC_DIVL		EQU		0x40002814


;Random variable constants 
A	EQU		0x19660D 
C 	EQU		0x3C6EF35F


;Location to store X
X_STORAGE    EQU        0x20001008	
	
	
;Number of cycles to flash score upon losing
NUM_CYCLES	 EQU		0xF		
NUM_CYC_WIN	 EQU		128	
	
	
; Vector Table Mapped to Address 0 at Reset
		AREA    RESET, Data, READONLY
		EXPORT  __Vectors

__Vectors    DCD        INITIAL_MSP            ; stack pointer value when stack is empty
			 DCD        Reset_Handler        ; reset vector

			AREA    MYCODE, CODE, READONLY
			EXPORT    Reset_Handler
			ENTRY

Reset_Handler        PROC

	BL GPIO_ClockInit
	BL GPIO_init

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN LOOP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mainLoop
	BL waitForPlayer
	BL normalGamePlay

	CMP R9, #0xF
	IT EQ
	BLEQ EndSuccess
	
	CMP R9, #0xF
	IT LT
	BLLT EndFailure
	
	B mainLoop
	
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; SUBROUTINES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GPIO_ClockInit
;;;
;;; Require:
;;;     -Address of RCC_APB2ENR
;;;     -Need to set bits 2,3, and 4: i.e. 0x1c -> 0001 1100
;;;
;;; Promise:
;;;     -Will Enable clock for ports A, B, and C
;;;
;;; NOTES:
;;;     -See pages (Page 91/713) of reference manual
;;;     -RCC = Reset and Clock Control
;;;     -This board uses Ports A, B, and clock
;;;     -Port A is used for pushbuttons and LEDS
;;;     -Port B is used for pushbuttons
;;;     -Port C is used for pushbuttons
;;;
;;;     Step 1) Load address of RCC_APB2ENR
;;;     Step 2) Get value at that address
;;;     Step 3) AND R5 with 0x0000001C to get rid of any junk/mask the desired bits
;;;     Step 4) ORR R5 with 0x1c to set desired bits/ports
;;;     Step 5) Store value R5 into address of RCC_APB2ENR to enable ports
;;;     Step 6) Branch back to main
;;;
;;; Modifies:
;;;     -R10 by getting address of RCC_APB2ENR
;;;     -R5 is changed to bits to enable clock
;;;     -RCC_APB2ENR bits are set/masked
;;;
	ALIGN
GPIO_ClockInit PROC

	LDR R10, = RCC_APB2ENR  ;Step 1: Load address
	LDR R5, [R10]           ;Step 2: Get value at address

	AND R5, #0x0000001c     ;Step 3: Get rid of junk
	ORR R5, #0x1c           ;Step 4: Set bits

	STR R5, [R10]           ;Step 5: Store value at address

	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GPIO_init
;;;
;;; Require:
;;;     -Clock must be enabled for Port addresses
;;;     -Must have the GPIOA_CRH address
;;;     -Must know which bits to enable
;;;     -Must have address of GPIOA_ODR
;;;
;;; Promise:
;;;     -Enables the GPIO for the LED's which are all on Port A
;;;     -Ensures that the LEDs are turned off for the start of the program
;;;
;;; NOTES:
;;;     -See pages (111/713) of refernce manual
;;;     -By default the I/O lines are input so only output needs to be configured
;;;     -ENEL 384 board LEDs: D1 - PA9, D2 - PA10, D3 - PA11, D4 - P12
;;;     -LEDs are active low
;;;     -All LEDs should be set to Max Speed 50MHz, genral purpose output push-pull
;;;      This sets the CNF MODE bits to #0x3 OR 0011 for all the LEDs
;;;     -Since GPIOA_CRH is the upper 16 bits and if we want to set PA9-12 we need to set
;;;      bits 4 to 19 of GPIO_CRH to get #0xFFF33330 OR (XXXX XXXX XXXX 0011 0011 0011 0011 XXXX)
;;;     -Since the LEDs are activce low, they will be turned on when enabled. So to set them off
;;;      going into the start of the program, it will be turned off using the bit pattern #0x1E00
;;;      and stored in GPIOA_ODR
;;;     -GPIO = General Purpose Input/Output
;;;     -CRH = High part (8-15)
;;;
;;;   Initilize GPIOA_CRH (Port A)
;;;     Step 1) Get masks for R6 and R7
;;;     Step 2) Load address of GPIOA_CRH and store it in R10
;;;     Step 3) Store the value at that address and store it in R5
;;;     Step 4) AND R5 with R6 to get rid of any junk values
;;;     Step 5) ORR R5 with R7 to set desired bits. I.e. #0x33330
;;;     Step 6) Store the value of R5 in memory at location R10, i.e. GPIOA_CRH
;;;
;;;   Turn off LEDs
;;;     Step 7) Load address of GPIOA_ODR and store it in R0
;;;     Step 8) Set desired LED bits and move it into R5 i.e. #0x1E00
;;;     Step 9) Store this in memory to have LEDs turned off
;;;     Step 10) Branch back to main
;;;
;;; Modifies:
;;;     -R0: Takes address of GPIOA_ODR. This will not change throughout the program
;;;     -R5: Takes value at address of GPIOA_CRH. Will be masked to get proper bit pattern to store
;;;          R5 will also get the code to set all LEDs to their off state. I.e. #0x1E00
;;;     -R6: Takes mask of #0xFFF33330 to clear any junk
;;;     -R7: Takes mask of #0x33330 to ORR with R5 to set proper bits.
;;;     -R10: Takes value of GPIOA_CRH
;;;
	ALIGN
GPIO_init  PROC

	MOV32 R6, #0xFFF33330   ;Step 1: Get masks for R6 and R7
	MOV32 R7, #0x33330

	LDR R10, = GPIOA_CRH    ;Step 2: Load address into R10
	LDR R5, [R10]           ;Step 3: Get value at address R10, store in R5

	AND R5, R6              ;Step 4: AND to get rid of junk
	ORR R5, R7              ;Step 5: ORR to set only desired bits

	STR R5, [R10]           ;Step 6: Store value in memory

	LDR R0, = GPIOA_ODR     ;Step 7: Load address into R0

	MOV R5, #0x1E00         ;Step 8: Set R5 with desired bits
	STR R5, [R0]            ;Step 9: Store R5 in memory, turning off LEDs

	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; waitForPlayer
;;;
;;; Require:
;;;     -Need output address of GPIOA_ODR
;;;     -Need input address of GPIOA_IDR, GPIOB_IDR, and GPIOC_IDR
;;;     -Need some delay time to store into R1 to keep LEDs on/off long enough
;;;
;;; Promise:
;;;     -Flashs all four LEDs on and off at the same time indefiniatly
;;;      until the player touches at least one of the pushbuttons
;;;     -Once a button is pressed the program will automatically go into
;;;      the next stage (PrelimWait/normalGamePlay).
;;;
;;; NOTES:
;;;     -LEDs will be off if the value at GPIOA_ODR is set to #0x1E00,
;;;      but on if the value is #0xE1FF. I.e. bits 9-12 are of impotance
;;;
;;;     Step 1) Load addresses and variables for:
;;;            i)   GPIOA_ODR (LEDs)
;;;            ii)  SHORT_DELAYTIME for flashing
;;;            iii) GPIOX_IDR for A-C for pushbutton input
;;;     Step 2) Enter delay
;;;     Step 3) Push R1
;;;     Step 4) Enter counter for delay
;;;     Step 5) Reset R6 to reset input check
;;;     Step 6) Check if any pushbuttons have been pressed
;;;             6a) Load Value at IDR address, store into R5
;;;             6b) AND R5 by mask to get desired input bit
;;;             6c) ORR R6 and R5 to save any input changes **Repeat steps 6a-6c for all inputs**
;;;             6d) Check if an input caused R6 to NOT equal 0x1320
;;;                 -If NOT equal then one or more inputs were pressed
;;;                 -Return back to main loop if NOT equal
;;;                 -if EQUAL then continue to step 7)
;;;     Step 7) Check if delay timer is 0
;;;            7a) Push R1 if finished
;;;            7a-else) If NOT finished, decrement R1 counter
;;;            7b-else) Loop back to counter loop
;;;     Step 8) Go into alternate lights being on or off sub
;;;     Step 9) Check if lights are on, turn them off if they are.
;;;             If lights are off, turn them on.
;;;     Step 10) Store new value/output of LEDs into memory at GPIOA_ODR
;;;     Step 11) Repeat back to delay until a button is pressed
;;;
;;; Modifies:
;;;     R1: Loads value of a delay time into it, this value decrements
;;;     R2: Loads address of GPIOA_IDR, this register DOES NOT change again in this routine
;;;     R3: Loads address of GPIOB_IDR, this register DOES NOT change again in this routine
;;;     R4: Loads address of GPIOC_IDR, this register DOES NOT change again in this routine
;;;     R5: Takes in values at different addresses. It is then masked to get an individual bit
;;;     R6: Will be ORRed with R5 to see if any buttons have been pressed. If no button is pressed
;;;         then it will have a value of #0x1320. If one has been touched, one or all set bits will
;;;         be shown as 0. On looping R6 will reset to 0
;;;     R7: Takes the current state of the LEDs and will alternate between loops
;;;         #0x1E00 for off and #0xE1FF for on
;;;     STACK: Pushes the value of R1 at the start of the sub routine
;;;            Pops the value of R1 at the end of the sub routine
;;;     GPIOA_ODR: The value at this memory will be updated by R7 to update the LEDs
;;;
	ALIGN
waitForPlayer PROC
;Step 1) Load addresses and variables
	LDR R0, = GPIOA_ODR          ;LED Output
	LDR R1, = SHORT_DELAYTIME    ;Delay time

	LDR R2, = GPIOA_IDR          ;Green button input
	LDR R3, = GPIOB_IDR          ;Black and red button input
	LDR R4, = GPIOC_IDR          ;Blue button input


sub_delay   ;Step 2) Enter delay loop
	push {R1}   ;Step 3) Push R1

;Step 4) Enter counter for delay
sub_counter

	MOV R6, #0  ;Step 5) Reset R6 check value

	;Step 6) Check if any pushbuttons are pressed
	;Check Blue button
	LDR R5, [R4]        ;6a) Load value at R4/GPIOC_IDR
	AND R5, #0x00001000 ;6b) Get rid of any junk
	ORR R6, R5          ;6c) Set desired bits

	;Check Red and/or Black button
	LDR R5, [R3]        ;6a) Load value at R3/GPIOB_IDR
	AND R5, #0x00000300 ;6b) Get rid of any junk
	ORR R6, R5          ;6c) Set desired bits

	;Check Green button
	LDR R5, [R2]        ;6a) Load value at R3/GPIOB_IDR
	AND R5, #0x00000020 ;6b) Get rid of any junk
	ORR R6, R5          ;6c) Set desired bits

	CMP R6, #0x1320     ;6d) Check if any inputs change, return to main if there is
	ITTTT NE
	LDRNE R12, = RTC_DIVL	
	LDRNE R11, [R12]
	POPNE {R1}
	BXNE LR

	CMP R1, #0      ;Step 7) Check if counter time = 0. Loop if not, continue if yes
	ITEE EQ
	POPEQ{R1}           ;7a) Pop R1 if finished
	SUBNE R1, R1, #1    ;7a-else) Decrement counter if not finished
	BNE sub_counter     ;7b-else) Loop again

;Step 8) Go into alternate lights being on or off sub
sub_alternate

	CMP R7, #0x1E00        ;Step 9) Check if lights are off
	ITE EQ
	MOVEQ R7, #0xE1FF      ;If off, turn on
	MOVNE R7, #0x1E00      ;If on, turn off

	LDR R0, = GPIOA_ODR
	STR R7, [R0]    ;Step 10) Store updated output to memory

	;Step 11) Repeat back to delay until a button is pressed
	B sub_delay

	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; normalGamePlay
;;;
;;; Require:
;;;     -Delay times
;;;		-Number of cycles the player can play
;;;		-Initial seed value
;;;		-Random value address, GPIOA_ODR address, etc. 
;;;
;;; Promise:
;;;     -Will initiate an intro sequence so the player is ready to
;;;		 play the game. normalGamePlay will randomize which LED to 
;;;		 light up and will give the player a short amount of time 
;;;		 to press the correct pushbutton
;;;		-IF the player incorrectly presses a button or if the time 
;;;		 runs out, then it will branch back to main function
;;;		-IF the player correctly presses a pushbutton, the difficulty 
;;;		 will increase and the game will get faster. This will continue
;;;		 until the player correctly presses 15 times OR loses and will 
;;;		 branch back to main upon winning
;;;
;;; NOTES:
;;;     -Random number generator can ignore overflow
;;;		-Random number generator should be Xn+1 = A*(Xn)+C
;;;			where A and C are some constants and Xinit is some seed value
;;;			*X will be stored at location X_Storage
;;;
;;;     Step 1) Ensure LEDs are off:
;;;				1a) Get LED OFF code
;;;				1b) Store OFF code into R0
;;;     Step 2) Get Delay time
;;;     Step 3) Initilize Counters
;;;				3a) Prelim LED sequence
;;;				3b) Reset level/score counter
;;;     Step 4) Enter PrelimWait Loop
;;;     Step 5) Push R1 onto stack 
;;;     Step 6) Enter counter/delay for lights loop
;;;     Step 7) Check if counter time has run out. Loop if not, continue if yes
;;;             7a) Pop R1 if finished
;;;             7a-else) Decrement time counter if not finished
;;;             7b-else) Loop again
;;;     Step 8) Enter fewer LED, this has all 4 LEDs ON and turns them off
;;;				one by one and then holds all OFF before going into the main game
;;;		Step 9) Check value of R8 to a number
;;;				9a) If equal, Mov LED code into R7*
;;;				*Do this for compares below
;;;				This lets the LEDs do an intro to the game sequence. The sequence
;;;				is the following:
;;;					i) ALL LEDs on
;;;					ii) LEDs 1,2,3 on; 4 off
;;;					iii) LEDs 1 and 2 on; 3 and 4 off
;;;					iv) LEDs 1 on; 2,3,4 off
;;;					v) ALL LEDs off
;;;		Step 10) Store new code into GPIOA_ODR
;;;		Step 11) Check if counter/sequence is finished
;;;				11a) If NOT finished, increase counter	
;;;				11b) If NOT finished, loop back to PrelimWait
;;;		Step 12) Enter main game loop
;;;		Step 13) Get hardset random X seed
;;;		Step 14) Get memory address to store X
;;;		Step 15) Store seed address X at X_STORAGE
;;;		Step 16) Get the react time for user
;;;		Step 17) Branch to get random number generator*
;;;				 *Jump to Step 30)
;;;		Step 18) Enter delay game loop
;;;		Step 19) Push R1 onto stack
;;;		Step 20) Enter counter for delay
;;;		Step 21) Reset R6 check value
;;;		Step 22) Check if any pushbuttons are pressed
;;;				 22a) Load value at R4/GPIOC_IDR
;;;				 22b) Get rid of any junk
;;;				 22c) Set desired bits
;;;				 22d) Check if any inputs change
;;;					i) Pop R1
;;;					ii) Increase score/level counter
;;;					iii) Branch to changeLights to turn on next light
;;;		Step 23) Check if multiple buttons are pressed
;;;				 23a) If multiple pressed, mov 0 into R1 delay counter
;;;		Step 24) Check if counter time = 0. Loop if not, continue if yes
;;;				 24a) Pop R1 if finished
;;;				 24a-else) Decrement counter if not finished
;;;				 24b-else) Loop again 
;;;				 24b) IF R1 = 0 then go back to main 
;;;		Step 25) Push R1
;;;		Step 26) Double amount delay time
;;;				 26a) Mov 2 into R5 as a scalar constant 
;;;				 26b) Multiply R1 delay time by 2
;;;		Step 27) Enter LED OFF delay 
;;;		Step 28) Store OFF code into GPIOA_ODR
;;;	 	Step 29) Check if counter time has run out. Loop if not, continue if yes
;;;             29a) Pop R1 if finished
;;;             29a-else) Decrement time counter if not finished
;;;             29b-else) Loop again
;;;		Step 30) Enter Random Number Generator 
;;;		Step 31) Get address of X_Storage
;;;		Step 32) Get value at X_Storage
;;;		Step 33) Load variables in 
;;;				 33a) Load multiplier A value
;;;			     33b) Load addition C value
;;;		Step 34) Get new random number
;;;				 34a) Multiple X by A (A*X)
;;;			     34b) Add C (A*X + C)
;;;			     34c) Store new X value in memory
;;;		Step 35) Shift X over by 30 bits to get the 2 left most bits
;;;				 that will allow to give 1, 2, 3, or 4 to turn on a 
;;;				 corresponding LED
;;;		Step 36) Mask to get desired bits 
;;;		Step 37) Check shifted X for which LED to turn on
;;;				 37a) If equal, set proper LED code
;;;				 37b) If equal, set pushbutton code
;;;				 Below are the pushbutton codes (i.e. which should be pressed)
;;;					i) 		RED: 	0x1220
;;;				 	ii) 	BLACK: 	0x1120
;;;				 	iii) 	BLUE: 	0x0320
;;;				 	iv) 	GREEN: 	0x1300
;;;		Step 38) Store LED code into GPIOA_ODR
;;;		Step 39) Decrement delay/on time of the LEDs to make it harder
;;;				 39a) Load the difficulty modifier
;;;				 39b) Subtract it from time delay 
;;;		Step 40) Check if maximum number of cycles 
;;;				 40a) Load total number of cycles
;;;				 40b) Check if score is less than 
;;;				 40b-true) Branch to delay if less than
;;;		Step 41) Shut off LEDs
;;;				 40a) Get LED OFF code
;;;				 40b) Store this code into GPIOA_ODR
;;;		Step 42) Branch back to main function 
;;;
;;; Modifies:
;;;		R1: Holds the time delays for ON/OFF LEDs. This decrements
;;;		R5: Will hold values at different addresses like [GPIOA_ODR]
;;;			Will also hold address values like X_STORAGE
;;;			Will also hold random values like #2 scalar values
;;;		R6: Starts as 0x0 and will change depending on button input 
;;;		R7: Holds LED codes that will be stored in GPIOA_ODR, also for C constant 
;;;		R8: Counter for LED sequence, Storage for initial seed and for A constant
;;;		R9: Level counter, increases everytime a pushbutton is correctly pressed
;;;		R10: LED code for random button that should be lit
;;;		R11: Value of X that is loaded, stored, and changed
;;;		R12: Value of pushbutton code that is needed to correctly get user input
;;;			 *See step 37 for pushbutton codes
;;;		GPIOA_ODR: Constantly changed for new LED ON/OFF order
;;;		STACK: R1 is constantly being pushed on/off	
;;;		X_STORAGE: Value at this address is updated with each random X value
;;;
	ALIGN
normalGamePlay	PROC
	;Step 1) Ensure LEDs are off
	MOV R7, #0xE1FF	;1a) Get LED OFF code
	STR R7, [R0]	;1b) Store OFF code into R0

	LDR R1, = HALF_DELAYTIME    ;Step 2) Get Delay time

	;Step 3) Initilize Counters
	MOV R8, #0    ;3a) Prelim LED sequence
	MOV R9, #0	  ;3b) Reset level/score counter

;Step 4) Enter PrelimWait Loop
PrelimWait
	push {R1}	;Step 5) Push R1 onto stack 

;Step 6) Enter counter/delay for lights loop
sub_counter_pre
	CMP R1, #0	;Step 7) Check if counter time has run out. Loop if not, continue if yes
	ITEE EQ
	POPEQ{R1}			;7a) Pop R1 if finished
	SUBNE R1, R1, #1	;7a-else) Decrement time counter if not finished
	BNE sub_counter_pre	;7b-else) Loop again

;Step 8) Enter fewer LED
sub_fewer_LED
	CMP R8, #0		;Step 9) Check value of R8 to a number
	IT EQ
	MOVEQ R7, #0xF1FF	;9a) If equal, Mov LED code into R7

	CMP R8, #0x1		;Step 9) Check value of R8 to a number
	IT EQ
	MOVEQ R7, #0xF9FF	;9a) If equal, Mov LED code into R7

	CMP R8, #2		;Step 9) Check value of R8 to a number
	IT EQ
	MOVEQ R7, #0xFDFF	;9a) If equal, Mov LED code into R7

	CMP R8, #3		;Step 9) Check value of R8 to a number
	IT EQ
	MOVEQ R7, #0xFEFF	;9a) If equal, Mov LED code into R7

	STR R7, [R0]	;Step 10) Store new code into GPIOA_ODR

	CMP R8, #5		;Step 11) Check if counter/sequence is finished
	ITT NE
	ADDNE R8, R8, #1	;11a) If NOT finished, increase counter		 
	BNE PrelimWait		;11b) If NOT finished, loop back to PrelimWait

;Step 12) Enter main game loop
sub_gamePlay
	MOV32 R8, #0x1FFF1234	;Step 13) Get hardset random X seed
	LDR R5, = X_STORAGE		;Step 14) Get memory address to store X
	LDR R8, [R5]			;Step 15) Store seed address X at X_STORAGE
	
	LDR R1, = REACT_TIME    ;Step 16) Get the react time for user

	B sub_getRandom			;Step 17) Branch to get random number generator

;Step 18) Enter delay game loop
sub_delay_game   
	push {R1}   ;Step 19) Push R1 onto stack

;Step 20) Enter counter for delay
sub_counter_game

	MOV R6, #0  ;Step 21) Reset R6 check value

	;Step 22) Check if any pushbuttons are pressed
	;Check Blue button
	LDR R5, [R4]        ;22a) Load value at R4/GPIOC_IDR
	AND R5, #0x00001000 ;22b) Get rid of any junk
	ORR R6, R5          ;22c) Set desired bits

	;Check Red and/or Black button
	LDR R5, [R3]        ;22a) Load value at R3/GPIOB_IDR
	AND R5, #0x00000300 ;22b) Get rid of any junk
	ORR R6, R5          ;22c) Set desired bits

	;Check Green button
	LDR R5, [R2]        ;22a) Load value at R3/GPIOB_IDR
	AND R5, #0x00000020 ;22b) Get rid of any junk
	ORR R6, R5          ;22c) Set desired bits	
	
	CMP R6, R12			;22d) Check if any inputs change
	ITTT EQ			
	POPEQ{R1}				;i) Pop R1 
	ADDEQ R9, #1			;ii) Increase score/level counter
	BEQ sub_changeLights	;iii) Branch to changeLights to turn on next light
	
	CMP R6, #0x1320     ;Step 23) Check if multiple inputs are pressed
	IT NE
	MOVNE R1, #0			;23a) If multiple pressed, mov 0 into R1 delay counter
	
	CMP R1, #0      ;Step 24) Check if counter time = 0. Loop if not, continue if yes
	ITEE EQ
	POPEQ{R1}           	;24a) Pop R1 if finished
	SUBNE R1, R1, #1    	;24a-else) Decrement counter if not finished
	BNE sub_counter_game    ;24b-else) Loop again

	BX LR			;24b) IF R1 = 0 then go back to main 
	
sub_changeLights
	push {R1}	;Step 25) Push R1
	
	;Step 26) Double amount delay time
	MOV R5, #2		;26a) Mov 2 into R5 as a scalar constant 
	MUL R1, R1, R5	;26b) Multiply R1 delay time by 2
	
;Step 27) Enter LED OFF delay 
sub_counter_off
	MOVEQ R7, #0x1E00	;Step 28) Store OFF code into GPIOA_ODR
	STR R7, [R0]		
	
	CMP R1, #0		;Step 29) Check if counter time has run out. Loop if not, continue if yes
	ITEE EQ
	POPEQ{R1}			;29a) Pop R1 if finished
	SUBNE R1, R1, #1	;29a-else) Decrement time counter if not finished
	BNE sub_counter_off ;29b-else) Loop again
	
;Step 30) Enter Random Number Generator 
sub_getRandom
	LDR R5, = X_STORAGE	;Step 31) Get address of X_Storage
	LDR R11, [R5]		;Step 32) Get value at X_Storage
	
	;Step 33) Load variables in 
	LDR R8, = A		;33a) Load multiplier A value
	LDR R7, = C		;33b) Load addition C value

	;Step 34) Get new random number
	MUL R11, R11, R8	;34a) Multiple X by A (A*X)
	ADD R11, R11, R7	;34b) Add C (A*X + C)

	STR R11, [R5]		;34c) Store new X value 
	
	LSR R11, #30			;Step 35) Shift X over 30bits
	AND R11, #0x00000003	;Step 36) Mask to get desired bits

	;Step 37) Check shifted X for which LED to turn on
	;Check if LED 1 should be used (Red PB)
	CMP R11, #0x0			
	ITT EQ 
	MOVEQ R10, #0xFDFF	;37a) If equal, set proper LED code 
	MOVEQ R12, #0x1220	;37b) if equal, set pushbutton code

	;Check if LED 2 should be used (Black PB)
	CMP R11, #0x1	
	ITT EQ 
	MOVEQ R10, #0xFBFF	;37a) If equal, set proper LED code 
	MOVEQ R12, #0x1120	;37b) if equal, set pushbutton code

	;Check if LED 3 should be used (Blue PB)
	CMP R11, #0x2	;right mid
	ITT EQ 
	MOVEQ R10, #0xF7FF	;37a) If equal, set proper LED code
	MOVEQ R12, #0x0320	;37b) if equal, set pushbutton code
	
	;Check if LED 4 should be used (Green PB)
	CMP R11, #0x3	;right right
	ITT EQ 
	MOVEQ R10, #0xEFFF	;37a) If equal, set proper LED code
	MOVEQ R12, #0x1300	;37b) if equal, set pushbutton code
	
	STR R10, [R0]	;Step 38) Store LED code into GPIOA_ODR
	
	;Step 39) Decrement delay/on time of the LEDs to make it harder
	LDR R5, = INC_DIFF	;39a) Load the difficulty modifier
	SUB R1, R1, R5		;39b) Subtract it from time delay 
	
	;Step 40) Check if maximum number of cycles 
	LDR R5, = NUM_CYCLES	;40a) Load total number of cycles
	CMP R9, R5				;40b) Check if score is less than 
	IT LT
	BLT sub_delay_game		;40b-true) Branch to delay if less than
	
	;Step 41) Shut off LEDs
	MOV R5, #0x1E00		;41a) Get OFF code
	STR R5, [R0]		;41b) Store it into GPIOA_ODR
	
	BX LR	;Step 42) Branch back to main 
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; EndSuccess
;;;
;;; Require:
;;;     -A delay time for R1
;;;		-Location of LED outputs
;;;
;;; Promise:
;;;     -When a player wins the game, the LEDs will flash in
;;;      patterns showing that the player has one.
;;;     -When the sequence is finished, all 4 LEDs will light
;;;      up for 1 minute indicating a win/level 15 was passed.
;;;     -The player CANNOT leave this stage and must wait until
;;;      the light sequence and 1 minute display is finished.
;;;
;;; NOTES:
;;;     Step 1) Load delay time into R1
;;;     Step 2) Initilize loop Counter
;;;     Step 3) Enter delay loop
;;;     Step 4) Push R1/Delay time
;;;     Step 5) Enter counter for delay
;;;     Step 6) Check if counter time has run out. Loop if not, continue if yes
;;;             6a) Pop R1 if finished
;;;             6a-else) Decrement time counter if not finished
;;;             6b-else) Loop again
;;;     Step 7) Enter light sequence sub
;;;     Step 8) Initiate first LED sequence (Alternate sets of 2 LEDs)
;;;             8a) Check if R8 = 0
;;;             8b) If EQ, set R5 to turn on right 2 LEDs
;;;             8c) Check if R8 = 1
;;;             8d) If EQ, set R5 to turn on left 2 LEDs
;;;     Step 9) Initiate second LED sequence (1 LED at a time in order)
;;;             9a) Check if R8 = 2
;;;             9b) If EQ, set R5 to turn on LED 1 on
;;;             9c) Check if R8 = 3
;;;             9d) If EQ, set R5 to turn on LED 2 on
;;;             9e) Check if R8 = 4
;;;             9f) If EQ, set R5 to turn on LED 3 on
;;;             9g) Check if R8 = 5
;;;             9h) If EQ, set R5 to turn on LED 4 on
;;;     Step 10) Initiate third LED sequence (1 LED at a time in reverse order)
;;;             10a) Check if R8 = 6
;;;             10b) If EQ, set R5 to turn on LED 3 on
;;;             10c) Check if R8 = 7
;;;             10d) If EQ, set R5 to turn on LED 2 on
;;;             10e) Check if R8 = 8
;;;             10f) If EQ, set R5 to turn on LED 1 on
;;;     Step 11) Initiate fourth LED sequence (all 4 LEDs on for 1 minute)
;;;             11a) Check if R8 > 8
;;;             11b) Keep all 4 LEDs on if EQ
;;;     Step 12) Store LED bit pattern in memory
;;;     Step 13) Check R8 if it has looped for 1 minute
;;;              To get 1min = 60 000ms with delay = 500ms -> Loop held for 120* more times
;;;              *This has been timed and works well
;;;             13a) If NE, increment loop counter
;;;             13b) Store new bit pattern in memory
;;;     Step 14) Set bit pattern of R5 to turn off all lights
;;;     Step 15) Store new bit pattern in memory
;;;     Step 16) Branch back to main
;;;
;;; Modifies:
;;;     R1: Loads value of Half_DelayTime which is popped/pushed and decremented
;;;     R5: Has the value that will be stored in ODR moved into it
;;;     R8: Counter used to change what the lights are doing using CMP
;;;     GPIOA_ODR: Changes all 4 LEDs each loop depending on R8 sequence
;;;     STACK: R1 Pushes and Pops on and off of it
;;;
	ALIGN
EndSuccess PROC
	LDR R1, = WINNING_TIME    ;Step 1) Load delay time into R1

	MOV R8, #0      ;Step 2) Initilize loop Counter

;Step 3) Enter delay loop
sub_delay_win
	push {R1}   ;Step 4) Push R1/delay time


;Step 5) Enter counter for delay
sub_counter_win
	CMP R1, #0      ;Step 6) Check if counter time has run out. Loop if not, continue if yes
	ITEE EQ
	POPEQ{R1}               ;6a) Pop R1 if finished
	SUBNE R1, R1, #1        ;6a-else) Decrement time counter if not finished
	BNE sub_counter_win     ;6b-else) Loop again


;Step 7) Enter light sequence sub
sub_lightSequence_win

	;Step 8) Initiate first LED sequence (Alternate sets of 2 LEDs)
	CMP R8, #0      ;8a/b) Check if R8 = 0 set R5 to turn on right 2 lights
	IT EQ
	MOVEQ R5, #0x0700

	CMP R8, #1      ;8c/d) Check if R8 = 1 If EQ, set R5 to turn on left 2 LEDs
	IT EQ
	MOVEQ R5, #0xF900

	;Step 9) Initiate second LED sequence (1 LED at a time in order)
	CMP R8, #2      ;9a/b) Check if R8 = 2 If EQ, set R5 to turn on LED 1
	IT EQ
	MOVEQ R5, #0xEF00

	CMP R8, #3      ;9c/d) Check if R8 = 3 If EQ, set R5 to turn on LED 2
	IT EQ
	MOVEQ R5, #0x1700

	CMP R8, #4      ;9e/f) Check if R8 = 4, If EQ, set R5 to turn on LED 3
	IT EQ
	MOVEQ R5, #0x1B00

	CMP R8, #5      ;9g/h) Check if R8 = 5  If EQ, set R5 to turn on LED 4
	IT EQ
	MOVEQ R5, #0x1D00

	;Step 10) Initiate third LED sequence (1 LED at a time in reverse order)
	CMP R8, #6      ;10a) Check if R8 = 6 If EQ, set R5 to turn on LED 3
	IT EQ
	MOVEQ R5, #0x1B00

	CMP R8, #7      ;10c) Check if R8 = 7 If EQ, set R5 to turn on LED 2
	IT EQ
	MOVEQ R5, #0x1700

	CMP R8, #8      ;10e) Check if R8 = 8 If EQ, set R5 to turn on LED 1
	IT EQ
	MOVEQ R5, #0xEF0

	;Step 11) Initiate fourth LED sequence (all 4 LEDs on for 1 minute)
	CMP R8, #8      ;11a/b) Check if R8 = 5 If EQ, set R5 to turn on all LEDs
	IT GT
	MOVGT R5, #0xE100

	STR R5, [R0]    ;Step 12) Store LED bit pattern in memory
	
	LDR R5, = NUM_CYC_WIN
	CMP R8, R5   ;Step 13) Check R8 if it has looped for 1 minute
	ITT NE
	ADDNE R8, R8, #1    ;13a) If NE, increment loop counter
	BNE sub_delay_win   ;13b) Loop back to sub_delay_win

	MOV R5, #0x1E00     ;Step 14) Set bit pattern of R5 to turn off all lights
	STR R5, [R0]        ;Step 15) Store new bit pattern in memory

	;Step 16) Return to main
	BX LR

	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; EndFailure
;;;
;;; Require:
;;;     -A level progress stored in (0 < R9 < 16)
;;;     -A delay time to be loaded into R1
;;;     -The address of GPIOA_ODR
;;;     -R9 MUST be unsigned
;;;
;;; Promise:
;;;     -Will indicate the player's progress (what level they got to)
;;;      and then return to waitForPlayer routine.
;;;     -The level indication will be represented by the 4 LEDs on
;;;      the board and will flash on and off a predefined amount of times
;;;
;;; NOTES:
;;;     -The player CANNOT immediatly leave this stage and must wait for it to finish
;;;     -The level progress will be represented as a binary number in LEDs
;;;      So for example, if the player gets to level 6 then the two centre
;;;      LEDs will be lit up in the pattern OFF ON ON OFF -> 0110
;;;     -If the player gets to level 15, but loses then it will flash all 4 lights
;;;     -If the player does not pass the very first level, then nothing will flash
;;;     -Since R9 (level counter) is at bits 0-3 and to turn on/off the LEDs we need
;;;      to set bits 9-12 of GPIOA_ODR. We can easily shift R9 over to those bits and
;;;      store the shift R9 into GPIOA_ODR directly.
;;;
;;;     Step 1) Load the delay time into R1
;;;     Step 2) EOR R9 with #0xF since current value will have LEDs off when we want them on.
;;;     Step 3) Shift R9 from 000...0 XXXX bit format to 000...0X XXX0 0000 0000 format
;;;             Shift amount is 9 bits left. Will use logical shift left.
;;;     Step 4) Initilize counters:
;;;             i) R8: Number of times lights have flashed
;;;             ii) R7: Set to 0 for bi state of lights
;;;     Step 5) Enter delay loop
;;;     Step 6) Push R1/Delay time
;;;     Step 7) Enter delay counter loop
;;;     Step 8) Check if counter time has run out. Loop if not, continue if yes
;;;             8a) Pop R1 if finished
;;;             8a-else) Decrement counter if R1/delay != 0
;;;             8b-else) Loop again
;;;     Step 9) Enter Alternate sub to alternate on/off of LEDs
;;;     Step 10) Check if R7 = 0. If EQ, have level lights on. If NE, have all lights off
;;;             10a) If EQ, make R5 = R9 -> Level lights on vavlue
;;;             10b) If EQ, R7 = 1
;;;             10a-else) Set R5 = #0x1E00 -> All lights off value
;;;             10b-else) Set R7 = 0
;;;     Step 11) Store R5 into memory GPIOA_ODR
;;;     Step 12) Check R8 to see if lights have flashed enough
;;;             12a) If not, increase R8
;;;             12b) If not, loop back to sub_delay_fail
;;;     Step 13) Turn all LEDs off
;;;     Step 14) Branch back to main
;;;
;;; Modifies:
;;;     R1: Loads half delay time. Will decrement in each time/counter loop
;;;     R5: Changes to the value that will be outputed to GPIOA_ODR
;;;     R7: Switches between 0 and 1 to alternate states of the LEDs
;;;     R8: Counter for times LEDs flash. Will start as 0 and increment to #0xA.
;;;     R9: Starts as level player failed on. Will be EORed to get opposite states
;;;         and finally shifted left by 9 bits to easily store in GPIOA_ODR
;;;     GPIOA_ODR: Bits 9-12 will be updated each loop to display what level the
;;;                failed on OR to display all lights off (i.e. flash)
;;;     STACK: R1 is pushed at the start and then popped when looping is done
;;;
	ALIGN
EndFailure    PROC
	LDR R1, = LOSING_TIME    ;Step 1) Load delay time

	EOR R9, #0xF    ;Step 2) EOR R9
	LSL R9, #9      ;Step 3) Shift R9

	;Step 4) Initilize counters (8 for times blinked, 7 for switch)
	MOV R8, #0  ;Times flashed
	MOV R7, #0  ;Which set of lights to turn on. I.e. 2 states
 

;Step 5) Enter delay loop
sub_delay_fail
	push {R1}   ;Step 6) Push R1


;Step 7) Enter counter for delay
sub_counter_fail

	CMP R1, #0          ;Step 8) Check if counter time has run out. Loop if not, continue if yes
	ITEE EQ
	POPEQ{R1}               ;8a) Pop R1 if finished
	SUBNE R1, R1, #1        ;8a-else) Decrement counter if R1/delay != 0
	BNE sub_counter_fail    ;8b-else) Loop again

;Step 9) Enter Alternate sub to alternate on/off of LEDs
sub_alternate_fail

	CMP R7, #0      ;Step 10) Check if R7 = 0
	ITTEE EQ
	MOVEQ R5, R9        ;10a) If EQ, set R5 = R9
	MOVEQ R7, #1        ;10b) If EQ, set R7 = 1
	MOVNE R5, #0x1E00   ;10a-else) Set R5 = #0x1E00
	MOVNE R7, #0        ;10b-else) Set R7 = 0

	;Step 11) Store R5 into memory GPIOA_ODR
	LDR R0, = GPIOA_ODR
	STR R5, [R0]

	CMP R8, #0xA         ;Step 12) Check to see if lights have flashed enough
	ITT NE
	ADDNE R8, R8, #1        ;12a) If not, increase R8
	BNE sub_delay_fail      ;12b) If not, loop back to sub_delay_fail

	;Step 13) Turn all LEDs off
	MOV R5, #0x1E00     ;13a) Set R5 to #0x1E00
	STR R5, [R0]        ;13b) Store R5 in memory

	;Step 14) Branch back to main
	BX LR

	ENDP
		
	ALIGN
	END