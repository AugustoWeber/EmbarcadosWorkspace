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
        NoC_UpperAddr       : std_logic_vector(11 downto 0) := x"090";
        DMA_UpperAddr       : std_logic_vector(11 downto 0) := x"080";
        MEM_UpperAddr       : std_logic_vector(11 downto 0) := x"100";
        IP_Addr             : std_logic_vector(11 downto 0)
    );
    port ( 
        clk         : in std_logic;
        rst         : in std_logic;
        
        data_in     : in std_logic_vector(31 downto 0);
        control_in  : in std_logic_vector(2 downto 0); --0 -> EOP; 1 -> RX; 2 <- STALL_GO
        
        data_out    : out std_logic_vector(31 downto 0);
        control_out : out std_logic_vector(2 downto 0) --0 -> EOP; 1 -> TX; 2 <- STALL_GO
    );
end MIPS_IP;

architecture structural of MIPS_IP is

    signal MIPS_MemWrite        : std_logic;
    signal MEM_MemWrite         : std_logic;
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

    signal data_o               : std_logic_vector(31 downto 0);
    signal MIPS_dataAddress     : std_logic_vector(31 downto 0);
    signal halt                 : std_logic;
    signal MIPS_instruction     : std_logic_vector(31 downto 0);

    signal STATUS               : std_logic_vector(31 downto 0);

    -- DMA
    signal DMA_data_o           : std_logic_vector(31 downto 0);
    signal DMA_data_i           : std_logic_vector(31 downto 0);
    signal DMA_addr             : std_logic_vector(31 downto 0);
    signal DMA_MEM_addr         : std_logic_vector(31 downto 0);
    signal DMA_NoC_data_o       : std_logic_vector(31 downto 0);
    signal DMA_NoC_data_i       : std_logic_vector(31 downto 0);
    signal DMA_write            : std_logic;
    signal Sending              : std_logic;
    signal Reciving             : std_logic;

    -- NoC
    signal NoC_addr             : std_logic_vector(31 downto 0);
    -- signal NoC_data_i           : std_logic_vector(31 downto 0);
    signal NoC_data_o           : std_logic_vector(31 downto 0);
    signal NoC_Write            : std_logic;
    signal RX_EOP               : std_logic;
    signal Readable             : std_logic;
    signal Writable             : std_logic;
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
            instruction         => MIPS_instruction,
                 
             -- Data memory interface
            dataAddress         => MIPS_dataAddress,
            data_i              => MIPS_data_i,
            data_o              => MIPS_data_o,
            MemWrite            => MIPS_MemWrite
        );
     
    
        MIPS_instruction <= x"00000000" when halt = '1' else
                           instruction;


    INSTRUCTION_MEMORY: entity work.Memory(behavioral)
        generic map (
            SIZE            => MemInstSize,                 -- Memory depth
            START_ADDRESS   => PC_START_ADDRESS,            -- MARS initial address (mapped to memory address 0x00000000)
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
            START_ADDRESS   => MEM_START_ADDRESS,       -- MARS initial address (mapped to memory address 0x00000000)
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
            reg_TX_addr => x"08000004",     -- Addr TX mem addr
            reg_RX_addr => x"08000008",     -- Addr RX mem addr
            IP_Addr     => IP_Addr
        )
        port map(
            clk         => clk,
            rst         => rst,
            -- MIPS interface
            MIPS_addr_i => MIPS_dataAddress,
            MIPS_data_i => MIPS_data_o,
            MIPS_data_o => DMA_data_o,--MIPS_data_i,
            MemWrite_i  => MIPS_MemWrite,
            halt_o      => halt,

            -- MEM interface
            MEM_addr_o  => DMA_MEM_addr,
            MEM_data_i  => DMA_data_o,
            MEM_data_o  => DMA_data_o,
            MEM_write_o => DMA_write,

            -- NoC Interface
            NoC_addr_o  => NoC_addr,
            NoC_data_i  => DMA_NoC_data_i,
            NoC_data_o  => DMA_NoC_data_o,
            NoC_Write   => NoC_Write,
            EOP_RX      => RX_EOP,

            -- Status
            Sending_o   => Sending,
            Reciving_o  => Reciving,
            Readable    => Readable,
            Writable    => Writable
        );

    NoCinterface: entity work.NoC_Interface(behavioral)
        generic map(IP_Addr => IP_Addr)
        port map(
            clk             => clk,
            rst             => rst,
        -- NoC Interface
            data_in         => data_in,
            control_in      => control_in,
            data_out        => data_out,
            control_out     => control_out,
        -- MIPS IP
            MIPS_data_i     => MIPS_data_o,
            MIPS_data_o     => NoC_data_o,--MIPS_data_i,
            MIPS_addr       => MIPS_dataAddress,
            MIPS_write      => MIPS_MemWrite,
        -- DMA
            DMA_write       => DMA_write,
            DMA_addr        => DMA_addr,
            DMA_data_i      => DMA_NoC_data_o,
            DMA_data_o      => DMA_NoC_data_i,
            halt_i          => halt,
        -- Status
            Writable_o      => Writable,
            Readable_o      => Readable,
        -- To All
            EOP_RX_o        => RX_EOP
        );

    MIPS_data_i <=  STATUS when MIPS_dataAddress = x"09000000" or MIPS_dataAddress = x"08000000" else
                    DMA_data_o when MIPS_dataAddress(31 downto 20) = DMA_UpperAddr else
                    NoC_data_o when MIPS_dataAddress(31 downto 20) = NoC_UpperAddr else
                    MEM_data_o;

    MEM_MemWrite <= MIPS_MemWrite when MIPS_dataAddress(31 downto 20) = MEM_UpperAddr and halt = '0' else
                    DMA_write when DMA_addr(31 downto 20) = MEM_UpperAddr and halt = '1' else
                    '0';

    MEM_addr <=     MIPS_dataAddress when halt = '0' else
                    DMA_MEM_addr;-- when halt = '1' else

    MEM_data_i <=   DMA_data_o when halt = '1' or MIPS_dataAddress(31 downto 20) = DMA_UpperAddr else
                    NoC_data_o when MIPS_dataAddress(31 downto 20) = NoC_UpperAddr else
                    MIPS_data_o;

    STATUS(31 downto 0) <= halt & x"00000" & "000" & RX_EOP & '0' & Readable & Writable & '0' & Reciving & '0' & Sending;
    -- STATUS(30 downto 8) <= x"00000" & "000";
    -- STATUS(07) <= RX_EOP;
    -- STATUS(06) <= '0'; -- EOP_TX;
    -- STATUS(05) <= Readable;
    -- STATUS(04) <= Writable;
    -- STATUS(03) <= '0'; -- DMA.Start_RX
    -- STATUS(02) <= Reciving;
    -- STATUS(01) <= '0'; -- DMA.Start_TX
    -- STATUS(00) <=  Sending;
end structural;