library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY CLOCK_DIVIDER IS
	PORT(	clk				: IN	std_logic;
			nReset 			: IN	std_logic;
			pwm_enabled		: IN	std_logic;
			clkDivReg		: IN	std_logic_vector (15 DOWNTO 0);
			enable			: OUT	std_logic  -- "divided clk signal"		
	);	
End CLOCK_DIVIDER;

ARCHITECTURE struct OF CLOCK_DIVIDER IS

	-- FSM states
	type state_type is (IDLE, COUNT);
	signal state : state_type := IDLE;
	
	-- count signals
	signal counter 		: unsigned (15 downto 0);
	signal max_count 		: unsigned (15 downto 0);
	
BEGIN


	process (clk)
	begin
		if (rising_edge(clk)) then
			if (counter = max_count) and (pwm_enabled = '1') then
				enable <= '1';
			else 
				enable <= '0';
			end if;
		end if;
	end process;
 
pFSM:
	process (nReset, clk)
	begin
		if nReset = '0' then
			state <= IDLE;	
			counter <= (others => '0'); -- TODO remove.. ? seems unnecessary but test
			
		elsif (rising_edge(clk)) then
			case state is 
				when IDLE =>
					if (pwm_enabled = '1') then
						counter <= (15 downto 1 => '0', 0 => '1');
						max_count <= unsigned(clkDivReg);						
						state <= COUNT;						
					end if;
										
				when COUNT =>
					if (pwm_enabled = '0') then
						state <= IDLE;
					else
						if (counter < max_count) then     -- increment counter
							counter <= counter + 1;
						elsif (counter = max_count) then  -- reset counter
							counter <= (15 downto 1 => '0', 0 => '1');
						end if;
					end if;
					
				when others =>
			end case;
		end if;
	end process pFSM;


END struct;
