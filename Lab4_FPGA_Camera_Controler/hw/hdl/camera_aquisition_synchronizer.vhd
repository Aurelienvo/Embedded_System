library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity camera_aquisition_synchronizer is
	port(	
	
		clk		: in	std_logic;
		-- TODO reset
	
	-- input CMOS sensor signals (TRDB-D5M camera)
		line_valid_in		: in	std_logic;	
		frame_valid_in		: in	std_logic;
		data_in				: in	std_logic_vector(11 downto 0); -- TODO way to configure "pixel" width ?
		
	-- output CMOS sensor signals (TRDB-D5M camera)
		line_valid_out		: out	std_logic;	
		frame_valid_out	: out	std_logic;
		data_out				: out	std_logic_vector(11 downto 0) -- TODO way to configure "pixel" width ?
	);
end camera_aquisition_synchronizer;

-- TODO unimplemented, do if time and/or necessary, seems not useful
architecture rtl of camera_aquisition_synchronizer is
	
begin
	line_valid_out 	<= line_valid_in;
	frame_valid_out	<= frame_valid_in;
	data_out				<= data_in;
		
end rtl;
