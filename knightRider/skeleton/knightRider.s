/* 
 * author(s):   Judith Fuog 
 *              Michele Wyss
 *
 * modified:    2011-May
 *
 */

.include "nios_macros.s"
.include "address_map.s"

/********************************************************************************
 * TEXT SECTION
 */
.text

/********************************************************************************
 * Entry point.
 */
.global _start
_start:
	/* set up sp and fp */
	movia 	sp, 0x007FFFFC			# stack starts from largest memory address 
	mov 		fp, sp

	/* This program exercises a few features of the DE1 basic computer. 
	 *
	 * It performs the following: 
	 *     1. displays a red light wandering from LEDR0 to LEDR9 and back again (and so on...)
	 *     2. speed of light can be increased by KEY3, decreased by KEY1 and initial value can be restored by KEY2
	 */	
		
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
	movia	r3, 0b1			# set shit amount
	movia	r2, 0b1000000000	# light position before changing direction to right
	movia	r10, 0b0000000001	# light position before changing direction to left
	movia	r7, 100			# set up timer
	movia	r9, TIME		# address of time counter in r9

	/* start wandering light */
START_RIGHT:
	movi	r5, 0b0000000001	# start with the right most light
	br 	GO_LEFT
	
GO_LEFT:
	beq	r5, r2, START_LEFT	# if the left side is reached, start from left to right
	call	DISPLAY			# turn on current light
	sll	r5, r5,r3		# initialize next light (left shift)
	call	WAIT
	br	GO_LEFT
	
WAIT:	ldw	r6, 0(r9)		# load current time
	blt	r6, r7, WAIT		# wait longer
	stwio	r0, 0(r9)		# reset timer
	ret				# return
	
START_LEFT:
	movi	r5, 0b1000000000	# start with the left most light
	br	GO_RIGHT
GO_RIGHT:
	beq 	r5, r10, START_RIGHT	# if the right side is reached, start from right to left
	call	DISPLAY			# turn on current light
	srl	r5, r5, r3		# initialize next light (right shift)
	call	WAIT
	br	GO_RIGHT

DISPLAY:
	stwio	r5, 0(r4)		# turn on current light
	ret
	
/********************************************************************************
 * DATA SECTION
 */
.data

/* to count how much time has passed*/
.global TIME
TIME:
	.word 0
/* TODO: Task (c) you may also want to add things here (but you don't need to) */
.end
