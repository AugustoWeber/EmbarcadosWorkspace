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
--use work.Arke_package.all;


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
        DMA_write       : in  std_logic;
        DMA_addr        : in  std_logic_vector(7 downto 0);
        DMA_data_i      : in  std_logic_vector(31 downto 0);
        DMA_data_o      : out std_logic_vector(31 downto 0);
        halt_i          : in  std_logic;
    -- Status
        Writable_o      : out std_logic;
        Readable_o      : out std_logic;
    -- To All
        EOP_RX_o        : out std_logic
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
    alias R0X       : std_logic is control_in(1);
    alias STALL_TX  : std_logic is control_in(2);

    -- register of status
    -- signal STATUS   : std_logic_vector(31 downto 0);
    signal Writable  : std_logic;-- is STATUS(4);   -- NoC WRITE
    signal Readable  : std_logic;-- is STATUS(5);   -- NoC WRITE

    signal EOP      : std_logic;

begin

    control_out(2) <= EOP_TX;
    control_out(1) <= T0X;
    control_out(0) <= STALL_RX;

    EOP_RX_o <= control_in(3);

    Stall_RX <= '1' when Readable = '0' else '0';

    T0X <= '1' when Stall_TX = '1' and Writable = '0';
    EOP_TX <= '1' when T0X = '1' and EOP = '1' else '0';

    Data_out <= Reg_TX when T0X = '1';

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
                if Writable = '1' and DMA_write = '1' then
                    Reg_TX <= Data_in;
                    Writable <= '0';
                elsif Readable = '1' then
                    DMA_data_o <= Reg_RX;
                    Readable <= '0';
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
            if EOP = '1' and T0X = '1' then
                EOP <= '0';
            end if;

            -- Reciving the Flit
            if Readable = '0' and R0X = '1' then
                Reg_RX <= Data_in;
            end if;

        end if;
    end process;

end behavioral;