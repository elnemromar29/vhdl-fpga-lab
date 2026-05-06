library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity UART is
  generic (
    CLK_FREQ    : integer := 100_000_000; -- 100 MHz
    BAUD        : integer := 115200;
    OVERSAMPLE  : integer := 16
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    -- serial side
    RxD       : in  std_logic;
    TxD       : out std_logic;
    -- user data/control side
    Tx_Data   : in  std_logic_vector(7 downto 0);
    Tx_Write  : in  std_logic;              -- pulse to write
    Tx_Ready  : out std_logic;              -- space in TX FIFO
    Rx_Data   : out std_logic_vector(7 downto 0);
    Rx_Read   : in  std_logic;              -- pulse to pop RX FIFO
    Rx_Valid  : out std_logic;              -- data present in RX FIFO
    Rx_PError : out std_logic               -- parity error (unused in 8N1 -> '0')
  );
end UART;

architecture rtl of UART is
  -- Baud tick @ x16 oversample
  signal tick_16x : std_logic;

  -- RX FIFO signals (FWFT)
  signal rxf_dout  : std_logic_vector(7 downto 0);
  signal rxf_empty : std_logic;
  signal rxf_valid : std_logic;
  signal rxf_rd_en : std_logic;
  signal rxf_full  : std_logic;
  signal rxf_wr_en : std_logic;
  signal rxf_din   : std_logic_vector(7 downto 0);

  -- TX FIFO signals (FWFT)
  signal txf_dout  : std_logic_vector(7 downto 0);
  signal txf_empty : std_logic;
  signal txf_valid : std_logic;
  signal txf_rd_en : std_logic;
  signal txf_full  : std_logic;
  signal txf_wr_en : std_logic;
  signal txf_din   : std_logic_vector(7 downto 0);

  -- RX/TX cores
  signal rx_data_byte : std_logic_vector(7 downto 0);
  signal rx_data_stb  : std_logic;  -- one?cycle when a byte received OK
  signal rx_frame_err : std_logic;

  signal tx_busy  : std_logic;

begin
  -- BAUD generator
  U_BAUD : entity work.baud_gen
    generic map (
      CLK_FREQ   => CLK_FREQ,
      BAUD       => BAUD,
      OVERSAMPLE => OVERSAMPLE
    )
    port map (
      clk      => clk,
      rst      => rst,
      tick_16x => tick_16x
    );

  -- Receiver core (pushes to RX FIFO)
  U_RX : entity work.uart_rx
    port map (
      clk        => clk,
      rst        => rst,
      tick_16x   => tick_16x,
      RxD        => RxD,
      data_o     => rx_data_byte,
      data_stb_o => rx_data_stb,
      frame_err  => rx_frame_err
    );

  -- RX FIFO (FWFT)
  rxf_din   <= rx_data_byte;
  rxf_wr_en <= rx_data_stb and (not rxf_full);

  U_RXF : entity work.your_fifo
    generic map (WIDTH => 8, DEPTH => 16)
    port map (
      clk   => clk,
      rst   => rst,
      din   => rxf_din,
      wr_en => rxf_wr_en,
      full  => rxf_full,
      dout  => rxf_dout,
      rd_en => rxf_rd_en,
      empty => rxf_empty,
      valid => rxf_valid
    );

  -- expose RX user side
  Rx_Data   <= rxf_dout;
  Rx_Valid  <= rxf_valid;
  rxf_rd_en <= Rx_Read;
  Rx_PError <= '0'; -- no parity used (8N1). Optionally OR with frame error to drive an LED.

  -- TX FIFO (FWFT) -- writes from user, pops into transmitter
  txf_din   <= Tx_Data;
  txf_wr_en <= Tx_Write and (not txf_full);
  Tx_Ready  <= not txf_full;
  

  U_TXF : entity work.your_fifo
    generic map (WIDTH => 8, DEPTH => 16)
    port map (
      clk   => clk,
      rst   => rst,
      din   => txf_din,
      wr_en => txf_wr_en,
      full  => txf_full,
      dout  => txf_dout,
      rd_en => txf_rd_en,
      empty => txf_empty,
      valid => txf_valid
    );

  -- Transmitter core
  U_TX : entity work.uart_tx
    port map (
      clk      => clk,
      rst      => rst,
      tick_16x => tick_16x,
      data_i   => txf_dout,
      data_vld => txf_valid,
      pop_i    => txf_rd_en,
      tx_o     => TxD,
      busy_o   => tx_busy
    );

end rtl;
