-- Project: Counter Project
-- Author: Omar elnemr (ew21b026)
-- Date: 05.06.2025
-- Description: Architecture of the counter unit, implementing an octal up/down counter with 1 Hz frequency.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture rtl of cntr is
    constant DIVIDER_VALUE : positive := CLK_FREQ_HZ / TICK_FREQ_HZ;

    signal clk_divider : natural range 0 to DIVIDER_VALUE - 1 := 0;
    signal tick_1hz : std_logic := '0';
    signal d0, d1, d2, d3 : unsigned(3 downto 0) := (others => '0');

begin
    assert CLK_FREQ_HZ >= TICK_FREQ_HZ
        report "CLK_FREQ_HZ must be greater than or equal to TICK_FREQ_HZ"
        severity failure;

    p_clk_div : process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            clk_divider <= 0;
            tick_1hz <= '0';
        elsif rising_edge(clk_i) then
            if clk_divider = DIVIDER_VALUE - 1 then
                clk_divider <= 0;
                tick_1hz <= '1';
            else
                clk_divider <= clk_divider + 1;
                tick_1hz <= '0';
            end if;
        end if;
    end process p_clk_div;

    p_count : process (clk_i, reset_i)
        variable increment_carry : std_logic;
        variable decrement_carry : std_logic;
    begin
        if reset_i = '1' then
            d0 <= (others => '0');
            d1 <= (others => '0');
            d2 <= (others => '0');
            d3 <= (others => '0');
        elsif rising_edge(clk_i) then
            if tick_1hz = '1' then
                if cntrreset_i = '1' then
                    d0 <= (others => '0');
                    d1 <= (others => '0');
                    d2 <= (others => '0');
                    d3 <= (others => '0');
                elsif cntrhold_i = '1' then
                    null;
                elsif cntrup_i = '1' then
                    increment_carry := '0';
                    if d0 = 7 then
                        d0 <= (others => '0');
                        increment_carry := '1';
                    else
                        d0 <= d0 + 1;
                    end if;
                    if increment_carry = '1' then
                        if d1 = 7 then
                            d1 <= (others => '0');
                            increment_carry := '1';
                        else
                            d1 <= d1 + 1;
                            increment_carry := '0';
                        end if;
                    end if;
                    if increment_carry = '1' then
                        if d2 = 7 then
                            d2 <= (others => '0');
                            increment_carry := '1';
                        else
                            d2 <= d2 + 1;
                            increment_carry := '0';
                        end if;
                    end if;
                    if increment_carry = '1' then
                        if d3 = 7 then
                            d3 <= (others => '0');
                        else
                            d3 <= d3 + 1;
                        end if;
                    end if;
                elsif cntrdown_i = '1' and cntrup_i = '0' then
                    decrement_carry := '0';
                    if d0 = 0 then
                        d0 <= to_unsigned(7, 4);
                        decrement_carry := '1';
                    else
                        d0 <= d0 - 1;
                        decrement_carry := '0';
                    end if;
                    if decrement_carry = '1' then
                        if d1 = 0 then
                            d1 <= to_unsigned(7, 4);
                            decrement_carry := '1';
                        else
                            d1 <= d1 - 1;
                            decrement_carry := '0';
                        end if;
                    end if;
                    if decrement_carry = '1' then
                        if d2 = 0 then
                            d2 <= to_unsigned(7, 4);
                            decrement_carry := '1';
                        else
                            d2 <= d2 - 1;
                            decrement_carry := '0';
                        end if;
                    end if;
                    if decrement_carry = '1' then
                        if d3 = 0 then
                            d3 <= to_unsigned(7, 4);
                        else
                            d3 <= d3 - 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process p_count;

    cntr0_o <= std_logic_vector(d0);
    cntr1_o <= std_logic_vector(d1);
    cntr2_o <= std_logic_vector(d2);
    cntr3_o <= std_logic_vector(d3);

end rtl;
