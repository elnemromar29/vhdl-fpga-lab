
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_io_ctrl is
end tb_io_ctrl;

architecture simulation of tb_io_ctrl is
    -- Signals
    signal clock_signal : std_logic := '0';
    signal reset_signal : std_logic := '0';
    signal switches : std_logic_vector(15 downto 0) := (others => '0');
    signal buttons : std_logic_vector(3 downto 0) := (others => '0');
    signal digit0 : std_logic_vector(3 downto 0) := "0000";
    signal digit1 : std_logic_vector(3 downto 0) := "0000";
    signal digit2 : std_logic_vector(3 downto 0) := "0000";
    signal digit3 : std_logic_vector(3 downto 0) := "0000";
    signal seven_seg : std_logic_vector(7 downto 0);
    signal seven_seg_select : std_logic_vector(3 downto 0);
    signal sync_switches : std_logic_vector(15 downto 0);
    signal sync_buttons : std_logic_vector(3 downto 0);

    -- Component declaration
    component io_ctrl
        generic (
            REFRESH_DIVIDER : positive := 50000
        );
        port (
            clk_i : in std_logic;
            reset_i : in std_logic;
            sw_i : in std_logic_vector(15 downto 0);
            pb_i : in std_logic_vector(3 downto 0);
            cntr0_i : in std_logic_vector(3 downto 0);
            cntr1_i : in std_logic_vector(3 downto 0);
            cntr2_i : in std_logic_vector(3 downto 0);
            cntr3_i : in std_logic_vector(3 downto 0);
            ss_o : out std_logic_vector(7 downto 0);
            ss_sel_o : out std_logic_vector(3 downto 0);
            swsync_o : out std_logic_vector(15 downto 0);
            pbsync_o : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Constants
    constant CLOCK_PERIOD : time := 10 ns; -- 100 MHz
    constant REFRESH_DIVIDER : positive := 8;
    constant DEBOUNCE_PERIOD : time := 4 * REFRESH_DIVIDER * CLOCK_PERIOD;
    constant DISPLAY_REFRESH : time := 8 * REFRESH_DIVIDER * CLOCK_PERIOD;

    -- Function for seven-segment patterns
    function get_seg_pattern(digit : integer) return std_logic_vector is
        variable pattern : std_logic_vector(7 downto 0);
    begin
        case digit is
            when 0 => pattern := "11000000"; -- 0
            when 1 => pattern := "11111001"; -- 1
            when 2 => pattern := "10100100"; -- 2
            when 3 => pattern := "10110000"; -- 3
            when 4 => pattern := "10011001"; -- 4
            when 5 => pattern := "10010010"; -- 5
            when 6 => pattern := "10000010"; -- 6
            when 7 => pattern := "11111000"; -- 7
            when others => pattern := "11111111"; -- Off
        end case;
        return pattern;
    end function;

begin
    -- Instantiate the IO control module
    io_ctrl_inst : io_ctrl
    generic map (
        REFRESH_DIVIDER => REFRESH_DIVIDER
    )
    port map(
        clk_i => clock_signal,
        reset_i => reset_signal,
        sw_i => switches,
        pb_i => buttons,
        cntr0_i => digit0,
        cntr1_i => digit1,
        cntr2_i => digit2,
        cntr3_i => digit3,
        ss_o => seven_seg,
        ss_sel_o => seven_seg_select,
        swsync_o => sync_switches,
        pbsync_o => sync_buttons
    );

    -- Clock generation
    process
    begin
        wait for CLOCK_PERIOD / 2;
        clock_signal <= not clock_signal;
    end process;

    -- Stimulus process
    process
        variable i : integer;
    begin
        -- Initial reset
        reset_signal <= '1';
        switches <= (others => '0');
        buttons <= (others => '0');
        digit0 <= "0000";
        digit1 <= "0000";
        digit2 <= "0000";
        digit3 <= "0000";
        wait for 10 ns;
        reset_signal <= '0';
        wait for 50 ns;

        -- Test 1: Reset behavior
        report "Test 1: Reset Behavior";
        assert seven_seg_select = "0000" report "Reset failed for seven_seg_select" severity error;
        assert seven_seg = get_seg_pattern(0) report "Reset failed for seven_seg" severity error;
        assert sync_switches = "0000000000000000" report "Reset failed for sync_switches" severity error;
        assert sync_buttons = "0000" report "Reset failed for sync_buttons" severity error;

        -- Test 2: Switch debouncing
        report "Test 2: Switch Debouncing";
        for i in 0 to 3 loop
            switches(i) <= '1';
            wait for DEBOUNCE_PERIOD / 4; -- Short pulse
            switches(i) <= '0';
            wait for DEBOUNCE_PERIOD / 4;
            switches(i) <= '1';
            wait for DEBOUNCE_PERIOD; -- Long pulse
            assert sync_switches(i) = '1' report "Switch " & integer'image(i) & " debouncing failed (high)" severity error;
            switches(i) <= '0';
            wait for DEBOUNCE_PERIOD;
            assert sync_switches(i) = '0' report "Switch " & integer'image(i) & " debouncing failed (low)" severity error;
        end loop;

        -- Test 3: Button debouncing
        report "Test 3: Button Debouncing";
        for i in 0 to 3 loop
            buttons(i) <= '1';
            wait for DEBOUNCE_PERIOD / 4;
            buttons(i) <= '0';
            wait for DEBOUNCE_PERIOD / 4;
            buttons(i) <= '1';
            wait for DEBOUNCE_PERIOD;
            assert sync_buttons(i) = '1' report "Button " & integer'image(i) & " debouncing failed (high)" severity error;
            buttons(i) <= '0';
            wait for DEBOUNCE_PERIOD;
            assert sync_buttons(i) = '0' report "Button " & integer'image(i) & " debouncing failed (low)" severity error;
        end loop;

        -- Test 4: Seven-segment display for octal digits (0 to 7)
        report "Test 4: Seven-segment Display for Octal Digits";
        digit0 <= std_logic_vector(to_unsigned(0, 4));
        digit1 <= std_logic_vector(to_unsigned(1, 4));
        digit2 <= std_logic_vector(to_unsigned(2, 4));
        digit3 <= std_logic_vector(to_unsigned(3, 4));
        wait for DISPLAY_REFRESH;

        wait until seven_seg_select = "1110" for DISPLAY_REFRESH; -- Digit 0
        wait for 5 ns;
        assert seven_seg = get_seg_pattern(0) report "Digit 0 display failed" severity error;

        wait until seven_seg_select = "1101" for DISPLAY_REFRESH; -- Digit 1
        wait for 5 ns;
        assert seven_seg = get_seg_pattern(1) report "Digit 1 display failed" severity error;

        wait until seven_seg_select = "1011" for DISPLAY_REFRESH; -- Digit 2
        wait for 5 ns;
        assert seven_seg = get_seg_pattern(2) report "Digit 2 display failed" severity error;

        wait until seven_seg_select = "0111" for DISPLAY_REFRESH; -- Digit 3
        wait for 5 ns;
        assert seven_seg = get_seg_pattern(3) report "Digit 3 display failed" severity error;

        report "Simulation Completed";
        wait;
    end process;

end simulation;
