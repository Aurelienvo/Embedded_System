library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cam_controller is
	port(
	-- main clock and reset
		clk						: in std_logic;
		nReset					: in std_logic;
		
	-- avalon interfaces signals
		-- slave
		AS_Addr					: in	std_logic_vector(2 downto 0);
		AS_Read					: in	std_logic;
		AS_Write					: in	std_logic;
		AS_ReadData				: out	std_logic_vector(31 downto 0);
		AS_WriteData			: in	std_logic_vector(31 downto 0);
		-- master :
		AM_Addr					: out std_logic_vector(31 downto 0);
		AM_ByteEnable			: out std_logic_vector( 3 downto 0);
		AM_Write					: out std_logic ;
		AM_DataWrite			: out std_logic_vector(31 downto 0);
		AM_BurstCount			: out std_logic_vector(31 downto 0);
		AM_WaitRequest			: in	std_logic;
	
	-- TRDB-D5M camera sensor signals
		camera_line_valid		: in	std_logic;	
		camera_frame_valid	: in	std_logic;
		camera_data				: in	std_logic_vector(11 downto 0); -- TODO way to configure "pixel" width ?
		camera_pixclk			: in	std_logic;
		
	-- etc... todo debug signals
		pixel_out				: out	std_logic_vector(15 downto 0);
		valid_out				: out std_logic
	
	);
end cam_controller;

architecture struct of cam_controller is

	-- camera acquisition module------------------------
	component camera_aquisition
	port(
		nReset				: in std_logic;

	--	input from Avalon MM-slave
		enable				: in std_logic;
	
	-- input TRDB-D5M camera sensor signals 
		line_valid			: in	std_logic;	
		frame_valid			: in	std_logic;
		data					: in	std_logic_vector(11 downto 0); -- TODO way to configure "pixel" width ?
		clk_in				: in	std_logic;
		
	-- output 16 bit pixel (RGB 5-6-5)
		pixel_out			: out	std_logic_vector(15 downto 0);
		valid_out			: out std_logic;
		clk_out				: out	std_logic
	);
	end component;
	signal camera_aquisition_pixel_out				: std_logic_vector(15 downto 0);
	signal camera_aquisition_valid_out				: std_logic;
	signal camera_aquisition_clk_out					: std_logic;
	----------------------------------------------------
	
	-- DCFIFO (camera acquisition <-> DMA)--------------
	component cam_controller_dcfifo
	port(	
		aclr					: in std_logic;
		data					: in std_logic_vector(15 downto 0);
		rdclk					: in std_logic ;
		rdreq					: in std_logic ;
		wrclk					: in std_logic ;
		wrreq					: in std_logic ;
		q						: out std_logic_vector(31 downto 0);
		rdusedw				: out std_logic_vector( 6 downto 0)
	);
	end component;
	signal cam_controller_dcfifo_aclr_in			: std_logic;
	signal cam_controller_dcfifo_data_out			: std_logic_vector(31 downto 0);
	signal cam_controller_dcfifo_rdusedw_out		: std_logic_vector( 6 downto 0);
	----------------------------------------------------
	
	-- Avalon Master module (DMA)-----------------------
	component DMA
	port(	
		clk					: in	std_logic;
		nReset				: in	std_logic;
		
		-- from/to DCFIFO (camera acquisition <-> DMA)
		fifo_q				: in	std_logic_vector(31 downto 0);
		fifo_rdusedw		: in	std_logic_vector( 6 downto 0);
		fifo_rdreq			: out	std_logic;

		-- from/to avalon slave module	
		MM_slave_addr				: in	std_logic_vector(31 downto 0);
		MM_slave_burst_length	: in	std_logic_vector(31 downto 0);
		MM_slave_frame_length	: in	std_logic_vector(31 downto 0);
		MM_slave_ack				: in	std_logic;
		MM_slave_status			: out	std_logic_vector( 1 downto 0);
		MM_slave_enable			: in	std_logic;
		
		-- avalon master interface signals	
		AM_Addr					: out std_logic_vector(31 downto 0);
		AM_ByteEnable			: out std_logic_vector( 3 downto 0);
		AM_Write					: out std_logic;
		AM_DataWrite			: out std_logic_vector(31 downto 0);
		AM_BurstCount			: out std_logic_vector(31 downto 0);
		AM_WaitRequest			: in	std_logic
	);
	end component;
	--TODO
	signal DMA_rdreq_out									: std_logic;
	signal DMA_status_out								: std_logic_vector(1 downto 0);
	----------------------------------------------------
	
	-- Avalon-MM slave module (configuration/ctrl/status)
	component avalon_slave
	port(
	-- Avalon interface signals
		clk 			: in	std_logic;
		nReset 		: in	std_logic;
		address 		: in	std_logic_vector(2 downto 0);
		read 			: in	std_logic;
		write 		: in	std_logic;
		readdata 	: out	std_logic_vector(31 downto 0);
		writedata 	: in	std_logic_vector(31 downto 0);
	-- from/to DMA and camera aquisition
		enable			: out	std_logic;
		buffer_addr		: out std_logic_vector(31 downto 0);
		frame_length	: out std_logic_vector(31 downto 0);
		burst_length	: out std_logic_vector(31 downto 0);
		DMA_ack_frame	: out std_logic;
		DMA_status		: in	std_logic_vector( 1 downto 0)
	);
	end component;
	--TODO
	signal avalon_slave_enable_out					: std_logic;
	signal avalon_slave_buffer_addr_out				: std_logic_vector(31 downto 0);
	signal avalon_slave_frame_length_out			: std_logic_vector(31 downto 0);
	signal avalon_slave_burst_length_out			: std_logic_vector(31 downto 0);
	signal avalon_slave_ack_frame_out				: std_logic;
	----------------------------------------------------
begin

	-- camera acquisition module-----------------------
	camera_aquisition_inst : camera_aquisition port map (
		nReset		=> nReset,
			
		--	input from Avalon MM-slave
		enable		=> avalon_slave_enable_out,
	
		-- input TRDB-D5M camera sensor signals 
		line_valid	=> camera_line_valid,
		frame_valid	=> camera_frame_valid,
		data			=> camera_data,
		clk_in		=> camera_pixclk,
		
		-- output 16 bit pixel (RGB 5-6-5)
		pixel_out	=> camera_aquisition_pixel_out,
		valid_out	=> camera_aquisition_valid_out,
		clk_out		=> camera_aquisition_clk_out
	);
	-- debug out
	pixel_out <= camera_aquisition_pixel_out;
	valid_out <= camera_aquisition_valid_out;
	---------------------------------------------------
	
	-- camera acquisition <-> DMA DCFIFO---------------
	cam_controller_dcfifo_aclr_in		<= not nReset;
	cam_controller_dcfifo_inst : cam_controller_dcfifo port map (
		aclr		=> cam_controller_dcfifo_aclr_in,
		data		=> camera_aquisition_pixel_out,
		rdclk		=> clk,
		rdreq		=> DMA_rdreq_out,
		wrclk		=> camera_aquisition_clk_out,
		wrreq		=> camera_aquisition_valid_out,
		q			=> cam_controller_dcfifo_data_out,
		rdusedw	=> cam_controller_dcfifo_rdusedw_out
	);
	---------------------------------------------------

	-- DMA Avalon master module------------------------
	DMA_inst : DMA port map (
		clk							=> clk,
		nReset						=> nReset,
		
		-- from/to DCFIFO (camera acquisition <-> DMA) TODO names..
		fifo_q						=> cam_controller_dcfifo_data_out,
		fifo_rdusedw				=> cam_controller_dcfifo_rdusedw_out,
		fifo_rdreq					=> DMA_rdreq_out,

		-- from/to avalon slave module TODO names.. 
		MM_slave_addr				=> avalon_slave_buffer_addr_out,
		MM_slave_burst_length	=> avalon_slave_burst_length_out,
		MM_slave_frame_length	=> avalon_slave_frame_length_out,
		MM_slave_ack				=> avalon_slave_ack_frame_out,
		MM_slave_status			=> DMA_status_out,
		MM_slave_enable			=> avalon_slave_enable_out,
		
		-- avalon master interface signals	
		AM_Addr						=> AM_Addr,
		AM_ByteEnable				=> AM_ByteEnable,
		AM_Write						=> AM_Write,
		AM_DataWrite				=> AM_DataWrite,
		AM_BurstCount				=> AM_BurstCount,
		AM_WaitRequest				=> AM_WaitRequest
	);
	---------------------------------------------------
	
	-- Avalon-MM slave module (configuration/ctrl/status)
	-- TODO
	avalon_slave_inst	: avalon_slave port map (
	-- Avalon interface signals
		clk				=> clk,
		nReset			=> nReset,
		address			=> AS_Addr,
		read				=> AS_Read,
		write				=> AS_Write,
		readdata			=> AS_ReadData,
		writedata		=> AS_WriteData,
	-- from/to DMA and camera aquisition
		enable			=> avalon_slave_enable_out,
		buffer_addr		=> avalon_slave_buffer_addr_out,
		frame_length	=> avalon_slave_frame_length_out,
		burst_length	=> avalon_slave_burst_length_out,
		DMA_ack_frame	=> avalon_slave_ack_frame_out,
		DMA_status		=> DMA_status_out
	);
	---------------------------------------------------

end struct;
