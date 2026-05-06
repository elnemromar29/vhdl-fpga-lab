library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity uart_tx is
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    tick_16x : in  std_logic;
    data_i   : in  std_logic_vector(7 downto 0);
    data_vld : in  std_logic;   -- FWFT FIFO indicates valid at dout
    pop_i    : out std_logic;   -- pulse to pop from FIFO when we actually take it
    tx_o     : out std_logic;
    busy_o   : out std_logic
  );
end uart_tx;

architecture rtl of uart_tx is
  type state_t is (IDLE, START, DATA, STOP);
  signal state   : state_t := IDLE;
  signal os_cnt  : unsigned(3 downto 0) := (others=>'0');
  signal bit_idx : unsigned(2 downto 0) := (others=>'0');
  signal shreg   : std_logic_vector(7 downto 0) := (others=>'0');
  signal tx      : std_logic := '1';
  signal pop     : std_logic := '0';
  signal busy    : std_logic := '0';

begin
  tx_o   <= tx;
  pop_i  <= pop;
  busy_o <= busy;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state   <= IDLE;
        os_cnt  <= (others=>'0');
        bit_idx <= (others=>'0');
        shreg   <= (others=>'0');
        tx      <= '1';
        pop     <= '0';
        busy    <= '0';
      else
        pop <= '0';
        if tick_16x = '1' then
          case state is
            when IDLE =>
              busy <= '0';
              tx   <= '1';
              if data_vld = '1' then
              report "UART_TX: loading new byte " & integer'image(to_integer(unsigned(data_i))) &
                         " at time " & time'image(now);
                shreg <= data_i;
                pop   <= '1';     -- take the byte now
                state <= START;
                os_cnt<= (others=>'0');
                busy  <= '1';
              end if;

            when START =>
              tx <= '0';
              if os_cnt = to_unsigned(15, os_cnt'length) then
                  os_cnt  <= (others=>'0');
                bit_idx <= (others=>'0');
                state   <= DATA;
              else
                os_cnt <= os_cnt + 1;
              end if;

            when DATA =>
              tx <= shreg(to_integer(bit_idx));
              if os_cnt = to_unsigned(15, os_cnt'length) then
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
              tx <= '1';
              if os_cnt = to_unsigned(15, os_cnt'length) then
              report "STOP " & integer'image(to_integer(unsigned(data_i))) &
                         " at time " & time'image(now);
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
