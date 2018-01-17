library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY PWM_GEN IS
	PORT(	clk				: IN	std_logic;
			nReset 			: IN	std_logic;
			dutyReg			: IN	std_logic_vector (15 DOWNTO 0);
			periodReg		: IN	std_logic_vector (15 DOWNTO 0);
			enable			: IN	std_logic;  -- "divided clk signal"	
			pwm_polarity	: IN	std_logic;
			pwm_out			: OUT	std_logic
	);	
End PWM_GEN;

ARCHITECTURE struct OF PWM_GEN IS

	signal pwm, next_pwm : std_logic := '0';

	-- FSM states
	type state_type is (IDLE, COUNT_DUTY, COUNT_PERIOD);
	signal state, next_state		: state_type := IDLE;
	
	-- count signal
	signal count, next_count		: unsigned (15 downto 0) := (others => '0');
	
BEGIN


	process (clk, nReset)
	begin
		if nReset = '0' then
			state		<= IDLE;	
			count 	<= (others => '0');
			pwm		<= '0';
		elsif rising_edge(clk) then
			pwm_out <= next_pwm;
			if enable = '1' then
				state <= next_state;
				count <= next_count;
				pwm <= next_pwm;
			end if;
		end if;
	end process;


pFSM:
	process (state, count, pwm, pwm_polarity, dutyReg, periodReg)
	begin
	
		next_state <= state;
		next_count <= count;
		next_pwm <= pwm;
		
		
		case state is
			when IDLE			=>
				next_count	<= (others => '0');
				next_state	<= COUNT_DUTY;
				next_pwm			<= not(pwm_polarity);
				
			when COUNT_DUTY	=>
				next_count	<= count + 1;
				if count = unsigned(dutyReg) then
					next_state	<= COUNT_PERIOD;
					next_pwm		<= pwm_polarity;
				end if;
			when COUNT_PERIOD	=>
				next_count	<= count + 1;
				if count = unsigned(periodReg) then
					next_count	<= (others => '0');
					next_state	<= COUNT_DUTY;
					next_pwm		<= not(pwm_polarity);
				end if;
			when others 		=>
		end case;
	end process pFSM;

END struct;
