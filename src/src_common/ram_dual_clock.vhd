---------------------------------------------------------------------------------
--                                                                             --
-- Author           : Florian TUTZO                                            --
--                                                                             --
-- Project          :                                                          --
--                                                                             --
-- Date             :  03/12/18                                                --
--                                                                             --
-- Description      :                                                          --
--                                                                             --
-- ------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity RAM_DUAL_CLOCK is
   generic
   (
      G_ADDR_LENGTH : integer := 8;
      G_DATA_LENGTH : integer := 8
   );
   port
   (
      CLK_WR  : in    std_logic;
      WR_ADDR : in    std_logic_vector(G_ADDR_LENGTH-1 downto 0);
      DIN     : in    std_logic_vector(G_DATA_LENGTH-1 downto 0);
      WE      : in    std_logic;
      CLK_RD  : in    std_logic;
      RD_ADDR : in    std_logic_vector(G_ADDR_LENGTH-1 downto 0);
      DOUT    : out   std_logic_vector(G_DATA_LENGTH-1 downto 0)
   );
end entity RAM_DUAL_CLOCK;

architecture ARCH_RAM_DUAL_CLOCK of RAM_DUAL_CLOCK is

   constant CST_RAM_DEPTH : integer := 2**G_ADDR_LENGTH;
   type mem is array(0 to CST_RAM_DEPTH-1) of std_logic_vector(G_DATA_LENGTH-1 downto 0);
   signal ram_block : mem:=(others=>(others=>'0'));


begin

   ------------------------------------------------------------------------
   -- PROCESS : P_RAM 
   -- Description :
   ------------------------------------------------------------------------
   P_WR : process(CLK_WR)
   begin
      if rising_edge(CLK_WR) then
         if WE = '1' then
            ram_block(to_integer(unsigned(WR_ADDR))) <= DIN;
         end if;
      end if;
   end process P_WR;

   P_RD : process(CLK_RD)
   begin
      if rising_edge(CLK_RD) then
         DOUT      <= ram_block(to_integer(unsigned(RD_ADDR))); 
      end if;
   end process P_RD;

end architecture ARCH_RAM_DUAL_CLOCK;

