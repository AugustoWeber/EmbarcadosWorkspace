--------------------------------------------------------------------------------------
-- DESIGN UNIT  : DMA                                                               --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Augusto Weber, Guilherme Carvalho, Wilim Padilha                  --
-- CREATED      : Nov 1st, 2019                                                     --
-- VERSION      : v1.0                                                              --
-- HISTORY      : Version 0.1 - Nov 1st, 2019                                       --
--------------------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MIPS_package.all;
use work.Arke_pkg.all;

entity DMA is
    generic(
        reg_status  : std_logic_vector(31 downto 0) := x"08000000";     -- Addr STATUS
        reg_TX_mem  : std_logic_vector(31 downto 0) := x"08000004";     -- Addr TX mem addr
        reg_RX_mem  : std_logic_vector(31 downto 0) := x"08000008"      -- Addr RX mem addr
    )
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        -- MIPS interface
        MIPS_addr_i : in std_logic_vector(31 downto 0);
        MIPS_data_i : in std_logic_vector(31 downto 0);
        MIPS_data_o : out std_logic_vector(31 downto 0);
        MemWrite_i  : in std_logic;
        halt_o      : out std_logic;

        -- MEM interface
        MEM_addr_o  : out std_logic_vector(31 downto 0);
        MEM_data_i  : in std_logic_vector(31 downto 0);
        MEM_data_o  : out std_logic_vector(31 downto 0);
        MEM_write_o : out std_logic;

        -- Arke Interface
        data_in     : in std_logic_vector(DATA_WIDTH-1 downto 0);
        control_in  : in std_logic_vector(CONTROL_WIDTH-1 downto 0); --0 -> EOP_RX; 1 -> RX; 2 <- STALL_TX
        
        data_out    : out std_logic_vector(DATA_WIDTH-1 downto 0);
        control_out : out std_logic_vector(CONTROL_WIDTH-1 downto 0) --0 -> EOP_TX; 1 -> TX; 2 <- STALL_RX
    );
end DMA;

architecture behavioral of DMA is

    -- register of status
    signal STATUS   : std_logic_vector(31 downto 0);
    alias Sending   : std_logic is STATUS(0);   -- DMA WRITE
    alias Start_TX  : std_logic is STATUS(1);   -- MIPS WRITE
    alias Reciving  : std_logic is STATUS(2);   -- DMA WRITE
    alias Start_RX  : std_logic is STATUS(3);   -- MIPS WRITE
    alias RX_waiting: std_logic is STATUS(4);   -- DMA WRITE
    alias TX_IP     : std_logic_vector(12 downto 0) is STATUS(17 downto 5); -- MIPS WRITE
    alias RX_IP     : std_logic_vector(12 downto 0) is STATUS(30 downto 18); -- MIPS WRITE
    alias halt      : std_logic is STATUS(31);  -- DMA WRITE

    -- NoC signals
    signal EOP_TX   : std_logic;
    signal TX       : std_logic;
    signal STALL_RX : std_logic;

    alias EOP_RX    : std_logic is control_in(EOP);
    alias RX        : std_logic is control_in(RX);
    alias STALL_TX  : std_logic is control_in(STALL_GO);


    type States is (Idle, Size, Tx/Rx, EndPkg);
    -- Idel - Start_TX/RX = '0' and Sending/Reciving = '0'
    -- Size - Read/Write the pkg size
    -- TX/RX - Start become '1' Sending/Reciving = '1'
    -- EndPkg - Tx send EOP signal = '1'
    signal TXstate: States;
    signal RXstate: States;

    signal RX_pkg_size  : std_logic_vector (31 downto 0);
    signal RX_pkg_write : std_logic_vector (31 downto 0);

begin


    MEM_data_o <= MIPS_data when halt = '0' else
                  XXXXXXXXXXXXXX;

    MEM_write <= MemWrite when halt = '0'

    MEM_addr_o <= MEM_addr;
    MEM_addr <= MIPS_addr_i when Sending = '0' and Reciving = '0' else
                reg_TX_mem when Sending = '1' else
                RX_pkg_write;-- when Reciving = '0';

    RX_pkg_write <= reg_RX_mem + RX_pkg_size(29 downto 0) & "00"; -- Base(reg_RX_mem) + RX_pkg_size*4

    control_out(EOP) <= EOP_TX;
    control_out(1) <= TX;
    control_out(STALL_GO) <= STALL_RX;

--------------------------------------------------------------------------
--                                                                      --
--                          SENDING                                     --
--                                                                      --
--------------------------------------------------------------------------
    process(clk, rst) --Status register
    begin
        if rst = '1' then
            Reciving = '0';
            Sending  = '0';
            Start_RX = '0';
            Start_TX = '0';
        elsif rising_edge(clk) then
            if Reciving = '1' then
                Start_RX = '0';
            end if;
            if Sending = '1' then
                Start_TX = '0';
            end if;
        end if;
    end process;

--------------------------------------------------------------------------
--                                                                      --
--                          RECIVING                                    --
--                                                                      --
--------------------------------------------------------------------------
    -- Reciving FSM
    process(clk, rst)
    begin
        if rst = '1' then
            START_RX <= '0';
            RXState <= Idle;
        elsif rising_edge(clk) then
            case RXstate is
                when Idle =>
                        Reciving <= '0';
                        if Start_RX = '1' then
                            RXstate <= TX/RX;
                        end if;
                when TX/RX =>
                        Reciving <= '1';
                        if EOP_RX = '1' then
                            RXstate <= Size;
                        end if;
                when Size =>
                        RXstate <= Idle
                        -- Write in the first addr the size of the pkg
                others =>
                    RXstate <= Idle;
            end case;
        end if;
    end process;

    -- Process to get the flits from the NoC
    process(clk,rst)
    begin
    if rst = '1' then
        STALL_RX <= '0';
    elsif rising_edge(clk) then
        if reciving = '1'
            when S0 => --Wait for flit
                if RX = '1' then --Reciving flit
                    flit_in <= data_in;
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
        end if;
    end if;
end process;

end behavioral;
