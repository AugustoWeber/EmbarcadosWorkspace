----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:52:02 10/02/2019 
-- Design Name: 
-- Module Name:    branch_table - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
--
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

entity branch_table is
    generic (size: integer := 8); -- numero de elementos da tablea
	 Port ( 
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        pc_in       : in  std_logic_vector(31 downto 0);
        pc_out      : out std_logic_vector(31 downto 0);
        endereco_in : in  std_logic_vector(31 downto 0);
        endereco_out: out std_logic_vector(31 downto 0);
        achou_out   : out std_logic;
        incluir     : in  std_logic
    );

end branch_table;

architecture Behavioral of branch_table is

    type table_array is array (0 to size-1) of std_logic_vector(31 downto 0);
    type table_satate_array is array (0 to size-1) of std_logic_vector(1 downto 0);
    signal pc           : table_array;
    signal endereco     : table_array;
    signal State        : table_satate_array;
    -- 00 - Not Taken
    -- 01 - Not Taken
    -- 10 - Taken
    -- 11 - Taken
    signal pc_save      : std_logic_vector(31 downto 0);

    signal include_index    : integer range 0 to size-1 := 0; --index para incluir novos elementos na tabela
    signal out_index        : integer range 0 to size-1;
    signal achou            : std_logic;
    signal i,j             : integer range 0 to size-1;

begin


    generate_for: for I in 0 to size-1 generate
        out_index(i) <= '1' when  pc(i) = pc_in and incluir = '0' else '0';
        endereco_out <= endereco(i) when achou = '1' else others <= '0';
        State <= State(i) when achou = '1' else others <= '0';
    end generate;

	
	
	achou <= or out_index;  -- OR entre todos os bits
	
	pc_save <= pc_in when (incluir = '1' and achou = 0) else pc_save;
		
    process(clk)	
    begin
        if rising_edge(clk) then
            if incluir = '1' then
                pc(include_index) <= pc_save;
                endereco(include_index) <= endereco_in;
                include_index <= include_index + 1;
            else -- consultar
                for I in 0 to size-1 loop
                    if pc(I) = pc_in then
                        achou <= true;
                        out_index <= I;
                    else 
                        achou <= false;
                    end if;
                end loop;
            end if;
        end if;
    end process;



--	 temp(0) <= inp(0);

	
--	 or_generate: for ii in 1 to size-1 generate
--        temp(ii) <= temp(ii-1) and out_index(ii);
--    end generate; 
--    achou <= temp(size-1); 

	--end generate

--	process (clk)
--		
--	begin
--		if rising_edge(clk) then
--			if incluir = '1' then
--				pc(include_index) <= pc_save;
--				endereco(include_index) <= endereco_in;
--				include_index <= include_index + 1;
--			else -- consultar
--			   
--				
--				for I in 0 to size-1 loop
--					if pc(I) = pc_in then
--						achou <= true;
--						out_index <= I;
--					else 
--						achou <= false;
--					end if;
--								
--				end loop;
--				
--				
--			end if;
--	  end if;
--	end process;


end Behavioral;

