library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity uart_rx is
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    tick_16x   : in  std_logic;
    RxD        : in  std_logic;
    data_o     : buffer std_logic_vector(7 downto 0);
    data_stb_o : buffer std_logic;   -- 1?cycle when a byte is ready
    frame_err  : buffer std_logic
  );
end uart_rx;

architecture rtl of uart_rx is
  type state_t is (IDLE, START, DATA, STOP);
  signal state       : state_t := IDLE;
  signal os_cnt      : unsigned(3 downto 0) := (others=>'0'); -- 0..15
  signal bit_idx     : unsigned(2 downto 0) := (others=>'0'); -- 0..7
  signal shreg       : std_logic_vector(7 downto 0) := (others=>'0');
  signal rx_meta, rx_sync : std_logic := '1';
  signal data_stb    : std_logic := '0';
  signal frm_err     : std_logic := '0';

begin
  data_o     <= shreg;
  data_stb_o <= data_stb;
  frame_err  <= frm_err;

  -- 2?FF synchronizer for RxD
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rx_meta <= '1';
        rx_sync <= '1';
      else
        rx_meta <= RxD;
        rx_sync <= rx_meta;
      end if;
    end if;
  end process;

  -- RX FSM
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state   <= IDLE;
        os_cnt  <= (others=>'0');
        bit_idx <= (others=>'0');
        shreg   <= (others=>'0');
        data_stb<= '0';
        frm_err <= '0';
      else
        data_stb <= '0';
        if tick_16x = '1' then
           case state is
            when IDLE =>
              frm_err <= '0';
              if rx_sync = '0' then
              report "UART_RX: loading new byte " & integer'image(to_integer(unsigned(data_o))) &
                         " at time " & time'image(now);
                state  <= START;
                os_cnt <= (others=>'0');
              end if;

            when START =>
              if os_cnt = to_unsigned(7, os_cnt'length) then -- mid start
                  if rx_sync = '0' then
                  os_cnt  <= (others=>'0');
                  bit_idx <= (others=>'0');
                  state   <= DATA;
                else
                  state <= IDLE; -- false start
                end if;
              else
                os_cnt <= os_cnt + 1;
              end if;

            when DATA =>
              if os_cnt = to_unsigned(7, os_cnt'length) then
                -- sample at each bit center (every 16 ticks)
                shreg(to_integer(bit_idx)) <= rx_sync;
                os_cnt <= (others=>'0');
                if bit_idx = 7 then
                  state <= STOP;
                else
                  bit_idx <= bit_idx + 1;
                end if;
              else
                os_cnt <= os_cnt + 1;
              end if;

            when STOP =>
              if os_cnt = to_unsigned(15, os_cnt'length) then
              report "RXSTOP " & integer'image(to_integer(unsigned(data_o))) &
                         " at time " & time'image(now);
                if rx_sync = '1' then
                  data_stb <= '1'; -- byte ready
                else
                  frm_err  <= '1'; -- framing error (stop bit low)
                end if;
                state  <= IDLE;
                os_cnt <= (others=>'0');
              else
                os_cnt <= os_cnt + 1;
              end if;
          end case;
        end if; -- tick
      end if; -- rst
    end if; -- clk
  end process;

end rtl;

