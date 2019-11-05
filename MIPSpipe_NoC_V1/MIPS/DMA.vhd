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

library ieee;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use work.MIPS_package.all;
use work.Arke_pkg.all;

entity DMA is
    generic(
        reg_status  : std_logic_vector(31 downto 0) := x"08000000";     -- Addr STATUS
        reg_TX_addr : std_logic_vector(31 downto 0) := x"08000004";     -- Addr TX mem addr
        reg_RX_addr : std_logic_vector(31 downto 0) := x"08000008";     -- Addr RX mem addr
        IP_Addr     : std_logic_vector(11 downto 0) := x"000"
    );
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

    signal MEM_addr : std_logic_vector(31 downto 0);
    signal reg_TX   : std_logic_vector(31 downto 0);
    signal reg_RX   : std_logic_vector(31 downto 0);

    -- NoC signals
    signal EOP_TX   : std_logic;
    signal T0X      : std_logic;
    signal STALL_RX : std_logic;

    alias EOP_RX    : std_logic is control_in(0);
    alias RX0       : std_logic is control_in(1);
    alias STALL_TX  : std_logic is control_in(2);


    type States is (S0, S1, S2);
    -- S0 - Idle - Start_TX/RX = '0' and Sending/Reciving = '0'
    -- S1 - Size - Read/Write the pkg size
    -- S2 - TX/RX - Start become '1' Sending/Reciving = '1'
    signal TX_FSM: States;
    signal RX_FSM: States;

    signal reg_TX_mem   : std_logic_vector(31 downto 0);
    signal reg_RX_mem   : std_logic_vector(31 downto 0);

    signal RX_pkg_size  : std_logic_vector (31 downto 0);
    signal recived      : std_logic_vector (31 downto 0);   -- Total of flits recived

    signal TX_pkg_size  : std_logic_vector (31 downto 0);   -- Size of package to be transmited
    signal transmited   : std_logic_vector (31 downto 0);   -- Total of flits transmited

begin


    MEM_data_o <= MIPS_data_i when halt = '0' else
                  recived when RX_FSM = S2 else
                  data_in;-- when RX0 = '1' or RX_FSM = S2 else

    MEM_write_o <=  MemWrite_i when halt = '0' and MIPS_addr_i(27) = '0' else
                    '1' when RX0 = '1' or RX_FSM = S2 else
                    '0';

    MEM_addr_o <= MEM_addr;
    MEM_addr <= MIPS_data_i when (Sending = '1' and T0X = '0') or MIPS_addr_i = reg_TX_addr else
                reg_RX when RX0 = '1' or RX_FSM = S2 else  -- when Reciving = '1';
                reg_TX when Sending = '1' else
                MIPS_addr_i; -- when Sending = '0' and Reciving = '0' else



    control_out(EOP) <= EOP_TX;
    control_out(TX) <= T0X;
    control_out(STALL_GO) <= STALL_RX;

    TX_IP <= (others => '0');
    RX_IP <= (others => '0');

    -- Process save MIPS to Regs
    process (clk, rst)
    begin
        if rst = '1' then
            reg_TX_mem <= x"00000000";
            reg_RX_mem <= x"00000000";
            Start_RX <= '0';
            Start_TX <= '0';
            RX_waiting <= '0';
            TX_pkg_size <= x"00000000";
        elsif rising_edge(clk) then
            if MIPS_addr_i = reg_TX_addr and MemWrite_i = '1' then
                reg_TX_mem <= MIPS_data_i;
            end if;
            if MIPS_addr_i = reg_RX_addr and MemWrite_i = '1' then
                reg_RX_mem <= MIPS_data_i;
            end if;
            if MIPS_addr_i = reg_STATUS and MemWrite_i = '1' then
                Start_RX <= MIPS_data_i(3);
                Start_TX <= MIPS_data_i(1);
            end if;
            if TX_FSM = S0 and Start_TX = '1' then
                Start_TX <= '0';
            end if;
            if MIPS_addr_i = reg_TX_addr then
                TX_pkg_size <= MEM_data_i;  -- Recive the first data from the memory (size of pkg)
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
    data_out <= MEM_data_i;
    
    process(clk, rst) begin
        if rst = '1' then
            TX_FSM <= S0;
            T0X <= '0';
            sending <= '0';
            EOP_TX <= '0';
            transmited <= x"00000000";
        elsif rising_edge(clk) then
            case TX_FSM is
                when S0 =>      -- Wait for the Start_TX in the STATUS register
                        if Start_TX = '1' then
                            Sending <= '1';
                            TX_FSM <= S1;
                            -- TX_pkg_size <= MEM_data_i;  -- Recive the first data from the memory (size of pkg)
                            transmited <= x"00000001";
                        else
                            Sending <= '0';
                            EOP_TX <= '0';
                        end if;
                        T0X  <= '0';
                when S1 =>      -- Start transmiting the PKG
                        if STALL_TX = '1' then
                            reg_TX <= reg_TX_mem + (transmited(29 downto 0) & "00");    -- Addr of the data in the DataMemory (base + offset)
                            if transmited = TX_pkg_size then    -- Send the last flit and the EOP signal.
                                EOP_TX <= '1';
                                TX_FSM <= S2;
                            else
                                EOP_TX <= '0';
                                T0X <= '1';
                            end if;
                            transmited <= STD_LOGIC_VECTOR(unsigned(transmited) + 1);
                        end if;
                when S2 =>      -- Restart the FSM
                        EOP_TX <= '0';
                        T0X <= '0';
                        Sending <= '0';
                        TX_FSM <= S0;
            end case;
        end if;
    end process;
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
            STALL_RX <= '0';
            reg_RX <= x"00000000";
        elsif rising_edge(clk) then
            case RX_FSM is
                when S0 =>      -- Wait for the Start_RX in the STATUS register
                        if Start_RX = '1' then
                            RX_FSM <= S1;
                            recived <= x"00000001";
                            STALL_RX <= '1';
                            Reciving <= '1';
                        else
                            Reciving <= '0';
                            reg_RX <= x"00000000";
                            STALL_RX <= '0';
                        end if;
                when S1 =>      -- Start Reciving the flits
                        if RX0 = '1' then
                            reg_RX <= reg_RX_mem + (recived(29 downto 0) & "00"); -- Base(reg_RX_mem) + RX_pkg_size*4
                            if EOP_RX = '1' then
                                RX_FSM <= S2;
                                reg_RX <= reg_RX_mem;
                                --recived <= STD_LOGIC_VECTOR(unsigned(recived) - 1);
                            else
                                recived <= STD_LOGIC_VECTOR(unsigned(recived) + 1);       -- Increment the total amount of recived flits
                            end if;
                        end if;
                when S2 =>
                        RX_FSM <= S0;
                        -- reg_RX <= reg_RX_mem; -- + STD_LOGIC_VECTOR(unsigned(recived) - 1);      -- Write in the first addr the size of the pkg
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


    --halt <= '1' when (MIPS_addr_i = reg_STATUS and (MIPS_data_i(1) = '1' or MIPS_data_i(3) = '1'))  or Reciving = '1' or Sending = '1' else '0';
end behavioral;
