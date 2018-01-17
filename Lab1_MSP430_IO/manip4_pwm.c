/*
 * manip4_pwm.c
 *
 *  Created on: 5 oct. 2017
 *      Author: AV
 */
#include <msp430.h>
#include "manip4_pwm.h"
#define  period 2  //ms
#define  SCLK 1000 // tick per ms



void PWM_Generator(float dutyms)
{
	//setup timerA1
	TA1CTL = TACLR;  					// reset TAR, divider and count direction

	// OPTION 1 use up mode
	TA1CTL = TASSEL_2 | MC_1 | ID_0;  	// source:SMCLK + mode:count continuous up to CCR0 + no divider
	TA1CCR0 = period*SCLK;
	TA1CCR1 = dutyms*SCLK;

	//setup CCR1 : PWM on TA1.1 => visible on P2.1 // Output mode 7 : Reset-Set
	TA1CCTL1 |= OUTMOD_7;

	// setup P2
	P2DIR |= BIT1;	// P2.1 as output
	P2SEL |= BIT1;	// P2.1 as peripheral (TA1.1)

	// note seems there is a HUGE number of ways to achieve the task...
	// + pay attention that the timer can only count up to 65535....
}
