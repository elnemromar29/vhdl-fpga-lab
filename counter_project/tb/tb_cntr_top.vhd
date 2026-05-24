library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_counter_top is
end tb_counter_top;

architecture simulation of tb_counter_top is
    -- Constants
    constant CLOCK_PERIOD : time := 10 ns;
    constant BASE_FREQ : positive := 100;
    constant OUTPUT_FREQ : positive := 10;
    constant REFRESH_DIVIDER : positive := 8;
    constant COUNT_PERIOD : time := (BASE_FREQ / OUTPUT_FREQ) * CLOCK_PERIOD + CLOCK_PERIOD;
    constant DISPLAY_REFRESH : time := 8 * REFRESH_DIVIDER * CLOCK_PERIOD;
    constant DEBOUNCE_PERIOD : time := 4 * REFRESH_DIVIDER * CLOCK_PERIOD;

    -- Segment patterns (active low)
    constant SEG_0 : std_logic_vector(7 downto 0) := "11000000"; -- 0
    constant SEG_1 : std_logic_vector(7 downto 0) := "11111001"; -- 1
    constant SEG_2 : std_logic_vector(7 downto 0) := "10100100"; -- 2
    constant SEG_7 : std_logic_vector(7 downto 0) := "11111000"; -- 7

    -- Signals
    signal clock_signal : std_logic := '0';
    signal reset_signal : std_logic := '0';
    signal switches : std_logic_vector(15 downto 0) := (others => '0');
    signal buttons : std_logic_vector(3 downto 0) := (others => '0');
    signal seven_seg : std_logic_vector(7 downto 0);
    signal seven_seg_select : std_logic_vector(3 downto 0);
    signal leds : std_logic_vector(15 downto 0);

    -- Component declaration
    component cntr_top
        generic (
            CLK_FREQ_HZ : positive := 100_000_000;
            TICK_FREQ_HZ : positive := 1;
            IO_REFRESH_DIVIDER : positive := 50000
        );
        port (
            clk_i : in std_logic;
            reset_i : in std_logic;
            sw_i : in std_logic_vector(15 downto 0);
            pb_i : in std_logic_vector(3 downto 0);
            ss_o : out std_logic_vector(7 downto 0);
            ss_sel_o : out std_logic_vector(3 downto 0);
            led_o : out std_logic_vector(15 downto 0)
        );
    end component;

begin
    -- Instantiate the top-level module
    top_inst : cntr_top
    generic map (
        CLK_FREQ_HZ => BASE_FREQ,
        TICK_FREQ_HZ => OUTPUT_FREQ,
        IO_REFRESH_DIVIDER => REFRESH_DIVIDER
    )
    port map(
        clk_i => clock_signal,
        reset_i => reset_signal,
        sw_i => switches,
        pb_i => buttons,
        ss_o => seven_seg,
        ss_sel_o => seven_seg_select,
        led_o => leds
    );

    -- Clock generation
    clock_gen : process
    begin
        while true loop
            clock_signal <= '0';
            wait for CLOCK_PERIOD / 2;
            clock_signal <= '1';
            wait for CLOCK_PERIOD / 2;
        end loop;
    end process;

    -- Stimulus process
    stim_proc : process
        procedure check_digit(digit_num : integer; expected_seg : std_logic_vector(7 downto 0)) is
            variable sel_expected : std_logic_vector(3 downto 0);
        begin
            case digit_num is
                when 0 => sel_expected := "1110"; -- AN0 active
                when 1 => sel_expected := "1101"; -- AN1 active
                when 2 => sel_expected := "1011"; -- AN2 active
                when 3 => sel_expected := "0111"; -- AN3 active
                when others => sel_expected := "0000";
            end case;
            wait until seven_seg_select = sel_expected and rising_edge(clock_signal);
            assert seven_seg = expected_seg
            report "Digit " & integer'image(digit_num) & " mismatch: expected " & to_string(expected_seg) & ", got " & to_string(seven_seg)
            severity error;
        end procedure;

    begin
        -- Initial reset
        reset_signal <= '1';
        switches <= (others => '0');
        buttons <= (others => '0');
        wait for 20 ns;
        reset_signal <= '0';
        wait for 20 ns;

        -- Test Case 1: Synchronous Reset (SW3 = '1')
        report "Test Case 1: Synchronous Reset";
        switches <= (others => '0');
        switches(3) <= '1'; -- Clear counter
        wait for 2 * COUNT_PERIOD + DISPLAY_REFRESH;
        for i in 0 to 3 loop
            check_digit(i, SEG_0); -- All digits should be 0
        end loop;
        switches(3) <= '0';
        wait for DISPLAY_REFRESH;

        -- Test Case 2: Count Up (SW0 = '0', SW1 = '1')
        report "Test Case 2: Count Up";
        switches <= (others => '0');
        switches(0) <= '0'; -- Run
        switches(1) <= '1'; -- Up
        wait for COUNT_PERIOD + DISPLAY_REFRESH; -- Should be 0001
        check_digit(0, SEG_1); -- Digit 0 should be 1
        check_digit(1, SEG_0);
        check_digit(2, SEG_0);
        check_digit(3, SEG_0);
        wait for COUNT_PERIOD + DISPLAY_REFRESH; -- Should be 0002
        check_digit(0, SEG_2); -- Digit 0 should be 2
        check_digit(1, SEG_0);
        check_digit(2, SEG_0);
        check_digit(3, SEG_0);
        switches(0) <= '1'; -- Hold
        wait for COUNT_PERIOD + DISPLAY_REFRESH;

        -- Test Case 3: Hold (SW0 = '1')
        report "Test Case 3: Hold";
        switches <= (others => '0');
        switches(0) <= '1'; -- Hold
        wait for 2 * COUNT_PERIOD + DISPLAY_REFRESH;
        check_digit(0, SEG_2); -- Still 2
        check_digit(1, SEG_0);
        check_digit(2, SEG_0);
        check_digit(3, SEG_0);

        -- Test Case 4: Count Down (SW0 = '0', SW2 = '1')
        report "Test Case 4: Count Down";
        switches <= (others => '0');
        switches(0) <= '0'; -- Run
        switches(2) <= '1'; -- Down
        wait for COUNT_PERIOD + DISPLAY_REFRESH; -- Should be 0001
        check_digit(0, SEG_1); -- Digit 0 should be 1
        check_digit(1, SEG_0);
        check_digit(2, SEG_0);
        check_digit(3, SEG_0);
        wait for COUNT_PERIOD + DISPLAY_REFRESH; -- Should be 7777 (octal underflow)
        check_digit(0, SEG_7); -- Digit 0 should be 7
        check_digit(1, SEG_7);
        check_digit(2, SEG_7);
        check_digit(3, SEG_7);
        switches(0) <= '1'; -- Hold
        wait for COUNT_PERIOD + DISPLAY_REFRESH;

        -- Test Case 5: Count Up from 7777
        report "Test Case 5: Count Up from 7777";
        switches <= (others => '0');
        switches(0) <= '0'; -- Run
        switches(1) <= '1'; -- Up
        wait for COUNT_PERIOD + DISPLAY_REFRESH; -- Should be 0000 (octal overflow)
        check_digit(0, SEG_0); -- Digit 0 should be 0
        check_digit(1, SEG_0);
        check_digit(2, SEG_0);
        check_digit(3, SEG_0);
        switches(0) <= '1'; -- Hold
        wait for COUNT_PERIOD + DISPLAY_REFRESH;

        -- Test Case 6: Reset Again
        report "Test Case 6: Reset";
        switches <= (others => '0');
        wait for 2 * DEBOUNCE_PERIOD;
        switches(3) <= '1'; -- Clear counter
        wait for 2 * COUNT_PERIOD + DISPLAY_REFRESH;
        for i in 0 to 3 loop
            check_digit(i, SEG_0); -- All digits should be 0
        end loop;
        switches(3) <= '0';

        -- End simulation
        report "Simulation Completed";
        wait;
    end process;

end simulation;
