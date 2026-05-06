--    NOTE: Entity name is "your_fifo" to match your top-level.
-- =============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity your_fifo is
  generic (
    WIDTH : integer := 8;
    DEPTH : integer := 16
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;          -- synchronous, active high
    din   : in  std_logic_vector(WIDTH-1 downto 0);
    wr_en : in  std_logic;
    full  : buffer std_logic;
    dout  : out std_logic_vector(WIDTH-1 downto 0);
    rd_en : in  std_logic;
    empty : buffer std_logic;
    valid : buffer std_logic           -- equals not empty (FWFT)
  );
end your_fifo;

architecture rtl of your_fifo is
    -- compute ceil(log2(DEPTH)) at elaboration time
  function clog2(n : natural) return natural is
    variable i : natural := 0;
    variable v : natural := 1;
  begin
    while v < n loop
      v := v * 2;
      i := i + 1;
    end loop;
    return i;
  end function;
  constant AW : integer := clog2(DEPTH);
  subtype idx_t is unsigned(AW-1 downto 0);

  type mem_t is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
  signal mem  : mem_t := (others => (others=>'0'));
  signal rd_ptr, wr_ptr : idx_t := (others=>'0');
  signal count : unsigned(AW downto 0) := (others=>'0'); -- up to DEPTH
  signal do    : std_logic_vector(WIDTH-1 downto 0) := (others=>'0');

  function inc_wrap(v: idx_t) return idx_t is
  begin
    if to_integer(v) = DEPTH-1 then
      return (others=>'0');
    else
      return v + 1;
    end if;
  end function;

begin
  dout  <= do;
  empty <= '1' when count = 0 else '0';
  full  <= '1' when count = DEPTH else '0';
  valid <= '0' when count = 0 else '1';

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rd_ptr <= (others=>'0');
        wr_ptr <= (others=>'0');
        count  <= (others=>'0');
        do     <= (others=>'0');
      else
        -- write
        if (wr_en = '1') and (full = '0') then
          mem(to_integer(wr_ptr)) <= din;
          wr_ptr <= inc_wrap(wr_ptr);
          count  <= count + 1;
          -- If FIFO was empty, update DO immediately for FWFT
          if count = 0 then
            do <= din;
          end if;
        end if;
        -- read (pop)
        if (rd_en = '1') and (empty = '0') then
          rd_ptr <= inc_wrap(rd_ptr);
          count  <= count - 1;
          -- update DO to next word if available
          if (count > 1) then
            do <= mem(to_integer(inc_wrap(rd_ptr)));
          end if;
        elsif (count > 0) then
          -- keep DO reflecting current head
          do <= mem(to_integer(rd_ptr));
        end if;
      end if;
    end if;
  end process;
end rtl;

