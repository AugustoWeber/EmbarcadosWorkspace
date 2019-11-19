--------------------------------------------------------------------------------------
-- DESIGN UNIT  : MEM_Control                                                       --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Augusto Weber, Guilherme Carvalho, Wilim Padilha                  --
-- CREATED      : Nov 14th, 2019                                                    --
-- VERSION      : v0.1                                                              --
-- HISTORY      : Version 0.1 - Nov 14th, 2019                                      --
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MIPS_package.all;

entity MEM_Control is
    generic(
        MEM_upperAddr   : std_logic_vector(11 downto 0) := x"100";
        NoC_upperAddr   : std_logic_vector(11 downto 0) := x"090";
        DMA_upperAddr   : std_logic_vector(11 downto 0) := x"080"     -- Addr STATUS
        -- reg_TX_addr     : std_logic_vector(31 downto 0) := x"08000004";     -- Addr TX mem addr
        -- reg_RX_addr     : std_logic_vector(31 downto 0) := x"08000008";     -- Addr RX mem
    );
    port(
        clk             : in  std_logic;
        rst             : in  std_logic;
        halt            : in  std_logic;

    -- Signals coming from the MIPS
        MIPS_MemWrite   : in  std_logic;
        MIPS_addr       : in  std_logic_vector(31 downto 0);
        MIPS_data_i     : in  std_logic_vector(31 downto 0);
        MIPS_data_o     : out std_logic_vector(31 downto 0);

    -- Signals coming from the Mrmory
        MEM_write       : out std_logic;
        MEM_addr        : out std_logic_vector(31 downto 0);
        MEM_data_i      : in  std_logic_vector(31 downto 0);    -- Data from Memory to mem control
        MEM_data_o      : out std_logic_vector(31 downto 0);    -- Data from MIPS or DMA to Memory

    -- Signals coming from the DMA
        DMA_Write       : in  std_logic;
        DMA_addr        : in  std_logic_vector(31 downto 0);
        DMA_data_i      : in  std_logic_vector(31 downto 0);
        DMA_data_o      : out std_logic_vector(31 downto 0);

    -- Signal coming from the NoC
        NoC_data_i      : in  std_logic_vector(31 downto 0);
        NoC_data_o      : out std_logic_vector(31 downto 0);
        NoC_addr        : out std_logic_vector(31 downto 0);
        NoC_write       : out std_logic
    );
end MEM_Control;

architecture behavioral of MEM_Control is


begin
    -- MIPS
    MIPS_data_o <=  MEM_data_i when MIPS_addr(31 downto 20) = MEM_upperAddr else
                    NoC_data_i; -- Transmit to MIPS and to the DMA the data from the memory when it's not acessing the NoC register.

    -- Memory
    MEM_data_o <=   MIPS_data_i when halt = '0' and MIPS_addr_i(31 downto 20) = MEM_upperAddr else
                    DMA_data_i when halt = '1' and DMA_addr_i(31 downto 20) = MEM_upperAddr else
                    (others => 'Z'); -- when halt = '1' else

    MEM_write <=    MIPS_MemWrite when halt = '0' and MIPS_addr_i(31 downto 20) = MEM_upperAddr else
                    DMA_write when halt = '1' and DMA_addr = MEM_upperAddr else
                    '0';

    MEM_addr <=     MIPS_addr when halt = '0' and MIPS_addr_i(31 downto 20) = MEM_upperAddr else
                    DMA_write when halt = '1' and DMA_addr = MEM_upperAddr else
                    (others => 'Z');

    -- DMA
    DMA_data_o <=   MIPS_data_i when MIPS_addr = DMA_upperAddr else
                    MEM_data_i;

    -- NoC
    NoC_data_o <=   MEM_data_i when halt = '1' and DMA_upperAddr = NoC_addr else
                    MIPS_data_i when halt = '0' and MIPS_addr = NoC_addr else
                    (others => 'Z');

    NoC_addr <=     DMA_addr when halt = '1' and DMA_upperAddr = NoC_addr else
                    MIPS_addr when halt = '0' and MIPS_addr = NoC_addr else
                    (others => 'Z');

    NoC_write <=    MIPS_MemWrite when halt = '0' and MIPS_addr_i(31 downto 20) = NoC_upperAddr else
                    DMA_write when halt = '1' and DMA_addr = NoC_upperAddr else
                    '0';

end behavioral;