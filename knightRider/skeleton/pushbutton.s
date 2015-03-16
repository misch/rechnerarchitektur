/* 
 * author(s):   Judith Fuog 
 *              Michele Wyss
 *
 * modified:    2011-May
 *
 */

.include "nios_macros.s"
.include "address_map.s"


/*****************************************************************************
 * Pushbutton - Interrupt Service Routine                                
 *                                                                          
******************************************************************************/
.global PUSHBUTTON_ISR
PUSHBUTTON_ISR:
	subi	sp,  sp, 12		# reserve space on the stack 
	stw	r2, 0(sp)
	stw	r3, 4(sp)
	stw	r4, 8(sp)
	
	movia	r2, PUSHBUTTON_BASE	# get the base address of the pushbuttons
	
	
	ldw	r3, 0xC(r2)		# read Edgecapture register
	movia	r4, 0b1000		# store value of KEY3
	beq	r3, r4, SLOW_DOWN	# check KEY3 for interrupt
	
	movia	r4, 0b0100		# store value of KEY2
	beq	r3, r4, RESET		# check KEY2 for interrupt
	
	movia	r4, 0b0010		# store value of KEY1
	beq	r3, r4, SPEED_UP	# check KEY1 for interrupt

SLOW_DOWN:
	addi	r7, r7, 20		# increase time delay
	stw	r0, 0xC(r2)		# reset Edgecapture register
	br	RESTORE
	
RESET:
	addi	r7, r0, 100 		# set time delay to default
	stw	r0, 0xC(r2)		# reset Edgecapture register
	br	RESTORE

SPEED_UP:
	subi	r7, r7, 20		# decrease time delay
	ble	r7, r0, RESET		# if time delay <= 0 reset it to default
	stw	r0, 0xC(r2)		# reset Edgecapture register
	br	RESTORE
	
RESTORE:
	ldw		r2, 0(sp)		# Restore all used register to previous 
	ldw		r3, 4(sp)
	ldw		r4, 8(sp)
	addi		sp,  sp, 12		# release the reserved space on the stack 

	ret

.end
	
