-------------------------------------------------------------------------
-- Design unit: Data path
-- Description: MIPS data path supporting ADDU, SUBU, AND, OR, LW, SW,  
--                  ADDIU, ORI, SLT, BEQ, J, LUI instructions.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 
use work.MIPS_package.all;

   
entity DataPath is
    generic (
        PC_START_ADDRESS    : integer := 0
    );
    port (  
        clock               : in  std_logic;
        reset               : in  std_logic;
        instructionAddress  : out std_logic_vector(31 downto 0);  -- Instruction memory address bus
        instruction         : in  std_logic_vector(31 downto 0);  -- Data bus from instruction memory
        dataAddress         : out std_logic_vector(31 downto 0);  -- Data memory address bus
        data_i              : in  std_logic_vector(31 downto 0);  -- Data bus from data memory 
        data_o              : out std_logic_vector(31 downto 0);  -- Data bus to data memory
        uins                : in  Microinstruction                -- Control path microinstruction
    );
end DataPath;


architecture structural of DataPath is

    signal incrementedPC, pc_q, result, readData1, readData2, ALUoperand2, signExtended, zeroExtended, writeData: std_logic_vector(31 downto 0);
    signal branchOffset, branchTarget, pc_d: std_logic_vector(31 downto 0);
    signal jumpTarget: std_logic_vector(31 downto 0);
    signal writeRegister   : std_logic_vector(4 downto 0);
    
    -- Retrieves the rs field from the instruction
    alias rs: std_logic_vector(4 downto 0) is instruction(25 downto 21);
        
    -- Retrieves the rt field from the instruction
    alias rt: std_logic_vector(4 downto 0) is instruction(20 downto 16);
        
    -- Retrieves the rd field from the instruction
    alias rd: std_logic_vector(4 downto 0) is instruction(15 downto 11);
    
    signal zero : std_logic; 
	 
	 
	-- PIPELINE signals
	--pipe0
	signal PIPE0_incrementedPC:	std_logic_vector(31 downto 0);
	signal PIPE0_instruction:	std_logic_vector(31 downto 0);
	--pipe1
	signal PIPE1_incrementedPC:	std_logic_vector(31 downto 0);
 	signal PIPE1_instruction:	std_logic_vector(25 downto 0);
 	signal PIPE1_readData1:		std_logic_vector(31 downto 0);
	signal PIPE1_readData2:		std_logic_vector(31 downto 0);
	signal PIPE1_signExtended:	std_logic_vector(31 downto 0);
	signal PIPE1_zeroExtended:	std_logic_vector(31 downto 0);
	signal PIPE1_rt:			std_logic_vector(4 downto 0);
	signal PIPE1_rd:			std_logic_vector(4 downto 0);
	signal PIPE1_dst:			std_logic_vector(4 downto 0);
	signal PIPE1_RegWrite:		std_logic;
	signal PIPE1_ALUSrc:		std_logic_vector(1 downto 0);
	signal PIPE1_RegDst:		std_logic;
	signal PIPE1_MemToReg:		std_logic;
	signal PIPE1_MemWrite:		std_logic;
	signal PIPE1_Branch:		std_logic;
	signal PIPE1_Jump:			std_logic;
	--pipe2
	signal PIPE2_jumpTarget:	std_logic_vector(31 downto 0);
	signal PIPE2_result:		std_logic_vector(31 downto 0);
	signal PIPE2_readData2:		std_logic_vector(31 downto 0);
	signal PIPE2_dst:			std_logic_vector(4 downto 0);
	signal PIPE2_zero:			std_logic;
	signal PIPE2_RegWrite:		std_logic;
	signal PIPE2_MemToReg:		std_logic;
	signal PIPE2_MemWrite:		std_logic;
	signal PIPE2_Branch:		std_logic;
	signal PIPE2_Jump:			std_logic;
	--pipe3
	signal PIPE3_data_i:		std_logic_vector(31 downto 0);
	signal PIPE3_result:		std_logic_vector(31 downto 0);
	signal PIPE3_dst:			std_logic_vector(4 downto 0);
	signal PIPE3_RegWrite:		std_logic;
	signal PIPE3_MemToReg:		std_logic;


    
begin

    -- incrementedPC points the next instruction address
    -- ADDER over the PC register
    ADDER_PC: incrementedPC <= STD_LOGIC_VECTOR(UNSIGNED(pc_q) + TO_UNSIGNED(4,32));
    
    -- PC register
    PROGRAM_COUNTER:    entity work.RegisterNbits
        generic map (
            LENGTH      => 32,
            INIT_VALUE  => PC_START_ADDRESS
        )
        port map (
            clock       => clock,
            reset       => reset,
            ce          => '1', 
            d           => pc_d, 
            q           => pc_q
        );
        
		  
	-----------------------------------------------------------
	-- Pipe0 register
	-----------------------------------------------------------
		P0_PCpp:    entity work.RegisterNbits
		generic map(LENGTH=> 32)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => incrementedPC, 
			q     => PIPE0_incrementedPC);

		P0_instruction:    entity work.RegisterNbits
		generic map (LENGTH=> 32)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => instruction, 
			q     => PIPE0_instruction);
		  
		  
	-----------------------------------------------------------
	-- Pipe1 register
	-----------------------------------------------------------
		P1_PCpp:    entity work.RegisterNbits
		generic map (LENGTH=> 32)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => PIPE0_incrementedPC, 
			q     => PIPE1_incrementedPC);
			
		P1_instruction:    entity work.RegisterNbits
		generic map (LENGTH=> 26)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => PIPE0_instruction(25 downto 0), 
			q     => PIPE1_instruction);
		
		P1_RA:    entity work.RegisterNbits
		generic map (LENGTH=> 32)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => readData1, 
			q     => PIPE1_readData1);
			
		P1_RB:    entity work.RegisterNbits
		generic map (LENGTH=> 32)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => readData2, 
			q     => PIPE1_readData2);
			
		P1_IMM:    entity work.RegisterNbits
		generic map (LENGTH=> 32)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => signExtended, 
			q     => PIPE1_signExtended);

		P1_zeroExtend:	entity work.RegisterNbits
		generic map(LENGTH =>32)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => zeroExtended, 
			q     => PIPE1_zeroExtended);
			
		P1_rt:    entity work.RegisterNbits
		generic map (LENGTH=> 5)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => rt, 
			q     => PIPE1_rt);
			
		P1_rd:    entity work.RegisterNbits
		generic map (LENGTH=> 5)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => rd, 
			q     => PIPE1_rd);
			
		--Control	
		P1_RegWrite:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => uins.RegWrite, 
			q     => PIPE1_RegWrite);

		P1_ALUSrc:    entity work.RegisterNbits
		generic map (LENGTH=> 2)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => std_logic_vector(uins.ALUSrc), 
			q     => PIPE1_ALUSrc);
			
		P1_RegDst:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => uins.RegDst, 
			q     => PIPE1_RegDst);

		P1_MemToReg:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => uins.MemToReg, 
			q     => PIPE1_MemToReg);

		P1_MemWrite:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => uins.MemWrite, 
			q     => PIPE1_MemWrite);

		P1_Branch:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => uins.Branch, 
			q     => PIPE1_Branch);

		P1_Jump:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => uins.Jump, 
			q     => PIPE1_Jump);
	-----------------------------------------------------------
	-- Pipe2 register
	-----------------------------------------------------------
		P2_target:    entity work.RegisterNbits
		generic map (LENGTH=> 32)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => jumpTarget,
			q     => PIPE2_jumpTarget);
			
		P2_ALUout:    entity work.RegisterNbits
		generic map (LENGTH=> 32)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => result,
			q     => PIPE2_result);
		
		P2_RB:    entity work.RegisterNbits
		generic map (LENGTH=> 32)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => PIPE1_readData2,
			q     => PIPE2_readData2);
			
		P2_dst:    entity work.RegisterNbits
		generic map (LENGTH=> 5)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => PIPE1_dst,
			q     => PIPE2_dst);

		--ALU zero
		P2_zero:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => zero,
			q     => PIPE2_zero);

		--Control	
		P2_RegWrite:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => PIPE1_RegWrite, 
			q     => PIPE2_RegWrite);

		P2_MemToReg:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => PIPE1_MemToReg, 
			q     => PIPE2_MemToReg);

		P2_MemWrite:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => PIPE1_MemWrite, 
			q     => PIPE2_MemWrite);

		P2_Branch:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => PIPE1_Branch, 
			q     => PIPE2_Branch);

		P2_Jump:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => PIPE1_Jump, 
			q     => PIPE2_Jump);
			
   -----------------------------------------------------------
	-- Pipe3 register
	-----------------------------------------------------------
		P3_ReadData:    entity work.RegisterNbits
		generic map (LENGTH=> 32)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => data_i,
			q     => PIPE3_data_i);
		
		P3_Out:    entity work.RegisterNbits
		generic map (LENGTH=> 32)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => PIPE2_result,
			q     => PIPE3_result);
			
		P3_dst:    entity work.RegisterNbits
		generic map (LENGTH=> 5)
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => PIPE2_dst,
			q     => PIPE3_dst);

		--Control	
		P3_RegWrite:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => PIPE2_RegWrite, 
			q     => PIPE3_RegWrite);
		
		P3_MemToReg:    entity work.RegisterBit
		port map (
			clock => clock,
			reset => reset,
			ce    => '1', 
			d     => PIPE2_MemToReg, 
			q     => PIPE3_MemToReg);


    -- Instruction memory is addressed by the PC register
    instructionAddress <= pc_q;
        
    
    -- Selects the instruction field witch contains the register to be written
    -- MUX at the register file input
	 PIPE1_dst<= PIPE1_rt when PIPE1_regDst = '0' else PIPE1_rd;
    MUX_RF: writeRegister <= PIPE3_dst;
    
    -- Sign extends the low 16 bits of instruction 
    SIGN_EX: signExtended <= x"FFFF" & PIPE0_instruction(15 downto 0) when PIPE0_instruction(15) = '1' else 
                    x"0000" & PIPE0_instruction(15 downto 0);
                    
    -- Zero extends the low 16 bits of instruction 
    ZERO_EX: zeroExtended <= x"0000" & PIPE0_instruction(15 downto 0);
       
    -- Converts the branch offset from words to bytes (multiply by 4) 
    -- Hardware at the second ADDER input
    SHIFT_L: branchOffset <= PIPE1_signExtended(29 downto 0) & "00";
    
    -- Branch target address
    -- Branch ADDER
    ADDER_BRANCH: branchTarget <= STD_LOGIC_VECTOR(UNSIGNED(PIPE1_incrementedPC) + UNSIGNED(branchOffset));
    
    -- Jump target address
    jumpTarget <= PIPE1_incrementedPC(31 downto 28) & PIPE1_instruction & "00";
    
    -- MUX which selects the PC value
    MUX_PC: pc_d <= branchTarget when (PIPE2_Branch and PIPE2_zero) = '1' else 
            PIPE2_jumpTarget when PIPE2_Jump = '1' else
            incrementedPC;
      
    -- Selects the second ALU operand
    -- MUX at the ALU input
    MUX_ALU: ALUoperand2 <= PIPE1_readData2 when PIPE1_ALUSrc = "00" else
                            PIPE1_zeroExtended when PIPE1_ALUSrc = "01" else
                            PIPE1_signExtended;
    
    -- Selects the data to be written in the register file
    -- MUX at the data memory output
    MUX_DATA_MEM: writeData <= PIPE3_data_i when PIPE3_memToReg = '1' else PIPE3_result;
    

    -- Data to data memory comes from the second read register at register file
    data_o <= PIPE2_readData2;
    
    -- ALU output address the data memory
    dataAddress <= PIPE2_result;
    
    
    -- Register file
    REGISTER_FILE: entity work.RegisterFile(structural)
        port map (
            clock            => clock,
            reset            => reset,            
            write            => PIPE3_RegWrite,            
            readRegister1    => rs,    
            readRegister2    => rt,
            writeRegister    => writeRegister,
            writeData        => writeData,          
            readData1        => readData1,        
            readData2        => readData2
        );
    
    
    -- Arithmetic/Logic Unit
    ALU: entity work.ALU(behavioral)
        port map (
            operand1    => PIPE1_readData1,
            operand2    => ALUoperand2,
            result      => result,
            zero        => zero,
            operation   => uins.instruction
        );

end structural;