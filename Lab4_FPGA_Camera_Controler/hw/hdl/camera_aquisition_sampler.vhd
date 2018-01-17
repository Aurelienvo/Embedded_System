library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity camera_aquisition_sampler is
	port(		
		nReset			: in	std_logic;	
		clk				: in	std_logic;
		
	-- input camera controller signals
		enable			: in	std_logic;
	
	-- input CMOS sensor signals (TRDB-D5M camera)
		line_valid		: in	std_logic;	
		frame_valid		: in	std_logic;
		data				: in	std_logic_vector(11 downto 0); -- TODO way to configure "pixel" width ?
		
	-- output signals
		valid				: out	std_logic;
		valid_data		: out	std_logic_vector(11 downto 0) -- TODO way to configure "pixel" width ?
		
	-- TODO status output ! for MM slave component
	);
end camera_aquisition_sampler;

architecture rtl of camera_aquisition_sampler is

	-- FSM state register and signal
	type state_type is (IDLE, WAIT_END_FRAME, WAIT_START_FRAME, READ_FRAME);
	signal reg_state, next_state				: state_type							:= IDLE;
		
	-- FSM output registers and signals
	signal reg_valid, next_valid				: std_logic 							:= '0';
	signal reg_valid_data, next_valid_data	: std_logic_vector(11 downto 0)	:= (others => '0');
	

begin

	-- output processes
	valid <= reg_valid;
	valid_data <= reg_valid_data;

	-- state and output register process
	pFSM_SYNC: process (clk, nReset)
	begin
		if nReset = '0' then
			reg_state		<= IDLE;	
			reg_valid		<= '0';
			reg_valid_data	<= (others => '0');
			
		elsif rising_edge(clk) then
			reg_state		<= next_state;
			reg_valid		<= next_valid;--frame_valid and line_valid;
			reg_valid_data	<= next_valid_data;
		end if;
	end process pFSM_SYNC;
	
	-- next state and output logic process
	pFSM_COMB: process (reg_state, enable, line_valid, frame_valid, data)
	begin
		
		next_state			<= reg_state;
		--
		next_valid_data	<= (others => '0');
		next_valid			<= '0';
		
		case reg_state is
			when IDLE =>
				if enable = '1' then
					if frame_valid = '1' then
						next_state		<= WAIT_END_FRAME;
					else
						next_state		<= WAIT_START_FRAME;
					end if;
				end if;
				
			when WAIT_END_FRAME =>
				if frame_valid = '0' then
					next_state			<= WAIT_START_FRAME;
				end if;
				
			when WAIT_START_FRAME =>
				if line_valid = '1' then
					next_state			<= READ_FRAME;
					next_valid			<= '1';
					next_valid_data	<= data;
				end if;				
					
			when READ_FRAME =>
				if line_valid = '1' then
					next_valid			<= '1';
					next_valid_data	<= data;
				elsif frame_valid = '0' then
					next_state 			<= IDLE;
				end if;
				-- else (not L_VAL) => nothing to do, stay here and wait for row
			when others =>
		end case;		
	end process pFSM_COMB;
		
end rtl;
