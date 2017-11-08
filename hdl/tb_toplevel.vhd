library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_toplevel is
  end tb_toplevel;

architecture behavior of tb_toplevel is
  component tinyfpga is
    port (
      pin1_usb_dp, pin2_usb_dn, pin4, pin5, pin6, pin7, pin8, pin9, pin10, pin11, pin12, pin13, pin14_sdo, pin15_sdi, pin16_sck, pin17_ss, pin18, pin19, pin20, pin21, pin22, pin23, pin24 : inout std_logic;
      pin3_clk_16mhz : in std_logic
    );
  end component;

  signal clk : std_logic := '0';
  signal sck : std_logic := '0';
  signal reset : std_logic := '0';
  signal ss : std_logic := '1';
  signal mosi : std_logic := '0';
  signal miso : std_logic;

  -- define the period of clock here.
  constant SPI_PERIOD : time := 100 ns; -- 10MHz
  constant CLK_PERIOD : time := 16 ns;  -- 60MHz

  shared variable ENDSIM : boolean := false;

begin
   -- instantiate the unit under test (uut)
  uut : tinyfpga port map (
                                  pin16_sck => sck,
                                  pin17_ss => ss,
                                  pin15_sdi => mosi,
                                  pin14_sdo => miso,
                                  pin3_clk_16mhz => clk
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