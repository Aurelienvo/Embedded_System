#include <msp430.h> 

#include "manip7_ADC.h"

int main(void)
{
	WDTCTL = WDTPW | WDTHOLD;	// disable watchdog timer // TODO configure it once all is done

	__bis_SR_register(GIE); //enable global interrupt

	run();
}
