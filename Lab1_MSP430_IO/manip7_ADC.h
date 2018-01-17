/*
 * manip7_ADC.h
 *
 *  Created on: 6 oct. 2017
 *      Author: LPI
 */

#ifndef MANIP7_ADC_H_
#define MANIP7_ADC_H_

void init_ADC(void);
void init_GPIO();
void init_CLK();
void init_TimerA0(float periodms);
void init_TimerA1(float periodms, float dutyms);
void run(void);

#endif /* MANIP7_ADC_H_ */
