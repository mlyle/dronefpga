library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.dronefpga_components.all;

entity wish_2812led is
  port (
    -- Overall system clock and reset
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
end entity;

-- ----------------------------------------------------------------------------
architecture RTL of wish_2812led is
  type mem_type is array (511 downto 0) of std_logic_vector(7 downto 0);

  signal mem : mem_type;

  signal acking : std_logic;
  signal do_wish_write : std_logic;

  signal num_bytes : unsigned(8 downto 0);

  signal read_next_byte : std_logic;
  signal read_in_prog : std_logic;
  signal next_byte : unsigned(8 downto 0);
  signal mem_raddr : unsigned(8 downto 0);
  signal mem_rdata : std_logic_vector(7 downto 0);
  signal mem_waddr : unsigned(8 downto 0);

  signal to_clock_out : std_logic_vector(7 downto 0);

  signal word_req : std_logic;
  signal word_strobe : std_logic;
begin

  process (clk)
  begin
    if clk'EVENT and clk = '1' then
      if rst = '1' then
        num_bytes <= (others => '0');
        next_byte <= (others => '0');
        read_in_prog <= '0';

        for i in mem'low to mem'high loop
          --mem(i) <= std_logic_vector(to_unsigned(i, 8));
        end loop;
      else
        read_in_prog <= read_next_byte;

        if read_in_prog = '1' then
          next_byte <= next_byte + 1;
        end if;

        if word_req = '1' then
          acking <= '0';
        elsif wbs_strobe = '1' then
          acking <= '1';

          if wbs_write = '1' then
            if (mem_waddr = 0) then
              num_bytes <= unsigned('0' & wbs_writedata) + unsigned('0' & wbs_writedata) + unsigned('0' & wbs_writedata);
            end if;

          end if;
        else
          acking <= '0';
        end if;
      end if;

      mem_rdata <= mem(to_integer(mem_raddr));

      if do_wish_write = '1' then
        mem(to_integer(mem_waddr)) <= wbs_writedata;
      end if;
    end if;
  end process;

  mem_waddr <= unsigned(wbs_address);

  wbs_ack <= wbs_strobe and acking;

  read_next_byte <= '1' when (word_req = '1') and (read_in_prog = '0') else '0';

  do_wish_write <= '1' when ((wbs_strobe = '1') and (wbs_write = '1') and (read_next_byte = '0') and (rst = '0')) else '0';
  mem_raddr <= next_byte when read_next_byte = '1' else unsigned(wbs_address);
  wbs_readdata <= mem_rdata;
  to_clock_out <= mem_rdata;

  word_strobe <= read_in_prog;

  pulse_generator : wordpulsegen
    generic map (
      timer_width => 7,
      active_output => '1',
      inactive_output => '0',
      max_word_width => 8
    )

    port map (
      clk => clk,
      rst => rst,
      word_width => "001000",
      word_value => to_clock_out,
      word_req => word_req,
      word_strobe => word_strobe,
      -- Bit time, 1.25us.  At 96MHz, 120 counts.
      -- 37 counts high for '0', 77 counts high for '1'
      one_duration => std_logic_vector(to_unsigned(77, 7)),
      zero_duration => std_logic_vector(to_unsigned(37, 7)),
      total_duration => std_logic_vector(to_unsigned(120, 7)),
      outpwm => outpwm,
      outpwmb => open
    );
end architecture RTL;
