-- Project: Counter Project
-- Author: Omar elnemr (ew21b026)
-- Date: 05.06.2025
-- Description: Entity declaration for the top-level module.

library IEEE;
use IEEE.std_logic_1164.all;

entity cntr_top is
    generic (
        CLK_FREQ_HZ : positive := 100_000_000;
        TICK_FREQ_HZ : positive := 1;
        IO_REFRESH_DIVIDER : positive := 50000
    );
    port (
        clk_i : in std_logic; -- 100 MHz system clock
        reset_i : in std_logic; -- Asynchronous high-active reset
        sw_i : in std_logic_vector(15 downto 0); -- 16-bit switch input
        pb_i : in std_logic_vector(3 downto 0); -- 4-bit pushbutton input
        ss_o : out std_logic_vector(7 downto 0); -- Seven-segment display output
        ss_sel_o : out std_logic_vector(3 downto 0); -- Seven-segment select output
        led_o : out std_logic_vector(15 downto 0) -- LEDs to monitor swsync_o (LD0-LD15)
    );
end cntr_top;
