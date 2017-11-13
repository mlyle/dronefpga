--    resetgen: Attempts to generate a clean reset signal for downstream logic
--    Copyright (C) 2017 Michael P. Lyle
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity reset_generator is
  generic (
    width           : integer
  );

  port (
    clk : in std_logic;

    -- active high async reset input
    reset_in         : in std_logic;

    -- active high reset output, sync to clock
    rst              : out std_logic
  );
end entity;

-- ----------------------------------------------------------------------------
architecture RTL of reset_generator is
  signal count_val       : unsigned(width downto 0) := (others => '0');
  signal reset_in_sync : std_logic_vector(3 downto 0) := (others => '1');
begin
  process (clk, reset_in)
  begin
    if clk'EVENT and clk = '1' then
      reset_in_sync <= reset_in_sync(2 downto 0) & reset_in;

      if reset_in_sync(3) = '1' then
        count_val <= (others => '0');
        rst <= '1';
      elsif count_val(width) = '0' then
        count_val <= count_val + 1;
        rst <= '1';
      else
        rst <= '0';
      end if;
    end if;

    if reset_in = '1' then
      reset_in_sync <= (others => '1');
      rst <= '1';
    end if;
  end process;
end architecture RTL;
