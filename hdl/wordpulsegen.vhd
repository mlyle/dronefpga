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
use work.dronefpga_components.all;

entity wordpulsegen is
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
end entity;

-- ----------------------------------------------------------------------------
architecture RTL of wordpulsegen is
  signal duration_strobe : std_logic;
  signal duration_req : std_logic;

  signal remaining_width : unsigned(5 downto 0);
  signal remaining_word  : std_logic_vector(max_word_width-1 downto 0);
  signal remaining_wordb : std_logic_vector(max_word_width-1 downto 0);

  signal bit_duration : std_logic_vector(timer_width-1 downto 0);
  signal bitb_duration : std_logic_vector(timer_width-1 downto 0);
begin
  process (clk)
  begin
    if clk'EVENT and clk = '1' then
      if rst = '1' then
        remaining_width <= (others => '0');
        duration_strobe <= '0';
        word_req <= '0';
      else
        if word_strobe = '1' then
          remaining_width <= unsigned(word_width);
          remaining_word  <= word_value;
          remaining_wordb <= wordb_value;
          duration_strobe <= '0';
          word_req <= '0';
        elsif duration_req = '1' and duration_strobe = '0' and remaining_width > 0 then
          remaining_width <= remaining_width - 1;
          remaining_word  <= remaining_word(max_word_width-2 downto 0) & '0';
          remaining_wordb <= remaining_word(max_word_width-2 downto 0) & '0';
          duration_strobe <= '1';
          word_req <= '0';
        elsif remaining_width = 0 then
          duration_strobe <= '0';
          word_req <= '1';
        else
          duration_strobe <= '0';
          word_req <= '0';
        end if;
      end if;
    end if;
  end process;

  bit_duration <= one_duration when remaining_word(max_word_width-1) = '1'
                  else zero_duration;

  bitb_duration <= one_duration when remaining_wordb(max_word_width-1) = '1'
                  else zero_duration;

  pulse_gen : pulsegen
    generic map(
      timer_width => timer_width,
      active_output => active_output,
      inactive_output => inactive_output
    )

    port map(
      clk => clk,
      rst => rst,
      active_duration => bit_duration,
      activeb_duration => bitb_duration,
      total_duration => total_duration,
      duration_req => duration_req,
      duration_strobe => duration_strobe,
      outpwm => outpwm,
      outpwmb => outpwmb
    );

end architecture RTL;
