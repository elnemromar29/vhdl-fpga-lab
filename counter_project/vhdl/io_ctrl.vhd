-- Project: Counter Project
-- Author: Omar elnemr (ew21b026)
-- Date: 05.06.2025
-- Description: Entity declaration for the IO control unit.

library ieee;
use ieee.std_logic_1164.all;

entity io_ctrl is
   generic (
      REFRESH_DIVIDER : positive := 50000
   );
   port (
      clk_i : in std_logic; -- 100 MHz system clock
      reset_i : in std_logic; -- asynchronous reset
      sw_i : in std_logic_vector(15 downto 0); -- switches
      pb_i : in std_logic_vector(3 downto 0); -- push buttons
      cntr0_i, cntr1_i, cntr2_i, cntr3_i : in std_logic_vector(3 downto 0); -- counter values
      ss_o : out std_logic_vector(7 downto 0); -- 7-segment display
      ss_sel_o : out std_logic_vector(3 downto 0); -- 7-segment display select
      swsync_o : out std_logic_vector(15 downto 0); -- debounced switches
      pbsync_o : out std_logic_vector(3 downto 0) -- debounced push buttons
   );
end io_ctrl;
