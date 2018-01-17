/*
 * manip1_GPIO.c
 *
 *  Created on: 29 sept. 2017
 *      Author: AV
 */
#include <msp430.h>
#include "manip1_GPIO.h"
#include "manip3_delayms.h"

/**
 * generate a PWM on P1.0
 */
void pwm_m1(void)
{
	// init P1.0
	P1DIR |= BIT0;  // P1.0 as output
	P1SEL &= ~BIT0; // P1.0 as I/O

	//PWM
	for(;;) {
		P1OUT |= BIT0;
		//__delay_cycles(100000);  // will take 100000 MCLK cycles
		delay_ms(500);
		P1OUT &= ~BIT0;
		//__delay_cycles(100000);
		delay_ms(500);
	}
}
