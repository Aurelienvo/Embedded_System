/*
 * manip5_interruption.c
 *
 *  Created on: 6 oct. 2017
 *      Author: AV
 */
#include <msp430.h>
#include "manip5_interruption.h"
#include <stdbool.h>

#define TICK_PER_MS 1000/8  // ~...
#define TICK_PER_COUNT 8
#define COUNT_PER_MS ((TICK_PER_MS) / (TICK_PER_COUNT))
#define MAX_COUNT ((unsigned int)(-1))
#define MAX_DELAY_MS ((MAX_COUNT) / (COUNT_PER_MS))


// TimerA0_CCR0 ISR
/*
#pragma vector=TIMER0_A0_VECTOR
__interrupt void TimerA0(void)
{
	TA0CCTL0 &= ~CCIFG;  //clear interrupt request
	//toggle pin;
	P1OUT = ~P1OUT; // FIXME toggle only BIT0
	return;
}
*/
void toggle_pin_timer_setup(unsigned int delayms)
{
	//config GPIO P1.0
	P1DIR |= BIT0;  // P1.0 as output
	P1SEL &= ~BIT0; // P1.0 as I/O

	//setup source of SMCLK and divider of SMCLK
	DCOCTL = CALDCO_1MHZ;  	// setup DCO
	BCSCTL2 = DIVS_3;  		// divider SMCLK: /8
	//setup timer
	TA0CTL = TACLR;  					// reset TAR, divider and count direction
	TA0CTL = TASSEL_2 | MC_1 | ID_3;	//source:SMCLK + mode:count up to CCR0 + divider: /8

	TA0CCR0 = delayms * COUNT_PER_MS;

	// configure CCR0 to raise interrupts
	TA0CCTL0 = CCIE;

	while(true);
	//TA0CTL = MC_0;	// halt timer
}
