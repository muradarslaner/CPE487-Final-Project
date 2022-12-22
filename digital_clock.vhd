LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY digital_clock IS
	PORT (
		clk_100MHz : IN STD_LOGIC;

		-- Buttons and switches
		reset : IN STD_LOGIC; -- BTNL
		btn_next : IN STD_LOGIC; -- BTNR
		format : IN STD_LOGIC; -- SW0; 1: XXmm hhss, 0: hhmm hhmm

		-- Time display
		anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		segments : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
		alarmled : OUT STD_LOGIC;
		led : OUT STD_LOGIC_VECTOR (0 TO 8);

		-- Keypad
		KB_col : OUT STD_LOGIC_VECTOR (4 DOWNTO 1);
		KB_row : IN STD_LOGIC_VECTOR (4 DOWNTO 1);

		-- Alarm
		dac_MCLK : OUT STD_LOGIC;
		dac_LRCK : OUT STD_LOGIC;
		dac_SCLK : OUT STD_LOGIC;
		dac_SDIN : OUT STD_LOGIC
	);
END digital_clock;

ARCHITECTURE Behavioral OF digital_clock IS
	-- Keypad
	SIGNAL kp_clk : STD_LOGIC;
	SIGNAL kp_hit : STD_LOGIC;
	SIGNAL kp_value : INTEGER RANGE 0 TO 10 := 0;

	COMPONENT keypad IS
		PORT (
			samp_ck : IN STD_LOGIC;
			col : OUT STD_LOGIC_VECTOR (4 DOWNTO 1);
			row : IN STD_LOGIC_VECTOR (4 DOWNTO 1);
			value : OUT INTEGER RANGE 0 TO 10;
			hit : OUT STD_LOGIC
		);
	END COMPONENT;
	
	-- State machine
	TYPE state IS (ALARM_HR_L_SET, ALARM_HR_L_KP, ALARM_HR_L_REL,
		ALARM_HR_S_SET, ALARM_HR_S_KP, ALARM_HR_S_REL,
		ALARM_MIN_L_SET, ALARM_MIN_L_KP, ALARM_MIN_L_REL,
		ALARM_MIN_S_SET, ALARM_MIN_S_KP, ALARM_MIN_S_REL,
		HR_L_SET, HR_L_KP, HR_L_REL,
		HR_S_SET, HR_S_KP, HR_S_REL,
		MIN_L_SET, MIN_L_KP, MIN_L_REL,
		MIN_S_SET, MIN_S_KP, RUN_ALARM_CLOCK);
	SIGNAL nx_state : state;
	
	-- Clock divider
	SIGNAL clk_1sec : STD_LOGIC;

	COMPONENT clock_divider
		PORT (
			clk_in : IN STD_LOGIC;
			clk_out : OUT STD_LOGIC
		);
	END COMPONENT;
    
	-- Set alarm time
	SIGNAL nx_alarm_hr_large, alarm_hr_large : INTEGER RANGE 0 TO 2 := 0;
	SIGNAL nx_alarm_hr_small, alarm_hr_small : INTEGER RANGE 0 TO 9 := 0;
	SIGNAL nx_alarm_min_large, alarm_min_large : INTEGER RANGE 0 TO 5 := 0;
	SIGNAL nx_alarm_min_small, alarm_min_small : INTEGER RANGE 0 TO 9 := 0;

	-- Set current time
	SIGNAL nx_hr_large_cnt, hr_large_cnt : INTEGER RANGE 0 TO 2 := 0;
	SIGNAL nx_hr_small_cnt, hr_small_cnt : INTEGER RANGE 0 TO 9 := 0;
	SIGNAL nx_min_large_cnt, min_large_cnt : INTEGER RANGE 0 TO 5 := 0;
	SIGNAL nx_min_small_cnt, min_small_cnt : INTEGER RANGE 0 TO 9 := 0;
	SIGNAL sec_large_cnt : INTEGER RANGE 0 TO 5 := 0;
	SIGNAL sec_small_cnt : INTEGER RANGE 0 TO 9 := 0;
	
	-- Alarm
	SIGNAL playalarm : STD_LOGIC := '0';

	COMPONENT siren IS
		PORT (
			clk_100MHz : IN STD_LOGIC; -- system clock (100 MHz)
			playalarm : IN STD_LOGIC;
			dac_MCLK : OUT STD_LOGIC; -- outputs to PMODI2L DAC
			dac_LRCK : OUT STD_LOGIC;
			dac_SCLK : OUT STD_LOGIC;
			dac_SDIN : OUT STD_LOGIC
		);
	END COMPONENT;
	
	-- Integer to 7 seg display
	-- Display current time
	SIGNAL hr_large_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL hr_small_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL min_large_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL min_small_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL sec_large_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL sec_small_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);

	-- Display alarm time
	SIGNAL alarm_hr_large_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL alarm_hr_small_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL alarm_min_large_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL alarm_min_small_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);

	COMPONENT int_to_segdigit
		PORT (
			int : IN INTEGER;
			segdigit : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
		);
	END COMPONENT;

	-- 7-seg display 8:1 mux
	SIGNAL cnt : STD_LOGIC_VECTOR (20 DOWNTO 0) := (OTHERS => '0');
	SIGNAL led_mpx : STD_LOGIC_VECTOR (2 DOWNTO 0);
BEGIN
	-- Set up 100MHz clock for state machine, LED mux
	ck_proc : PROCESS (clk_100MHz)
	BEGIN
		IF rising_edge(clk_100MHz) THEN
			cnt <= cnt + 1;
		END IF;
	END PROCESS;

	kp_clk <= cnt(16);
	led_mpx <= cnt(19 DOWNTO 17);

	-- Set up keypad logic
	create_keypad : keypad PORT MAP(samp_ck => kp_clk, col => KB_col, row => KB_row, value => kp_value, hit => kp_hit);

	-- State machine
	create_fsm : PROCESS (clk_100MHz, nx_state, btn_next, kp_hit, kp_value)
	BEGIN
		IF rising_edge(clk_100MHZ) THEN
			IF reset = '1' THEN
				nx_state <= ALARM_HR_L_SET;
			ELSE
				CASE nx_state IS
					WHEN ALARM_HR_L_SET =>
						led <= "100000000";
						IF kp_hit = '1' THEN
							IF kp_value < 3 THEN
								nx_alarm_hr_large <= kp_value;
							END IF;
							nx_state <= ALARM_HR_L_KP;
						ELSIF btn_next = '1' THEN
							nx_state <= ALARM_HR_L_REL;
						ELSE
							nx_state <= ALARM_HR_L_SET;
						END IF;
					WHEN ALARM_HR_L_KP =>
						led <= "110000000";
						IF kp_hit = '0' THEN
							nx_state <= ALARM_HR_L_SET;
						ELSE
							nx_state <= ALARM_HR_L_KP;
						END IF;
					WHEN ALARM_HR_L_REL =>
						led <= "111000000";
						IF btn_next = '0' THEN
							nx_state <= ALARM_HR_S_SET;
						ELSE
							nx_state <= ALARM_HR_L_REL;
						END IF;

					WHEN ALARM_HR_S_SET =>
						led <= "010000000";
						IF kp_hit = '1' THEN
							IF (kp_value < 4) OR (kp_value < 10 AND nx_alarm_hr_large /= 2) THEN
								nx_alarm_hr_small <= kp_value;
							END IF;
							nx_state <= ALARM_HR_S_KP;
						ELSIF btn_next = '1' THEN
							nx_state <= ALARM_HR_S_REL;
						ELSE
							nx_state <= ALARM_HR_S_SET;
						END IF;
					WHEN ALARM_HR_S_KP =>
						led <= "011000000";
						IF kp_hit = '0' THEN
							nx_state <= ALARM_HR_S_SET;
						ELSE
							nx_state <= ALARM_HR_S_KP;
						END IF;
					WHEN ALARM_HR_S_REL =>
						led <= "011100000";
						IF btn_next = '0' THEN
							nx_state <= ALARM_MIN_L_SET;
						ELSE
							nx_state <= ALARM_HR_S_REL;
						END IF;

					WHEN ALARM_MIN_L_SET =>
						led <= "001000000";
						IF kp_hit = '1' THEN
							IF kp_value < 6 THEN
								nx_alarm_min_large <= kp_value;
							END IF;
							nx_state <= ALARM_MIN_L_KP;
						ELSIF btn_next = '1' THEN
							nx_state <= ALARM_MIN_L_REL;
						ELSE
							nx_state <= ALARM_MIN_L_SET;
						END IF;
					WHEN ALARM_MIN_L_KP =>
						led <= "001100000";
						IF kp_hit = '0' THEN
							nx_state <= ALARM_MIN_L_SET;
						ELSE
							nx_state <= ALARM_MIN_L_KP;
						END IF;
					WHEN ALARM_MIN_L_REL =>
						led <= "001110000";
						IF btn_next = '0' THEN
							nx_state <= ALARM_MIN_S_SET;
						ELSE
							nx_state <= ALARM_MIN_L_REL;
						END IF;

					WHEN ALARM_MIN_S_SET =>
						led <= "000100000";
						IF kp_hit = '1' THEN
							nx_alarm_min_small <= kp_value;
							nx_state <= ALARM_MIN_S_KP;
						ELSIF btn_next = '1' THEN
							nx_state <= ALARM_MIN_S_REL;
						ELSE
							nx_state <= ALARM_MIN_S_SET;
						END IF;
					WHEN ALARM_MIN_S_KP =>
						led <= "000110000";
						IF kp_hit = '0' THEN
							nx_state <= ALARM_MIN_S_SET;
						ELSE
							nx_state <= ALARM_MIN_S_KP;
						END IF;
					WHEN ALARM_MIN_S_REL =>
						led <= "000111000";
						IF btn_next = '0' THEN
							nx_state <= HR_L_SET;
						ELSE
							nx_state <= ALARM_MIN_S_REL;
						END IF;

					WHEN HR_L_SET =>
						led <= "000010000";
						IF kp_hit = '1' THEN
							IF kp_value < 3 THEN
								nx_hr_large_cnt <= kp_value;
							END IF;
							nx_state <= HR_L_KP;
						ELSIF btn_next = '1' THEN
							nx_state <= HR_L_REL;
						ELSE
							nx_state <= HR_L_SET;
						END IF;
					WHEN HR_L_KP =>
						led <= "000011000";
						IF kp_hit = '0' THEN
							nx_state <= HR_L_SET;
						ELSE
							nx_state <= HR_L_KP;
						END IF;
					WHEN HR_L_REL =>
						led <= "000011100";
						IF btn_next = '0' THEN
							nx_state <= HR_S_SET;
						ELSE
							nx_state <= HR_L_REL;
						END IF;

					WHEN HR_S_SET =>
						led <= "000001000";
						IF kp_hit = '1' THEN
							IF (kp_value < 4) OR (kp_value < 10 AND nx_hr_large_cnt /= 2) THEN
								nx_hr_small_cnt <= kp_value;
							END IF;
							nx_state <= HR_S_KP;
						ELSIF btn_next = '1' THEN
							nx_state <= HR_S_REL;
						ELSE
							nx_state <= HR_S_SET;
						END IF;
					WHEN HR_S_KP =>
						led <= "000001100";
						IF kp_hit = '0' THEN
							nx_state <= HR_S_SET;
						ELSE
							nx_state <= HR_S_KP;
						END IF;
					WHEN HR_S_REL =>
						led <= "000001110";
						IF btn_next = '0' THEN
							nx_state <= MIN_L_SET;
						ELSE
							nx_state <= HR_S_REL;
						END IF;

					WHEN MIN_L_SET =>
						led <= "000000100";
						IF kp_hit = '1' THEN
							IF kp_value < 6 THEN
								nx_min_large_cnt <= kp_value;
							END IF;
							nx_state <= MIN_L_KP;
						ELSIF btn_next = '1' THEN
							nx_state <= MIN_L_REL;
						ELSE
							nx_state <= MIN_L_SET;
						END IF;
					WHEN MIN_L_KP =>
						led <= "000000110";
						IF kp_hit = '0' THEN
							nx_state <= MIN_L_SET;
						ELSE
							nx_state <= MIN_L_KP;
						END IF;
					WHEN MIN_L_REL =>
						led <= "000000111";
						IF btn_next = '0' THEN
							nx_state <= MIN_S_SET;
						ELSE
							nx_state <= MIN_L_REL;
						END IF;

					WHEN MIN_S_SET =>
						led <= "000000010";
						IF kp_hit = '1' THEN
							nx_min_small_cnt <= kp_value;
							nx_state <= MIN_S_KP;
						ELSIF btn_next = '1' THEN
							nx_state <= RUN_ALARM_CLOCK;
						ELSE
							nx_state <= MIN_S_SET;
						END IF;
					WHEN MIN_S_KP =>
						led <= "000000011";
						IF kp_hit = '0' THEN
							nx_state <= MIN_S_SET;
						ELSE
							nx_state <= MIN_S_KP;
						END IF;
					WHEN RUN_ALARM_CLOCK =>
						led <= "111111111";
						nx_state <= RUN_ALARM_CLOCK;
				END CASE;
			END IF;
		END IF;
	END PROCESS;

	-- Divide 100MHz clock to 1Hz for calculating time
	create_clk_1sec : clock_divider PORT MAP(clk_in => clk_100MHz, clk_out => clk_1sec);
	
	-- Set up alarm sound
	create_alarm : siren PORT MAP(
		clk_100MHz => clk_100MHz, playalarm => playalarm,
		dac_MCLK => dac_MCLK, dac_LRCK => dac_LRCK, dac_SCLK => dac_SCLK, dac_SDIN => dac_SDIN);
	
	clk_logic : PROCESS (nx_state, reset, clk_1sec,
		nx_alarm_hr_large, nx_alarm_hr_small, nx_alarm_min_large, nx_alarm_min_small,
		alarm_hr_large, alarm_hr_small, alarm_min_large, alarm_min_small,
		nx_hr_large_cnt, nx_hr_small_cnt, nx_min_large_cnt, nx_min_small_cnt,
		hr_large_cnt, hr_small_cnt, min_large_cnt, min_small_cnt)
	BEGIN
		IF reset = '1' THEN
			hr_large_cnt <= 0;
			hr_small_cnt <= 0;
			min_large_cnt <= 0;
			min_small_cnt <= 0;
			sec_large_cnt <= 0;
			sec_small_cnt <= 0;

			alarm_hr_large <= 0;
			alarm_hr_small <= 0;
			alarm_min_large <= 0;
			alarm_min_small <= 0;

			alarmled <= '0';
			playalarm <= '0';

		ELSIF (nx_state = ALARM_HR_L_SET) THEN
			alarm_hr_large <= nx_alarm_hr_large;
		ELSIF (nx_state = ALARM_HR_S_SET) THEN
			alarm_hr_small <= nx_alarm_hr_small;
		ELSIF (nx_state = ALARM_MIN_L_SET) THEN
			alarm_min_large <= nx_alarm_min_large;
		ELSIF (nx_state = ALARM_MIN_S_SET) THEN
			alarm_min_small <= nx_alarm_min_small;
		ELSIF (nx_state = HR_L_SET) THEN
			hr_large_cnt <= nx_hr_large_cnt;
		ELSIF (nx_state = HR_S_SET) THEN
			hr_small_cnt <= nx_hr_small_cnt;
		ELSIF (nx_state = MIN_L_SET) THEN
			min_large_cnt <= nx_min_large_cnt;
		ELSIF (nx_state = MIN_S_SET) THEN
			min_small_cnt <= nx_min_small_cnt;

		ELSIF (nx_state = RUN_ALARM_CLOCK) THEN
			IF rising_edge(clk_1sec) THEN
				sec_small_cnt <= sec_small_cnt + 1;
				IF (sec_small_cnt >= 9) THEN
					sec_small_cnt <= 0;
					sec_large_cnt <= sec_large_cnt + 1;
					IF (sec_large_cnt >= 5) THEN
						sec_large_cnt <= 0;
						min_small_cnt <= min_small_cnt + 1;
						IF (min_small_cnt >= 9) THEN
							min_small_cnt <= 0;
							min_large_cnt <= min_large_cnt + 1;
							IF (min_large_cnt >= 5) THEN
								min_large_cnt <= 0;
								hr_small_cnt <= hr_small_cnt + 1;
								IF (hr_small_cnt >= 9) THEN
									hr_small_cnt <= 0;
									hr_large_cnt <= hr_large_cnt + 1;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
				IF (hr_large_cnt = 2 AND hr_small_cnt >= 3 AND min_large_cnt >= 5 AND min_small_cnt >= 9 AND sec_large_cnt >= 5 AND sec_small_cnt >= 9) THEN
					hr_large_cnt <= 0;
					hr_small_cnt <= 0;
					min_large_cnt <= 0;
					min_small_cnt <= 0;
					sec_large_cnt <= 0;
					sec_small_cnt <= 0;
				END IF;
			END IF;
			-- Alarm
			IF (hr_large_cnt = alarm_hr_large AND hr_small_cnt = alarm_hr_small AND min_large_cnt = alarm_min_large AND min_small_cnt = alarm_min_small) THEN
				alarmled <= '1';
				playalarm <= '1';
			END IF;
		END IF;
	END PROCESS;
	-- Translate each digit on the clock to 7-seg cathode values
	convert_sec_small : int_to_segdigit PORT MAP(int => sec_small_cnt, segdigit => sec_small_digit);
	convert_sec_large : int_to_segdigit PORT MAP(int => sec_large_cnt, segdigit => sec_large_digit);
	convert_min_small : int_to_segdigit PORT MAP(int => min_small_cnt, segdigit => min_small_digit);
	convert_min_large : int_to_segdigit PORT MAP(int => min_large_cnt, segdigit => min_large_digit);
	convert_hr_small : int_to_segdigit PORT MAP(int => hr_small_cnt, segdigit => hr_small_digit);
	convert_hr_large : int_to_segdigit PORT MAP(int => hr_large_cnt, segdigit => hr_large_digit);

	convert_alarm_min_small : int_to_segdigit PORT MAP(int => alarm_min_small, segdigit => alarm_min_small_digit);
	convert_alarm_min_large : int_to_segdigit PORT MAP(int => alarm_min_large, segdigit => alarm_min_large_digit);
	convert_alarm_hr_small : int_to_segdigit PORT MAP(int => alarm_hr_small, segdigit => alarm_hr_small_digit);
	convert_alarm_hr_large : int_to_segdigit PORT MAP(int => alarm_hr_large, segdigit => alarm_hr_large_digit);

	-- Drive which anode is being updated with what digit
	which_display : PROCESS (clk_100MHz, format)
	BEGIN
		IF rising_edge(clk_100MHz) THEN
			IF (format = '1') THEN
				IF led_mpx = "111" THEN
					segments <= "1111111"; -- Blank
					anode <= "01111111";
				ELSIF led_mpx = "110" THEN
					segments <= "1111111"; -- Blank
					anode <= "10111111";
				ELSIF led_mpx = "101" THEN
					segments <= hr_large_digit;
					anode <= "11011111";
				ELSIF led_mpx = "100" THEN
					segments <= hr_small_digit;
					anode <= "11101111";
				ELSIF led_mpx = "011" THEN
					segments <= min_large_digit;
					anode <= "11110111";
				ELSIF led_mpx = "010" THEN
					segments <= min_small_digit;
					anode <= "11111011";
				ELSIF led_mpx = "001" THEN
					segments <= sec_large_digit;
					anode <= "11111101";
				ELSE
					segments <= sec_small_digit;
					anode <= "11111110";
				END IF;
			ELSE
				IF led_mpx = "111" THEN
					segments <= alarm_hr_large_digit;
					anode <= "01111111";
				ELSIF led_mpx = "110" THEN
					segments <= alarm_hr_small_digit;
					anode <= "10111111";
				ELSIF led_mpx = "101" THEN
					segments <= alarm_min_large_digit;
					anode <= "11011111";
				ELSIF led_mpx = "100" THEN
					segments <= alarm_min_small_digit;
					anode <= "11101111";
				ELSIF led_mpx = "011" THEN
					segments <= hr_large_digit;
					anode <= "11110111";
				ELSIF led_mpx = "010" THEN
					segments <= hr_small_digit;
					anode <= "11111011";
				ELSIF led_mpx = "001" THEN
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
