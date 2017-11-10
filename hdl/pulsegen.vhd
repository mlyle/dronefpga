--    pulsegen: generates PWM-style pulses
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

entity pulsegen is
  generic (
    timer_width     : integer;
    active_output   : std_logic;
    inactive_output : std_logic
  );

  port (
    -- Overall system clock
    clk : in std_logic;
    rst : in std_logic;

    active_duration : in std_logic_vector(timer_width-1 downto 0);
    total_duration  : in std_logic_vector(timer_width-1 downto 0);
    duration_req    : out std_logic;
    duration_strobe : in std_logic;

    outpwm : out std_logic
  );
end entity;

-- ----------------------------------------------------------------------------
architecture RTL of pulsegen is
  signal counter : unsigned(timer_width-1 downto 0);
  signal top_of_count : std_logic;
begin
  process (clk)
  begin
    if clk'EVENT and clk = '1' then
      if rst = '1' then
        counter <= (others => '0');
      else
        if top_of_count = '1' then
          if duration_strobe = '1' then
            counter <= (others => '0');
          end if;
        else
          counter <= counter + 1;
        end if;
      end if;

      if counter < unsigned(active_duration) then
        outpwm <= active_output;
      else
        outpwm <= inactive_output;
      end if;
    end if;
  end process;

  top_of_count <= '1' when counter >= unsigned(total_duration) else '0';
  duration_req <= top_of_count;
end architecture RTL;
