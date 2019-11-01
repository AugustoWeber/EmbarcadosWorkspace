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
        uins                : in  Microinstruction;               -- Control path microinstruction
		instr_contrl        : out std_logic_vector(31 downto 0);
		MemWrite            : out std_logic
    );
end DataPath;


architecture structural of DataPath is

    signal incrementedPC:   std_logic_vector(31 downto 0);
    signal pc_q:            std_logic_vector(31 downto 0);
    signal result:          std_logic_vector(31 downto 0);
    signal readData1:       std_logic_vector(31 downto 0); 
    signal readData2:       std_logic_vector(31 downto 0); 
    signal ALUoperand2:     std_logic_vector(31 downto 0);
    signal signExtended:    std_logic_vector(31 downto 0); 
    signal zeroExtended:    std_logic_vector(31 downto 0);
    signal writeData:       std_logic_vector(31 downto 0);
    signal branchOffset:    std_logic_vector(31 downto 0);
    signal branchTarget:    std_logic_vector(31 downto 0);
    signal pc_d:            std_logic_vector(31 downto 0);
    signal jumpTarget:      std_logic_vector(31 downto 0);
    signal writeRegister:   std_logic_vector(4 downto 0);  
			   
    signal rs: std_logic_vector(4 downto 0);
    signal rt: std_logic_vector(4 downto 0);
    signal rd: std_logic_vector(4 downto 0);
    
    signal zero : std_logic; 
    
	 
    type pipe_reg1 is
    record
        pc,ir: std_logic_vector(31 downto 0);
    end record;
    
    type pipe_reg2 is
    record
        uins : Microinstruction;
        pc,rb,ra,imm :std_logic_vector(31 downto 0);
        rt, rd :std_logic_vector(4 downto 0);
        jumptarget: std_logic_vector(31 downto 0);
        zeroExtended: std_logic_vector(31 downto 0);
    end record;
    
    
    type pipe_reg3 is
    record
        uins : Microinstruction;
        --target :std_logic_vector(31 downto 0);
        aluOut :std_logic_vector(31 downto 0);
        rb		 :std_logic_vector(31 downto 0);
        dst	 :std_logic_vector(4  downto 0);
        zero	 :std_logic;
        branchtarget: std_logic_vector(31 downto 0);
        jumptarget: std_logic_vector(31 downto 0);
    end record;
        
    type pipe_reg4 is
    record
        uins : Microinstruction;
        readData: std_logic_vector(31 downto 0);
        aluOut	: std_logic_vector(31 downto 0);
        dst		: std_logic_vector(4 downto 0);
    end record;
                            
    signal pipe1 : pipe_reg1;
    signal pipe2 : pipe_reg2;
    signal pipe3 : pipe_reg3;
    signal pipe4 : pipe_reg4;
	

begin
	process(clock,reset)
	begin
	
	if reset = '1' then
		pipe1.pc <= (others => '0');
		pipe1.ir <= (others => '0');
		
		pipe2.uins.RegWrite	<= '0';
		pipe2.uins.RegDst		<= '0';
		pipe2.uins.MemToReg	<= '0';
		pipe2.uins.ALUSrc		<= (others => '0');
		pipe2.uins.MemWrite	<= '0';
		pipe2.uins.Branch		<= '0';
		pipe2.uins.Jump		<= '0';
		pipe2.uins.instruction	<= NOP;
		pipe2.pc<= (others => '0');
		pipe2.rb<= (others => '0');
		pipe2.ra<= (others => '0');
		pipe2.imm<= (others => '0');
		pipe2.rt<= (others => '0');
		pipe2.rd <= (others => '0');
		pipe2.jumptarget<= (others => '0');
		pipe2.zeroExtended<= (others => '0');
		
		
		pipe3.uins.RegWrite	<= '0';
		pipe3.uins.RegDst		<= '0';
		pipe3.uins.MemToReg	<= '0';
		pipe3.uins.ALUSrc		<= (others => '0');
		pipe3.uins.MemWrite	<= '0';
		pipe3.uins.Branch		<= '0';
		pipe3.uins.Jump		<= '0';
		pipe3.uins.instruction	<= NOP;
		pipe3.aluOut <= (others => '0');
		pipe3.rb <= (others => '0');
		pipe3.dst <= (others => '0');
		pipe3.branchtarget <= (others => '0');
		pipe3.jumptarget <= (others => '0');
		pipe3.zero <= '0';
		
		pipe4.uins.RegWrite	<= '0';
		pipe4.uins.RegDst		<= '0';
		pipe4.uins.MemToReg	<= '0';
		pipe4.uins.ALUSrc		<= (others => '0');
		pipe4.uins.MemWrite	<= '0';
		pipe4.uins.Branch		<= '0';
		pipe4.uins.Jump		<= '0';
		pipe4.uins.instruction	<= NOP;
		pipe4.readData	<= (others => '0');
		pipe4.ALUOut <= (others => '0');
		pipe4.dst	<= (others => '0');
		
	elsif rising_edge(clock) then
	--Pipe1--
        pipe1.pc <= incrementedPC; -- para pipe 2
        pipe1.ir <= instruction;
		
    --Pipe2--
        pipe2.jumpTarget    <= jumpTarget;
        pipe2.pc            <= pipe1.pc;
        pipe2.uins          <= uins;
        pipe2.ra            <= readData1;
        pipe2.rb            <= readData2;
        pipe2.imm           <= signExtended;
        pipe2.zeroExtended  <= zeroExtended;
        pipe2.rt            <= rt;
        pipe2.rd            <= rd;
	
	--Pipe3--
        pipe3.uins          <= pipe2.uins;
        pipe3.Branchtarget  <= branchtarget;
        pipe3.jumptarget    <= pipe2.jumptarget;
        pipe3.aluOut        <= result;
        pipe3.rb            <= pipe2.rb;
        pipe3.dst           <= writeRegister;
        pipe3.zero          <= zero;
    
    --pipe4--	
        pipe4.uins		<= pipe3.uins;
        pipe4.readData	<= data_i;
        pipe4.aluout	<= pipe3.aluOut;
        pipe4.dst 		<= pipe3.dst;
		
    end if;
    end process;
	
	instr_contrl	<= pipe1.ir;
	
	    -- Retrieves the rs field from the instruction
	rs <= pipe1.ir(25 downto 21);
        
    -- Retrieves the rt field from the instruction
	rt <= pipe1.ir(20 downto 16);
        
    -- Retrieves the rd field from the instruction
	rd <= pipe1.ir(15 downto 11);
	
	
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
        
		  
    -- Instruction memory is addressed by the PC register
    instructionAddress <= pc_q;
        

    -- Selects the instruction field witch contains the register to be written
    -- MUX at the register file input
    MUX_RF: writeRegister <= pipe2.rt when pipe2.uins.regDst = '0' else pipe2.rd;
    
    -- Sign extends the low 16 bits of instruction 
    SIGN_EX: signExtended <= x"FFFF" & pipe1.ir(15 downto 0) when pipe1.ir(15) = '1' else 
                    x"0000" & pipe1.ir(15 downto 0);
                    
    -- Zero extends the low 16 bits of instruction 
    ZERO_EX: zeroExtended <= x"0000" & pipe1.ir(15 downto 0);
       
    -- Converts the branch offset from words to bytes (multiply by 4) 
    -- Hardware at the second ADDER input
    SHIFT_L: branchOffset <= pipe2.imm(29 downto 0) & "00";
    
    -- Branch target address
    -- Branch ADDER
    ADDER_BRANCH: branchTarget <= STD_LOGIC_VECTOR(UNSIGNED(pipe2.pc) + UNSIGNED(branchOffset));
    
    -- Jump target address
    jumpTarget <= pipe1.pc(31 downto 28) & pipe1.ir(25 downto 0) & "00";
    
    -- MUX which selects the PC value
    
	 
	 MUX_PC: pc_d <= pipe3.branchTarget when (pipe3.uins.Branch and pipe3.zero) = '1' else 
            pipe3.jumpTarget when pipe3.uins.Jump = '1' else
            incrementedPC;
      
    -- Selects the second ALU operand
    -- MUX at the ALU input
    MUX_ALU: ALUoperand2 <= pipe2.rb when pipe2.uins.ALUSrc = "00" else
                            pipe2.zeroExtended when pipe2.uins.ALUSrc = "01" else
                            pipe2.imm;
    
    -- Selects the data to be written in the register file
    -- MUX at the data memory output
    MUX_DATA_MEM: writeData <= pipe4.readData when pipe4.uins.memToReg = '1' else pipe4.aluOut;
    

    -- Data to data memory comes from the second read register at register file
    data_o <= pipe3.rb;
    
    -- ALU output address the data memory
    dataAddress <= pipe3.aluOut;
    
	MemWrite <= pipe3.uins.MemWrite;
	
    -- Register file
    REGISTER_FILE: entity work.RegisterFile(structural)
        port map (
            clock            => clock,
            reset            => reset,
            write            => pipe4.uins.RegWrite,
            readRegister1    => rs,
            readRegister2    => rt,
            writeRegister    => pipe4.dst,
            writeData        => writeData,
            readData1        => readData1,
            readData2        => readData2
        );
    
    
    -- Arithmetic/Logic Unit
    ALU: entity work.ALU(behavioral)
        port map (
            operand1    => pipe2.ra,
            operand2    => ALUoperand2,
            result      => result,
            zero        => zero,
            operation   => pipe2.uins.instruction
        );

end structural;