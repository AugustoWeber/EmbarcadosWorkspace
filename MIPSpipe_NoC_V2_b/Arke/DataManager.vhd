--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Data Manager                                                      --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara, Iaçanã Ianiski Weber & Michel Duarte        --
-- CREATED      : Jul 9th, 2015                                                     --
-- VERSION      : v1.0                                                             --
-- HISTORY      : Version 0.1 - Jul 9th, 2015                                       --
--              : Version 0.2.1 - Set 18th, 2015                                    --
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.Text_Package.all;
use work.Arke_pkg.all;


entity DataManager is 
    generic(
            fileNameIn  : string;
            fileNameOut : string
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        
        data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
        control_in : in std_logic_vector(CONTROL_WIDTH-1 downto 0);
        
        data_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
        control_out : out std_logic_vector(CONTROL_WIDTH-1 downto 0)
    );
end DataManager;

architecture behavioral of DataManager is
begin
    SEND: block
        type state is (S0, S1, S2, S3, S4);
        signal currentState : state;
        signal words : std_logic_vector(DATA_WIDTH+3 downto 0); --  eop + word 
        file flitFile : text open read_mode is fileNameIn;
    begin
        process (clk, rst)
            variable flitLine   : line;
            variable str        : string(1 to 9); --16 bits 1 to 5
        begin 
            if rst = '1' then
                control_out(TX) <= '0';
                currentState <= S0;
            
            elsif rising_edge(clk) then
                case currentState is
                    
                    --  Sends each file line as a flit
                    when S0 =>
                        if not endfile(flitFile) then
                            if control_in(STALL_GO) = '1' then
                                readline(flitFile, flitLine);
                                read(flitLine, str);
                                words <= StringToStdLogicVector(str);
                                control_out(TX) <= '1';
                            end if;
                            currentState <= S1;
                        else
                            control_out(TX) <= '0';
                            currentState <= S4;
                        end if;

                    when S1 => -- Wait 1 cycle to transmit the next flit
                        control_out(TX) <= '0';
                        currentState <= S2;

                    when S2 => -- Wait 2 cycle to transmit the next flit
                        control_out(TX) <= '0';
                        currentState <= S3;
                    
                    when S3 => -- Wait 3 cycle to transmit the next flit
                        control_out(TX) <= '0';
                        currentState <= S0;

                    when S4 =>  -- End of file

                end case;
            end if;
        end process;
        
        data_out <= words(DATA_WIDTH-1 downto 0);
        control_out(EOP) <= words(DATA_WIDTH);
    
    end block SEND;
    
    
    
    RECIEVE: block
        signal completeLine : std_logic_vector(DATA_WIDTH+3 downto 0);
        file flitFile : text open write_mode is fileNameOut;
    begin
        
        completeLine <= "000" & control_in(EOP) & data_in;
        
        process(clk, rst)
            variable flitLine   : line;
            variable str        : string (1 to 9);
        begin
            if rst = '1' then
                control_out(STALL_GO) <= '1';
            
            elsif rising_edge(clk) then
                if control_in(RX) = '1' then
                    write(flitLine, StdLogicVectorToString(completeLine));
                    writeline(flitFile, flitLine);
                end if;
            end if;
            
        end process;
    end block RECIEVE;
    
end architecture;