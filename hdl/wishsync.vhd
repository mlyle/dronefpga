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
  signal write_sync    : std_logic;
  signal strobe_sync   : std_logic_vector(2 downto 0);

  -- Clock enables for latches
  signal ctrl_cken     : std_logic;
  signal readdata_cken : std_logic;

  signal next_strobe   : std_logic;
  signal writing       : std_logic;

begin
  -- Provides an asynchronous interface to wishbone

  process (clk)
  begin
    if clk'EVENT and clk = '1' then
      -- Synchronizer FFs capture on the system clock
      strobe_sync <= strobe_sync(1 downto 0) & wbs_strobe;
      write_sync  <= wbs_write;

      -- This is super slow & safe.
      if ctrl_cken = '1' then
        wbm_strobe    <= next_strobe;
        wbm_cycle     <= next_strobe;
        wbm_address   <= wbs_address;
        wbm_writedata <= wbs_writedata;
        writing       <= write_sync and next_strobe;
      end if;

      if readdata_cken = '1' then
        wbs_readdata <= wbm_readdata;
      end if;

    end if;
  end process;

  ctrl_cken     <= (strobe_sync(1) and (not strobe_sync(2))) or wbm_ack;
  readdata_cken <= wbm_ack and not writing;

  next_strobe   <= '0' when wbm_ack = '1' else '1';
  wbm_write     <= writing;
end architecture RTL;
