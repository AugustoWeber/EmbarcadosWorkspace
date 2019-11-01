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
        clk               : in  std_logic;
        reset               : in  std_logic;
        instructionAddress  : out std_logic_vector(31 downto 0);  -- Instruction memory address bus
        instruction         : in  std_logic_vector(31 downto 0);  -- Data bus from instruction memory
        dataAddress         : out std_logic_vector(31 downto 0);  -- Data memory address bus
        data_i              : in  std_logic_vector(31 downto 0);  -- Data bus from data memory 
        data_o              : out std_logic_vector(31 downto 0);  -- Data bus to data memory
        uins                : in  Microinstruction;               -- Control path microinstruction
		instr_contrl		: out std_logic_vector(31 downto 0);
		MemWrite			: out std_logic
    );
end DataPath;


architecture structural of DataPath is

    signal incrementedPC, pc_q, result, readData1, readData2, ALUoperand1, ALUoperand2, signExtended, zeroExtended, writeData: std_logic_vector(31 downto 0);
    signal branchOffset, branchTarget, pc_d: std_logic_vector(31 downto 0);
    signal jumpTarget: std_logic_vector(31 downto 0);
    signal writeRegister   : std_logic_vector(4 downto 0);  
		
    signal rs: std_logic_vector(4 downto 0);
    signal rt: std_logic_vector(4 downto 0);
    signal rd: std_logic_vector(4 downto 0);
    
    signal zero : std_logic;
    signal clk_n    : std_logic;
    signal RegWrite : std_logic;
    signal bouble : std_logic;
    signal pipeClean: std_logic; 

    type pipe_reg1 is
    record
        pc,ir: std_logic_vector(31 downto 0);
        achou: std_logic;
    end record;

    type pipe_reg2 is
    record
        uins : Microinstruction;
        pc,rb,ra,imm :std_logic_vector(31 downto 0);
        rt, rd, rs :std_logic_vector(4 downto 0);
        jumptarget: std_logic_vector(31 downto 0);
        zeroExtended : std_logic_vector(31 downto 0);
        achou: std_logic;
    end record;


    type pipe_reg3 is
    record
        uins : Microinstruction;
        aluOut :std_logic_vector(31 downto 0);
        rb		 :std_logic_vector(31 downto 0);
        dst         :std_logic_vector(4  downto 0);
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
	process(clk)
	begin
	
    if rising_edge(clk) then
    -- --Pipe1--
    --     pipe1.ir <= instruction;

    if pipeClean = '1' then
        pipe1.pc <= x"00";
        pipe1.ir <= x"00";

        pipe2.jumpTarget        <= jumpTarget;
        pipe2.pc	              <= pipe1.pc;
        pipe2.uins.RegWrite 	  <= '0';
        pipe2.uins.MemWrite 	  <= '0';
        pipe2.uins.Branch       <= '0';
        pipe2.uins.Jump      	  <= '0';
        pipe2.uins.Instruction  <= NOP;  
			pipe2.rt				<= "00000";
			pipe2.rs				<= "00000";
			pipe2.rd				<= "00000";		  
        
    
    elsif bouble = '1' then
        pipe1 <= pipe1;
        --pipe2 <= pipe2;
    -- --Pipe1--
    --         pipe1.pc <= pc_q;
        
	--Pipe2--
            pipe2.jumpTarget        <= jumpTarget;
            pipe2.pc	            <= pipe1.pc;
            pipe2.uins.RegWrite 	<= '0';
            pipe2.uins.MemWrite 	<= '0';
            pipe2.uins.Branch       <= '0';
            pipe2.uins.Jump      	<= '0';
            pipe2.uins.Instruction 	<= NOP; 
            pipe2.rt				<= "00000";
            pipe2.rs				<= "00000";
            pipe2.rd				<= "00000";

    else
    --Pipe1--
            pipe1.pc <= incrementedPC;
            pipe1.ir <= instruction;

	--Pipe2--
            pipe2.jumpTarget <= jumpTarget;
            pipe2.pc	<= pipe1.pc;
            pipe2.uins  <= uins;
            pipe2.ra 	<= readData1;
            pipe2.rb 	<= readData2;
            pipe2.imm 	<= signExtended;
            pipe2.rt 	<= rt;
            pipe2.rs    <= rs;
            pipe2.rdinstruction 	<= rd;
            pipe2.zeroExtended <= zeroExtended;
        end if; 
    --Pipe3--
        pipe3.uins 			<= pipe2.uins;
        pipe3.Branchtarget  <= branchtarget;
        pipe3.jumptarget 	<= pipe2.jumptarget;
        pipe3.aluOut 	  	<= result;
        pipe3.rb			<= pipe2.rb;
        pipe3.dst		  	<= writeRegister;
        pipe3.zero			<= zero;
    --pipe4--
        
        pipe4.uins		<= pipe3.uins;
        pipe4.readData  <= data_i;
        pipe4.aluout	<= pipe3.aluOut;
        pipe4.dst 		<= pipe3.dst;
        
    end if;
    end process;

    instr_contrl <= pipe1.ir;
	
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
            clock       => clk,
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
    
	 --alterando o calculo do branch para antes do pipe2
	 
    -- Branch target address
    -- Branch ADDER
    ADDER_BRANCH: branchTarget <= STD_LOGIC_VECTOR(UNSIGNED(pipe2.pc) + UNSIGNED(branchOffset));
	

    
    -- Jump target address
    jumpTarget <= pipe1.pc(31 downto 28) & pipe1.ir(25 downto 0) & "00";
    
    -- MUX which selects the PC value
    
	 
    MUX_PC: pc_d <= pc_q when bouble = '1' else
                    branchTarget when (pipe2.uins.Branch and zero) = '1' else 
                    pipe2.jumpTarget when pipe2.uins.Jump = '1' else
                    incrementedPC;
	
    bouble <= '1' when pipe2.uins.instruction = lw and ((pipe2.rt = rs) or (pipe2.rt = rt)) else '0';
    
	 
    pipeClean <= '1' when (pipe2.uins.Branch and zero) = '1' or pipe2.uins.Jump = '1' else '0';
       
    -- Selects the ALU operands
    -- MUX at the ALU input with FORWARDING
    MUX_ALU1: ALUoperand1 <=pipe3.aluOut when pipe3.dst = pipe2.rs and pipe3.uins.RegWrite = '1' else
                            writeData when pipe4.dst = pipe2.rs and pipe4.uins.RegWrite = '1' else
                            pipe2.ra;

    MUX_ALU2: ALUoperand2 <= pipe3.aluOut when pipe3.dst = pipe2.rt and pipe3.uins.RegWrite = '1' else
                             writeData when pipe4.dst = pipe2.rt and pipe4.uins.RegWrite = '1' else
                             pipe2.rb when pipe2.uins.ALUSrc = "00" else
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
    
    -- Signal to write in the first half of the clock cicle.
	RegWrite <= '1' when pipe4.uins.RegWrite = '1' and clock = '1' else '0';

	 
    -- Register file
    REGISTER_FILE: entity work.RegisterFile(structural)
        port map (
            clock            => clk_n,
            reset            => reset,            
            write            => RegWrite,            
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
            operand1    => ALUoperand1,
            operand2    => ALUoperand2,
            result      => result,
            zero        => zero,
            operation   => pipe2.uins.instruction
        );

        clk_n   <= not clk;
end structural;