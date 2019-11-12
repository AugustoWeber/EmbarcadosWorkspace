--------------------------------------------------------------------------------------
-- DESIGN UNIT  : NoC test bench                                                           --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara, Iaçanã Ianiski Weber & Michel Duarte        --
-- CREATED      : Aug 10th, 2015                                                    --
-- VERSION      : v1.0                                                             --
-- HISTORY      : Version 0.1 - Aug 10th, 2015                                      --
--              : Version 0.2.1 - Set 18th, 2015                                    --
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.Text_Package.all;
use work.Arke_pkg.all;

entity NoC_tb is
end NoC_tb;

architecture NoC_tb of NoC_tb is

    signal clk         : std_logic := '0';
    signal rst         : std_logic;
    signal data_in     : Array3D_data(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1);
    signal data_out    : Array3D_data(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1);
    signal control_in  : Array3D_control(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1);
    signal control_out : Array3D_control(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1);

begin
    
    clk <= not clk after 5 ns;
    
    rst <= '1', '0' after 3 ns;

    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(0,0,0)
    IP_00_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 1700,
            MemDataFile         => "./MIPS/MemData1500-00.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_TX.txt",
            IP_addr             => x"000"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(0,0,0),
            control_in  => control_out(0,0,0),
            data_out    => data_in(0,0,0),
            control_out => control_in(0,0,0)
        );

    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(0,1,0)
    IP_01_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-01.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"001"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(0,1,0),
            control_in  => control_out(0,1,0),
            data_out    => data_in(0,1,0),
            control_out => control_in(0,1,0)
        );

    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(0,2,0)
    IP_02_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-02.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"002"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(0,2,0),
            control_in  => control_out(0,2,0),
            data_out    => data_in(0,2,0),
            control_out => control_in(0,2,0)
        );

    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(0,3,0)
    IP_03_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-03.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"003"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(0,3,0),
            control_in  => control_out(0,3,0),
            data_out    => data_in(0,3,0),
            control_out => control_in(0,3,0)
        );


    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(1,0,0)
    IP_10_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-10.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"004"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(1,0,0),
            control_in  => control_out(1,0,0),
            data_out    => data_in(1,0,0),
            control_out => control_in(1,0,0)
        );

    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(1,1,0)
    IP_11_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-11.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_Addr             => x"005"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(1,1,0),
            control_in  => control_out(1,1,0),
            data_out    => data_in(1,1,0),
            control_out => control_in(1,1,0)
        );
    
    
    


    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(1,2,0)
    IP_12_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-12.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"006"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(1,2,0),
            control_in  => control_out(1,2,0),
            data_out    => data_in(1,2,0),
            control_out => control_in(1,2,0)
        );

    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(1,3,0)
    IP_13_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-13.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"007"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(1,3,0),
            control_in  => control_out(1,3,0),
            data_out    => data_in(1,3,0),
            control_out => control_in(1,3,0)
        );


    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(2,0,0)
    IP_20_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-20.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"008"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(2,0,0),
            control_in  => control_out(2,0,0),
            data_out    => data_in(2,0,0),
            control_out => control_in(2,0,0)
        );


    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(2,1,0)
    IP_21_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-21.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"009"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(2,1,0),
            control_in  => control_out(2,1,0),
            data_out    => data_in(2,1,0),
            control_out => control_in(2,1,0)
        );
    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(2,2,0)
    IP_22_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-22.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"00A"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(2,2,0),
            control_in  => control_out(2,2,0),
            data_out    => data_in(2,2,0),
            control_out => control_in(2,2,0)
        );

    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(2,3,0)
    IP_23_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-23.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"00B"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(2,3,0),
            control_in  => control_out(2,3,0),
            data_out    => data_in(2,3,0),
            control_out => control_in(2,3,0)
        );

    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(3,0,0)
    IP_30_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-30.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"00C"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(3,0,0),
            control_in  => control_out(3,0,0),
            data_out    => data_in(3,0,0),
            control_out => control_in(3,0,0)
        );

    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(3,1,0)
    IP_31_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-31.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"00D"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(3,1,0),
            control_in  => control_out(3,1,0),
            data_out    => data_in(3,1,0),
            control_out => control_in(3,1,0)
        );

    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(3,2,0)
    IP_32_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-32.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"00E"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(3,2,0),
            control_in  => control_out(3,2,0),
            data_out    => data_in(3,2,0),
            control_out => control_in(3,2,0)
        );

    -- Router address format: router(x,y,z). For 2D-Mesh z = 0.
    -- IP connected at router(3,3,0)
    IP_33_MIPS: entity work.MIPS_IP(structural) 
        generic map(
            PC_START_ADDRESS    => x"00400000",
            MEM_START_ADDRESS   => x"10010000",
            MemDataSize         => 110,
            MemDataFile         => "./MIPS/MemData100-33.txt",
            MemInstSize         => 100,
            MemInstFile         => "./MIPS/MIPS_Etapa3_RX.txt",
            IP_addr             => x"00F"
        )
        port map(
            clk         => clk,
            rst         => rst,
            data_in     => data_out(3,3,0),
            control_in  => control_out(3,3,0),
            data_out    => data_in(3,3,0),
            control_out => control_in(3,3,0)
        );
   
    
    ARKE: entity work.NoC
    port map(
        clk         => clk,
        rst         => rst,
        data_in     => data_in,
        data_out    => data_out,
        control_in  => control_in,
        control_out => control_out
    );
    
end NoC_tb;
