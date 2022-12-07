LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY clock_divider IS
	PORT (
		clk_in : IN STD_LOGIC;
		clk_out : OUT STD_LOGIC
	);
END clock_divider;

ARCHITECTURE Behavioral OF clock_divider IS

	SIGNAL cycle : INTEGER := 1;
	SIGNAL clk_temp : STD_LOGIC := '0';

BEGIN
	clk_div : PROCESS (clk_in)
	BEGIN
		IF rising_edge(clk_in) THEN
			cycle <= cycle + 1;
			IF (cycle >= 50000000) THEN -- Set to '2' for testbench; The idea is that then the 1sec clock will count up every 80ns
				cycle <= 1;
				clk_temp <= NOT clk_temp;
			END IF;
		END IF;
	END PROCESS;
	clk_out <= clk_temp;
END Behavioral;