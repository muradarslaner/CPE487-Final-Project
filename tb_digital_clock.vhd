LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_digital_clock IS
END tb_digital_clock;

ARCHITECTURE tb OF tb_digital_clock IS

	COMPONENT digital_clock
		PORT (
			clk_100MHz : IN STD_LOGIC;
			reset : IN STD_LOGIC;
			format : IN STD_LOGIC;
			anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			segments : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
			alarmled : OUT STD_LOGIC);
	END COMPONENT;

	SIGNAL clk_100MHz : STD_LOGIC;
	SIGNAL reset : STD_LOGIC;
	SIGNAL format : STD_LOGIC;
	SIGNAL anode : STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL segments : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL alarmled : STD_LOGIC;

	CONSTANT TbPeriod : TIME := 2 ps; -- Put right period here
	SIGNAL TbClock : STD_LOGIC := '0';
	SIGNAL TbSimEnded : STD_LOGIC := '0';

BEGIN

	dut : digital_clock
	PORT MAP(
		clk_100MHz => clk_100MHz,
		reset => reset,
		format => format,
		anode => anode,
		segments => segments,
		alarmled => alarmled);

	-- Clock generation
	TbClock <= NOT TbClock AFTER TbPeriod/2 WHEN TbSimEnded /= '1' ELSE '0';
	clk_100MHz <= TbClock;

	stimuli : PROCESS
	BEGIN
		-- Initializiation
		format <= '0';

		-- Reset generation
		reset <= '0';
		WAIT FOR 100 ns;
		reset <= '1';

		-- Stimulus
		WAIT FOR 1 hr;
	END PROCESS;

END tb;