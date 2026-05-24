
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_counter is
end tb_counter;

architecture simulation of tb_counter is
    constant CLOCK_PERIOD : time := 10 ns;
    constant BASE_FREQ : positive := 100;
    constant OUTPUT_FREQ : positive := 10;
    constant CYCLES_PER_TICK : positive := BASE_FREQ / OUTPUT_FREQ;

    -- Signals
    signal clock_signal : std_logic := '0';
    signal halt_clock : boolean := false;
    signal async_reset : std_logic := '0';
    signal up_enable : std_logic := '0';
    signal down_enable : std_logic := '0';
    signal sync_reset : std_logic := '0';
    signal hold_enable : std_logic := '0';
    signal digit0 : std_logic_vector(3 downto 0);
    signal digit1 : std_logic_vector(3 downto 0);
    signal digit2 : std_logic_vector(3 downto 0);
    signal digit3 : std_logic_vector(3 downto 0);

    procedure wait_ticks(n : integer) is
    begin
        wait for n * CYCLES_PER_TICK * CLOCK_PERIOD + CLOCK_PERIOD;
    end procedure;

    procedure verify_count(
        exp_d3, exp_d2, exp_d1, exp_d0 : integer;
        msg : string
    ) is
    begin
        assert to_integer(unsigned(digit3)) = exp_d3
        report msg & ": Digit3 expected " & integer'image(exp_d3) & ", got " & integer'image(to_integer(unsigned(digit3))) severity error;
        assert to_integer(unsigned(digit2)) = exp_d2
        report msg & ": Digit2 expected " & integer'image(exp_d2) & ", got " & integer'image(to_integer(unsigned(digit2))) severity error;
        assert to_integer(unsigned(digit1)) = exp_d1
        report msg & ": Digit1 expected " & integer'image(exp_d1) & ", got " & integer'image(to_integer(unsigned(digit1))) severity error;
        assert to_integer(unsigned(digit0)) = exp_d0
        report msg & ": Digit0 expected " & integer'image(exp_d0) & ", got " & integer'image(to_integer(unsigned(digit0))) severity error;
    end procedure;

begin
    counter_inst : entity work.cntr(rtl)
    generic map (
        CLK_FREQ_HZ => BASE_FREQ,
        TICK_FREQ_HZ => OUTPUT_FREQ
    )
    port map(
        clk_i => clock_signal,
        reset_i => async_reset,
        cntrup_i => up_enable,
        cntrdown_i => down_enable,
        cntrreset_i => sync_reset,
        cntrhold_i => hold_enable,
        cntr0_o => digit0,
        cntr1_o => digit1,
        cntr2_o => digit2,
        cntr3_o => digit3
    );

    clock_gen : process
    begin
        while not halt_clock loop
            clock_signal <= '0';
            wait for CLOCK_PERIOD / 2;
            clock_signal <= '1';
            wait for CLOCK_PERIOD / 2;
        end loop;
        wait;
    end process clock_gen;

    stim_gen : process
    begin
        -- Initial reset
        async_reset <= '1';
        wait for 20 ns;
        async_reset <= '0';

        -- Test 1: Async Reset
        report "Test 1: Async Reset Check";
        async_reset <= '1';
        wait for 20 ns;
        async_reset <= '0';
        wait for 20 ns;
        verify_count(0, 0, 0, 0, "Post-async reset");

        -- Test 2: Sync Reset
        report "Test 2: Sync Reset Check";
        sync_reset <= '1';
        wait_ticks(1); -- 1-second tick
        sync_reset <= '0';
        verify_count(0, 0, 0, 0, "Post-sync reset");

        -- Test 3: Count Up to 0002
        report "Test 3: Count Up to 0002";
        up_enable <= '1';
        wait_ticks(2); -- 2 seconds
        up_enable <= '0';
        verify_count(0, 0, 0, 2, "Count up to 0002");

        -- Test 4: Hold at 0002
        report "Test 4: Hold at 0002";
        hold_enable <= '1';
        wait_ticks(2); -- 2 seconds
        hold_enable <= '0';
        verify_count(0, 0, 0, 2, "Hold at 0002");

        -- Test 5: Count Up to 0010 (Octal Rollover)
        report "Test 5: Count Up to 0010 with Rollover";
        sync_reset <= '1';
        wait_ticks(1);
        sync_reset <= '0';
        up_enable <= '1';
        wait_ticks(8); -- Reach 0007
        verify_count(0, 0, 0, 7, "Count to 0007");
        wait_ticks(1); -- Rollover to 0010
        verify_count(0, 0, 1, 0, "Count to 0010");
        up_enable <= '0';

        -- Test 6: Count Down with Underflow (0000 to 7777)
        report "Test 6: Count Down to 7777";
        sync_reset <= '1';
        wait_ticks(1);
        sync_reset <= '0';
        down_enable <= '1';
        wait_ticks(1); -- Underflow to 7777
        down_enable <= '0';
        verify_count(7, 7, 7, 7, "Underflow to 7777");

        -- Test 7: Reset Priority Over Up
        report "Test 7: Reset Priority Over Up";
        sync_reset <= '1';
        up_enable <= '1';
        wait_ticks(1);
        sync_reset <= '0';
        up_enable <= '0';
        verify_count(0, 0, 0, 0, "Reset over up");

        -- Test 8: Up Priority Over Down
        report "Test 8: Up Priority Over Down";
        up_enable <= '1';
        down_enable <= '1';
        wait_ticks(1);
        up_enable <= '0';
        down_enable <= '0';
        verify_count(0, 0, 0, 1, "Up over down");

        -- End simulation
        report "Simulation Finished";
        halt_clock <= true;
        wait;
    end process stim_gen;

end simulation;
