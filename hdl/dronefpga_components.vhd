library IEEE;
use IEEE.STD_LOGIC_1164.all;

package dronefpga_components is
  component wish_syncer is
    port (
      -- Overall system clock
      clk : in std_logic;

      -- Pseudo-wishbone async slave signals
      wbs_address   : in std_logic_vector(15 downto 0);
      wbs_writedata : in std_logic_vector(7 downto 0);
      wbs_readdata  : out std_logic_vector(7 downto 0);
      wbs_write     : in std_logic;
      wbs_strobe    : in std_logic;

      -- Wishbone interface signals
      wbm_address   : out std_logic_vector(15 downto 0);
      wbm_writedata : out std_logic_vector(7 downto 0);
      wbm_readdata  : in std_logic_vector(7 downto 0);
      wbm_write     : out std_logic;
      wbm_strobe    : out std_logic;
      wbm_ack       : in std_logic;
      wbm_cycle     : out std_logic
    );
  end component;

  component wordpulsegen is
    generic (
      timer_width     : integer;
      active_output   : std_logic;
      inactive_output : std_logic;
      max_word_width  : integer
    );

    port (
      -- Overall system clock
      clk : in std_logic;
      rst : in std_logic;

      word_width        : in std_logic_vector(5 downto 0);  -- XXX
      word_value        : in std_logic_vector(max_word_width-1 downto 0);
                            -- (left justified when partial width)
      wordb_value       : in std_logic_vector(max_word_width-1 downto 0) := (others => '0');
      word_req          : out std_logic;
      word_strobe       : in std_logic;

      one_duration      : in std_logic_vector(timer_width-1 downto 0);
      zero_duration     : in std_logic_vector(timer_width-1 downto 0);
      total_duration    : in std_logic_vector(timer_width-1 downto 0);

      outpwm            : out std_logic;
      outpwmb           : out std_logic
    );
  end component;

  component pulsegen is
    generic (
      timer_width     : integer;
      active_output   : std_logic;
      inactive_output : std_logic
    );

    port (
      -- Overall system clock
      clk : in std_logic;
      rst : in std_logic;

      active_duration  : in std_logic_vector(timer_width-1 downto 0);
      activeb_duration : in std_logic_vector(timer_width-1 downto 0) := (others => '0');
      total_duration   : in std_logic_vector(timer_width-1 downto 0);
      duration_req     : out std_logic;
      duration_strobe  : in std_logic;

      outpwm  : out std_logic;
      outpwmb : out std_logic
    );
  end component;

  component wish_2812led is
    port (
      -- Overall system clock
      clk : in std_logic;
      rst : in std_logic;

      -- Wishbone interface signals
      wbs_address   : in std_logic_vector(8 downto 0);
      wbs_writedata : in std_logic_vector(7 downto 0);
      wbs_readdata  : out std_logic_vector(7 downto 0);
      wbs_write     : in std_logic;
      wbs_strobe    : in std_logic;
      wbs_ack       : out std_logic;

      outpwm        : out std_logic
    );
  end component;

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
    wbm_cycle      : out std_logic;

    -- Status word to return at beginning of transaction
    status_word   : in std_logic_vector(15 downto 0)
  );
  end component;
end dronefpga_components;
