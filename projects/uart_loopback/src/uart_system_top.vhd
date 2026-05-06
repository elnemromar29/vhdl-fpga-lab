library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity uart_system_top is
  port (
    clk_100MHz : in  std_logic;
    rst        : in  std_logic;   -- active-high, synchronous
    RxD        : in  std_logic;   -- serial in from Pmod
    TxD        : out std_logic    -- serial out to Pmod
  );
end uart_system_top;

architecture rtl of uart_system_top is
  -- UART <-> user-side signals
  signal s_tx_data  : std_logic_vector(7 downto 0);
  signal s_tx_write : std_logic;
  signal s_tx_ready : std_logic;
  signal s_rx_data  : std_logic_vector(7 downto 0);
  signal s_rx_read  : std_logic;
  signal s_rx_valid : std_logic;
  signal s_rx_perr  : std_logic; -- not used on pins, could map to LED if exposed

  -- Loopback FIFO (external buffer between RX user side and TX user side)
  signal lb_din   : std_logic_vector(7 downto 0);
  signal lb_wr_en : std_logic;
  signal lb_full  : std_logic;
  signal lb_dout  : std_logic_vector(7 downto 0);
  signal lb_rd_en : std_logic;
  signal lb_empty : std_logic;
  signal lb_valid : std_logic;

begin
  ------------------------------------------------------------------
  -- UART instance (8N1). You can adjust BAUD generic if desired.
  ------------------------------------------------------------------
  U_UART : entity work.UART
    generic map (
      BAUD => 115200
    )
    port map (
      clk       => clk_100MHz,
      rst       => rst,
      -- serial side
      RxD       => RxD,
      TxD       => TxD,
      -- user side
      Tx_Data   => s_tx_data,
      Tx_Write  => s_tx_write,
      Tx_Ready  => s_tx_ready,
      Rx_Data   => s_rx_data,
      Rx_Read   => s_rx_read,
      Rx_Valid  => s_rx_valid,
      Rx_PError => s_rx_perr
    );

  ------------------------------------------------------------------
  -- External loopback FIFO (FWFT). Named "your_fifo" per your top.
  ------------------------------------------------------------------
  loopback_buffer : entity work.your_fifo
    generic map (
      WIDTH => 8,
      DEPTH => 16
    )
    port map (
      clk   => clk_100MHz,
      rst   => rst,
      din   => lb_din,
      wr_en => lb_wr_en,
      full  => lb_full,
      dout  => lb_dout,
      rd_en => lb_rd_en,
      empty => lb_empty,
      valid => lb_valid
    );

  ------------------------------------------------------------------
  -- Simple handshake glue for user-side loopback
  -- RX path: when UART has data and loopback FIFO not full, pop from
  --          UART RX FIFO and push into loopback buffer.
  -- TX path: when UART ready and loopback has valid data, pop buffer
  --          and push into UART TX FIFO.
  ------------------------------------------------------------------
  lb_din    <= s_rx_data;
  s_tx_data <= lb_dout;

  process(clk_100MHz)
  begin
    if rising_edge(clk_100MHz) then
      if rst = '1' then
        lb_wr_en   <= '0';
        lb_rd_en   <= '0';
        s_rx_read  <= '0';
        s_tx_write <= '0';
      else
        -- defaults
        lb_wr_en   <= '0';
        lb_rd_en   <= '0';
        s_rx_read  <= '0';
        s_tx_write <= '0';

        -- move RX->loopback when possible
        if (s_rx_valid = '1') and (lb_full = '0') then
          lb_wr_en  <= '1';
          s_rx_read <= '1';
        end if;

        -- move loopback->TX when possible
        if (s_tx_ready = '1') and (lb_valid = '1') then
          lb_rd_en   <= '1';
          s_tx_write <= '1';
        end if;
      end if;
    end if;
  end process;

end rtl;

