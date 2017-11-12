-- ----------------------------------------------------------------------
--LOGI-hard
--Copyright (c) 2013, Jonathan Piat, Michael Jones, All rights reserved.
--
--This library is free software; you can redistribute it and/or
--modify it under the terms of the GNU Lesser General Public
--License as published by the Free Software Foundation; either
--version 3.0 of the License, or (at your option) any later version.
--
--This library is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
--Lesser General Public License for more details.
--
--You should have received a copy of the GNU Lesser General Public
--License along with this library.
-- ----------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.dronefpga_components.all;

entity wishbone_intercon is
generic (
         memory_map : array_of_addr;
         cycle_delay : boolean
       );
port(
		-- Syscon signals
		gls_reset    : in std_logic ;
		gls_clk      : in std_logic ;

		-- Wishbone slave signals
		wbs_address       : in std_logic_vector(ADDR_WIDTH-1 downto 0) ;
		wbs_writedata : in std_logic_vector(DATA_WIDTH-1 downto 0);
		wbs_readdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
		wbs_strobe    : in std_logic ;
		wbs_cycle      : in std_logic ;
		wbs_write     : in std_logic ;
		wbs_ack       : out std_logic;

		-- Wishbone master signals
		wbm_address       : out array_of_addr((memory_map'length-1) downto 0) ;
		wbm_writedata : out array_of_data((memory_map'length-1) downto 0);
		wbm_readdata  : in array_of_data((memory_map'length-1) downto 0);
		wbm_strobe    : out std_logic_vector((memory_map'length-1) downto 0) ;
		wbm_cycle     : out std_logic_vector((memory_map'length-1) downto 0) ;
		wbm_write     : out std_logic_vector((memory_map'length-1) downto 0) ;
		wbm_ack       : in std_logic_vector((memory_map'length-1) downto 0)

);
end wishbone_intercon;

architecture Behavioral of wishbone_intercon is

signal cs_vector : std_logic_vector(0 to (memory_map'length-1));
signal ack_vector : std_logic_vector(0 to (memory_map'length-1));

begin

proc_gcs_clk_generate: if cycle_delay generate
process(gls_clk)
begin
    -- delay this a cycle; adds a cycle delay to transactions but makes clock faster
    if gls_clk'EVENT and gls_clk = '1' then
      for i in 0 to (memory_map'length-1) loop
        if wbs_address(wbs_address'length-1 downto find_X(memory_map(i))) = memory_map(i)(wbs_address'length-1 downto find_X(memory_map(i))) then
          cs_vector(i) <= wbs_strobe and not wbm_ack(i);
        else
          cs_vector(i) <= '0';
        end if;
      end loop;
    end if;
end process;
end generate proc_gcs_clk_generate;

gen_slaves : for i in 0 to (memory_map'length-1) generate

  csgen: if not cycle_delay generate
    cs_vector(i) <= wbs_strobe when wbs_address(wbs_address'length-1 downto find_X(memory_map(i))) = memory_map(i)(wbs_address'length-1 downto find_X(memory_map(i))) else
                    '0' ;
  end generate csgen;

  ack_vector(i) <= wbm_ack(i) and cs_vector(i);

  wbm_address(i)(wbs_address'length-1 downto find_X(memory_map(i))) <= (others => '0') ;
  wbm_address(i)(find_X(memory_map(i))-1 downto 0) <= wbs_address(find_X(memory_map(i))-1 downto 0) ;

  wbm_writedata(i) <= wbs_writedata ;
  wbm_write(i) <= wbs_write;
  wbm_strobe(i) <= cs_vector(i);
  wbm_cycle(i) <= wbs_cycle;

	wbs_readdata <= wbm_readdata(i) when cs_vector(i) = '1' else
						(others => 'Z') ;

end generate ;

wbs_ack <= '1' when unsigned(ack_vector) /= 0 else
			  '0' ;
wbs_readdata <= (others => '0')  when unsigned(cs_vector) = 0 else
					(others => 'Z') ;

end Behavioral;
