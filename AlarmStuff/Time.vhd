LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY digital_clock IS
	PORT (
		clk_100MHz : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		format : IN STD_LOGIC; -- 1: XXmmhhss, 0: hhmmhhmm
		anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		segments : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
		alarmled : OUT STD_LOGIC;
		alarmled_part2 : OUT STD_LOGIC;
		alarmled_part3 : OUT STD_LOGIC;
		alarmled_part4 : OUT STD_LOGIC;
		alarmled_part5 : OUT STD_LOGIC;
		alarmled_part2SIR : INOUT STD_LOGIC;
		alarmled_part3SIR : INOUT STD_LOGIC;
		alarmled_part4SIR : INOUT STD_LOGIC;
		alarmled_part5SIR : INOUT STD_LOGIC
	);
END digital_clock;

ARCHITECTURE Behavioral OF digital_clock IS
	COMPONENT siren IS
		PORT (
		clk_100MHz : IN STD_LOGIC; -- system clock (100 MHz)
		dac_MCLK : OUT STD_LOGIC; -- outputs to PMODI2L DAC
		dac_LRCK : OUT STD_LOGIC;
		dac_SCLK : OUT STD_LOGIC;
		dac_SDIN : OUT STD_LOGIC
	   );
	END COMPONENT;

	-- clock divider
	SIGNAL clk_1sec : STD_LOGIC := '0';
	SIGNAL clk_freq : INTEGER := 500000; -- 100 MHz
	SIGNAL count : INTEGER := 1;

	-- 7-seg display 8:1 mux
	SIGNAL div : STD_LOGIC_VECTOR (22 DOWNTO 0);
	SIGNAL which_display : STD_LOGIC_VECTOR (2 DOWNTO 0);

	-- current time
	SIGNAL sec_small_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL sec_large_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL min_small_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL min_large_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL hr_small_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL hr_large_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
 
	-- alarm time
	SIGNAL alarm_hr_large_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL alarm_hr_small_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL alarm_min_large_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL alarm_min_small_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	
	
	-- Clock divider from 100 MHz to 1 Hz
BEGIN
	s1: siren 
	PORT MAP(
	       clk_100MHz => clk_100MHz,
	       dac_MCLK => alarmled_part2SIR, 
	       dac_LRCK => alarmled_part3SIR, 
	       dac_SCLK => alarmled_part4SIR, 
	       dac_SDIN => alarmled_part5SIR
	       );

	PROCESS (clk_100MHz)
	BEGIN
		IF rising_edge(clk_100MHz) THEN
			count <= count + 1;
			IF (count = clk_freq) THEN
				clk_1sec <= NOT clk_1sec;
				count <= 1;
			END IF;
		END IF;
	END PROCESS;

	-- Main digital clock counting logic
	-- current time
	PROCESS (clk_1sec, reset)
	VARIABLE sec_small_cnt : INTEGER RANGE 0 TO 10 := 0;
	VARIABLE sec_large_cnt : INTEGER RANGE 0 TO 6 := 0;
	VARIABLE min_small_cnt : INTEGER RANGE 0 TO 10 := 0;
	VARIABLE min_large_cnt : INTEGER RANGE 0 TO 6 := 0;
	VARIABLE hr_small_cnt : INTEGER RANGE 0 TO 10 := 0;
	VARIABLE hr_large_cnt : INTEGER RANGE 0 TO 2 := 0;
 
	-- alarm time
	VARIABLE alarm_hr_large : INTEGER RANGE 0 TO 2 := 0;
	VARIABLE alarm_hr_small : INTEGER RANGE 0 TO 9 := 1;
	VARIABLE alarm_min_large : INTEGER RANGE 0 TO 5 := 3;
	VARIABLE alarm_min_small : INTEGER RANGE 0 TO 9 := 0;
		BEGIN
			IF (reset = '1') THEN
				sec_small_cnt := 0;
				sec_large_cnt := 0;
				min_small_cnt := 0;
				min_large_cnt := 0;
				hr_small_cnt := 0;
				hr_large_cnt := 0;
				alarmled <= '0';
				alarmled_part2 <= '0';
                		alarmled_part3 <= '0';
              			alarmled_part4 <= '0';
                		alarmled_part5 <= '0';

			ELSIF rising_edge(clk_1sec) THEN
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
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
				IF (hr_large_cnt = 2 AND hr_small_cnt >= 4) THEN
					sec_small_cnt := 0;
					sec_large_cnt := 0;
					min_small_cnt := 0;
					min_large_cnt := 0;
					hr_small_cnt := 0;
					hr_large_cnt := 0;
				END IF;
				-- alarm
				IF (hr_large_cnt = alarm_hr_large AND hr_small_cnt = alarm_hr_small AND min_large_cnt = alarm_min_large AND min_small_cnt = alarm_min_small) THEN
					alarmled <= '1';
				-- Once the time is reached, this section will sound the siren
					alarmled_part2 <= alarmled_part2SIR;
					alarmled_part3 <= alarmled_part3SIR;
					alarmled_part4 <= alarmled_part4SIR;
					alarmled_part5 <= alarmled_part5SIR;
				END IF;
			END IF;

			-- Translate each digit on the clock to 7-seg cathode values
			-- current time
			CASE sec_small_cnt IS
				WHEN 0 => sec_small_digit <= "0000001";
				WHEN 1 => sec_small_digit <= "1001111";
				WHEN 2 => sec_small_digit <= "0010010";
				WHEN 3 => sec_small_digit <= "0000110";
				WHEN 4 => sec_small_digit <= "1001100";
				WHEN 5 => sec_small_digit <= "0100100";
				WHEN 6 => sec_small_digit <= "0100000";
				WHEN 7 => sec_small_digit <= "0001111";
				WHEN 8 => sec_small_digit <= "0000000";
				WHEN 9 => sec_small_digit <= "0000100";
				WHEN OTHERS => NULL;
			END CASE;

			CASE sec_large_cnt IS
				WHEN 0 => sec_large_digit <= "0000001";
				WHEN 1 => sec_large_digit <= "1001111";
				WHEN 2 => sec_large_digit <= "0010010";
				WHEN 3 => sec_large_digit <= "0000110";
				WHEN 4 => sec_large_digit <= "1001100";
				WHEN 5 => sec_large_digit <= "0100100";
				WHEN 6 => sec_large_digit <= "0100000";
			END CASE;

			CASE min_small_cnt IS
				WHEN 0 => min_small_digit <= "0000001";
				WHEN 1 => min_small_digit <= "1001111";
				WHEN 2 => min_small_digit <= "0010010";
				WHEN 3 => min_small_digit <= "0000110";
				WHEN 4 => min_small_digit <= "1001100";
				WHEN 5 => min_small_digit <= "0100100";
				WHEN 6 => min_small_digit <= "0100000";
				WHEN 7 => min_small_digit <= "0001111";
				WHEN 8 => min_small_digit <= "0000000";
				WHEN 9 => min_small_digit <= "0000100";
				WHEN OTHERS => NULL;
			END CASE;

			CASE min_large_cnt IS
				WHEN 0 => min_large_digit <= "0000001";
				WHEN 1 => min_large_digit <= "1001111";
				WHEN 2 => min_large_digit <= "0010010";
				WHEN 3 => min_large_digit <= "0000110";
				WHEN 4 => min_large_digit <= "1001100";
				WHEN 5 => min_large_digit <= "0100100";
				WHEN 6 => min_large_digit <= "0100000";
			END CASE;

			CASE hr_small_cnt IS
				WHEN 0 => hr_small_digit <= "0000001";
				WHEN 1 => hr_small_digit <= "1001111";
				WHEN 2 => hr_small_digit <= "0010010";
				WHEN 3 => hr_small_digit <= "0000110";
				WHEN 4 => hr_small_digit <= "1001100";
				WHEN 5 => hr_small_digit <= "0100100";
				WHEN 6 => hr_small_digit <= "0100000";
				WHEN 7 => hr_small_digit <= "0001111";
				WHEN 8 => hr_small_digit <= "0000000";
				WHEN 9 => hr_small_digit <= "0000100";
				WHEN OTHERS => NULL;
			END CASE;

			CASE hr_large_cnt IS
				WHEN 0 => hr_large_digit <= "0000001";
				WHEN 1 => hr_large_digit <= "1001111";
				WHEN 2 => hr_large_digit <= "0010010";
			END CASE;
 
			-- alarm time
			CASE alarm_min_small IS
				WHEN 0 => alarm_min_small_digit <= "0000001";
				WHEN 1 => alarm_min_small_digit <= "1001111";
				WHEN 2 => alarm_min_small_digit <= "0010010";
				WHEN 3 => alarm_min_small_digit <= "0000110";
				WHEN 4 => alarm_min_small_digit <= "1001100";
				WHEN 5 => alarm_min_small_digit <= "0100100";
				WHEN 6 => alarm_min_small_digit <= "0100000";
				WHEN 7 => alarm_min_small_digit <= "0001111";
				WHEN 8 => alarm_min_small_digit <= "0000000";
				WHEN 9 => alarm_min_small_digit <= "0000100";
				WHEN OTHERS => NULL;
			END CASE;

			CASE alarm_min_large IS
				WHEN 0 => alarm_min_large_digit <= "0000001";
				WHEN 1 => alarm_min_large_digit <= "1001111";
				WHEN 2 => alarm_min_large_digit <= "0010010";
				WHEN 3 => alarm_min_large_digit <= "0000110";
				WHEN 4 => alarm_min_large_digit <= "1001100";
				WHEN 5 => alarm_min_large_digit <= "0100100";
			END CASE;

			CASE alarm_hr_small IS
				WHEN 0 => alarm_hr_small_digit <= "0000001";
				WHEN 1 => alarm_hr_small_digit <= "1001111";
				WHEN 2 => alarm_hr_small_digit <= "0010010";
				WHEN 3 => alarm_hr_small_digit <= "0000110";
				WHEN 4 => alarm_hr_small_digit <= "1001100";
				WHEN 5 => alarm_hr_small_digit <= "0100100";
				WHEN 6 => alarm_hr_small_digit <= "0100000";
				WHEN 7 => alarm_hr_small_digit <= "0001111";
				WHEN 8 => alarm_hr_small_digit <= "0000000";
				WHEN 9 => alarm_hr_small_digit <= "0000100";
				WHEN OTHERS => NULL;
			END CASE;

			CASE alarm_hr_large IS
				WHEN 0 => alarm_hr_large_digit <= "0000001";
				WHEN 1 => alarm_hr_large_digit <= "1001111";
				WHEN 2 => alarm_hr_large_digit <= "0010010";
			END CASE;
		END PROCESS;

		-- Drive which anode is being updated with what digit
		div <= div + 1 WHEN rising_edge(clk_100MHz);
		which_display <= div(16 DOWNTO 14);

		PROCESS (clk_100MHz)
			BEGIN
				IF rising_edge(clk_100MHz) THEN
					IF (format = '1') THEN
						IF which_display = "111" THEN
							segments <= "1111111"; --blank
							anode <= "01111111";
						ELSIF which_display = "110" THEN
							segments <= "1111111"; --blank
							anode <= "10111111";
						ELSIF which_display = "101" THEN
							segments <= hr_large_digit;
							anode <= "11011111";
						ELSIF which_display = "100" THEN
							segments <= hr_small_digit;
							anode <= "11101111";
						ELSIF which_display = "011" THEN
							segments <= min_large_digit;
							anode <= "11110111";
						ELSIF which_display = "010" THEN
							segments <= min_small_digit;
							anode <= "11111011";
						ELSIF which_display = "001" THEN
							segments <= sec_large_digit;
							anode <= "11111101";
						ELSE
							segments <= sec_small_digit;
							anode <= "11111110";
						END IF;
					ELSE
						IF which_display = "111" THEN
							segments <= alarm_hr_large_digit;
							anode <= "01111111";
						ELSIF which_display = "110" THEN
							segments <= alarm_hr_small_digit;
							anode <= "10111111";
						ELSIF which_display = "101" THEN
							segments <= alarm_min_large_digit;
							anode <= "11011111";
						ELSIF which_display = "100" THEN
							segments <= alarm_min_small_digit;
							anode <= "11101111";
						ELSIF which_display = "011" THEN
							segments <= hr_large_digit;
							anode <= "11110111";
						ELSIF which_display = "010" THEN
							segments <= hr_small_digit;
							anode <= "11111011";
						ELSIF which_display = "001" THEN
							segments <= min_large_digit;
							anode <= "11111101";
						ELSE
							segments <= min_small_digit;
							anode <= "11111110";
						END IF;
					END IF;
				END IF;
			END PROCESS;
END Behavioral;
