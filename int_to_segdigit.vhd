LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY int_to_segdigit IS
	PORT (
		int : IN INTEGER;
		segdigit : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
	);
END int_to_segdigit;

ARCHITECTURE Behavioral OF int_to_segdigit IS
BEGIN
-- Perfectly working behavioral
	conversion : PROCESS (int)
	BEGIN
		CASE int IS
			WHEN 0 => segdigit <= "0000001";
			WHEN 1 => segdigit <= "1001111";
			WHEN 2 => segdigit <= "0010010";
			WHEN 3 => segdigit <= "0000110";
			WHEN 4 => segdigit <= "1001100";
			WHEN 5 => segdigit <= "0100100";
			WHEN 6 => segdigit <= "0100000";
			WHEN 7 => segdigit <= "0001111";
			WHEN 8 => segdigit <= "0000000";
			WHEN 9 => segdigit <= "0000100";
			WHEN OTHERS => NULL;
		END CASE;
	END PROCESS;
	
-- Slightly buggy dataflow
--	segdigit <= "0000001" WHEN int = 0 ELSE
--	"1001111" WHEN int = 1 ELSE
--	"0010010" WHEN int = 2 ELSE
--	"0000110" WHEN int = 3 ELSE
--	"1001100" WHEN int = 4 ELSE
--	"0100100" WHEN int = 5 ELSE
--	"0100000" WHEN int = 6 ELSE
--	"0001111" WHEN int = 7 ELSE
--	"0000000" WHEN int = 8 ELSE
--	"0000100" WHEN int = 9 ELSE
--	"1111111";
END Behavioral;
