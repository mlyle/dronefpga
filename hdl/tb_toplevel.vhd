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
  signal rst : std_logic := '0';
  signal ss : std_logic := '1';
  signal mosi : std_logic := '0';
  signal miso : std_logic;
  signal outpwm : std_logic;

  -- define the period of clock here.
  constant SPI_PERIOD : time := 100 ns; -- 10MHz
  constant CLK_PERIOD : time := 16.67 ns;  -- 60MHz

  shared variable ENDSIM : boolean := false;

begin
   -- instantiate the unit under test (uut)
  uut : tinyfpga port map (
                                  pin16_sck => sck,
                                  pin17_ss => ss,
                                  pin15_sdi => mosi,
                                  pin14_sdo => miso,
                                  pin3_clk_16mhz => clk,
                                  pin4 => rst,
                                  pin5 => outpwm
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

    -- select address 1 for transaction, no auto increment, writing.
    wait for SPI_PERIOD*13;

    mosi <= '1';

    wait for SPI_PERIOD;

    mosi <= '0';

    wait for SPI_PERIOD;

    mosi <= '1';

    wait for SPI_PERIOD;

    mosi <= '0';

    wait for SPI_PERIOD*24; --wait for 24 clock cycles. (3 transactions)

    ss <= '1';

    wait for SPI_PERIOD*10; --wait for 10 clock cycles.

    ss <= '0';

    -- **000100 00000011 autoincrement write
    wait for SPI_PERIOD*3;
    mosi <= '1';
    wait for SPI_PERIOD;
    mosi <= '0';
    wait for SPI_PERIOD*8;
    mosi <= '1';

    wait for SPI_PERIOD*500; --wait for 512 clock cycles.

    ss <= '1';

    wait for SPI_PERIOD*1;

    mosi <= '0';
    ss <= '0';

    wait for SPI_PERIOD*12;

    mosi <= '1';

    wait for SPI_PERIOD*100; --wait for 112 clock cycles.

    ss <= '1';

    wait for SPI_PERIOD*2;

    ENDSIM := true;

    wait;
  end process;
end;
