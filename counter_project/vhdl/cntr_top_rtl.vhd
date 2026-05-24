-- Project: Counter Project
-- Author: Omar elnemr (ew21b026)
-- Date: 05.06.2025
-- Description: Top-level architecture integrating the counter and IO control units.

library IEEE;
use IEEE.std_logic_1164.all;

architecture rtl of cntr_top is
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
            swsync_o : out std_logic_vector(15 downto 0);
            pbsync_o : out std_logic_vector(3 downto 0);
            ss_o : out std_logic_vector(7 downto 0);
            ss_sel_o : out std_logic_vector(3 downto 0)
        );
    end component;

    component cntr
        generic (
            CLK_FREQ_HZ : positive := 100_000_000;
            TICK_FREQ_HZ : positive := 1
        );
        port (
            clk_i : in std_logic;
            reset_i : in std_logic;
            cntrup_i : in std_logic;
            cntrdown_i : in std_logic;
            cntrreset_i : in std_logic;
            cntrhold_i : in std_logic;
            cntr0_o : out std_logic_vector(3 downto 0);
            cntr1_o : out std_logic_vector(3 downto 0);
            cntr2_o : out std_logic_vector(3 downto 0);
            cntr3_o : out std_logic_vector(3 downto 0)
        );
    end component;

    signal sync_switches : std_logic_vector(15 downto 0);
    signal sync_buttons : std_logic_vector(3 downto 0);
    signal count0, count1, count2, count3 : std_logic_vector(3 downto 0);
    signal hold_signal : std_logic;

begin
    hold_signal <= sync_switches(0);

    io_unit : io_ctrl
    generic map (
        REFRESH_DIVIDER => IO_REFRESH_DIVIDER
    )
    port map (
        clk_i => clk_i,
        reset_i => reset_i,
        sw_i => sw_i,
        pb_i => pb_i,
        cntr0_i => count0,
        cntr1_i => count1,
        cntr2_i => count2,
        cntr3_i => count3,
        swsync_o => sync_switches,
        pbsync_o => sync_buttons,
        ss_o => ss_o,
        ss_sel_o => ss_sel_o
    );

    led_o <= sync_switches;

    counter_unit : cntr
    generic map (
        CLK_FREQ_HZ => CLK_FREQ_HZ,
        TICK_FREQ_HZ => TICK_FREQ_HZ
    )
    port map (
        clk_i => clk_i,
        reset_i => reset_i,
        cntrup_i => sync_switches(1),
        cntrdown_i => sync_switches(2),
        cntrreset_i => sync_switches(3),
        cntrhold_i => hold_signal,
        cntr0_o => count0,
        cntr1_o => count1,
        cntr2_o => count2,
        cntr3_o => count3
    );

end rtl;
