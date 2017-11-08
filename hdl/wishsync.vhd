--    wish_syncer: Asynchronous bus to wishbone master bridge
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

entity wish_syncer is
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
end entity;

-- ----------------------------------------------------------------------------
architecture RTL of wish_syncer is
  signal write_sync  : std_logic;
  signal strobe_sync : std_logic_vector(2 downto 0);

  signal writing     : std_logic;

  -- Recirculating mux synchronized signals
  signal address   : std_logic_vector(15 downto 0);
  signal writedata : std_logic_vector(7 downto 0);
begin
  -- Provides an asynchronous interface to wishbone

  process (clk)
  begin
    if clk'EVENT and clk = '1' then
      strobe_sync <= strobe_sync(1 downto 0) & wbs_strobe;
      write_sync  <= wbs_write;

      -- This is super slow & safe.

      -- Rising edge on strobe
      if strobe_sync(2) = '0' and strobe_sync(1) = '1' then
        address   <= wbs_address;
        writedata <= wbs_writedata;
        -- From one cycle back behind edge, since we're not
        -- guaranteed they arrived together.
        writing    <= write_sync;
        wbm_cycle  <= '1';
        wbm_strobe <= '1';
      elsif wbm_ack = '1' then
        wbm_cycle  <= '0';
        wbm_strobe <= '0';

        if writing = '0' then
          wbs_readdata <= wbm_readdata;
        end if;

        writing    <= '0';
      end if;
    end if;
  end process;

  wbm_address   <= address;
  wbm_writedata <= writedata;
  wbm_write     <= writing;
end architecture RTL;
