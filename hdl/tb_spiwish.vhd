library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spiwish is
  end tb_spiwish;

architecture behavior of tb_spiwish is
  component spi_wishmaster is
    port
    (
    -- SPI SIGNALS
    mosi, ss, sck : in std_logic;
    miso : out std_logic;

    -- Global Signals
    clk            : in std_logic;

    -- Wishbone interface signals
    wbm_address    : out std_logic_vector(15 downto 0);
    wbm_readdata   : in  std_logic_vector(7 downto 0);
    wbm_writedata  : out std_logic_vector(7 downto 0);
    wbm_strobe     : out std_logic;
    wbm_write      : out std_logic;
    wbm_ack        : in std_logic;
    wbm_cycle      : out std_logic
  );
  end component;

  component dumb_bone is
    port
    (
      -- Overall system clock
      clk : in std_logic;

      -- Wishbone interface signals
      wbs_address    : in std_logic_vector(15 downto 0);
      wbs_writedata  : in std_logic_vector(7 downto 0);
      wbs_readdata   : out  std_logic_vector(7 downto 0);
      wbs_write      : in std_logic;
      wbs_strobe     : in std_logic;
      wbs_ack        : out std_logic
    );
  end component;

  signal clk : std_logic := '0';
  signal sck : std_logic := '0';
  signal reset : std_logic := '0';
  signal ss : std_logic := '1';
  signal mosi : std_logic := '0';
  signal miso : std_logic;

  signal addr : std_logic_vector(15 downto 0);
  signal wdata : std_logic_vector(7 downto 0);
  signal rdata : std_logic_vector(7 downto 0);
  signal write : std_logic;
  signal strobe : std_logic;
  signal ack : std_logic;
  signal cycle: std_logic;

  -- define the period of clock here.
  constant SPI_PERIOD : time := 100 ns; -- 10MHz
  constant CLK_PERIOD : time := 16 ns;  -- 60MHz

  shared variable ENDSIM : boolean := false;

begin
   -- instantiate the unit under test (uut)
  uut : spi_wishmaster port map (
                                  sck => sck,
                                  ss => ss,
                                  mosi => mosi,
                                  miso => miso,
                                  clk => clk,
                                  wbm_address => addr,
                                  wbm_readdata => rdata,
                                  wbm_writedata => wdata,
                                  wbm_strobe => strobe,
                                  wbm_write => write,
                                  wbm_ack => ack,
                                  wbm_cycle => cycle
                                );

  -- and our example slave
  slave : dumb_bone port map (
                              clk => clk,
                              wbs_address => addr,
                              wbs_writedata => wdata,
                              wbs_readdata => rdata,
                              wbs_write => write,
                              wbs_strobe => strobe,
                              wbs_ack => ack
                            );


  -- Clock processes
  clk_process :process
  begin
    if ENDSIM=false then
      clk <= '0';
      wait for CLK_PERIOD/2;  --for half of clock period clk stays at '0'.
      clk <= '1';
      wait for CLK_PERIOD/2;  --for next half of clock period clk stays at '1'.
    else
      wait;
    end if;
  end process;

  sck_process :process
  begin
    if ENDSIM=false then
      sck <= '0';
      wait for SPI_PERIOD/2;  --for half of clock period sck stays at '0'.
      sck <= '1';
      wait for SPI_PERIOD/2;  --for next half of clock period sck stays at '1'.
    else
      wait;
    end if;
  end process;

  -- Stimulus process, Apply inputs here.
  stim_proc: process
  begin
    wait for SPI_PERIOD*10; --wait for 10 clock cycles.
    ss <= '0';

    wait for SPI_PERIOD*32; --wait for 32 clock cycles.

    ss <= '1';

    wait for SPI_PERIOD*10; --wait for 10 clock cycles.

    ss <= '0';

    wait for SPI_PERIOD*12;
    mosi <= '1';

    wait for SPI_PERIOD*52; --wait for 64 clock cycles.

    ss <= '1';

    wait for SPI_PERIOD*2; --wait a lil more

    ENDSIM := true;

    wait;
  end process;
end;
