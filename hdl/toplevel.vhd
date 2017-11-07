library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tinyfpga is
  port (
    pin1_usb_dp, pin2_usb_dn, pin4, pin5, pin6, pin7, pin8, pin9, pin10, pin11, pin12, pin13, pin14_sdo, pin15_sdi, pin16_sck, pin17_ss, pin18, pin19, pin20, pin21, pin22, pin23, pin24 : inout std_logic;
    pin3_clk_16mhz : in std_logic
  );
end entity;

architecture RTL of tinyfpga is
  component spi_wishmaster is
    port (
      -- SPI SIGNALS
      mosi, ss, sck : in std_logic;
      miso          : out std_logic;

      -- Global Signals
      clk : in std_logic;

      -- Wishbone interface signals
      wbm_address   : out std_logic_vector(15 downto 0);
      wbm_readdata  : in std_logic_vector(7 downto 0);
      wbm_writedata : out std_logic_vector(7 downto 0);
      wbm_strobe    : out std_logic;
      wbm_write     : out std_logic;
      wbm_ack       : in std_logic;
      wbm_cycle     : out std_logic
    );
  end component;

  component dumb_bone is
    port (
      -- Overall system clock
      clk : in std_logic;

      -- Wishbone interface signals
      wbs_address   : in std_logic_vector(15 downto 0);
      wbs_writedata : in std_logic_vector(7 downto 0);
      wbs_readdata  : out std_logic_vector(7 downto 0);
      wbs_write     : in std_logic;
      wbs_strobe    : in std_logic;
      wbs_ack       : out std_logic
    );
  end component;

  signal addr                : std_logic_vector(15 downto 0);
  signal wdata               : std_logic_vector(7 downto 0);
  signal rdata               : std_logic_vector(7 downto 0);
  signal write               : std_logic;
  signal strobe              : std_logic;
  signal ack                 : std_logic;
  signal cycle               : std_logic;
  signal clk                 : std_logic;

  signal miso, mosi, sck, ss : std_logic;

begin
  bridge : spi_wishmaster
  port map(
    sck           => sck,
    ss            => ss,
    mosi          => mosi,
    miso          => miso,
    clk           => clk,
    wbm_address   => addr,
    wbm_readdata  => rdata,
    wbm_writedata => wdata,
    wbm_strobe    => strobe,
    wbm_write     => write,
    wbm_ack       => ack,
    wbm_cycle     => cycle
  );

  -- and our example slave
  slave : dumb_bone
  port map(
    clk           => clk,
    wbs_address   => addr,
    wbs_writedata => wdata,
    wbs_readdata  => rdata,
    wbs_write     => write,
    wbs_strobe    => strobe,
    wbs_ack       => ack
  );

  clk         <= pin3_clk_16mhz;
  mosi        <= pin15_sdi;
  pin14_sdo   <= miso;
  sck         <= pin16_sck;
  ss          <= pin17_ss;

  pin1_usb_dp <= 'Z';
  pin2_usb_dn <= 'Z';

end architecture RTL;
