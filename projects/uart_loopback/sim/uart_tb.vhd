library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity uart_tb is
end uart_tb;

architecture sim of uart_tb is
  -- DUT signals
  signal clk_100MHz : std_logic := '0';
  signal rst        : std_logic := '1';
  signal RxD        : std_logic := '1';  -- idle high
  signal TxD        : std_logic;

  -- constants
  constant CLK_PERIOD : time := 10 ns;  -- 100 MHz
  constant BAUD       : integer := 115200;
  constant BIT_PERIOD : time := 1 sec / BAUD;

  -- stimulus
  type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);
  constant test_data : byte_array := (
    x"55", x"A5", x"0F", x"F0", x"99"
  );

begin
  -- clock gen
  clk_100MHz <= not clk_100MHz after CLK_PERIOD/2;

  -- reset pulse
  process
  begin
    rst <= '1';
    wait for 200 ns;
    rst <= '0';
    wait;
  end process;

  -- DUT
  DUT: entity work.uart_system_top
    port map (
      clk_100MHz => clk_100MHz,
      rst        => rst,
      RxD        => RxD,
      TxD        => TxD
    );

  ----------------------------------------------------------------
  -- UART Stimulus: send bytes on RxD serial line
  ----------------------------------------------------------------
  process
    procedure send_byte(b : std_logic_vector(7 downto 0)) is
    begin
      -- start bit
      RxD <= '0';
      wait for BIT_PERIOD;
      -- data bits (LSB first)
      for i in 0 to 7 loop
        RxD <= b(i);
        wait for BIT_PERIOD;
      end loop;
      -- stop bit
      RxD <= '1';
      wait for BIT_PERIOD;
    end procedure;
  begin
    wait until rst = '0';
    wait for 1 ms;  -- let DUT settle

    for i in test_data'range loop
      report "TB: Sending byte " & integer'image(to_integer(unsigned(test_data(i))));
      send_byte(test_data(i));
      wait for 1 ms; -- space between bytes
    end loop;

    wait for 20 ms;
    report "TB: Simulation finished.";
    wait;
  end process;

  ----------------------------------------------------------------
  -- UART Monitor: watch TxD and reconstruct bytes
  ----------------------------------------------------------------
  process
    variable shiftreg : std_logic_vector(7 downto 0);
  begin
    wait until rst = '0';
    wait;
    while true loop
      -- wait for start bit
      wait until TxD = '0';
      report "TB: Detected start bit on TxD at time " & time'image(now);
      wait for BIT_PERIOD/2;  -- mid start bit sample
      if TxD /= '0' then
        next; -- false start
      end if;
      -- sample data bits
      for i in 0 to 7 loop
        wait for BIT_PERIOD;
        shiftreg(i) := TxD;
        report "TB: Sampled bit " & integer'image(i) &
               " = " & std_logic'image(TxD) &
               " at " & time'image(now);
      end loop;
      -- stop bit
      wait for BIT_PERIOD;
      if TxD = '1' then
        report "TB: Detected start bit on TxD at time " & time'image(now);
        report "TB: Received byte " & integer'image(to_integer(unsigned(shiftreg)));
      else
        report "TB: Framing error on TxD!";
      end if;
    end loop;
  end process;

end sim;
