----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:50:37 10/02/2019 
-- Design Name: 
-- Module Name:    preditor_desvio - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MIPS_package.all;


entity preditor_desvio is
    Port (  
        clk             : in  STD_LOGIC;
        rst             : in  STD_LOGIC;
        taken_i         : in std_logic; -- Tell the FSM if the branch occurs
        CS              : in branch_prediction;
        NState          : out branch_prediction
        );
end preditor_desvio;

architecture Behavioral of preditor_desvio is
    signal CurrentState : branch_prediction;
    signal NextState    : branch_prediction;

begin



preditor: process(clk, rst)
begin
    if rst = '1' then	-- estado inicial
        -- CurrentState <= NT2;      --A
    elsif rising_edge(clk) then
--         CurrentState <= NextState;
--     end if;
-- end process;

-- process (CurrentState,taken_i) begin
    case CurrentState is
        when NT2 => --A
            if taken_i = '1' then 
                NextState <= NT;  --A
            else
                NextState <= NT2;  --B
            end if;

        when NT =>  --B
            if taken_i = '1' then 
                NextState <= T;  --A
            else
                NextState <= NT2;  --C
            end if;

        when T =>   --C
            if taken_i = '1' then 
                NextState <= T2;    --
            else
                NextState <= NT;   --
            end if;

        when others =>   -- when T2 =>  --
            if taken_i = '1' then 
                NextState <= T2;    --
            else
                NextState <= T;  --
            end if;

    end case;
    end if;
end process;

CurrentState <= CS;
NState <= NextState;

end Behavioral;