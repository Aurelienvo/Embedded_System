library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity avalon_slave is
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
		-- TODO 
		enable			: out	std_logic;
		buffer_addr		: out std_logic_vector(31 downto 0);
		frame_length	: out std_logic_vector(31 downto 0);
		burst_length	: out std_logic_vector(31 downto 0);
		DMA_ack_frame	: out std_logic;
		DMA_status		: in	std_logic_vector( 1 downto 0)
	);
end avalon_slave;

architecture rtl of avalon_slave is

	-- avalon MM-registers
	-- R/W
	signal reg_dma_buffer_addr				: std_logic_vector(31 downto 0)	:= (others => '0');  
	signal reg_dma_frame_lenght			: std_logic_vector(31 downto 0)	:= (others => '0');  -- in bytes
	signal reg_dma_burst_length			: std_logic_vector(31 downto 0)	:= (others => '0');  
	
	-- avalon MM-register addresses	
	-- R
	constant status_addr						: std_logic_vector             	:= "000";
	-- R/W
	constant reg_dma_buffer_addr_addr	: std_logic_vector					:= "001";
	constant reg_dma_frame_lenght_addr	: std_logic_vector             	:= "010";
	constant reg_dma_burst_length_addr	: std_logic_vector             	:= "011";
	-- W
	constant ctrl_addr						: std_logic_vector             	:= "100";
	
	-- internal signals and registers
	signal reg_enable							: std_logic								:= '0';
	signal reg_dma_ack_frame				: std_logic								:= '0';			
		
begin

	-- output processes
	enable			<= reg_enable;
	buffer_addr		<= reg_dma_buffer_addr;
	frame_length	<= reg_dma_frame_lenght;
	burst_length	<= reg_dma_burst_length;
	DMA_ack_frame	<= reg_dma_ack_frame;
					
	-- avalon write
pregwr:
	process(clk, nreset)
	begin
		if nReset = '0' then
		   reg_dma_buffer_addr	<= (others => '0');
		   reg_dma_frame_lenght	<= (others => '0');
			reg_dma_burst_length	<= (others => '0');
			--
			reg_enable				<= '0';
			reg_dma_ack_frame		<= '0';
											
		elsif rising_edge(clk) then
			reg_enable						<= '0'; -- TODO check ok (would them to be high during one clock cycle)
			reg_dma_ack_frame				<= '0';
			
			if write = '1' then 	-- write cycle
				case address is
					when reg_dma_buffer_addr_addr => 
						reg_dma_buffer_addr	<= writedata;
						
					when reg_dma_frame_lenght_addr => 
						reg_dma_frame_lenght	<= writedata;
					
					when reg_dma_burst_length_addr =>
						reg_dma_burst_length	<= writedata;
					
					when ctrl_addr =>
						reg_enable				<= writedata(0);	
						reg_dma_ack_frame		<= writedata(1);					
					when others => null;
				end case;
			end if;
		end if;
	end process pregwr;
	
	-- avalon read
pregrd:
	process(clk)
	begin
		if rising_edge(clk) then
			readdata <= (others => '0');  -- default read value is 0
			
			if read = '1' then -- read cycle
				case address is
					when status_addr =>
						readdata <= (31 downto 2 => '0') & DMA_status;
					
					when reg_dma_buffer_addr_addr => 
						readdata <= reg_dma_buffer_addr;
						
					when reg_dma_frame_lenght_addr => 
						readdata	<= reg_dma_frame_lenght;
						
					when reg_dma_burst_length_addr =>
						readdata <= reg_dma_burst_length;
						
					when others => null;
				end case;
			end if;
		end if;
	end process pregrd;
end rtl;
