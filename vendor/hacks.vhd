library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity SbtSPLL40  is
 
	generic ( 
		 FEEDBACK_PATH 			: string 		 :="SIMPLE"; 
		 DELAY_ADJUSTMENT_MODE_FEEDBACK	: string 		 :="FIXED"; 
		 DELAY_ADJUSTMENT_MODE_RELATIVE : string 		 :="FIXED";
		 SHIFTREG_DIV_MODE		: bit_vector(1 downto 0) := "00"; 
		 FDA_FEEDBACK			: bit_vector(3 downto 0) :="0000";
		 FDA_RELATIVE			: bit_vector(3 downto 0) := "0000";
		 PLLOUT_SELECT_PORTA		: string 		 :="GENCLK"; 
		 PLLOUT_SELECT_PORTB            : string         	 :="GENCLK";

		 DIVR				: bit_vector(3 downto 0) := "0000";
		 DIVF  				: bit_vector(6 downto 0) := "0000000";
		 DIVQ	   			: bit_vector(2 downto 0) := "000";  
		 FILTER_RANGE 			: bit_vector(2 downto 0) := "000";
		 		
 		 ENABLE_ICEGATE_PORTA            : bit 			 :='0';
		 ENABLE_ICEGATE_PORTB           : bit 			 :='0' 
	);
	port	(
		REFERENCECLK	: in    std_logic;
		EXTFEEDBACK 	: in    std_logic; 				 	
		DYNAMICDELAY	: in    std_logic_vector(7 downto 0); 
		BYPASS 		: in	std_logic;
		RESETB	 	: in 	std_logic;
		PLLOUT1 	: out  	std_logic;
		PLLOUT2		: out 	std_logic ; 
		LOCK		: out 	std_logic  
	); 

end SbtSPLL40;

architecture lame of SbtSPLL40  is
  signal multiplier : real;
  signal clock_val : std_logic;
  signal half_period : time := 5.255 ns;

  shared variable last_tick : time := 0 fs;
begin
  process(REFERENCECLK)
  begin
    if REFERENCECLK'EVENT then
      last_tick := now;
    end if;
  end process;

  generate_pll_clock: process
  begin
    if (now - last_tick) < 1 us then
      wait for half_period;
      clock_val <= '0';
      wait for half_period;
      clock_val <= '1';
    else
      wait;
    end if;
  end process;

  LOCK <= '1';
  PLLOUT1 <= clock_val;
  PLLOUT1 <= clock_val;
end architecture lame;
