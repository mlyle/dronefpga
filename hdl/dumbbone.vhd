-- Dumb wishbone slave core by Michael Lyle; public domain

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dumb_bone is
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
end entity;

-- ----------------------------------------------------------------------------
architecture RTL of dumb_bone is
signal ack_internal : std_logic;
begin

  process (clk)
  begin
    if clk'EVENT and clk = '1' then
      if wbs_strobe = '1' then
        if wbs_write = '0' then
          wbs_readdata <= wbs_address(15 downto 8) xor wbs_address(7 downto 0);
        end if;
      end if;

      ack_internal <= wbs_strobe;
    end if;
  end process;

  wbs_ack      <= ack_internal and wbs_strobe;

end architecture RTL;
