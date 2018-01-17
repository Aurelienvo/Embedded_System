library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity camera_aquisition is
	port(	
	
		nReset		: in std_logic;
	
	-- input from Avalon MM-slave
		enable		: in std_logic;
	
	-- input TRDB-D5M camera sensor signals 
		line_valid	: in	std_logic;	
		frame_valid	: in	std_logic;
		data			: in	std_logic_vector(11 downto 0);
		clk_in		: in	std_logic;
		
	-- output 16 bit pixel (RGB 5-6-5)
		pixel_out	: out	std_logic_vector(15 downto 0);
		valid_out	: out std_logic;
		clk_out		: out	std_logic
	);
end camera_aquisition;

architecture struct of camera_aquisition is

	-- TODO use entity direct instantation instead of components ? (we designed using paper and pen..)

	-- input synchronizer submodule
	-- TODO if necessary/time
	
	-- sampler submodule
	component camera_aquisition_sampler
		port(	nReset			: in	std_logic;	
				clk				: in	std_logic;
				
				enable			: in	std_logic;
			
				line_valid		: in	std_logic;	
				frame_valid		: in	std_logic;
				data				: in	std_logic_vector(11 downto 0);
				
				valid				: out	std_logic;
				valid_data		: out	std_logic_vector(11 downto 0)
		);
	end component;
	signal camera_aquisition_sampler_valid_out								: std_logic								:= '0';
	signal camera_aquisition_sampler_valid_data_out							: std_logic_vector(11 downto 0)	:= (others => '0');
	
	
	-- bayer decoder submodule
	component camera_aquisition_bayer_decoder
		port(	nReset			: in	std_logic;	
				clk				: in	std_logic;
				
				valid_in			: in	std_logic;	
				valid_data		: in	std_logic_vector(11 downto 0); -- TODO way to configure "pixel" width ?
				
				valid_out		: out	std_logic;
				valid_pixel		: out	std_logic_vector(15 downto 0) -- TODO way to configure "pixel" width ?
		);
	end component;
	--signal camera_aquisition_bayer_decoder_valid_out				: std_logic								:= '0';
	--signal camera_aquisition_bayer_decoder_valid_pixel_out		: std_logic_vector(11 downto 0)	:= (others => '0');
	

begin

	clk_out <= clk_in; -- TODO ok or better to avoid ?
	
	-- sampler
	camera_aquisition_sampler_inst : camera_aquisition_sampler port map (
		nReset		=> nReset,
		clk	 		=> clk_in,
		enable		=> enable,	
			
		line_valid	=> line_valid,		
		frame_valid => frame_valid,
		data			=> data,		
		
		valid			=> camera_aquisition_sampler_valid_out,	
		valid_data	=> camera_aquisition_sampler_valid_data_out
	);
	
	-- bayer decoder
	camera_aquisition_bayer_decoder_inst : camera_aquisition_bayer_decoder port map (
		nReset		=> nReset,			
		clk			=> clk_in,
		
		valid_in		=> camera_aquisition_sampler_valid_out,
		valid_data	=> camera_aquisition_sampler_valid_data_out,
		
		valid_out	=> valid_out,
		valid_pixel	=> pixel_out	
	);
			
end struct;
