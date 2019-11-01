----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:24:22 10/18/2019 
-- Design Name: 
-- Module Name:    tabela_branch - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tabela_branch is

    Port ( clk           : in  STD_LOGIC;
           rst           : in  STD_LOGIC;
			  endereco_in   : in  STD_LOGIC_VECTOR(31 downto 0);
			  endereco_out  : out STD_LOGIC_VECTOR(31 downto 0);
			  pc_in			 : in  STD_LOGIC_VECTOR(31 downto 0);
			  preditor_in   : in  STD_LOGIC_VECTOR(1 downto 0);
			  preditor_out	 : out STD_LOGIC_VECTOR(1 downto 0);
			 
			  incluir		 : in STD_LOGIC;
			  achou			 : out STD_LOGIC
			  );
end tabela_branch;
architecture Behavioral of tabela_branch is
    
	 constant SIZE 			: integer := 8; --TAMANHO DA TABELA
	 signal include_index 	: integer := 0;
	 signal index_out			: integer range 0 to SIZE-1 := 0;
	 signal achou_array		: std_logic_vector(SIZE-1 downto 0); -- ARRAY COM O RESULTADO DA BUSCA POR PC PARA CADA ELEMENTO DA TABELA
	 signal temp				: std_logic_vector(SIZE-1 downto 0);
	 signal I,II,iii			: integer range 0 to SIZE-1;
	 signal achou_temp		: std_logic;
	 
	 type entry is
        record 
            PC, endereco    : std_logic_vector(31 downto 0);
            Predict         : STD_LOGIC_VECTOR(1 downto 0);
        end record;
    type tabela_dec is array (0 to size-1) of entry;
	 signal tabela : tabela_dec;
	 
begin 

	--INCLUIR PC
	process(clk,incluir,index_out)
	begin
		if rising_edge(clk) then
			if incluir = '1' then
				tabela(include_index).pc 		 <= pc_in;
				tabela(include_index).endereco <= endereco_in;
				include_index <= include_index+1;

				if include_index = size then
					include_index <= 0;
				end if;
			
			end if;
		end if;
	
	end process;

   -- COMPARAR PC
   COMPARA_PC: for I in 0 to SIZE-1 generate
		achou_array(I) <= '1' when tabela(I).PC = pc_in else '0';
		
		
		
		endereco_out <= tabela(I).endereco  	when achou_array(I) = '1' and
							incluir = '0' 				and 
							achou_temp = '1' 			else
							"ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
							
		preditor_out <= tabela(I).Predict 		when achou_array(I) = '1' and
							 incluir = '0' 			and 
							 achou_temp = '1'		   else 
							 "ZZ";
							 
							 
   end generate COMPARA_PC;
	
	
--	process(achou_array)
--	begin
--		for II in 0 to SIZE-1 loop
--			if achou_array(II) = '1' then
--				index_out <= II;
--			end if;			
--		end loop;
--	end process;
	
    -- achou <= or achou_array;  -- OR entre todos os bits
    temp(0) <= achou_array(0);
    or_generate: for iii in 1 to size-1 generate
       temp(iii) <= temp(iii-1) or achou_array(iii);
    end generate; 
    achou_temp <= temp(size-1);
		
	achou <= achou_temp when incluir = '0' else '0';

end Behavioral;

