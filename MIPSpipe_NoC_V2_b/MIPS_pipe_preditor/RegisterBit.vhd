-------------------------------------------------------------------------
-- Design unit: Register
-- Description: Parameterizable length clock enabled register.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 


entity RegisterBit is
    port (  
        clock       : in std_logic;
        reset       : in std_logic; 
        ce          : in std_logic;
        d           : in  std_logic;
        q           : out std_logic
    );
end RegisterBit;


architecture behavioral of RegisterBit is
begin

    process(clock, reset)
    begin
        if reset = '1' then
            q <= '0';
        
        elsif rising_edge(clock) then
            if ce = '1' then
                q <= d; 
            end if;
        end if;
    end process;
        
end behavioral;