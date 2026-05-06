library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity baud_gen is
  generic (
    CLK_FREQ   : integer := 100_000_000;
    BAUD       : integer := 115200;
    OVERSAMPLE : integer := 16
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    tick_16x : out std_logic  -- 1-cycle pulse at (BAUD*OVERSAMPLE)
  );
end baud_gen;

architecture rtl of baud_gen is
  constant DIVISOR : integer := integer(real(CLK_FREQ) / real(BAUD*OVERSAMPLE) + 0.5);
  signal cnt : integer range 0 to DIVISOR-1 := 0;
  signal tck : std_logic := '0';
begin
  tick_16x <= tck;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt <= 0;
        tck <= '0';
      else
        if cnt = DIVISOR-1 then
          cnt <= 0;
          tck <= '1';
        else
          cnt <= cnt + 1;
          tck <= '0';
        end if;
      end if;
    end if;
  end process;
end rtl;

