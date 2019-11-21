-------------------------------------------------------------------------
-- Design unit: ALU
-- Description: 
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use work.MIPS_package.all;

entity ALU is
    port( 
        operand1    : in std_logic_vector(31 downto 0);
        operand2    : in std_logic_vector(31 downto 0);
        result      : out std_logic_vector(31 downto 0);
        zero        : out std_logic;
        operation   : in Instruction_type   
    );
end ALU;

architecture behavioral of ALU is

    signal temp, op1, op2: UNSIGNED(31 downto 0);
    alias shamt    : std_logic_vector(4 downto 0) is operand2(10 downto 6);
    signal shiftamount : integer range 0 to 32 := 1;

begin

    op1 <= UNSIGNED(operand1);
    op2 <= UNSIGNED(operand2);

    shiftamount <= to_integer(unsigned(shamt));
    
    result <= STD_LOGIC_VECTOR(temp);
        
    temp <= shift_left(op1,shiftamount)  when operation = SSLL else
            shift_right(op1,shiftamount) when operation = SSRL else
            op1 - op2                   when operation = SUBU or operation = BEQ else
            op1 and op2                 when operation = AAND else 
            op1 or  op2                 when operation = OOR or operation = ORI else 
            (0=>'1', others=>'0')       when operation = SLT and op1 < op2 else
            (others=>'0')               when operation = SLT and not (op1 < op2) else
            op2(15 downto 0) & x"0000"  when operation = LUI else
            op1 + op2;    -- default for ADDU, ADDIU, SW, LW   

    -- Generates the zero flag
    zero <= '1' when temp = 0 else '0';
    
end behavioral;