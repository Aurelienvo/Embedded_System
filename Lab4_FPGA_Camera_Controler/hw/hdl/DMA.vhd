library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DMA is

	port(
		clk					: in	std_logic;
		nReset				: in	std_logic;
		
		-- from/to DCFIFO (camera acquisition <-> DMA)
		-- TODO names => ~data_in, data_available, data_ack
		fifo_q				: in	std_logic_vector(31 downto 0);
		fifo_rdusedw		: in	std_logic_vector( 6 downto 0);
		fifo_rdreq			: out	std_logic;

		-- from/to Avalon-MM slave module (configuration)
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
	
end DMA;

architecture rtl of DMA is

	-- fsm state register and signal
	type state_type is (IDLE, WAIT_DATA, WRITE_DATA, WAIT_ACK);
	signal reg_state, next_state					: state_type							:= IDLE;
		
	-- fsm output registers and signals
	constant status_running							: std_logic_vector             	:= "00"; -- not done, not idle
	constant status_idle								: std_logic_vector					:= "01"; -- not done, idle
	constant status_wait_ack						: std_logic_vector					:= "10"; -- done, not idle

	signal reg_addr, next_addr						: std_logic_vector(31 downto 0)	:= (others => '0');
	signal reg_byte_enable, next_byte_enable	: std_logic_vector( 3 downto 0)	:= (others => '0');
	signal reg_write_mem, next_write_mem		: std_logic								:= '0';
	signal reg_data_write, next_data_write		: std_logic_vector(31 downto 0)	:= (others => '0');
	signal reg_burst_count, next_burst_count  : std_logic_vector(31 downto 0)  := (others => '0'); -- dans le cas ou burst_length==32
	signal reg_status, next_status				: std_logic_vector( 1 downto 0)  := "01";  -- not done and idle
	
	-- intern registers and signal
	signal reg_countburst, next_countburst		: unsigned(31 downto 0)				:= (others => '0');
	signal reg_countlength, next_countlength	: unsigned(31 downto 0)				:= (others => '0');-- dans le cas ou les burst sont tres courts

begin

	-- output processes
	AM_Addr		 		<= reg_addr;
	AM_ByteEnable		<= reg_byte_enable;
	AM_Write				<= reg_write_mem;
	AM_DataWrite		<= reg_data_write;
	AM_BurstCount		<= reg_burst_count;
	MM_slave_status	<= reg_status;
	
	-- state and 'output' registers process
	pFSM_SYNC: process(clk, nReset)
	begin
		if nReset = '0' then
			reg_state			<= idle;
			--
			reg_addr				<= (others => '0');
			reg_byte_enable	<= (others => '0');
			reg_write_mem		<= '0';
			reg_data_write		<= (others => '0');
			reg_burst_count	<= (others => '0');
			--
			reg_countburst		<= (others => '0');
			reg_countlength	<= (others => '0');
			--
			reg_status			<= status_idle;
			
		elsif rising_edge(clk) then
			reg_state			<= next_state;
			--
			reg_addr				<= next_addr;
			reg_byte_enable	<= next_byte_enable;
			reg_write_mem		<= next_write_mem;
			reg_data_write		<= next_data_write;
			reg_burst_count	<= next_burst_count;
			--
			reg_countburst		<= next_countburst;
			reg_countlength	<= next_countlength;
			--
			reg_status			<= next_status;
		end if;
	end process pFSM_SYNC;
	
	-- next state and 'output' logic process
	pFSM_COMB: process(	reg_state, MM_slave_burst_length, MM_slave_frame_length, fifo_rdusedw, am_waitrequest, reg_countburst, reg_countlength, 
								reg_addr, reg_byte_enable,reg_data_write, reg_burst_count, reg_status, fifo_q, MM_slave_addr, MM_slave_ack,MM_slave_enable)
	begin
		
		--defaults TODO
		next_state       <= reg_state;
		--
		next_addr        <= reg_addr;
		next_byte_enable <= reg_byte_enable; -- TODO never reset => bug or better get rid of register
		next_write_mem   <= '0';
		next_data_write  <= reg_data_write;
		next_burst_count <= reg_burst_count;
		--
		fifo_rdreq		  <= '0';
		--
		next_countburst  <= reg_countburst;
		next_countlength <= reg_countlength;
		--
		next_status		  <= reg_status;
		
		case reg_state is
			when IDLE =>
				if (MM_slave_enable = '1') then
					next_state			<= WAIT_DATA;
					next_countlength	<= (others => '0');
					next_status			<= status_running;
				end if;
				
			when WAIT_DATA =>
				if fifo_rdusedw = MM_slave_burst_length(6 downto 0) then  -- TODO documente in register map
					next_state 			<= WRITE_DATA;
					next_countburst	<= (others => '0');					
					-- Avalon request
					if reg_countlength > 0 then --check si c'est pas le premier burst de la frame.
						next_addr			<= std_logic_vector (unsigned(reg_addr) +  64); -- addr of next burst
					
					elsif reg_countlength = 0 then 
						next_addr			<= MM_slave_addr; -- stock pour le 1er burst, la premiere addresse d'ecriture dans reg_addr, apres MM_slave_addr useless
					end if;
					next_burst_count 		<= MM_slave_burst_length; -- TODO rename burst length ?
					next_data_write 		<= fifo_q;
					next_byte_enable 		<= (3 downto 0 => '1');
					
					----------ATT
					next_write_mem 		<= '1';-- start
				end if; -- sinon je ne fais rien
				
			when WRITE_DATA => 
				
				if am_waitrequest = '0'  and  reg_countburst < unsigned(MM_slave_burst_length) - 1 then
					next_countburst	<= reg_countburst + 1;
					fifo_rdreq 			<= '1'; -- ack previous/ request new word from fifo
					next_data_write	<= fifo_q;
					next_write_mem    <= '1';
					-- remain in WRITE_DATA to complete burst
					
				elsif am_waitrequest = '0'  and reg_countburst = unsigned(MM_slave_burst_length) - 1 then
				
					if reg_countlength = unsigned(MM_slave_frame_length) - 1 then --fin transmission frame
						next_state 		<= WAIT_ACK;
						next_status 	<= status_wait_ack;
						next_write_mem    <= '1';
						fifo_rdreq 			<= '1';
	
					else --prepare for next burst
						next_countlength <= reg_countlength + 1;
						fifo_rdreq 		<= '1';
						next_state		<= WAIT_DATA;
					end if;

					next_write_mem <= '0';  -- stop
				 else
				 
						next_write_mem    <= '1';
				 
				 end if;
				
			when WAIT_ACK =>
				if (MM_slave_ack = '1') then
					next_state 			<= IDLE;
					next_status			<= status_idle;
				end if;
				
			when others =>
		end case;		
	end process pFSM_COMB;
			
end rtl;