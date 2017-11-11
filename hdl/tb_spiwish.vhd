library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dronefpga_components.all;

entity tb_spiwish is
end tb_spiwish;

architecture behavior of tb_spiwish is
  signal clk : std_logic := '0';
  signal sck : std_logic := '0';
  signal rst : std_logic := '0';
  signal ss : std_logic := '1';
  signal mosi : std_logic := '0';
  signal miso : std_logic;
  signal outpwm : std_logic;

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
                                  wbm_cycle => cycle,
                                  status_word => "1100110011100101"
                                );

  -- and our example slave
  slave : wish_2812led port map (
                              clk => clk,
                              rst => rst,
                              wbs_address => addr(8 downto 0),
                              wbs_writedata => wdata,
                              wbs_readdata => rdata,
                              wbs_write => write,
                              wbs_strobe => strobe,
                              wbs_ack => ack,
                              outpwm => outpwm
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
    wait for CLK_PERIOD*5;

    rst <= '1';

    wait for CLK_PERIOD*5;

    rst <= '0';

    wait until sck='0';

    wait for SPI_PERIOD*2; --wait for 2 clock cycles.
    ss <= '0';

    wait for SPI_PERIOD*32; --wait for 32 clock cycles.

    ss <= '1';

    wait for SPI_PERIOD*10; --wait for 10 clock cycles.

    ss <= '0';

    wait for SPI_PERIOD*12;
    mosi <= '1';

    wait for SPI_PERIOD*500; --wait for 512 clock cycles.

    ss <= '1';

    wait for SPI_PERIOD*2; --wait a lil more

    ENDSIM := true;

    wait;
  end process;
end;
