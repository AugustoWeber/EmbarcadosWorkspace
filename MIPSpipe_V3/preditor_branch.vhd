----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:48:14 10/24/2019 
-- Design Name: 
-- Module Name:    preditor_branch - Behavioral 
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
use IEEE.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity preditor_branch is
    Port ( 
			  clk,rst				 : in STD_LOGIC;
			  
			  pc_consulta			 : in  STD_LOGIC_VECTOR(31 downto 0);
           achou 					 : out STD_LOGIC;
           endereco_out			 : out STD_LOGIC_VECTOR(31 downto 0);
			  pc_indice_tab_out	 : out STD_LOGIC_VECTOR(2 downto 0); -- depende do tamanho do SIZE
			  
			  pc_incluir 			 : in  STD_LOGIC_VECTOR(31 downto 0);
           endereco_incluir 	 : in  STD_LOGIC_VECTOR(31 downto 0);
           incluir 				 : in  STD_LOGIC;
           atualizar				 : in  STD_LOGIC;
           pc_indice_tab_in	 : in  STD_LOGIC_VECTOR(2 downto 0)); -- depende do tamanho do SIZE
			  
			  -- adicionar entradas predição
end preditor_branch;

architecture Behavioral of preditor_branch is

	 
	 constant SIZE 			: integer := 8; --TAMANHO DA TABELA
	 signal pc_indice_tabela: std_logic_vector(2 downto 0);
	 signal endereco_encontrado : STD_LOGIC_VECTOR(31 downto 0);
	 signal include_index 	: integer range 0 to SIZE-1 := 0;
	 signal index_out			: integer range 0 to SIZE-1 := 0;
	 signal achou_array		: std_logic_vector(SIZE-1 downto 0); -- ARRAY COM O RESULTADO DA BUSCA POR PC PARA CADA ELEMENTO DA TABELA
	 signal temp				: std_logic_vector(SIZE-1 downto 0);
	 signal I,II,iii			: integer range 0 to SIZE-1;
	 signal achou_temp		: std_logic;
	 signal predicao			: std_logic_vector(1 downto 0);
	 
	 --signal atualizar 		: integer range 0 to SIZE-1;
	 type entry is
        record 
            PC, endereco    : std_logic_vector(31 downto 0);
            Predict         : STD_LOGIC_VECTOR(1 downto 0);
        end record;
    type tabela_dec is array (0 to size-1) of entry;
	 signal tabela : tabela_dec;
begin


------------------------BUSCA TABELA-------------------------------------------|

	
	COMPARA_PC: for I in 1 to SIZE-1 generate
		achou_array(I)   <= '1' when tabela(I).PC = pc_consulta else '0';
		pc_indice_tabela <= std_logic_vector(to_unsigned(I,pc_indice_tabela'length)) when achou_array(I) = '1' else "ZZZ";
   end generate COMPARA_PC;
	
	endereco_out	<= tabela(to_integer(unsigned(pc_indice_tabela))).endereco when achou_temp <= '1' else x"00000000";
	achou				<= achou_temp;
	pc_indice_tab_out	<= pc_indice_tabela;
	
	temp(0) <= achou_array(0);
   or_generate: for ii in 1 to size-1 generate
		temp(ii) <= temp(ii-1) or achou_array(ii);
   end generate; 
   achou_temp <= temp(size-1);
	


--------------------ATUALIZAR TABELA------------------------------------------|
process(clk,incluir)
	begin
		if rising_edge(clk) then
			if incluir = '1' then
				tabela(include_index).pc 		 <= pc_incluir;
				tabela(include_index).endereco <= endereco_incluir;
				tabela(include_index).predict  <= predicao;
				include_index <= include_index+1;
			end if;
			
			if atualizar = '1' then
				tabela(to_integer(unsigned(pc_indice_tab_in))).predict  <= predicao;
			end if;
		end if;
	
end process;
		
	

end Behavioral;

