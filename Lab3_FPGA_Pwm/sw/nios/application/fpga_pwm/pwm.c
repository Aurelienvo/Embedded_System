// C99
/*
 * Authors : Aurélien Vouaillat, Lucas Pires
 *
 */

#include <stdio.h>
#include <inttypes.h>
#include <stdbool.h>
#include "system.h"
#include "io.h"


// TODO header pwm_slave with more helper functions
enum pwm_registers {
	dutyReg,
	periodReg,
	clkdivReg,
	commandReg,
	statusReg
};

uint16_t register_read(enum pwm_registers reg)
{
	return IORD_16DIRECT(PWM_SLAVE_0_BASE, reg * PWM_SLAVE_0_SPAN/8);
}

void register_write(enum pwm_registers reg, uint16_t data)
{
	IOWR_16DIRECT(PWM_SLAVE_0_BASE, reg * PWM_SLAVE_0_SPAN/8, data);
}

void test(bool reset)
{
	uint16_t duty = 1337;
	uint16_t period = 1338;
	uint16_t clkdiv = 1339;

	// write
	register_write(dutyReg, duty);
	register_write(periodReg, period);
	register_write(clkdivReg, clkdiv);

	// read
	duty = 0;
	period = 0;
	clkdiv = 0;

	duty = register_read(dutyReg);
	period = register_read(periodReg);
	clkdiv = register_read(clkdivReg);

	uint16_t status = register_read(statusReg);

	if (duty != 1337) {
		fprintf(stderr, "failed to write read duty, %"PRIu16"\n", duty);
	}
	if (period != 1338) {
		fprintf(stderr, "failed to write read period, %"PRIu16"\n", period);
	}
	if (clkdiv != 1339) {
		fprintf(stderr, "failed to write read clkdiv, %"PRIu16"\n", clkdiv);
	}
	if (status != 0) {
		fprintf(stderr, "failed, status should be 0 %"PRIu16"", status);
	}

	register_write(commandReg, 1);  // start
	status = register_read(statusReg);
	if (status != 1) {
		fprintf(stderr, "failed, status(0) should be 1 if started %"PRIu16"", status);
	}

	register_write(commandReg, 0);  // stop
	status = register_read(statusReg);
	if (status != 0) {
		printf("failed, status(0) should be 0 if stopped %"PRIu16"", status);
	}

	register_write(commandReg, 1);  // start again

	if (reset) {
		// !! manual reset here !!

		// read
		duty = register_read(dutyReg);
		period = register_read(periodReg);
		clkdiv = register_read(clkdivReg);
		status = register_read(statusReg);

		if (duty != 0) {
			fprintf(stderr, "failed to reset duty, %"PRIu16"\n", duty);
		}
		if (period != 0) {
			fprintf(stderr, "failed to reset period, %"PRIu16"\n", period);
		}
		if (clkdiv != 0) {
			fprintf(stderr, "failed to reset clkdiv, %"PRIu16"\n", clkdiv);
		}
		if (status != 0) {
			fprintf(stderr, "failed to reset status should be 0, %"PRIu16"", status);
		}
	}
}

/***
 * duty, period : in tenth of ms
 */
int set_pwm(int duty, int period, bool polarity)
{
	if (duty >= period) {
		fprintf(stderr, "illegal settings, duty >= period");
		return 1;
	}

	const uint16_t START = 0x0001;
	// TODO polarity doc
	const uint16_t POLARITY = polarity ? 0x0002 : 0x0000;

	//ensure pwm_slave is stopped
	register_write(commandReg, 0);
	//configure
	register_write(clkdivReg, 5000); // clk freq is 50MHz => 50000 ticks / ms => 5000 ticks for a 10th of ms => pwm clk freq is 10 KHz
	register_write(dutyReg, duty);
	register_write(periodReg, period);
	//start
	register_write(commandReg, START | POLARITY);
	return 0;
}

int main()
{
	printf("Hello from Nios II!\n");

	test(false);  // basic test read write

	set_pwm(12, 20, 0);

	printf("status: %"PRIu16"\n", register_read(statusReg));

	for(int i=0; i<1000000; ++i);

	set_pwm(12, 20, 1);

	printf("status: %"PRIu16"\n", register_read(statusReg));


	while(1);
	return 0;
}
