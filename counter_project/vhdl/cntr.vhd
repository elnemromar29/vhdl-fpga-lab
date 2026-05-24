-- Project: Counter Project
-- Author: Omar elnemr (ew21b026)
-- Date: 05.06.2025
-- Description: Entity declaration for the counter unit.

library IEEE;
use IEEE.std_logic_1164.all;

entity cntr is
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
end cntr;
