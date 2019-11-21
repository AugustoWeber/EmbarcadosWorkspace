-------------------------------------------------------------------------
-- Design unit: MIPS monocycle
-- Description: Control and data paths port map
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MIPS_package.all;

entity MIPS_monocycle is
    generic (
        PC_START_ADDRESS    : integer := 0 
    );
    port ( 
        clock, reset        : in std_logic;
        halt_in				 : in std_logic;
        -- Instruction memory interface
        instructionAddress  : out std_logic_vector(31 downto 0);
        instruction         : in  std_logic_vector(31 downto 0);
        
        -- Data memory interface
        dataAddress         : out std_logic_vector(31 downto 0);
        data_i              : in  std_logic_vector(31 downto 0);      
        data_o              : out std_logic_vector(31 downto 0);
        MemWrite            : out std_logic 
    );
end MIPS_monocycle;

architecture structural of MIPS_monocycle is
    
    signal uins: Microinstruction; 
    signal instr_contrl: std_logic_vector(31 downto 0);
    -- signal clock    : std_logic;

begin


    CONTROL_PATH: entity work.ControlPath(behavioral)
        port map (
            clock          => clock,
            reset          => reset,
            instruction    => instr_contrl,
            uins           => uins

        );
         
         
    DATA_PATH: entity work.DataPath(structural)
        generic map (
           PC_START_ADDRESS => PC_START_ADDRESS
        )
        port map (
            clock               => clock,
            reset               => reset,
            
            uins                => uins,
             
            instructionAddress  => instructionAddress,
            instruction         => instruction, 
            dataAddress         => dataAddress,
            data_i              => data_i,
            data_o              => data_o,
            instr_contrl		=> instr_contrl,
            MemWrite 			=> MemWrite,
				halt_in				=> halt_in
	
        );
    
    --MemWrite <= uins.MemWrite;

    -- clock divider: clock = clk/2
    -- process(clk) begin
    --     if falling_edge(clk) then
    --         clock <= not clock;
    --     end if;
    -- end process;
     
end structural;
