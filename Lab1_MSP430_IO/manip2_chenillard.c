/*
 * manip2_chenillard.c
 *
 *  Created on: 29 sept. 2017
 *      Author: AV
 */

#include <msp430.h>
#include "manip2_chenillard.h"

void chenillard(void)
{
	// init P2.0-5 as I/O output
	P2DIR |= (BIT5 | BIT4 | BIT3 | BIT2 | BIT1 | BIT0);  // 1 => output
	P2SEL &= ~(BIT5 | BIT4 | BIT3 | BIT2 | BIT1 | BIT0); // 0 => I/O

	// chenillard
	int i;
	while(1) {
		P2OUT = BIT0;
		for(i = 0; i <= 5; ++i) {
			__delay_cycles(100000);
			P2OUT <<= 1;
		}
	}
}
