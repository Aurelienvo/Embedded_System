	component system is
		port (
			clk_clk                     : in  std_logic := 'X'; -- clk
			reset_reset_n               : in  std_logic := 'X'; -- reset_n
			pwm_slave_0_conduit_end_pwm : out std_logic         -- pwm
		);
	end component system;

	u0 : component system
		port map (
			clk_clk                     => CONNECTED_TO_clk_clk,                     --                     clk.clk
			reset_reset_n               => CONNECTED_TO_reset_reset_n,               --                   reset.reset_n
			pwm_slave_0_conduit_end_pwm => CONNECTED_TO_pwm_slave_0_conduit_end_pwm  -- pwm_slave_0_conduit_end.pwm
		);

