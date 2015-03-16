/* 
 * author(s):   Ruth Schuler 
 *              Michele Wyss
 *
 * modified:    2011-May
 *
 */

.include "nios_macros.s"
.include "address_map.s"
/* Pong */

/********************************************************************************
 * Entry point.
 */

.global _start

_start:
	/* set up sp and fp */
	movia 	sp, 0x007FFFFC			# stack starts from largest memory address 
	mov 		fp, sp
		
	/* set up timer interval = 0x0000C350 steps * 1/(50 MHz) = 1 millisecond*/
	movia	r15, TIMER_COUNTER_LOW
	movui	r16, 0xC350
	sthio		r16, 0(r15)
	
	movia	r15, TIMER_COUNTER_HIGH
	movui	r16, 0x0000
	sthio		r16, 0(r15)
	
	/* start interval timer, enable its interrupts */
	movia	r15, TIMER_STOP_START_CONT_ITO
	movi		r16, 0b0111		# START = 1, CONT = 1, ITO = 1 
	sthio		r16, 0(r15)
	
	/* enable pushbutton interrupts */
	movia	r16, PUSHBUTTON_BASE
	movi		r15, 0b01110		# set all 3 interrupt mask bits to 1 (bit 0 is Nios II Reset) 
	stwio		r15, 8(r16)
	
	/* enable processor interrupts */
	movi		r16, 0b011		# enable interrupts for timer and pushbuttons 
	wrctl		ienable, r16
	movi		r16, 1
	wrctl		status, r16
	
	/* initialize registers for wandering light*/
	movia	r4, RED_LED_BASE	# set LED lights base
	movia	r3, 0b1			# set shift amount
	movia	r2, 0b1000000000	# light position before changing direction to right
	movia	r10,0b0000000001	# light position before changing direction to left
	movia	r7, 300			# set up timer
	movia	r9, TIME		# address of time counter in r9
	mov	r19, r0			# set score of right player to 0
	mov	r18, r0			# set score of left player to 0
	movia	r11, HEX3_HEX0_BASE	# r11 = base address of the display
	movia	r21, 0b1010		# r21 = value of "KEY3 and KEY1 are pressed"
	movia	r22, 0b1000		# r22 = value of "KEY3 is pressed"
	movia	r23, 0b0010		# r23 = value of "KEY1 is pressed"
	movia	r15, 10			# winner score: 10

	movia	r8, 0b01110011011000110010001101101111	# represents "Pong" on the display
	stwio	r8, 0(r11)				# write it on the display
	
/* start the game */
	

BLINK:
	movia	r5, 0b0000100000	# display LEDR5
	call	DISPLAY_LIGHT
	
	beq	r14, r21, KEYS_PRESSED	# if KEY3 and KEY1 are pressed, go to KEYS_PRESSED
	
	movia	r5, 0b0000010000	# display LEDR4
	call	DISPLAY_LIGHT
	
	beq	r14, r21, KEYS_PRESSED	# if KEY3 and KEY1 are pressed, go to KEYS_PRESSED
	
	br	BLINK			# else, continue blinking

KEYS_PRESSED:
	mov	r14, r0			# reset "pressed keys"
	call	PUSHBUTTON_ISR		# check if the keys are still pressed
	beq	r14, r0, START_GAME	# if the keys are released, start the game
	br	KEYS_PRESSED		# wait (until the keys are released)
	
START_GAME:
	mov	r14, r0				# no button pressed
	movia	r21, 0b000100000		# r21 = value of LEDR5
	beq	r5, r21, START_FOR_RIGHT	# if the light before pressing the keys was LEDR5, go right
	br	START_FOR_LEFT			# else, go left
	

START_FOR_LEFT:
	movia	r5, 0b0000010000	# initialize the starting light
	call DISPLAY_LIGHT		# turn it on
	br GO_LEFT			# go left

START_FOR_RIGHT:
	movia	r5, 0b0000100000	# initialize the starting light
	call	DISPLAY_LIGHT		# turn it on
	br	GO_RIGHT		# go right
	
GO_LEFT:
	mov	r14, r0
	sll	r5, r5,r3			# initialize next light (left shift, amount 1)
	call	DISPLAY_LIGHT			# turn on current light
	beq	r5, r2, CHECK_KEY3_PRESSED	# if the left side is reached, wait for key3
	br	CHECK_WRONG_TIME_PRESSED_L	# check if a key has been pressed at the wrong time

GO_RIGHT:
	mov	r14, r0
	srl	r5, r5, r3			# initialize next light (right shift)
	call	DISPLAY_LIGHT			# turn on current light
	beq 	r5, r10, CHECK_KEY1_PRESSED	# if the right side is reached, KEY1 should be pressed
	br	CHECK_WRONG_TIME_PRESSED_R	# check if a key has been pressed at the wrong time

	
WAIT:	ldw	r17, 0(r9)		# load current time
	blt	r17, r7, WAIT		# if the time is not yet reached, wait longer.
	stwio	r0, 0(r9)		# reset timer
	ret				# return
	
CHECK_WRONG_TIME_PRESSED_R:
	beq	r14, r22, POINT_TO_RIGHT_PLAYER	# if key3 is pressed at the wrong time, give a point to the left player
	beq	r14, r23, POINT_TO_LEFT_PLAYER	# if key1 is pressed at the wrong time, give a point to the right player
	br	GO_RIGHT
	
CHECK_WRONG_TIME_PRESSED_L:
	beq	r14, r22, POINT_TO_RIGHT_PLAYER	# if key3 is pressed at the wrong time, give a point to the left player
	beq	r14, r23, POINT_TO_LEFT_PLAYER	# if key1 is pressed at the wrong time, give a point to the right player
	br	GO_LEFT

DISPLAY_LIGHT:
	stwio	r5, 0(r4)		# turn on current light
	
	subi	sp,  sp, 4		# save return address before overriding it by calling a subroutine 
	stw	ra, 0(sp)
	
	call	WAIT			# Let it shine! :-)
	
	ldw	ra, 0(sp)		# reload return address
	addi	sp, sp, 4
	
	ret
	
CHECK_KEY3_PRESSED:
	call	PUSHBUTTON_ISR			# it will be stored in r14 which button has been pressed
	movia	r6, 0b1000			# r6 = "KEY3 has been pressed"
	beq	r14, r6, SPEED_UP_GO_RIGHT	# if KEY3 has been pressed, speed up and go right again
	br	POINT_TO_RIGHT_PLAYER		# else, the right player gets a point
	
CHECK_KEY1_PRESSED:
	call	PUSHBUTTON_ISR			# it will be stored in r14 which button has been pressed
	movia	r6, 0b0010			# r6 = "KEY1 has been pressed"
	beq	r14, r6, SPEED_UP_GO_LEFT	# if KEY1 has been pressed, speed up and go left again
	br	POINT_TO_LEFT_PLAYER		# else, the left player gets a point

SPEED_UP_GO_RIGHT:
	call	SPEED_UP			# increase speed
	movia	r5, 0b1000000000		# set the new starting light before going right
	br	GO_RIGHT			# change the direction to right
SPEED_UP_GO_LEFT:
	call	SPEED_UP			# increase speed
	movia	r5, 0b0000000001		# set the new starting light before going left
	br	GO_LEFT				# change the direction to left

SPEED_UP:
	ble	r7, r0, SET_MAX_SPEED		# if time delay <= 0 reset it to default
	subi	r7, r7, 5			# decrease time delay
	ret
SET_MAX_SPEED:
	movia	r7, 1				# set time delay to 1

POINT_TO_RIGHT_PLAYER:
	addi	r19, r19, 1			# increase the score of right player
	beq	r19, r15, RIGHT_WINS
	call	DIGIT_DISPLAY			# this will handle the displaying of the current score on the 7-digit display
	br	START_FOR_RIGHT			# start again in the middle and go right

POINT_TO_LEFT_PLAYER:
	addi	r18, r18, 1			# increase the score of left player
	beq	r18, r15, LEFT_WINS
	call 	DIGIT_DISPLAY			# this will handle the displaying of the current score on the 7-digit display
	br	START_FOR_LEFT			# start again in the middle and go left
	
RIGHT_WINS:
	movia	r17, 0b01110111000000000000011000111111	# represents "R 10" on the display
	stwio	r17, 0(r11)				# write it on the display
	movia	r7, 3000				# set time to display the winner
	call	WAIT					# display winner for a while
	br	END

LEFT_WINS:
	movia	r17, 0b00111000000000000000011000111111	# represents "L 10" on the display
	stwio	r17, 0(r11)				# write it on the display
	movia	r7, 3000				# set time to display the winner
	call	WAIT					# display winner for a while
	br	END

DIGIT_DISPLAY:
	subi	sp,  sp, 20				# reserve space on the stack 
	stw	r23, 0(sp)				# store registers to memory
	stw	r3, 4(sp)
	stw	r6, 8(sp)
	stw	r4, 12(sp)
	stw	r5, 16(sp)
		
	
	movia	r23, 0x08000000		# set the base address where the values of the digits will be saved
	
	/* save digits into memory*/
	movia	r6, 0b0111111			# r1 = "0" on the display
	stw	r6, 0(r23)			# save "0" at 0(r23)
	movia	r6, 0b0000110			# r1 = "1" on the display
	stw	r6, 4(r23)			# save "1" at 4(r23)
	movia	r6, 0b1011011			# r1 = "2"
	stw	r6, 8(r23)			# ...
	movia	r6, 0b1001111			# "3"
	stw	r6, 12(r23)			# ...
	movia	r6, 0b1100110			# "4"
	stw	r6, 16(r23)
	movia	r6, 0b1101101			# "5"
	stw	r6, 20(r23)
	movia	r6, 0b1111101			# "6"
	stw	r6, 24(r23)
	movia	r6, 0b0000111			# "7"
	stw	r6, 28(r23)
	movia	r6, 0b1111111			# "8"
	stw	r6, 32(r23)
	movia	r6, 0b1101111			# "9"
	stw	r6, 36(r23)
	
	movia	r3, 2				# set shift amount
	sll	r18, r18,r3			# shift both score values (multiply with 4 to use it as offset)
	sll	r19, r19, r3
	
	add	r4, r23, r18			# get address of the digit of the left players score
	add	r5, r23, r19			# get address of the digit of the right players score
	
	srl	r18, r18,r3			# reset score to its actual value
	srl	r19, r19, r3
	
	ldw	r4, 0(r4)			# load the digit of the left players score
	ldw	r5, 0(r5)			# load the digit of the right players score
	
	movia	r3, 24				# shift the left players digit to the left most position
	sll	r4, r4, r3			
	or	r6, r4, r5			# combine the scores so that it's "one picture" to display
	
	stwio	r6, 0(r11)			# display the scores
	
	ldw	r5, 16(sp)			# reload registers from memory
	ldw	r4, 12(sp)
	ldw	r6, 8(sp)
	ldw	r3, 4(sp)			
	ldw	r23, 0(sp)			
	addi	sp,  sp, 20			# release the reserved space on the stack 
	ret

END:
	movia	r17, 0b011110010101010001011110	# represents "End" on the display
	stwio	r17, 0(r11)				# write it on the display
	call	WAIT
	
/********************************************************************************
 * DATA SECTION
 */
.data

/* to count how much time has passed*/
.global TIME
TIME:
	.word 0
.end
