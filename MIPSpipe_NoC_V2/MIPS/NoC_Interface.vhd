--------------------------------------------------------------------------------------
-- DESIGN UNIT  : NoC_Interface                                                     --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Augusto Weber, Guilherme Carvalho, Wilim Padilha                  --
-- CREATED      : Nov 14th, 2019                                                    --
-- VERSION      : v0.1                                                              --
-- HISTORY      : Version 0.1 - Nov 14th, 2019                                      --
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Arke_package.all;


entity NoC_Interface is
    generic(
        IP_Addr         : std_logic_vector(11 downto 0) := x"000";
        NoC_upperAddr   : std_logic_vector(11 downto 0) := x"090";
        reg_Status      : std_logic_vector(31 downto 0) := x"09000000";
        reg_TXRX        : std_logic_vector(31 downto 0) := x"09000004";
        reg_TX_EOP      : std_logic_vector(31 downto 0) := x"09000008"
    );
    port(
        clk             : in  std_logic;
        rst             : in  std_logic;
    -- NoC Interface
        data_in         : in  std_logic_vector(31 downto 0);
        control_in      : in  std_logic_vector(31 downto 0);    --0 -> EOP_RX; 1 -> RX; 2 <- STALL_TX
        data_out        : out std_logic_vector(31 downto 0);
        control_out     : out std_logic_vector(31 downto 0);    --0 -> EOP_TX; 1 -> TX; 2 <- STALL_RX
    -- MIPS IP
        MIPS_data_i      : in  std_logic_vector(31 downto 0);    -- RX data to MIPS_IP
        MIPS_data_o      : out std_logic_vector(31 downto 0);    -- TX data from MIPS_IP
        MIPS_addr        : in  std_logic_vector(31 downto 0);    -- addr
        MIPS_write       : in  std_logic;
    -- DMA
        DAM_write       : in  std_logic;
        DMA_addr        : in  std_logic_vector(7 downto 0);
        DMA_data_i      : in  std_logic_vector(31 downto 0);
        DMA_data_o      : out std_logic_vector(31 downto 0);
        halt            : in  std_logic;
    -- Status
        Writable_o      : out std_logic;
        Readable_o      : out std_logic
    );
end NoC_Interface;

architecture behavioral of NoC_Interface is
-- 2 registradores (dado recebido e STATUS)

    signal Reg_TX   : std_logic_vector(31 downto 0);
    signal Reg_RX   : std_logic_vector(31 downto 0);
    signal Reg_EOP  : std_logic_vector(31 downto 0);

    signal EOP_TX   : std_logic;
    signal T0X      : std_logic;
    signal STALL_RX : std_logic;

    alias EOP_RX    : std_logic is control_in(0);
    alias RX0       : std_logic is control_in(1);
    alias STALL_TX  : std_logic is control_in(2);

    -- type States is (S0, S1, S2);
    -- -- S0 - Idle - Start_TX/RX = '0' and Sending/Reciving = '0'
    -- -- S1 - Size - Read/Write the pkg size
    -- -- S2 - TX/RX - Start become '1' Sending/Reciving = '1'
    -- signal TX_FSM: States;
    -- signal RX_FSM: States;

    -- register of status
    signal STATUS   : std_logic_vector(31 downto 0);
    -- alias Sending   : std_logic is STATUS(0);   -- DMA WRITE
    -- alias Start_TX  : std_logic is STATUS(1);   -- MIPS WRITE
    -- alias Reciving  : std_logic is STATUS(2);   -- DMA WRITE
    -- alias Start_RX  : std_logic is STATUS(3);   -- MIPS WRITE
    alias Writable  : std_logic is STATUS(4);   -- NoC WRITE
    alias Readable  : std_logic is STATUS(5);   -- NoC WRITE
    --alias TX_IP     : std_logic_vector(12 downto 0) is STATUS(17 downto 5); -- MIPS WRITE
    --alias RX_IP     : std_logic_vector(12 downto 0) is STATUS(30 downto 18); -- MIPS WRITE
    -- alias halt      : std_logic is STATUS(31);  -- DMA WRITE

    signal EOP      : std_logic;

begin

    control_out(EOP) <= EOP_TX;
    control_out(TX) <= T0X;
    control_out(STALL_GO) <= STALL_RX;

    Stall_RX <= '1' when Readable = '0' else '0';

    TX <= '1' when Stall_TX = '1' and Writable = '0';
    EOP_TX <= '1' when TX = '1' and EOP = '1' else '0';

    Data_out <= Reg_TX when TX = '1';

    process(clk, rst) begin
        if rst = '1' then
            Reg_TX <= (others => '0');
            Reg_RX <= (others => '0');
            Readable <= '0';
            Writable <= '1';
            EOP_TX <= '0';
            EOP <= '0';
        elsif rising_edge(clk) then
            -- Read and write from the In/Out register
            if DMA_addr = reg_TXRX then
                if Writable = '1' and DAM_write = '1' then
                    Reg_TX <= NoC_data_i;
                    Writable <= '0';
                elsif Readable = '1' then
                    DMA_data_o <= Reg_RX;
                    Radable <= '0';
                end if;

            elsif MIPS_addr = reg_TXRX then
                if Writable = '1' and MIPS_write = '1' then
                    Reg_TX <= MIPS_data_i;
                    Writable <= '0';
                elsif Readable = '1' then
                    MIPS_data_o <= Reg_RX;
                    Readable <= '0';
                end if;
            
            -- End Of Package to be transmited
            elsif MIPS_addr = reg_TX_EOP then
                if Writable = '1' and MIPS_write = '1' then
                    Reg_EOP <= MIPS_data_i;
                    EOP <= '1';
                    Writable <= '0';
                end if;

            elsif DMA_addr = reg_TX_EOP then
                if Writable = '1' and DMA_write = '1' then
                    Reg_EOP <= MIPS_data_i;
                    EOP <= '1';
                    Writable <= '0';
                end if;
            end if;
            -- Reset the EOP flag
            if EOP = '1' and TX = '1' then
                EOP <= '0';
            end if;

            -- Reciving the Flit
            if Readable = '0' and RX = '1' then
                Reg_RX <= Data_in;
            end if;

        end if;
    end process;


--------------------------------------------------------------------------
--                                                                      --
--                          SENDING                                     --
--                                                                      --
--------------------------------------------------------------------------
-- Sending FSM


-- process(clk, rst) begin
--     if rst = '1' then
--         TX_FSM <= S0;
--         T0X <= '0';
--         EOP_TX <= '0';
--     elsif rising_edge(clk) then
--         case TX_FSM is
--             when S0 =>      -- Wait for the Start_TX in the STATUS register
--                     if Start_TX = '1' then
--                         TX_FSM <= S1;
--                         -- TX_pkg_size <= MEM_data_i;  -- Recive the first data from the memory (size of pkg)
--                     else
--                         EOP_TX <= '0';
--                     end if;
--                     T0X  <= '0';
--             when S1 =>      -- Start transmiting the PKG
--                     if STALL_TX = '1' then
--                         reg_TX <= reg_TX_mem + (transmited(29 downto 0) & "00");    -- Addr of the data in the DataMemory (base + offset)
--                         if transmited = TX_pkg_size then    -- Send the last flit and the EOP signal.
--                             EOP_TX <= '1';
--                             TX_FSM <= S2;
--                         else
--                             EOP_TX <= '0';
--                             T0X <= '1';
--                         end if;
--                         transmited <= STD_LOGIC_VECTOR(unsigned(transmited) + 1);
--                     end if;
--             when S2 =>      -- Restart the FSM
--                     EOP_TX <= '0';
--                     T0X <= '0';
--                     Sending <= '0';
--                     TX_FSM <= S0;
--         end case;
--     end if;
-- end process;


--------------------------------------------------------------------------
--                                                                      --
--                          RECIVING                                    --
--                                                                      --
--------------------------------------------------------------------------

    -- -- Reciving FSM
    -- process(clk, rst) begin
    --     if rst = '1' then
    --         RX_FSM <= S0;
    --         reciving <= '0';
    --         STALL_RX <= '0';
    --         reg_RX <= x"00000000";
    --     elsif rising_edge(clk) then
    --         case RX_FSM is
    --             when S0 =>      -- Wait for the Start_RX in the STATUS register
    --                     if Start_RX = '1' then
    --                         RX_FSM <= S1;
    --                         recived <= x"00000002";
    --                         -- STALL_RX <= '1';
    --                         Reciving <= '1';
    --                     else
    --                         Reciving <= '0';
    --                         reg_RX <= STD_LOGIC_VECTOR(unsigned(reg_RX_mem) + 4);
    --                         STALL_RX <= '0';
    --                     end if;
    --             when S1 =>      -- Start Reciving the flits
    --                     STALL_RX <= '1';
    --                     if RX0 = '1' then
    --                         reg_RX <= reg_RX_mem + (recived(29 downto 0) & "00"); -- Base(reg_RX_mem) + RX_pkg_size*4
    --                         if EOP_RX = '1' then
    --                             RX_FSM <= S2;
    --                             reg_RX <= reg_RX_mem;
    --                             recived <= STD_LOGIC_VECTOR(unsigned(recived) - 1);
    --                         else
    --                             recived <= STD_LOGIC_VECTOR(unsigned(recived) + 1);       -- Increment the total amount of recived flits
    --                         end if;
    --                     end if;
    --             when S2 =>
    --                     RX_FSM <= S0;
    --                     -- reg_RX <= reg_RX_mem; -- + STD_LOGIC_VECTOR(unsigned(recived) - 1);      -- Write in the first addr the size of the pkg
    --                     reciving <= '0';
    --         end case;
    --     end if;
    -- end process;

end behavioral;