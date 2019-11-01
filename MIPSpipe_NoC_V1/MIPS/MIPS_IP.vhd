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
        MemInstFile         : string-- := "./MIPS/BubbleSort_code.txt"
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

    constant NoC_addr_data_in   : std_logic_vector(31 downto 0) := x"08000000";
    constant NoC_addr_data_out  : std_logic_vector(31 downto 0) := x"08000000";
    constant NoC_addr_data_eop  : std_logic_vector(31 downto 0) := x"08000004";
    constant NoC_addr_status    : std_logic_vector(31 downto 0) := x"08000008";

    type State is (S0, S1);
    signal TXstate  : State;
    signal RXstate  : State;

    signal MemWrite             : std_logic;
    signal MemWrite_NoC         : std_logic;
    signal MemWrite_MIPS        : std_logic;
    signal instructionAddress   : std_logic_vector(31 downto 0);
    signal dataAddress          : std_logic_vector(31 downto 0);
    signal instruction          : std_logic_vector(31 downto 0);
    signal data_i               : std_logic_vector(31 downto 0);
    signal data_o               : std_logic_vector(31 downto 0);
    signal data_mem_i           : std_logic_vector(31 downto 0);
    signal data_mem_o           : std_logic_vector(31 downto 0);
    signal data_NoC_i           : std_logic_vector(31 downto 0);
    signal data_NoC_o           : std_logic_vector(31 downto 0);
    signal flit_out             : std_logic_vector(31 downto 0);
    signal flit_in              : std_logic_vector(31 downto 0);
    signal data_NoC_EOP         : std_logic_vector(31 downto 0);
    signal uins: Microinstruction;



    signal NoC_status  : std_logic_vector(31 downto 0):= (others => '0');
     -----Transmission-----    
    alias TX          : std_logic is NoC_status(1); --out
    alias EOP_TX      : std_logic is NoC_status(0); --out
    alias STALL_TX    : std_logic is NoC_status(2); --in
    alias NoC_writable: std_logic is NoC_status(6);
    -- alias TX_empty_n  : std_logic is NoC_status(0):= '0'; --out STALL
     -----Reciver-----
    alias RX          : std_logic is NoC_status(4); --in
    alias EOP_RX      : std_logic is NoC_status(3); --in
    alias STALL_RX    : std_logic is NoC_status(5); --out
    -- alias RX_empty_n  : std_logic is NoC_status(0):= '0'; --out STALL
    

begin

    MIPS_MONOCYCLE: entity work.MIPS_monocycle(structural) 
        generic map (
            PC_START_ADDRESS => TO_INTEGER(UNSIGNED(PC_START_ADDRESS))
        )
        port map (
            clock                 => clk,
            reset                 => rst,
            
            -- Instruction memory interface
            instructionAddress  => instructionAddress,
            instruction         => instruction,
                 
             -- Data memory interface
            dataAddress         => dataAddress,
            data_i              => data_i,
            data_o              => data_o,
            MemWrite            => MemWrite_MIPS
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
            --imageFileName   => "selectionSort_data.txt"
            -- imageFileName   => "./MIPS/MemData100.txt"
        )
        port map (
            clock           => clk,
            MemWrite        => MemWrite,
            address         => dataAddress,
            data_i          => data_mem_o,
            data_o          => data_mem_i
        );    


--------------------------------------------------------------------------
--                                                                      --
--                      NoC INTERFACE                                   --
--                                                                      --
--------------------------------------------------------------------------

    EOP_RX <= control_in(EOP);
    RX <= control_in(1);
    STALL_TX <= control_in(STALL_GO);

    control_out(EOP) <= EOP_TX;
    control_out(1) <= TX;
    control_out(STALL_GO) <= STALL_RX;


    MemWrite <= '1' when MemWrite_MIPS = '1' and dataAddress(31 downto 24) = x"10" else '0';
    MemWrite_NoC <= '1' when MemWrite_MIPS = '1' and dataAddress(31 downto 24) = x"08" else '0';

    data_mem_o <= data_o;
    data_NoC_o <= data_o when dataAddress = NoC_addr_data_out and NoC_writable = '1';-- else (others =>'Z');
    data_NoC_EOP <= data_o when dataAddress = NoC_addr_data_eop else 
                    (others =>'0') when rst = '1' or falling_edge(EOP_RX);


    data_i <= data_mem_i when dataAddress(31 downto 24) = x"10" else
              flit_in when dataAddress(31 downto 0) = NoC_addr_data_in else
              NoC_status when dataAddress(31 downto 0) = NoC_addr_status else
              (others => '0');

-- Avoid overwriting the flit not transmitted.
process (clk, rst)
begin
    if rst = '1' then
        NoC_writable <= '1';
    elsif clk = '1' then
        if STALL_TX = '1' and MemWrite_NoC = '1' then -- Write in the memory
            NoC_writable <= '0';
        elsif NoC_writable = '0' and TX = '1' then -- Transmitted the data from reg
            NoC_writable <= '1';
        end if;
    end if;
end process;

-- SENDER: block
    -- TX <= '1' when flit_out != x"00000000" else '0';
    process (clk,rst)
    begin
        if rst = '1' then
            -- Logica do reset

            TXstate <= S0;
            EOP_TX <= '0';
            TX <= '0';
        elsif rising_edge(clk) then -- and TX = '1'
            case TXstate is
                when S0 => 
                    if STALL_TX = '1' then
                        if data_NoC_EOP /= x"00000000" then
                            data_out <= data_NoC_EOP;
                            TX <= '1';
                            EOP_TX <= '1';
                            TXstate <= S1;
                        elsif NoC_writable = '0' then
                            data_out <= data_NoC_o;
                            TX <= '1';
                            TXstate <= S1;
                        end if;
                    else
                        TX <= '0';
                    end if;

                when S1 =>
                    TX <= '0';
                    EOP_TX <= '0';
                    TXstate <= S0;
            end case;
        end if;
    end process;
-- end block SENDER;




-- RECIVER: block
process(clk,rst)
begin
    if rst = '1' then
        STALL_RX <= '0';
        RXState <= S0;
    elsif rising_edge(clk) then
        case RXState is
            when S0 => --Wait for flit
                if RX = '1' then --Reciving flit
                    flit_in <= data_in;
                    STALL_RX <= '0'; --Register full;
                    RXState <= S1;
                else
                    STALL_RX <= '1';
                    RXState <= S0;
                end if;
            when S1 =>
                if dataAddress = NoC_addr_data_in and write = '0' then
                    STALL_RX <= '1'; --Register was read;
                    RXState <= S0;
                end if;
        end case;
    end if;
end process;
-- end block RECIVER;

end structural;