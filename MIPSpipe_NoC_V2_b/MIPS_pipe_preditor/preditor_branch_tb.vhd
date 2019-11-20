--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:16:16 10/30/2019
-- Design Name:   
-- Module Name:   /home/padilha/Programas/14.7/ISE_DS/Mips_Pipeline_v4/preditor_branch_tb.vhd
-- Project Name:  Mips_Pipeline_v4
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: preditor_branch
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY preditor_branch_tb IS
END preditor_branch_tb;
 
ARCHITECTURE behavior OF preditor_branch_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT preditor_branch
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         predicao_out : OUT  std_logic_vector(1 downto 0);
         pc_consulta : IN  std_logic_vector(31 downto 0);
         achou : OUT  std_logic;
         endereco_out : OUT  std_logic_vector(31 downto 0);
         pc_indice_tab_out : OUT  std_logic_vector(2 downto 0);
         pc_incluir : IN  std_logic_vector(31 downto 0);
         endereco_incluir : IN  std_logic_vector(31 downto 0);
         incluir : IN  std_logic;
         atualizar : IN  std_logic;
         pc_indice_tab_in : IN  std_logic_vector(2 downto 0);
         zero_in : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal pc_consulta : std_logic_vector(31 downto 0) := (others => '0');
   signal pc_incluir : std_logic_vector(31 downto 0) := (others => '0');
   signal endereco_incluir : std_logic_vector(31 downto 0) := (others => '0');
   signal incluir : std_logic := '0';
   signal atualizar : std_logic := '0';
   signal pc_indice_tab_in : std_logic_vector(2 downto 0) := (others => '0');
   signal zero_in : std_logic := '0';

 	--Outputs
   signal predicao_out : std_logic_vector(1 downto 0);
   signal achou : std_logic;
   signal endereco_out : std_logic_vector(31 downto 0);
   signal pc_indice_tab_out : std_logic_vector(2 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: preditor_branch PORT MAP (
          clk => clk,
          rst => rst,
          predicao_out => predicao_out,
          pc_consulta => pc_consulta,
          achou => achou,
          endereco_out => endereco_out,
          pc_indice_tab_out => pc_indice_tab_out,
          pc_incluir => pc_incluir,
          endereco_incluir => endereco_incluir,
          incluir => incluir,
          atualizar => atualizar,
          pc_indice_tab_in => pc_indice_tab_in,
          zero_in => zero_in
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 10 ns;	

      wait for clk_period*10;

		pc_consulta <= x"00000004";
      wait for clk_period;
		incluir <= '1';
		pc_incluir <= x"00000004";
		endereco_incluir <= x"00000004";
		zero_in <= '1';
		wait for clk_period;
		
		pc_incluir <= x"00000005";
		endereco_incluir <= x"00000005";
		zero_in <= '0';
		wait for clk_period;
		
		pc_incluir <= x"00000006";
		endereco_incluir <= x"00000006";
		zero_in <= '1';
	
		wait for clk_period;
		
		pc_consulta <= x"00000005";
		pc_incluir <= x"00000007";
		endereco_incluir <= x"00000007";
		zero_in <= '1';
		wait for clk_period;
		
		pc_incluir <= x"00000008";
		endereco_incluir <= x"00000008";
		wait for clk_period;
		
		incluir <= '0';
		pc_consulta<= x"00000004";
		atualizar <= '1';
		
		pc_indice_tab_in <= pc_indice_tab_out;
		zero_in <= '1';
		
		wait for clk_period;
			
		
		incluir <= '0';
		pc_consulta<= x"00000004";
		atualizar <= '1';
		
		pc_indice_tab_in <= pc_indice_tab_out;
		zero_in <= '1';
		
		wait for clk_period;
		
		
		incluir <= '0';
		pc_consulta<= x"00000004";
		atualizar <= '1';
		
		pc_indice_tab_in <= pc_indice_tab_out;
		zero_in <= '0';
		
		wait for clk_period;
		
		
		incluir <= '0';
		pc_consulta<= x"00000004";
		atualizar <= '1';
		
		pc_indice_tab_in <= pc_indice_tab_out;
		zero_in <= '0';
		
		wait for clk_period;
		
		
		incluir <= '0';
		pc_consulta<= x"00000004";
		atualizar <= '1';
		
		pc_indice_tab_in <= pc_indice_tab_out;
		zero_in <= '0';
      -- insert stimulus here 

      wait;
   end process;

END;
