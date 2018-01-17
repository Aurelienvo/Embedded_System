//UTF-8
//c99
/*
 * camera_controller.h
 *
 *  Created on: 17 dec. 2017
 *      Author: Lucas PIRES
 */

#ifdef __cplusplus
	extern "C" {
#endif

#ifndef CAMERA_CONTROLLER_H
	#define CAMERA_CONTROLLER_H
	#include <inttypes.h>
	#include <stdbool.h>

	#define FRAME_LENGTH (150 << 10)  // 320*240*16/8 bytes = 150KiB
	#define DMA_BURST_LENGTH 16  // words of 32bits => 1 burst = 32 pixels (=> 1 frame transfer needs 2400 bursts)

	/**
	 * avalon mm-slave registers
	 */
	enum cam_controller_registers {
		reg_status,  // R
		reg_dma_write_addr,  // R/W
		reg_dma_frame_lenght,// R/W
		reg_dma_burst_length,// R/W
		reg_ctrl	 // W
	};

	/**
	 * valid status flags for reg_status
	 */
	enum cam_controller_status {
		// TODO unnecessarily complicated.. if time change for 0->IDLE 1->RUNNING 2->DONE
		IDLE = 1,
		DONE = 2,
		RUNNING = !DONE | !IDLE,
		WAITING_ACK = DONE | !IDLE // = DONE = frame ready in memory
	};

	/**
	 * valid control flags for reg_ctrl
	 */
	enum cam_controller_ctrl {
		CAPTURE_FRAME = 1,
		ACK_FRAME = 2
	};

	/**
	 * read register
	 * @param reg register word address (from slave point of view) (see enum cam_controller_registers)
	 */
	uint32_t register_read(enum cam_controller_registers reg);

	/**
	 * write register
	 * @param reg register word address (from slave point of view) (see enum cam_controller_registers)
	 * @param data data to write
	 */
	void register_write(enum cam_controller_registers reg, uint32_t data);

	/**
	 * check R/W on MM-registers
	 */
	int check_mm_slave();

	/**
	 * check R/W HPS DDR3 (256 MB)
	 */
	int check_hps_ddr3(bool quick);

	/**
	 * initialize and start sahand's cmos_sensor_output_generator
	 */
	int init_and_start_camera_emulator();

	/**
	 * initialize the DMA with its long term default paramters (framelength and burstlength)
	 */
	int init_camera_controller();

#endif

#ifdef __cplusplus
	}
#endif
