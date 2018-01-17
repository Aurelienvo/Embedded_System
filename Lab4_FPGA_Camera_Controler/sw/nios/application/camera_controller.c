//UTF-8
//c99
/*
 * camera_controller.c
 *
 *  Created on: 17 dec. 2017
 *      Author: Lucas PIRES
 */
#include <inttypes.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#include "io.h"
#include "system.h"

#include "camera_controller.h"
#include "cmos_sensor_output_generator/cmos_sensor_output_generator.h"
#include "cmos_sensor_output_generator/cmos_sensor_output_generator_regs.h"

#define CENSOR_FRAME_WIDTH 640
#define CENSOR_FRAME_HEIGHT 480

uint32_t register_read(enum cam_controller_registers reg)
{
	return IORD_32DIRECT(CAM_CONTROLLER_0_BASE, reg * CAM_CONTROLLER_0_SPAN/8);
}

void register_write(enum cam_controller_registers reg, uint32_t data)
{
	IOWR_32DIRECT(CAM_CONTROLLER_0_BASE, reg * CAM_CONTROLLER_0_SPAN/8, data);
}

int check_mm_slave()
{
	printf("checking register R/W\n");
	uint32_t frame_addr = 0;
	uint32_t frame_length = 150 << 10;  // bytes
	uint32_t burst_length = 16;  // words

	// write
	register_write(reg_dma_write_addr, frame_addr);
	register_write(reg_dma_frame_lenght, frame_length);
	register_write(reg_dma_burst_length, burst_length);

	// read
	frame_addr = 42;
	frame_length = 0;
	burst_length = 0;

	frame_addr = register_read(reg_dma_write_addr);
	frame_length = register_read(reg_dma_frame_lenght);
	burst_length = register_read(reg_dma_burst_length);

	uint32_t status = register_read(reg_status);

	if (frame_addr != 0) {
		fprintf(stderr, "failed to read/write frame addr, %"PRIu32"\n", frame_addr);
		return EXIT_FAILURE;
	}
	if (frame_length != (150 << 10)) {
		fprintf(stderr, "failed to read/write frame length, %"PRIu32"\n", frame_length);
		return EXIT_FAILURE;
	}
	if (frame_length != (150 << 10)) {
		fprintf(stderr, "failed to read/write burst length, %"PRIu32"\n", burst_length);
		return EXIT_FAILURE;
	}
	if (status != IDLE) {
		fprintf(stderr, "failed, status should be 1 %"PRIu32"", status);
		return EXIT_FAILURE;
	}

	/*// TODO update vhdl to allow reset without reprogramm and then test that reset is working..
	register_write(reg_ctrl, CAPTURE_FRAME);
	status = register_read(reg_status);
	if (status != RUNNING) {
		fprintf(stderr, "failed, status should be 0 %"PRIu32"", status);
		return EXIT_FAILURE;
	}*/

	return EXIT_SUCCESS;
}

int check_hps_ddr3(bool quick)
{
	printf("checking HPS DDR3 R/W:\n");
	printf("HPS_0_briges base address: %#010x\n", HPS_0_BRIDGES_BASE);
	printf("HPS_0_briges span: %d\n", HPS_0_BRIDGES_SPAN);
	const uint32_t ONE_MB = 1024*1024;

	uint32_t megabyte_count = 0;
	for (uint32_t i = 0; i < HPS_0_BRIDGES_SPAN; i += sizeof(uint32_t)) {
		// Print progress through 256 MB memory available through address span expander
		if ((i % ONE_MB) == 0) {
		  printf("megabyte_count = %" PRIu32 "\n", megabyte_count);
		  megabyte_count++;
		}
		if (quick && megabyte_count >= 2) {
			break;
		}

		uint32_t addr = HPS_0_BRIDGES_BASE + i;

		// Write through address span expander
		uint32_t writedata = i;
		IOWR_32DIRECT(addr, 0, writedata);

		// Read through address span expander
		uint32_t readdata = IORD_32DIRECT(addr, 0);

		// Check if read data is equal to written data
		if (writedata != readdata) {
			return EXIT_FAILURE;
		}
	}
	return EXIT_SUCCESS;
}

int init_and_start_camera_emulator()
{
	cmos_sensor_output_generator_dev cmos_sensor_output_generator = cmos_sensor_output_generator_inst(CMOS_SENSOR_OUTPUT_GENERATOR_0_BASE,
																											  CMOS_SENSOR_OUTPUT_GENERATOR_0_PIX_DEPTH,
																											  CMOS_SENSOR_OUTPUT_GENERATOR_0_MAX_WIDTH,
																											  CMOS_SENSOR_OUTPUT_GENERATOR_0_MAX_HEIGHT);
	cmos_sensor_output_generator_init(&cmos_sensor_output_generator);

	cmos_sensor_output_generator_stop(&cmos_sensor_output_generator);

	cmos_sensor_output_generator_configure(&cmos_sensor_output_generator,
											CENSOR_FRAME_WIDTH,
											CENSOR_FRAME_HEIGHT,
											CMOS_SENSOR_OUTPUT_GENERATOR_CONFIG_FRAME_FRAME_BLANK_MIN,
											CMOS_SENSOR_OUTPUT_GENERATOR_CONFIG_FRAME_LINE_BLANK_MIN,
											CMOS_SENSOR_OUTPUT_GENERATOR_CONFIG_LINE_LINE_BLANK_MIN,
											CMOS_SENSOR_OUTPUT_GENERATOR_CONFIG_LINE_FRAME_BLANK_MIN);

	cmos_sensor_output_generator_start(&cmos_sensor_output_generator);
	return EXIT_SUCCESS;
}

int init_camera_controller(uint32_t frame_length, uint32_t dma_burst_length)
{
	// DMA long term settings
	register_write(reg_dma_frame_lenght, frame_length);
	register_write(reg_dma_burst_length, dma_burst_length);
}

