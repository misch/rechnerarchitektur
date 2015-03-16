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
	 * 	1. reads the parallel port attached to the SW switches and
	 * 	2. assigns the SW values to the red LEDR
	 */

DO_DISPLAY:
	/* load slider switch value to display */
	movia	r15, SLIDER_SWITCH_BASE
	ldwio		r16, 0(r15)		

	/* write to red LEDs */
	movia	r15, RED_LED_BASE
	stwio		r16, 0(r15)

	br 		DO_DISPLAY
.end

