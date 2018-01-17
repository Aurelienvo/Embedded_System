/*
 * manip3_delayms.c
 *
 *  Created on: 30 sept. 2017
 *      Author: AV
 */

#include <msp430.h>
#include "manip3_delayms.h"
#include <stdbool.h>

#define TICK_PER_MS 1000/8  // ~...
#define TICK_PER_COUNT 8
#define COUNT_PER_MS ((TICK_PER_MS) / (TICK_PER_COUNT))
#define MAX_COUNT ((unsigned int)(-1))
#define MAX_DELAY_MS ((MAX_COUNT) / (COUNT_PER_MS))


void delay_ms(unsigned int delayms)
{
	// SMCLK on P1.4 to verify with logic analyzer if clock freq. is ~ok
	//P1DIR |= BIT4;                            // P1.4 outputs
	//P1SEL |= BIT4;                            // P1.4 SMCLK

	//setup source of SMCLK and divider of SMCLK
	DCOCTL = CALDCO_1MHZ;  	// setup DCO
	BCSCTL2 = DIVS_3;  		// divider SMCLK: /8
	//setup timer
	TA0CTL = TACLR;  					// reset TAR, divider and count direction
	TA0CTL = TASSEL_2 | MC_1 | ID_3;  	// source:SMCLK + mode:count up to CCR0 + divider: /8
	if (delayms > MAX_DELAY_MS) {
		// TODO FIXME ... use multiple "interupt flags" before returning etc..
		while(true);
	}
	TA0CCR0 = delayms * COUNT_PER_MS;

	while(!(TA0CTL & CCIFG));  // busy wait for CCIFG TODO or TAIFG, see
	TA0CTL = MC_0;	// halt timer
	return;
}


