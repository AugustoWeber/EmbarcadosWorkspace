-------------------------------------------------------------------------
-- Design unit: MIPS monocycle test bench
-- Description: 
-------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MIPS_package.all;


entity MIPS_monocycle_tb is
end MIPS_monocycle_tb;


architecture structural of MIPS_monocycle_tb is

    -- signal clk: std_logic := '0';
    signal clock: std_logic := '0';
    signal reset, MemWrite: std_logic;
    signal instructionAddress, dataAddress, instruction, data_i, data_o : std_logic_vector(31 downto 0);
    signal uins: Microinstruction;

    constant MARS_INSTRUCTION_OFFSET    : std_logic_vector(31 downto 0) := x"00400000";
    constant MARS_DATA_OFFSET           : std_logic_vector(31 downto 0) := x"10010000";
    
begin

    clock <= not clock after 5 ns;
    
    reset <= '1', '0' after 12 ns;
    
    -- clock divider: clock = clk/2
    -- process(clk) begin
    --     if falling_edge(clk) then
    --         clock <= not clock;
    --     end if;
    -- end process;

    MIPS_MONOCYCLE: entity work.MIPS_monocycle(structural) 
        generic map (
            PC_START_ADDRESS => TO_INTEGER(UNSIGNED(MARS_INSTRUCTION_OFFSET))
        )
        port map (
            clock               => clock,
            reset               => reset,
            
            -- Instruction memory interface
            instructionAddress  => instructionAddress,    
            instruction         => instruction,        
                 
             -- Data memory interface
            dataAddress         => dataAddress,
            data_i              => data_i,
            data_o              => data_o,
            MemWrite            => MemWrite
        );
     
    
    INSTRUCTION_MEMORY: entity work.Memory(behavioral)
        generic map (
            SIZE            => 200,                 -- Memory depth
            START_ADDRESS   => MARS_INSTRUCTION_OFFSET,    -- MARS initial address (mapped to memory address 0x00000000)
            imageFileName   => "bubbleSort.txt"
			-- imageFileName   => "InsertionSort.txt"
            -- imageFileName   => "selectionSort.txt"
            -- imageFileName   => "teste.txt"
        )
        port map (
            clock           => clock,
            MemWrite        => '0',
            address         => instructionAddress,    
            data_i          => data_o,
            data_o          => instruction
        );
        
        
    DATA_MEMORY: entity work.Memory(behavioral)
        generic map (
            SIZE            => 105,             -- Memory depth
            START_ADDRESS   => MARS_DATA_OFFSET,     -- MARS initial address (mapped to memory address 0x00000000)
            
			--imageFileName   => "selectionSort_data.txt"
			imageFileName   => "MemData100.txt"
        )
        port map (
            clock           => clock,
            MemWrite        => MemWrite,
            address         => dataAddress,    
            data_i          => data_o,
            data_o          => data_i
        );    
    
end structural;


