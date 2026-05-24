-- Project: Counter Project
-- Author: Omar elnemr (ew21b026)
-- Date: 05.06.2025
-- Description: Architecture of the IO control unit, managing inputs and outputs for the counter project.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of io_ctrl is
    signal clk_counter : unsigned(15 downto 0) := (others => '0');
    signal enable_slow : std_logic := '0';
    signal digit_select : unsigned(1 downto 0) := "00";
    type debounce_sw_t is array (15 downto 0) of std_logic_vector(1 downto 0);
    type debounce_pb_t is array (3 downto 0) of std_logic_vector(1 downto 0);
    signal sw_deb : debounce_sw_t := (others => "00");
    signal pb_deb : debounce_pb_t := (others => "00");
    signal seg_pattern : std_logic_vector(7 downto 0);

begin
    -- Clock divider to 2 kHz
    process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            clk_counter <= (others => '0');
            enable_slow <= '0';
        elsif rising_edge(clk_i) then
            if clk_counter = REFRESH_DIVIDER - 1 then
                clk_counter <= (others => '0');
                enable_slow <= '1';
            else
                clk_counter <= clk_counter + 1;
                enable_slow <= '0';
            end if;
        end if;
    end process;

    -- Digit selection and display decoding
    process (clk_i, reset_i)
        variable current_digit : std_logic_vector(3 downto 0);
    begin
        if reset_i = '1' then
            digit_select <= "00";
            ss_sel_o <= "0000";
            seg_pattern <= "11000000"; -- Display '0'
        elsif rising_edge(clk_i) then
            if enable_slow = '1' then
                digit_select <= digit_select + 1;
                case digit_select is
                    when "00" => ss_sel_o <= "1110"; -- Digit 0
                    when "01" => ss_sel_o <= "1101"; -- Digit 1
                    when "10" => ss_sel_o <= "1011"; -- Digit 2
                    when "11" => ss_sel_o <= "0111"; -- Digit 3
                    when others => ss_sel_o <= "0000";
                end case;

                case digit_select is
                    when "00" => current_digit := cntr0_i;
                    when "01" => current_digit := cntr1_i;
                    when "10" => current_digit := cntr2_i;
                    when "11" => current_digit := cntr3_i;
                    when others => current_digit := "0000";
                end case;

                case current_digit is
                    when "0000" => seg_pattern <= "11000000"; -- 0
                    when "0001" => seg_pattern <= "11111001"; -- 1
                    when "0010" => seg_pattern <= "10100100"; -- 2
                    when "0011" => seg_pattern <= "10110000"; -- 3
                    when "0100" => seg_pattern <= "10011001"; -- 4
                    when "0101" => seg_pattern <= "10010010"; -- 5
                    when "0110" => seg_pattern <= "10000010"; -- 6
                    when "0111" => seg_pattern <= "11111000"; -- 7
                    when "1000" => seg_pattern <= "10000000"; -- 8
                    when "1001" => seg_pattern <= "10010000"; -- 9
                    when others => seg_pattern <= "11111111"; -- Off
                end case;
            end if;
        end if;
    end process;

    ss_o <= seg_pattern;

    -- Switch debouncing
    process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            sw_deb <= (others => "00");
            swsync_o <= (others => '0');
        elsif rising_edge(clk_i) then
            if enable_slow = '1' then
                for i in 0 to 15 loop
                    sw_deb(i) <= sw_deb(i)(0) & sw_i(i);
                    if sw_deb(i) = "11" then
                        swsync_o(i) <= '1';
                    elsif sw_deb(i) = "00" then
                        swsync_o(i) <= '0';
                    end if;
                end loop;
            end if;
        end if;
    end process;

    -- Button debouncing
    process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            pb_deb <= (others => "00");
            pbsync_o <= (others => '0');
        elsif rising_edge(clk_i) then
            if enable_slow = '1' then
                for i in 0 to 3 loop
                    pb_deb(i) <= pb_deb(i)(0) & pb_i(i);
                    if pb_deb(i) = "11" then
                        pbsync_o(i) <= '1';
                    elsif pb_deb(i) = "00" then
                        pbsync_o(i) <= '0';
                    end if;
                end loop;
            end if;
        end if;
    end process;
end rtl;
