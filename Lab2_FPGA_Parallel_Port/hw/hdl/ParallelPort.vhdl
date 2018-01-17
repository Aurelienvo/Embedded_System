-- Design of an Avalon slave unit that
-- implement a simple 8 bits Parallel Port ParPort[0..7] with programmable direction bit by bit.
-- 
-- 
-- ParPort: if ParPort[i] direction is output => value memorized in iRegPort[i] is outputted.
--				if ParPort[i] direction is input => the output value is 'Z' (High-Impedance)
--
-- 5 addresses used for configuration/usage:
-- 0: iRegDir direction register R/W: iRegDir[i] = 1/0 -> ParPort[i] output/input
-- 1: iRegPin pin register R (W ignored): read port/pin state (value at the pin interface, direction doesn't matter)
-- 2: iRegPort port register R/W: memorized state/value 
-- 3: iRegPort regset W (R always 0): sets the bits specified at '1' level, the other bits are not changed
-- 4: iRegPort regclear W (R always 0): clear the bits specified at '1' level, the other bits are not changed

-- write at other addresses are ignored and read at other addresses 'return' 0


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY ParallelPort IS
	PORT(
	-- Avalon interfaces signals
		Clk : IN std_logic;
		nReset : IN std_logic;
		Address : IN std_logic_vector (2 DOWNTO 0);
		ChipSelect : IN std_logic;
		Read : IN std_logic;
		Write : IN std_logic;
		ReadData : OUT std_logic_vector (7 DOWNTO 0);
		WriteData : IN std_logic_vector (7 DOWNTO 0);

	-- Parallel Port external interface
		ParPort : INOUT std_logic_vector (7 DOWNTO 0)
	);
End ParallelPort;

ARCHITECTURE comp OF ParallelPort IS

	signal iRegDir : std_logic_vector (7 DOWNTO 0);
	signal iRegPort: std_logic_vector (7 DOWNTO 0);
	signal iRegPin : std_logic_vector (7 DOWNTO 0);
	
BEGIN

-- Parallel Port Input value
	iRegPin <= ParPort;


-- Parallel Port output value
pPort: 
	process(iRegDir, iRegPort)
	begin
			for i in 0 to 7 loop
				if iRegDir(i) = '1' then
					ParPort(i) <= iRegPort(i);
				else
					ParPort(i) <= 'Z';
				end if;
			end loop;
	end process pPort;
	
-- Process Write to registers
pRegWr:
	process(Clk, nReset)
	begin
		if nReset = '0' then
			iRegDir <= (others => '0'); 	-- default direction is Input
			iRegPort <= (others => '0'); 	-- memorized state is 0 by default
			
		elsif rising_edge(Clk) then
			if ChipSelect = '1' and Write = '1' then 	-- Write cycle
				case Address(2 downto 0) is
					when "000" => iRegDir <= WriteData ; 							-- iRegDir  			address
					when "010" => iRegPort <= WriteData;  							-- iRegPort 			address
					when "011" => iRegPort <= iRegPort OR WriteData;  			-- iRegPort regset 	address
					when "100" => iRegPort <= iRegPort AND NOT WriteData; 	-- iRegPort regclear address
					when others => null;
				end case;
			end if;
		end if;
	end process pRegWr;
	
-- Process Read from registers
pRegRd:
	process(Clk)
	begin
		if rising_edge(Clk) then
			ReadData <= (others => '0');  -- default read value is 0
			
			if ChipSelect = '1' and Read = '1' then -- Read cycle
				case Address(2 downto 0) is
					when "000" => ReadData <= iRegDir ;								-- iRegDir  			address
					when "001" => ReadData <= iRegPin;                       -- iRegPin 				address
					when "010" => ReadData <= iRegPort;                      -- iRegPort 			address
					when others => null;
				end case;
			end if;
		end if;
	end process pRegRd;

END comp;