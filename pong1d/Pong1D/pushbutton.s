/* 
 * author(s):   Ruth Schuler 
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
	
	
	ldw	r4, 0xC(r2)		# read Edgecapture register and load it into r4
	or	r14, r4, r14		# store all pressed buttons in r14
	stw	r0, 0xC(r2)		# reset Edgecapture register

	ldw	r4, 8(sp)
	ldw	r3, 4(sp)	# Restore all used register to previous
	ldw	r2, 0(sp)	
	addi	sp,  sp, 12	# release the reserved space on the stack 

	ret

.end
	
