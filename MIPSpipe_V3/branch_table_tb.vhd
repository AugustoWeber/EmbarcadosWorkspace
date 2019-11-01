--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:47:28 10/02/2019
-- Design Name:   
-- Module Name:   /Mipspipe_V3/branch_table_tb.vhd
-- Project Name:  MIPSpipe_V3
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: branch_table
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
--
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY branch_table_tb IS
END branch_table_tb;
 
ARCHITECTURE behavior OF branch_table_tb IS 
 
      -- Component Declaration for the Unit Under Test (UUT)

      COMPONENT branch_table
      PORT(
         clk   : IN  std_logic;
         rst   : IN  std_logic;
         pc_in : IN  std_logic_vector(31 downto 0);
         pc_out         : OUT  std_logic_vector(31 downto 0);
         endereco_in    : IN  std_logic_vector(31 downto 0);
         endereco_out   : OUT  std_logic_vector(31 downto 0);
         achou_out      : OUT  std_logic;
         incluir        : IN  std_logic
         );
      END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   --signal pc_in : std_logic_vector(31 downto 0) := (others => '0');
   signal endereco_in, pc_in : std_logic_vector(31 downto 0) := (others => '0');
   signal incluir : std_logic := '0';

   --Outputs
   signal pc_out : std_logic_vector(31 downto 0);
   signal endereco_out : std_logic_vector(31 downto 0);
   signal achou_out : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
   -- Instantiate the Unit Under Test (UUT)
   uut: branch_table 
   PORT MAP (
          clk =>     clk, 
          rst =>     rst,
          pc_in =>   pc_in ,
          pc_out =>  pc_out,
          endereco_in =>   endereco_in,
          endereco_out =>  endereco_out,
          achou_out =>  achou_out,
          incluir =>    incluir
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
      -- hold reset state for 15 ns.
      wait for 15 ns;	

      pc_in <= x"00000004";
      incluir <= '0';

      wait for clk_period;
      pc_in <= pc_in + x"00000004";
      incluir <= not incluir;
      endereco_in <= x"00000004";
      -- insert stimulus here 
 
      wait;
   end process;
END;
