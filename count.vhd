-- source: https://gist.githubusercontent.com/aviansun/977420/raw/88d15444bde38d596e87e08962a41641a7ace3bb/Digi_Clock.vhd

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY counter IS
	PORT (
		clk : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		hour : IN std_logic;
		anode0 : OUT std_logic;
		anode1 : OUT std_logic;
		anode2 : OUT std_logic;
		anode3 : OUT std_logic;
		segments : OUT std_logic_vector (6 DOWNTO 0)
	);
END counter;

ARCHITECTURE counter OF counter IS
	SIGNAL clk1 : std_logic := '0';
	SIGNAL count : INTEGER := 1;
	SIGNAL div : std_logic_vector(22 DOWNTO 0);
	SIGNAL WhichDisplay : std_logic_vector(1 DOWNTO 0);
	SIGNAL digit1 : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL digit2 : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL digit3 : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL digit4 : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL digit5 : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL digit6 : STD_LOGIC_VECTOR (6 DOWNTO 0);

BEGIN
	PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			count <= count + 1;
			IF (count = 50000000) THEN
				clk1 <= NOT clk1;
				count <= 1;
			END IF;
		END IF;
	END PROCESS;

	PROCESS (clk1, reset)
	VARIABLE sec_small_cnt : INTEGER RANGE 0 TO 10;
	VARIABLE sec_large_cnt : INTEGER RANGE 0 TO 6;
	VARIABLE min_small_cnt : INTEGER RANGE 0 TO 10;
	VARIABLE min_large_cnt : INTEGER RANGE 0 TO 6;
	VARIABLE hr_small_cnt : INTEGER RANGE 0 TO 10;
	VARIABLE hr_large_cnt : INTEGER RANGE 0 TO 3;
		BEGIN
			---- counter: ----------------------
			IF (reset = '1') THEN
				sec_small_cnt := 0;
				sec_large_cnt := 0;
				min_small_cnt := 0;
				min_large_cnt := 0;
				hr_small_cnt := 0;
				hr_large_cnt := 0;

			ELSIF rising_edge(clk1) THEN
				sec_small_cnt := sec_small_cnt + 1;
				IF (sec_small_cnt = 10) THEN
					sec_small_cnt := 0;
					sec_large_cnt := sec_large_cnt + 1;
					IF (sec_large_cnt = 6) THEN
						sec_large_cnt := 0;
						min_small_cnt := min_small_cnt + 1;
						IF (min_small_cnt = 10) THEN
							min_small_cnt := 0;
							min_large_cnt := min_large_cnt + 1;
							IF (min_large_cnt = 6) THEN
								min_large_cnt := 0;
								hr_small_cnt := hr_small_cnt + 1;
								IF (hr_small_cnt = 10) THEN
									hr_small_cnt := 0;
									hr_large_cnt := hr_large_cnt + 1;
									IF (hr_large_cnt = 3) THEN
										sec_small_cnt := 0;
										sec_large_cnt := 0;
										min_small_cnt := 0;
										min_large_cnt := 0;
										hr_small_cnt := 0;
										hr_large_cnt := 0;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;

			CASE sec_small_cnt IS
				WHEN 0 => digit1 <= "0000001";
				WHEN 1 => digit1 <= "1001111";
				WHEN 2 => digit1 <= "0010010";
				WHEN 3 => digit1 <= "0000110";
				WHEN 4 => digit1 <= "1001100";
				WHEN 5 => digit1 <= "0100100";
				WHEN 6 => digit1 <= "0100000";
				WHEN 7 => digit1 <= "0001111";
				WHEN 8 => digit1 <= "0000000";
				WHEN 9 => digit1 <= "0000100";
				WHEN OTHERS => NULL;
			END CASE;
			CASE sec_large_cnt IS
				WHEN 0 => digit2 <= "0000001";
				WHEN 1 => digit2 <= "1001111";
				WHEN 2 => digit2 <= "0010010";
				WHEN 3 => digit2 <= "0000110";
				WHEN 4 => digit2 <= "1001100";
				WHEN 5 => digit2 <= "0100100";
				WHEN 6 => digit2 <= "0100000";
				WHEN OTHERS => NULL;
			END CASE;

			CASE min_small_cnt IS
				WHEN 0 => digit3 <= "0000001";
				WHEN 1 => digit3 <= "1001111";
				WHEN 2 => digit3 <= "0010010";
				WHEN 3 => digit3 <= "0000110";
				WHEN 4 => digit3 <= "1001100";
				WHEN 5 => digit3 <= "0100100";
				WHEN 6 => digit3 <= "0100000";
				WHEN 7 => digit3 <= "0001111";
				WHEN 8 => digit3 <= "0000000";
				WHEN 9 => digit3 <= "0000100";
				WHEN OTHERS => NULL;
			END CASE;

			CASE min_large_cnt IS
				WHEN 0 => digit4 <= "0000001";
				WHEN 1 => digit4 <= "1001111";
				WHEN 2 => digit4 <= "0010010";
				WHEN 3 => digit4 <= "0000110";
				WHEN 4 => digit4 <= "1001100";
				WHEN 5 => digit4 <= "0100100";
				WHEN 6 => digit4 <= "0100000";
				WHEN OTHERS => NULL;
			END CASE;

			CASE hr_small_cnt IS
				WHEN 0 => digit5 <= "0000001";
				WHEN 1 => digit5 <= "1001111";
				WHEN 2 => digit5 <= "0010010";
				WHEN 3 => digit5 <= "0000110";
				WHEN 4 => digit5 <= "1001100";
				WHEN 5 => digit5 <= "0100100";
				WHEN 6 => digit5 <= "0100000";
				WHEN 7 => digit5 <= "0001111";
				WHEN 8 => digit5 <= "0000000";
				WHEN 9 => digit5 <= "0000100";
				WHEN OTHERS => NULL;
			END CASE;

			CASE hr_large_cnt IS
				WHEN 0 => digit6 <= "0000001";
				WHEN 1 => digit6 <= "1001111";
				WHEN 2 => digit6 <= "0010010";
				WHEN 3 => digit6 <= "0000110";
				WHEN OTHERS => NULL;
			END CASE;
		END PROCESS;
		div <= div + 1 WHEN rising_edge(clk);
		WhichDisplay <= div(16 DOWNTO 15);

		PROCESS (clk)
			BEGIN
				IF rising_edge(clk) THEN
 
					IF WhichDisplay = "11" THEN
						segments <= digit4; -- 0
						anode3 <= '0';
						anode1 <= '1';
						anode2 <= '1';
						anode0 <= '1';
					ELSIF WhichDisplay = "10" THEN
						segments <= digit3; -- 1
						anode2 <= '0';
						anode1 <= '1';
						anode3 <= '1';
						anode0 <= '1';
					ELSIF WhichDisplay = "01" THEN
						segments <= digit2; -- 2
						anode1 <= '0';
						anode2 <= '1';
						anode3 <= '1';
						anode0 <= '1';
					ELSE
						segments <= digit1; -- 3
						anode0 <= '0';
						anode1 <= '1';
						anode2 <= '1';
						anode3 <= '1';
					END IF;
 
					IF hour = '1' THEN
						IF WhichDisplay = "11" THEN
							segments <= digit6; -- 0
							anode3 <= '0';
							anode1 <= '1';
							anode2 <= '1';
							anode0 <= '1';
						ELSIF WhichDisplay = "10" THEN
							segments <= digit5; -- 1
							anode2 <= '0';
							anode1 <= '1';
							anode3 <= '1';
							anode0 <= '1';
						ELSIF WhichDisplay = "01" THEN
							segments <= digit4; -- 2
							anode1 <= '0';
							anode2 <= '1';
							anode3 <= '1';
							anode0 <= '1';
						ELSE
							segments <= digit3; -- 3
							anode0 <= '0';
							anode1 <= '1';
							anode2 <= '1';
							anode3 <= '1';

						END IF;
					END IF;
 
				ELSE
					NULL;
				END IF;
 
			END PROCESS;
END counter;