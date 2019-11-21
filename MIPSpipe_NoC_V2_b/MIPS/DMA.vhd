--------------------------------------------------------------------------------------
-- DESIGN UNIT  : DMA                                                               --
-- DESCRIPTION  : The PKG int the memory have:                                      --
--                  1st Addr: Size (don't count in pkg size; Start count in 0)      --
--                  2nd Addr: Target IP                                             --
--                  ...     : Flits                                                 --
-- AUTHOR       : Augusto Weber, Guilherme Carvalho, Wilim Padilha                  --
-- CREATED      : Nov 1st, 2019                                                     --
-- VERSION      : v1.0                                                              --
-- HISTORY      : Version 0.1 - Nov 1st, 2019                                       --
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use work.MIPS_package.all;
use work.Arke_pkg.all;

entity DMA is
    generic(
        reg_status  : std_logic_vector(31 downto 0) := x"08000000";     -- Addr STATUS
        reg_TX_addr : std_logic_vector(31 downto 0) := x"08000004";     -- Addr TX mem addr
        reg_TX_size : std_logic_vector(31 downto 0) := x"08000008";     -- Addr TX size
        reg_RX_addr : std_logic_vector(31 downto 0) := x"08000014";     -- Addr RX mem addr
        reg_RX_size : std_logic_vector(31 downto 0) := x"08000018";     -- Addr RX size
        IP_Addr     : std_logic_vector(11 downto 0) := x"000"
    );
    port(
        clk         : in  std_logic;
        rst         : in  std_logic;
        -- MIPS interface
        MIPS_addr_i : in  std_logic_vector(31 downto 0);
        MIPS_data_i : in  std_logic_vector(31 downto 0);
        MIPS_data_o : out std_logic_vector(31 downto 0);
        MemWrite_i  : in  std_logic;            -- Write signal from MIPS
        halt_o      : out std_logic;

        -- MEM interface
        MEM_addr_o  : out std_logic_vector(31 downto 0);
        MEM_data_i  : in  std_logic_vector(31 downto 0);
        MEM_data_o  : out std_logic_vector(31 downto 0);
        MEM_write_o : out std_logic;

        -- NoC Interface
        NoC_addr_o  : out std_logic_vector(31 downto 0);
        NoC_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        NoC_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        NoC_Write   : out std_logic;
        EOP_RX      : in  std_logic;

        -- Status
        Sending_o   : out std_logic;
        Reciving_o  : out std_logic;
        Readable    : in  std_logic;
        Writable    : in  std_logic
    );
end DMA;

architecture behavioral of DMA is

    -- register of status
    signal STATUS   : std_logic_vector(31 downto 0);
    alias Sending   : std_logic is STATUS(0);   -- DMA WRITE
    alias Start_TX  : std_logic is STATUS(1);   -- MIPS WRITE
    alias Reciving  : std_logic is STATUS(2);   -- DMA WRITE
    alias Start_RX  : std_logic is STATUS(3);   -- MIPS WRITE
    alias halt      : std_logic is STATUS(31);  -- DMA WRITE

    signal MEM_addr : std_logic_vector(31 downto 0);
    signal reg_TX   : std_logic_vector(31 downto 0);    -- Data to be send
    signal reg_RX   : std_logic_vector(31 downto 0);    -- Data recived.
    signal EOP      : std_logic;

    type States is (S0, S1, S2);
    -- S0 - Idle - Start_TX/RX = '0' and Sending/Reciving = '0'
    -- S1 - Size - Read/Write the pkg size
    -- S2 - TX/RX - Start become '1' Sending/Reciving = '1'
    signal TX_FSM: States;
    signal RX_FSM: States;

    signal reg_TX_mem   : std_logic_vector(31 downto 0);    -- Save the base addr to be transmited
    signal reg_RX_mem   : std_logic_vector(31 downto 0);    -- Save the base addr to be stored

    -- signal RX_size      : std_logic_vector (31 downto 0);   -- Register with the pkg size
    signal RX_pkg_size  : std_logic_vector (31 downto 0);   -- Size of pkg recived
    signal recived      : std_logic_vector (31 downto 0);   -- Total of flits recived

    -- signal TX_size      : std_logic_vector (31 downto 0);   -- Register with the pkg size
    signal TX_pkg_size  : std_logic_vector (31 downto 0);   -- Size of package to be transmited
    signal transmited   : std_logic_vector (31 downto 0);   -- Total of flits transmited

    signal teste: std_logic; -- Debug

begin

    Reciving_o <=   Reciving;
    Sending_o <=    Sending;

    -- TX_IP <=        (others => '0');
    -- RX_IP <=        (others => '0');

    MIPS_data_o <=  RX_pkg_size when MIPS_addr_i = reg_RX_size else
                    TX_pkg_size when MIPS_addr_i = reg_TX_size else
                    (others => 'Z');

    NoC_addr_o <=   x"09000008" when Sending = '1' and EOP = '1' else
                    x"09000004" when (Sending = '1') or (Reciving = '1') else
                    (others => 'Z');

    NoC_data_o <=   MEM_data_i when Sending = '1' else
                    (others => 'Z');

    NoC_Write <=    '1' when Sending = '1' and Writable = '1' else
                    '0';

    MEM_data_o <=   NoC_data_i;

    MEM_Write_o <=  '1' when (Reciving = '1' and Readable = '1') else
                    '0';

    MEM_addr_o <=   reg_RX when Reciving = '1' else
                    reg_TX when Sending = '1' else
                    (others => 'Z');


    -- Process save MIPS to Regs
    process (clk, rst) begin
        if rst = '1' then
            reg_TX_mem <= x"00000000";
            reg_RX_mem <= x"00000000";
            Start_RX <= '0';
            Start_TX <= '0';
            -- TX_size <= x"00000000";
            -- RX_size <= x"00000000";
            TX_pkg_size <= x"00000000";
        elsif rising_edge(clk) then
            if MemWrite_i = '1' then
                if MIPS_addr_i = x"08000004" then --reg_TX_addr then
                    reg_TX_mem <= MIPS_data_i;
                elsif MIPS_addr_i = x"08000008" then --reg_TX_size then
                    TX_pkg_size <= MIPS_data_i;
                elsif MIPS_addr_i = x"08000014" then --reg_RX_addr then
                    reg_RX_mem <= MIPS_data_i;
                    teste <= '1';   -- Debug
                elsif MIPS_addr_i = x"08000000" then --reg_STATUS then
                    if MIPS_data_i(1) = '1' then
                        Start_TX <= '1';
                    elsif MIPS_data_i(3) = '1' then
                        Start_RX <= '1';
                    end if;
                end if;
                -- teste <= '1';   -- Debug
            else                -- Debug
                teste <= '0';   -- Debug
            end if;
            if TX_FSM = S0 and Start_TX = '1' then
                Start_TX <= '0';
            end if;
            if RX_FSM = S0 and Start_RX = '1' then
                Start_RX <= '0';
            end if;
        end if;
    end process;

--------------------------------------------------------------------------
--                                                                      --
--                          SENDING                                     --
--                                                                      --
--------------------------------------------------------------------------
    -- Sending FSM    
    process(clk, rst) begin
        if rst = '1' then
            TX_FSM <= S0;
            sending <= '0';
            -- EOP <= '0';
            transmited <= x"00000000";
            -- reg_TX  <= x"00000000";
        elsif rising_edge(clk) then
            case TX_FSM is
                when S0 =>      -- Wait for the Start_TX in the STATUS register
                        if Start_TX = '1' then
                            Sending <= '1';
                            TX_FSM <= S1;
                            -- transmited <= x"00000000";
                            -- NoC_addr_o <= x"09000004";
                        else
                            Sending <= '0';
                            -- EOP <= '0';
                        end if;
                        transmited <= x"00000000";
                when S1 =>      -- Start transmiting the PKG
                        if Writable = '1' then
                            -- reg_TX <= reg_TX_mem + (transmited(29 downto 0) & "00");    -- Addr of the data in the DataMemory (base + offset)
                            if transmited = STD_LOGIC_VECTOR(unsigned(TX_pkg_size) - 0) then    -- Send the last flit and the EOP signal.                                EOP <= '1';
                                TX_FSM <= S2;
                                -- EOP <= '1';
                            -- else
                                -- EOP <= '0';
                            end if;
                            transmited <= STD_LOGIC_VECTOR(unsigned(transmited) + 1);
                        end if;
                when S2 =>      -- Restart the FSM
                        Sending <= '0';
                        TX_FSM <= S0;
                        -- EOP <= '0';
            end case;
        end if;
    end process;

    reg_TX <= reg_TX_mem + (transmited(29 downto 0) & "00");

    EOP <= '1' when transmited = STD_LOGIC_VECTOR(unsigned(TX_pkg_size) - 0) else '0';


--------------------------------------------------------------------------
--                                                                      --
--                          RECIVING                                    --
--                                                                      --
--------------------------------------------------------------------------

    -- Reciving FSM
    process(clk, rst) begin
        if rst = '1' then
            RX_FSM <= S0;
            reciving <= '0';
            reg_RX <= x"00000000";
        elsif rising_edge(clk) then
            case RX_FSM is
                when S0 =>      -- Wait for the Start_RX in the STATUS register
                        if Start_RX = '1' then
                            RX_FSM <= S1;
                            recived <= x"00000000";
                            -- Reciving <= '1';
                        else
                            Reciving <= '0';
                        end if;
                when S1 =>      -- Start Reciving the flits
                        Reciving <= '1';
                        if Readable = '1' then
                            reg_RX <= reg_RX_mem + (recived(29 downto 0) & "00"); -- Base(reg_RX_mem) + RX_pkg_size*4
                            if EOP_RX = '1' then
                                RX_FSM <= S2;
                                RX_pkg_size <= recived;
                            else
                                recived <= STD_LOGIC_VECTOR(unsigned(recived) + 1);       -- Increment the total amount of recived flits
                            end if;
                        end if;
                when S2 =>
                        RX_FSM <= S0;
                        reciving <= '0';
            end case;
        end if;
    end process;

--------------------------------------------------------------------------
--                                                                      --
--                             HALT                                     --
--                                                                      --
--------------------------------------------------------------------------

    halt_o <= halt;
    halt <= '1' when Sending = '1' or Reciving = '1' or Start_TX = '1' or Start_RX = '1' else '0';
end behavioral;
