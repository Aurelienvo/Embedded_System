library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY PWM IS
	PORT(
	-- Avalon interfaces signals
		Clk 			: IN	std_logic;
		nReset 		: IN	std_logic;
		Address 		: IN	std_logic_vector (2 DOWNTO 0);
		ChipSelect 	: IN	std_logic;
		Read 			: IN	std_logic;
		Write 		: IN	std_logic;
		ReadData 	: OUT	std_logic_vector (15 DOWNTO 0);
		WriteData 	: IN	std_logic_vector (15 DOWNTO 0);

	-- PWM external interface
		PwmOut		: out std_logic
	);
END PWM;

ARCHITECTURE struct OF PWM IS

	-- clock_divider submodule
	COMPONENT clock_divider
		PORT(	clk				: IN	std_logic;
				nReset 			: IN	std_logic;
				pwm_enabled		: IN	std_logic;
				clkDivReg		: IN	std_logic_vector (15 DOWNTO 0);
				enable			: OUT	std_logic  -- "divided clk signal"
		);	
	END COMPONENT;
	
	-- pwm_gen submodule
	COMPONENT pwm_gen
		PORT(	clk				: IN	std_logic;
				nReset 			: IN	std_logic;
				dutyReg			: IN	std_logic_vector (15 DOWNTO 0);
				periodReg		: IN	std_logic_vector (15 DOWNTO 0);
				enable			: IN	std_logic;  -- "divided clk signal"	
				pwm_polarity	: IN	std_logic;
				pwm_out			: OUT	std_logic
	);		
	END COMPONENT;

	-- registers
	signal dutyReg 	: std_logic_vector (15 DOWNTO 0);
	signal periodReg	: std_logic_vector (15 DOWNTO 0);
	signal clkDivReg  : std_logic_vector (15 DOWNTO 0); -- TODO if time do clever things, such as make clkdivreg an internal reg, configurable via command and status thing, offer only predefined dividers etc..	
	
	-- addresses
	constant REG_DUTY		: std_logic_vector := "000";
	constant REG_PERIOD	: std_logic_vector := "001";
	constant REG_CLKDIV	: std_logic_vector := "010";
	constant REG_COMMAND	: std_logic_vector := "011";
	constant REG_STATUS	: std_logic_vector := "100";
	
	-- internal machinery
	signal pwm_enabled	: std_logic;
	signal pwm_polarity	: std_logic;
	signal enable			: std_logic; -- TODO maybe rename, here it is the "divided clock signal" that is mapped to the clock divider output
	
BEGIN

	-- map the clock divider submodule to the internal signals
	clkdiv1 : clock_divider PORT MAP (
					clk 			=> Clk,
					nReset		=> nReset,
					pwm_enabled => pwm_enabled,
					clkDivReg	=> clkDivReg,
					enable		=> enable
				);
				
	-- map the pwm_gen submodule to the internal signals
	pwmgen1 : pwm_gen PORT MAP (
					clk				=> Clk,	
					nReset			=> nReset,
					dutyReg			=> dutyReg,
					periodReg		=> periodReg,
					enable			=> enable,
					pwm_polarity	=> pwm_polarity,
					pwm_out			=> PWmOut				
				);
				
	-- TODO check reset logic, and initial values
	
	-- avalon write
pRegWr:
	process(Clk, nReset)
	begin
		if nReset = '0' then
			pwm_enabled <= '0';
			clkDivReg 	<= (others => '0');
			dutyReg		<= (others => '0');
			periodReg	<= (others => '0');
			pwm_enabled	<= '0'; -- TODO decide and documente
			pwm_polarity<=	'0';
				
		elsif rising_edge(Clk) then
			if ChipSelect = '1' and Write = '1' then 	-- Write cycle
				case Address is
					when REG_DUTY 		=> dutyReg 		<= writeData;
					when REG_PERIOD	=> periodReg 	<= writeData;
					when REG_CLKDIV	=> clkDivReg	<= writeData;
					when REG_COMMAND	=> 
						pwm_enabled		<= writeData(0);
						pwm_polarity	<= writeData(1);
					when others 		=> null;
				end case;
			end if;
		end if;
	end process pRegWr;
	
	-- avalon read
pRegRd:
	process(Clk)
	begin
		if rising_edge(Clk) then
			ReadData <= (others => '0');  -- default read value is 0
			
			if ChipSelect = '1' and Read = '1' then -- Read cycle
				case Address is
					when REG_DUTY		=> ReadData <= dutyReg;
					when REG_PERIOD	=> ReadData <= periodReg;
					when REG_CLKDIV	=> ReadData <= clkDivReg;
					when REG_STATUS	=>
						ReadData(0) <= pwm_enabled;
						ReadData(1) <= pwm_polarity;
					when others 		=> null;
				end case;
			end if;
		end if;
	end process pRegRd;
	
END struct;
