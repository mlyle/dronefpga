library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity wish_uart is
  port (
    -- Overall system clock and reset
    clk : in std_logic;
    rst : in std_logic;

    -- Wishbone interface signals
    wbs_address   : in std_logic_vector(3 downto 0);
    wbs_writedata : in std_logic_vector(7 downto 0);
    wbs_readdata  : out std_logic_vector(7 downto 0);
    wbs_write     : in std_logic;
    wbs_strobe    : in std_logic;
    wbs_ack       : out std_logic
  );
end entity;

-- ----------------------------------------------------------------------------
architecture RTL of wish_uart is
  type REGS_BANK is array (integer range <>) of std_logic_vector(7 downto 0);

  signal registers : REGS_BANK(0 to 7);
  constant register_writable : std_logic_vector(7 downto 0) := "00111111";
  signal addr : integer;

  signal reg3 : std_logic_vector(7 downto 0);
  signal reg6 : std_logic_vector(7 downto 0);
  signal reg7 : std_logic_vector(7 downto 0);
begin
  process (clk)
  variable addr : integer;
  begin
    if clk'EVENT and clk = '1' then
      if rst = '1' then
        registers(0) <= "00000000";
        registers(1) <= "00000000";
        registers(2) <= "00000000";
        registers(3) <= "01010000";
        registers(4) <= "01101101";
        registers(5) <= "11110111";
        registers(6) <= "00000000";
        registers(7) <= "00000000";
      else
        registers(7) <= std_logic_vector(unsigned(registers(7)) + 1);

        if (wbs_strobe = '1') then
          addr := to_integer(unsigned(wbs_address));

          if wbs_write = '1' then
            if (addr >= 0) and (addr <= 7) and (register_writable(addr) = '1') then
              registers(addr) <= wbs_writedata;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  addr <= to_integer(unsigned(wbs_address));

  process(addr, wbs_strobe, wbs_write, registers)
  begin
    if (wbs_strobe /= '1') or (wbs_write /= '0') or (addr < 0) or (addr > 7) then
      wbs_readdata <= (others => '1');
    else
      wbs_readdata <= registers(addr);
    end if;
  end process;

  -- Everything we complete in one bus cycle.
  wbs_ack <= wbs_strobe;

  reg3 <= registers(3);
  reg6 <= registers(6);
  reg7 <= registers(7);
end architecture RTL;
