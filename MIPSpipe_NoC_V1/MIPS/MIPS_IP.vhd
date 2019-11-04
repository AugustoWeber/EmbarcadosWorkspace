--------------------------------------------------------------------------------------
-- DESIGN UNIT  : MIPS_IP                                                           --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Augusto Weber, Guilherme Carvalho, Wilim Padilha                  --
-- CREATED      : Oct 24th, 2019                                                    --
-- VERSION      : v1.0                                                              --
-- HISTORY      : Version 0.1 - Oct 24th, 2019                                      --
--------------------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MIPS_package.all;
use work.Arke_pkg.all;


entity MIPS_IP is
    generic (
        PC_START_ADDRESS    : std_logic_vector(31 downto 0);-- := x"00400000";
        MEM_START_ADDRESS   : std_logic_vector(31 downto 0);-- := x"10010000";
        MemDataSize         : integer;-- := 10;
        MemDataFile         : string;-- := "./MIPS/BubbleSort_data.txt"
        MemInstSize         : integer;-- := 50;
        MemInstFile         : string;-- := "./MIPS/BubbleSort_code.txt"
        IP_Addr             : std_logic_vector(11 downto 0)
    );
    port ( 
        clk         : in std_logic;
        rst         : in std_logic;
        
        data_in     : in std_logic_vector(DATA_WIDTH-1 downto 0);
        control_in  : in std_logic_vector(CONTROL_WIDTH-1 downto 0); --0 -> EOP; 1 -> RX; 2 <- STALL_GO
        
        data_out    : out std_logic_vector(DATA_WIDTH-1 downto 0);
        control_out : out std_logic_vector(CONTROL_WIDTH-1 downto 0) --0 -> EOP; 1 -> TX; 2 <- STALL_GO
    );
end MIPS_IP;

architecture structural of MIPS_IP is

    signal MIPS_MemWrite        : std_logic;
    signal MEM_MemWrite        : std_logic;
    -- Instruction Memory
    signal instructionAddress   : std_logic_vector(31 downto 0);
    signal dataAddress          : std_logic_vector(31 downto 0);
    signal instruction          : std_logic_vector(31 downto 0);
    -- Data Memory
    signal MEM_data_i           : std_logic_vector(31 downto 0);
    signal MEM_data_o           : std_logic_vector(31 downto 0);
    signal MEM_addr             : std_logic_vector(31 downto 0);
    -- Mips data Memory
    signal MIPS_data_i          : std_logic_vector(31 downto 0);
    signal MIPS_data_o          : std_logic_vector(31 downto 0);
    signal MIPS_addr            : std_logic_vector(31 downto 0);
	 
	 signal MEM_write				  : std_logic;
	 signal data_o					  : std_logic_vector(31 downto 0);
	 signal MIPS_dataAddress     : std_logic_vector(31 downto 0);
	 signal halt					  : std_logic;
begin

    MIPS_MONOCYCLE: entity work.MIPS_monocycle(structural) 
        generic map (
            PC_START_ADDRESS => TO_INTEGER(UNSIGNED(PC_START_ADDRESS))
        )
        port map (
            clock                 => clk,
            reset                 => rst,
            halt_in               => halt,
            
            -- Instruction memory interface
            instructionAddress  => instructionAddress,
            instruction         => instruction,
                 
             -- Data memory interface
            dataAddress         => MIPS_dataAddress,
            data_i              => MIPS_data_i,
            data_o              => MIPS_data_o,
            MemWrite            => MIPS_MemWrite
        );
     
    
    INSTRUCTION_MEMORY: entity work.Memory(behavioral)
        generic map (
            SIZE            => MemInstSize,                 -- Memory depth
            START_ADDRESS   => PC_START_ADDRESS,    -- MARS initial address (mapped to memory address 0x00000000)
            -- imageFileName   => "bubbleSort.txt"
            -- imageFileName   => "InsertionSort.txt"
            -- imageFileName   => "selectionSort.txt"
            imageFileName   => MemInstFile
        )
        port map (
            clock           => clk,
            MemWrite        => '0',
            address         => instructionAddress,
            data_i          => data_o,
            data_o          => instruction
        );
        
        
    DATA_MEMORY: entity work.Memory(behavioral)
        generic map (
            SIZE            => MemDataSize,             -- Memory depth
            START_ADDRESS   => MEM_START_ADDRESS,     -- MARS initial address (mapped to memory address 0x00000000)
            imageFileName   => MemDataFile
            -- imageFileName   => "selectionSort_data.txt"
            -- imageFileName   => "./MIPS/MemData100.txt"
        )
        port map (
            clock           => clk,
            MemWrite        => MEM_MemWrite,
            address         => MEM_addr,
            data_i          => MEM_data_i,
            data_o          => MEM_data_o
        );
    
    DMA: entity work.DMA(behavioral)
        generic map(
            reg_status  => x"08000000",     -- Addr STATUS
            reg_TX_mem  => x"08000004",     -- Addr TX mem addr
            reg_RX_mem  => x"08000008",     -- Addr RX mem addr
            IP_Addr     => IP_Addr
        )
        port map(
            clk         => clk,
            rst         => rst,
            -- MIPS interface
            MIPS_addr_i => MIPS_dataAddress,
            MIPS_data_i => MIPS_data_o,
            MIPS_data_o => MIPS_data_i,
            MemWrite_i  => MIPS_MemWrite,
            halt_o      => halt,

            -- MEM interface
            MEM_addr_o  => MEM_addr,
            MEM_data_i  => MEM_data_o,
            MEM_data_o  => MEM_data_i,
            MEM_write_o => MEM_write,

            -- Arke Interface
            data_in     => data_in,         -- NoC_data_i
            control_in  => control_in,      -- NoC_control_i,   -- 0 -> EOP_RX; 1 -> RX; 2 <- STALL_TX
            data_out    => data_out,        -- NoC_data_o,
            control_out => control_out      -- NoC_control_o    -- 0 -> EOP_TX; 1 -> TX; 2 <- STALL_RX
        );

end structural;