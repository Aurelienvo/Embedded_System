//UTF-8
//c99
/*
 * main.c
 *
 *  Created on: 17 dec. 2017
 *      Author: Lucas PIRES
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "camera_controller.h"
#include "system.h"

int main()
{
	printf("Hello from Nios II cam_controller design !\n");
	printf("quick checks:\n");
	if (check_mm_slave() != EXIT_SUCCESS) {
		fprintf(stderr, "something wrong with our cam_controller registers\n");
		return EXIT_FAILURE;
	}
	if (check_hps_ddr3(true) != EXIT_SUCCESS) {
		fprintf(stderr, "something wrong with the HPS DDR3\n");
		return EXIT_FAILURE;
	}
	printf("quick checks passed\n");

	// init camera and DMA
	init_and_start_camera_emulator();
	init_camera_controller(FRAME_LENGTH, DMA_BURST_LENGTH);
	uint32_t buffer1 = 0x0;
	uint32_t buffer2 = buffer1 + FRAME_LENGTH;  // TODO add safety margin ?
	uint32_t buffer = buffer1;
	for(;;) {
		// configure DMA buffer address
		register_write(reg_dma_write_addr, buffer);

		// start capture
		register_write(reg_ctrl, CAPTURE_FRAME);

		// wait frame written to memory
		uint32_t status;
		do {
			status = register_read(reg_status);
		} while (status != WAITING_ACK);

		// check frame content
		char* filename = "/mnt/host/image.ppm";
		FILE *foutput = fopen(filename, "w");
		if (!foutput) {
			printf("Error: could not open \"%s\" for writing\n", filename);
			return false;
		}
		/* Use fprintf function to write to file through file pointer */
		fprintf(foutput, "Writing text to file\n");
		// ack frame
		// exchange buffers
		buffer = (buffer == buffer1) ? buffer2 : buffer1;
		// loop
	}
	return EXIT_SUCCESS;
}
