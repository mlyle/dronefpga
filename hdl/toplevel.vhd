library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.dronefpga_components.all;

entity tinyfpga is
  port (
    pin1_usb_dp, pin2_usb_dn, pin4, pin5, pin6, pin7, pin8, pin9, pin10, pin11, pin12, pin13, pin14_sdo, pin15_sdi, pin16_sck, pin17_ss, pin18, pin19, pin20, pin21, pin22, pin23, pin24 : inout std_logic;
    pin3_clk_16mhz : in std_logic
  );
end entity;

architecture RTL of tinyfpga is
  signal addr                : std_logic_vector(15 downto 0);
  signal wdata               : std_logic_vector(7 downto 0);
  signal rdata               : std_logic_vector(7 downto 0);
  signal write               : std_logic;
  signal strobe              : std_logic;
  signal ack                 : std_logic;
  signal cycle               : std_logic;
  signal clk                 : std_logic;
  signal rst                 : std_logic;

  signal periph_addrs        : array_of_addr(0 downto 0);
  signal periph_wdata        : array_of_data(0 downto 0);
  signal periph_rdata        : array_of_data(0 downto 0);
  signal periph_strobe       : std_logic_vector(0 downto 0);
  signal periph_cycle        : std_logic_vector(0 downto 0);
  signal periph_write        : std_logic_vector(0 downto 0);
  signal periph_ack          : std_logic_vector(0 downto 0);

  signal miso, mosi, sck, ss : std_logic;
  signal outpwm : std_logic;

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
    wbm_cycle     => cycle,
    status_word   => "1100110011100101"
  );

  intercon : wishbone_intercon
  generic map (
    memory_map => (
                    0 => "0000000XXXXXXXXX" -- wish_2812led
    )
  )
  port map (
    gls_reset      => rst,
    gls_clk        => clk,
    wbs_address    => addr,
    wbs_writedata  => wdata,
    wbs_readdata   => rdata,
    wbs_strobe     => strobe,
    wbs_cycle      => cycle,
    wbs_write      => write,
    wbs_ack        => ack,

    wbm_address    => periph_addrs,
    wbm_writedata  => periph_wdata,
    wbm_readdata   => periph_rdata,
    wbm_strobe     => periph_strobe,
    wbm_cycle      => periph_cycle,
    wbm_write      => periph_write,
    wbm_ack        => periph_ack
  );

  slave : wish_2812led port map (
                              clk => clk,
                              rst => rst,
                              wbs_address => periph_addrs(0)(8 downto 0),
                              wbs_writedata => periph_wdata(0),
                              wbs_readdata => periph_rdata(0),
                              wbs_write => periph_write(0),
                              wbs_strobe => periph_strobe(0),
                              wbs_ack => periph_ack(0),
                              outpwm => outpwm
                            );

  clk         <= pin3_clk_16mhz;
  rst         <= pin4;
  mosi        <= pin15_sdi;
  pin14_sdo   <= miso;
  sck         <= pin16_sck;
  ss          <= pin17_ss;
  pin5        <= outpwm;

  pin1_usb_dp <= 'Z';
  pin2_usb_dn <= 'Z';

end architecture RTL;
