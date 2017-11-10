--    spi_wishmaster: SPI slave to wishbone master bridge
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

entity spi_wishmaster is
  port (
    -- SPI signals
    mosi, ss, sck : in std_logic;
    miso          : out std_logic;

    clk           : in std_logic;

    -- Wishbone interface signals
    wbm_address   : out std_logic_vector(15 downto 0);
    wbm_writedata : out std_logic_vector(7 downto 0);
    wbm_readdata  : in std_logic_vector(7 downto 0);
    wbm_strobe    : out std_logic;
    wbm_write     : out std_logic;
    wbm_ack       : in std_logic;
    wbm_cycle     : out std_logic;

    -- Status word to return at beginning of transaction
    status_word   : in std_logic_vector(15 downto 0)
  );
end entity;

architecture RTL of spi_wishmaster is
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

  type spi_txn_state is (ST_ADDRHI, ST_ADDRLO, ST_DATA);

  signal bit_count     : std_logic_vector(2 downto 0);
  signal data_in_sr    : std_logic_vector(7 downto 0);
  signal data_out_sr   : std_logic_vector(7 downto 0);

  signal bus_state     : spi_txn_state;

  signal wr_address    : std_logic_vector(15 downto 0);
  signal rd_address    : std_logic_vector(15 downto 0);
  signal read_data     : std_logic_vector(7 downto 0);
  signal auto_inc      : std_logic;
  signal writing       : std_logic;

  signal awb_address   : std_logic_vector(15 downto 0);
  signal awb_writedata : std_logic_vector(7 downto 0);
  signal awb_readdata  : std_logic_vector(7 downto 0);
  signal awb_write     : std_logic;
  signal awb_strobe    : std_logic;
begin
  -- data in looks like
  -- AAAAAAAA AAAAAAIW DDDDDDDD DDDDDDDD
  -- A = address, I = auto-increment mode, W = write, D = data
  -- D is don't-care if not writing.
  -- Due to nature of this, we know address of transaction after 6th bit
  -- always, and speculatively begin read (and expect to be able to latch
  -- 2 bits later).

  -- data out looks like
  -- 00000000 SSSSSSSS RRRRRRRR RRRRRRRR
  -- We always read and return value, even in a write txn (returning old
  -- value).  Also, we'll end up reading ahead one byte past the end of
  -- the transaction.

  process (sck, ss)
  variable bits : unsigned(2 downto 0);
  begin
    if ss = '1' then
      -- slave select being high is an asynchronous reset, pushing us
      -- back to default state
      bus_state   <= ST_ADDRHI;
      bit_count   <= (others => '0');
      -- Status word is sampled asynchronously
      data_out_sr <= status_word(15 downto 8);
    elsif sck'EVENT and sck = '1' then
      bits := unsigned(bit_count);

      case bus_state is
        when ST_ADDRHI =>
          -- First byte, we don't do much.

          awb_write  <= '0';
          awb_strobe <= '0';

          if (bits = 7) then
            bus_state                <= ST_ADDRLO;
            rd_address(15 downto 14) <= (others => '0');
            rd_address(13 downto 6)  <= data_in_sr;

            data_out_sr              <= status_word(7 downto 0);
          end if;

        when ST_ADDRLO =>
          if (bits = 5) then
            -- Peek at shift register prematurely to dispatch read
            -- right away!
            rd_address(5 downto 0) <= data_in_sr(5 downto 0);
            awb_address            <= rd_address(15 downto 6) &
              data_in_sr(5 downto 0);
              awb_strobe <= '1';
          elsif (bits = 7) then
            bus_state   <= ST_DATA;
            auto_inc    <= data_in_sr(1);
            writing     <= data_in_sr(0);
            data_out_sr <= awb_readdata;
            awb_strobe  <= '0';
          end if;

        when ST_DATA =>
          if (bits = 0) then
            wr_address <= rd_address;

            if (auto_inc = '1') then
              rd_address <= std_logic_vector(unsigned(rd_address) + 1);
            end if;
          elsif (bits = 1) then
            awb_strobe <= '0';
            awb_write  <= '0';
          elsif (bits = 3) then
            -- strobe read, etc
            awb_address <= rd_address;
            awb_strobe  <= '1';
          elsif (bits = 5) then
            -- Complete the read; this is wasteful and could be made better
            -- with a wider shift reg. We do this earlier to have a nice
            -- period of time where awb_strobe is 0, allowing SPI to run
            -- faster relative to system clock.
            awb_strobe <= '0';
            read_data  <= awb_readdata;
          elsif (bits = 7) then
            data_out_sr <= read_data;

            -- do the write.
            if writing = '1' then
              awb_address   <= wr_address;
              awb_writedata <= data_in_sr;
              awb_strobe    <= '1';
              awb_write     <= '1';
          end if;
        end if;
      end case;

      if (bits /= 7) then
        data_out_sr <= data_out_sr(6 downto 0) & '0';
      end if;

      data_in_sr(7 downto 1) <= data_in_sr(6 downto 0);
      bit_count              <= std_logic_vector(bits + 1);
    end if;
  end process;

  async_wb : wish_syncer
  port map(
    clk           => clk,
    wbs_address   => awb_address,
    wbs_writedata => awb_writedata,
    wbs_readdata  => awb_readdata,
    wbs_write     => awb_write,
    wbs_strobe    => awb_strobe,
    wbm_address   => wbm_address,
    wbm_writedata => wbm_writedata,
    wbm_readdata  => wbm_readdata,
    wbm_write     => wbm_write,
    wbm_strobe    => wbm_strobe,
    wbm_ack       => wbm_ack,
    wbm_cycle     => wbm_cycle
    );

  miso          <= data_out_sr(7) when ss = '0' else 'Z';

  data_in_sr(0) <= mosi;
end architecture RTL;
