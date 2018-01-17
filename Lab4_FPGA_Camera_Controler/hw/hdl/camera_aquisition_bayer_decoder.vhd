

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity camera_aquisition_bayer_decoder is
	port(		
		nReset			: in	std_logic;	
		clk				: in	std_logic;
	
	-- input signals (bayer encoded data stream from camera aquisition sampler)
		valid_in			: in	std_logic;	
		valid_data		: in	std_logic_vector(11 downto 0);
		
	-- output signals (RGB 5-6-5 pixel stream toward FIFO DMA)
		valid_out		: out	std_logic;
		valid_pixel		: out	std_logic_vector(15 downto 0)
	);
end camera_aquisition_bayer_decoder;

architecture rtl of camera_aquisition_bayer_decoder is

	-- !show-ahead! scfifo
	component camera_aquisition_bayer_decoder_scfifo
		port (	aclr			: in	std_logic ;  -- async clear
					clock			: in	std_logic ;
					data			: in	std_logic_vector(11 downto 0);
					rdreq			: in	std_logic ;
					wrreq			: in	std_logic ;
					almost_full	: out	std_logic ;  -- when usedw >= 640
					empty			: out	std_logic ;
					full			: out	std_logic ;
					q				: out	std_logic_vector(11 downto 0);
					usedw			: out	std_logic_vector(9 downto 0)	);
	end component;
	
	-- TODO in/out from fifo's point of view
	signal fifo_data_out									: std_logic_vector(11 downto 0)	:= (others => '0');
	signal fifo_wrreq										: std_logic								:= '0';
	signal fifo_rdreq										: std_logic								:= '0';
	signal fifo_aclr										: std_logic								:= '0';
	--signal fifo_row_complete							: std_logic								:= '0';
	
	-- DECODE registers and signals
	signal reg_green_one, next_green_one			: std_logic_vector(11 downto 0)	:= (others => '0');
	signal reg_red, next_red							: std_logic_vector(11 downto 0)	:= (others => '0');
	signal reg_green_two, next_green_two			: std_logic_vector(11 downto 0)	:= (others => '0');
	signal reg_blue, next_blue							: std_logic_vector(11 downto 0)	:= (others => '0');
	
	-- FSM state register and signal
	type state_type is (IDLE, WRITE_FIFO, WAIT_START_ROW, READ_G1_B, READ_R_G2_DECODE);
	signal reg_state, next_state						: state_type							:= IDLE;
		
	-- FSM output registers and signals
	signal reg_valid_out, next_valid_out			: std_logic 							:= '0';
	signal reg_valid_pixel, next_valid_pixel		: std_logic_vector(15 downto 0)	:= (others => '0');
	

begin

	fifO_aclr	<= not nReset;
	camera_aquisition_bayer_decoder_scfifo_inst : camera_aquisition_bayer_decoder_scfifo port map (
		aclr			=> fifo_aclr,
		clock	 		=> clk,
		data			=> valid_data,
		rdreq			=> fifo_rdreq,
		wrreq			=> fifo_wrreq,
		almost_full	=> open,
		empty			=> open,
		full			=> open,
		q				=> fifo_data_out,
		usedw			=> open
	);


	-- output processes
	valid_out 	<= reg_valid_out;
	valid_pixel <= reg_valid_pixel;

	-- state and 'output' registers process
	pFSM_SYNC: process (clk, nReset)
	begin
		if nReset = '0' then
			reg_state			<= IDLE;	
			--
			reg_green_one		<= (others => '0');
			reg_blue				<= (others => '0');
			reg_red				<= (others => '0');
			reg_green_two		<= (others => '0');
			--
			reg_valid_out		<= '0';
			reg_valid_pixel	<= (others => '0');
			
		elsif rising_edge(clk) then
			reg_state			<= next_state;
			--
			reg_green_one		<= next_green_one;
			reg_blue				<= next_blue;
			reg_red				<= next_red;
			reg_green_two		<= next_green_two;
			--
			reg_valid_out		<= next_valid_out;
			reg_valid_pixel	<= next_valid_pixel;
			
		end if;
	end process pFSM_SYNC;
	
	-- next state and 'output' logic process
	pFSM_COMB: process (reg_state, reg_green_one, reg_red, reg_green_two, reg_blue, valid_in, fifo_data_out, valid_data)
	variable RED, BLUE	: std_logic_vector(4 downto 0)	:= (others => '0');
	variable GREEN			: std_logic_vector(5 downto 0)	:= (others => '0');
	begin
		
		--defaults
		next_state			<= reg_state;
		--
		next_valid_out		<= '0';
		next_valid_pixel	<= (others => '0');
		--
		fifO_rdreq			<= '0';
		fifO_wrreq			<= '0';
		--
		next_green_one		<= reg_green_one;
		next_red				<= reg_red;
		next_green_two		<= reg_green_two;
		next_blue			<= reg_blue;
		
		case reg_state is
			when IDLE =>
				if valid_in = '1' then
					next_state		<= WRITE_FIFO;
					fifO_wrreq		<= '1';
				end if;
					
			when WRITE_FIFO =>
				if valid_in = '1' then
					fifO_wrreq		<= '1';  -- keep writing
				else
					-- end of row, wait start of "2nd row"
					next_state		<= WAIT_START_ROW;
				end if;			
				
			when WAIT_START_ROW =>
				if valid_in = '1' then
					next_state		<= READ_G1_B;
					fifO_rdreq		<= '1';
					next_green_one	<= fifo_data_out;  -- from previous row (read into fifo)
					next_blue		<= valid_data;		 -- from sampler
				end if;
							
			when READ_G1_B =>
				-- here reg_green_one and reg_blue are loaded with meaningfull data
				if valid_in = '1' then
					next_state		<= READ_R_G2_DECODE;
					fifO_rdreq		<= '1';
					next_red			<= fifo_data_out;  -- from previous row (read into fifo)
					next_green_two	<= valid_data;		 -- from sampler
				else 
					-- ERROR... or ?? should not happen TODO error signal ?
				end if;
				
			when READ_R_G2_DECODE =>
				-- here reg_green_one, reg_blue, reg_red, reg_green_two are loaded with meaningfull data
				-- DECODE
				RED	:= (reg_red(11)	or reg_red(10)) & 
							(reg_red(9)		or reg_red(8) ) &
							(reg_red(7)		or reg_red(6) ) &
							(reg_red(5)		or reg_red(4) ) &
							(reg_red(3)		or reg_red(2));
				GREEN	:= (reg_green_one(11)	or reg_green_one(10) or 
							 reg_green_two(11)	or reg_green_two(10)) &
							(reg_green_one(9)		or reg_green_one(8) or 
							 reg_green_two(9) 	or reg_green_two(8)) &
							(reg_green_one(7)		or reg_green_one(6) or 
							 reg_green_two(7) 	or reg_green_two(6)) &
							(reg_green_one(5)		or reg_green_one(4) or 
							 reg_green_two(5) 	or reg_green_two(4)) &
							(reg_green_one(3)		or reg_green_one(2) or 
							 reg_green_two(3) 	or reg_green_two(2)) &
							(reg_green_one(1)		or reg_green_one(0) or 
							 reg_green_two(1) 	or reg_green_two(0));							
				BLUE	:= (reg_blue(11)	or reg_blue(10)) & 
							(reg_blue(9)	or reg_blue(8) ) &
							(reg_blue(7)	or reg_blue(6) ) &
							(reg_blue(5)	or reg_blue(4) ) &
							(reg_blue(3)	or reg_blue(2));
				
				next_valid_out		<= '1';
				next_valid_pixel	<= RED & GREEN & BLUE;
				
				if valid_in = '1' then
					next_state		<= READ_G1_B;
					fifO_rdreq		<= '1';
					next_green_one	<= fifo_data_out;  -- from previous row (read into fifo)
					next_blue		<= valid_data;		 -- from sampler
				else 
					-- end of row
					next_state		<= IDLE;
					-- TODO flush FIFO by precaution ??
				end if;
				
			when others =>
		end case;		
	end process pFSM_COMB;
		
end rtl;
