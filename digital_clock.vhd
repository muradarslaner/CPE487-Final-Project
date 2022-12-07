LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY digital_clock IS
	PORT (
		clk_100MHz : IN STD_LOGIC;

		-- Inputs to change display
		reset : IN STD_LOGIC := '1';
		format : IN STD_LOGIC; -- 1: XXmm hhss, 0: hhmm hhmm

		-- Increment time switches
		btn_up : IN STD_LOGIC := '1';
		btn_next : IN STD_LOGIC := '1';
		btn_down : IN STD_LOGIC := '1';

		-- Time display outputs
		anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		segments : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
		alarmled : OUT STD_LOGIC
	);
END digital_clock;

ARCHITECTURE Behavioral OF digital_clock IS
	-- Clock divider
	SIGNAL clk_1sec : STD_LOGIC;

	COMPONENT clock_divider
		PORT (
			clk_in : IN STD_LOGIC;
			clk_out : OUT STD_LOGIC
		);
	END COMPONENT;

	-- Integer to 7 seg display
	-- Current time
	SIGNAL nx_sec_small_cnt, sec_small_cnt : INTEGER RANGE 0 TO 9 := 0;
	SIGNAL nx_sec_large_cnt, sec_large_cnt : INTEGER RANGE 0 TO 5 := 0;
	SIGNAL nx_min_small_cnt, min_small_cnt : INTEGER RANGE 0 TO 9 := 0;
	SIGNAL nx_min_large_cnt, min_large_cnt : INTEGER RANGE 0 TO 5 := 0;
	SIGNAL nx_hr_small_cnt, hr_small_cnt : INTEGER RANGE 0 TO 9 := 0;
	SIGNAL nx_hr_large_cnt, hr_large_cnt : INTEGER RANGE 0 TO 2 := 0;

	SIGNAL sec_small_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL sec_large_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL min_small_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL min_large_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL hr_small_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL hr_large_digit : STD_LOGIC_VECTOR (6 DOWNTO 0);

	-- Alarm time
	SIGNAL nx_alarm_hr_large, alarm_hr_large : INTEGER RANGE 0 TO 2 := 0;
	SIGNAL nx_alarm_hr_small, alarm_hr_small : INTEGER RANGE 0 TO 9 := 0;
	SIGNAL nx_alarm_min_large, alarm_min_large : INTEGER RANGE 0 TO 5 := 0;
	SIGNAL nx_alarm_min_small, alarm_min_small : INTEGER RANGE 0 TO 9 := 1;

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

	-- 7-seg display 8:1 mux (+ keypad)
	SIGNAL cnt : STD_LOGIC_VECTOR (20 DOWNTO 0) := (OTHERS => '0');
	SIGNAL kp_clk : STD_LOGIC;
	SIGNAL led_mpx : STD_LOGIC_VECTOR (2 DOWNTO 0);

	-- State machine
	SIGNAL sm_clk : STD_LOGIC;

	TYPE state IS (ALARM_HR_L_STATE, ALARM_HR_S_STATE, ALARM_MIN_L_STATE, ALARM_MIN_S_STATE,
		HR_L_STATE, HR_S_STATE, MIN_L_STATE, MIN_S_STATE, RUN_ALARM_CLOCK);

	SIGNAL curr_state, nx_state : state;

BEGIN
	-- Set up 100MHz clock for state machine, LED mux, keypad
	ck_proc : PROCESS (clk_100MHz)
	BEGIN
		IF rising_edge(clk_100MHz) THEN
			cnt <= cnt + 1;
		END IF;
	END PROCESS;

	kp_clk <= cnt(20);
	sm_clk <= cnt(15);
	led_mpx <= cnt(19 DOWNTO 17);

	-- Divide 100MHz clock to 1Hz for calculating time
	create_clk_1sec : clock_divider PORT MAP(clk_in => clk_100MHz, clk_out => clk_1sec);

	-- Set up state machine clock process and transition logic
	sm_ck_pr : PROCESS (reset, sm_clk)
	BEGIN
		IF reset = '0' THEN
			curr_state <= RUN_ALARM_CLOCK;
		ELSIF rising_edge (sm_clk) THEN
			curr_state <= nx_state;
		END IF;
	END PROCESS;

	-- State machine combinatorial process; Determines output of state machine and next state
	sm_comb_pr : PROCESS (curr_state, clk_1sec)
	BEGIN
		CASE curr_state IS
			WHEN ALARM_HR_L_STATE =>
			WHEN ALARM_HR_S_STATE =>
			WHEN ALARM_MIN_L_STATE =>
			WHEN ALARM_MIN_S_STATE =>
			WHEN HR_L_STATE =>
			WHEN HR_S_STATE =>
			WHEN MIN_L_STATE =>
			WHEN MIN_S_STATE =>
			WHEN RUN_ALARM_CLOCK =>
                IF (reset = '0') THEN
                sec_small_cnt <= 0;
                sec_large_cnt <= 0;
                min_small_cnt <= 0;
                min_large_cnt <= 0;
                hr_small_cnt <= 0;
                hr_large_cnt <= 0;
    
                -- alarm_min_small <= 0;
                -- alarm_min_large <= 0;
                -- alarm_hr_small <= 0;
                -- alarm_hr_large <= 0;
                alarmled <= '0';
    
                -- Current time
				ELSIF rising_edge(clk_1sec) THEN
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
					IF (hr_large_cnt = 2 AND hr_small_cnt >= 4) THEN
						sec_small_cnt <= 0;
						sec_large_cnt <= 0;
						min_small_cnt <= 0;
						min_large_cnt <= 0;
						hr_small_cnt <= 0;
						hr_large_cnt <= 0;
					END IF;

					-- Alarm
					IF (hr_large_cnt = alarm_hr_large AND hr_small_cnt = alarm_hr_small AND min_large_cnt = alarm_min_large AND min_small_cnt = alarm_min_small) THEN
						alarmled <= '1'; -- FIXME Alarm goes off a second late?
					END IF;
				END IF;
				
				nx_state <= RUN_ALARM_CLOCK;
		END CASE;
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