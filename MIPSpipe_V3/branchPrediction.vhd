----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:52:02 10/02/2019 
-- Design Name: 
-- Module Name:    branch_table - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
--
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.MIPS_package.all;

entity branchPrediction is
    generic (size: integer := 8); -- numero de elementos da tablea
	 Port ( 
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        uins        : in  Microinstruction;                 -- From pipe 3
        zero        : in  std_logic;                        -- Zero signal from ALU
        taken       : in  std_logic;                        -- DATAPATH: pipe2.uins.Branch and zero
        pc_in       : in  std_logic_vector(31 downto 0);    -- From PC
        pc_out      : out std_logic_vector(31 downto 0);    -- PC from table entry
        endereco_in : in  std_logic_vector(31 downto 0);    -- Generate in second stage
        endereco_out: out std_logic_vector(31 downto 0)     -- To be the NextPC
        incluir     : in  std_logic
        pc_incluir  : in  std_logic_vector(31 downto 0);
        achou_out   : out std_logic;
    );

end branchPrediction;

architecture Behavioral of branchPrediction is


    -- signals for Table criation
    type entry is
        record 
            PC, jumpAddr    : std_logic_vector(31 downto 0);
            Predict         : branch_prediction;
        end record;
    type entry_array is array (1 to size) of entry;

    signal row              : entry_array;-- (size 1 to size); -- (size downto 1);
    signal include_index    : integer range 0 to size -1 :=0; --index para incluir novos elementos na tabela
    signal entry_match      : std_logic_vector(size-1 downto 0); --integer range 0 to size-1;
    signal achou            : std_logic;
    signal index            : integer range size to 0;

    signal ii               : integer range size to 0;
    signal temp             : std_logic_vector(size-1 downto 0); -- To OR between all positions in the std_logic_Vector
    signal temp1            : std_logic_vector(size-1 downto 0);

    -- Signals for FSM update
    signal branch           : std_logic;
    signal predicted        : branch_prediction; --CurrentState to be save in the table
    signal prediction       : branch_prediction; --NextState to be save in the table
    signal em1              : std_logic_vector(size-1 downto 0); -- entryMatch1 <= entryMatch
    signal em2              : std_logic_vector(size-1 downto 0); -- entryMatch2 <= entryMatch1


    -- Signals for Table insertion
    signal pc_save          : std_logic_vector(31 downto 0);
    signal achou1           : std_logic;     
    

    function to_boolean( V: std_logic)
        return boolean is
    begin
        if V = '1' then 
            return TRUE; 
        else 
            return FALSE; 
        end if;
    end to_boolean; 

    function Oor(var    :std_logic_vector(size downto 1)
                    )return boolean is
        variable j      : integer;--std_logic_vector(size-1 downto 0);
        variable temp   : std_logic_vector(size downto 1);
    begin
        temp(1) := var(1);
        for j in 2 to size loop
            temp(j) := temp(j-1) or var(j);
        end loop;
        return to_boolean(temp(size));
    end function Oor;

    component preditor_desvio
        Port (
            clk             : in std_logic;
            rst             : in std_logic;
            taken_i         : in std_logic; -- Tell the FSM if the branch occurs
            CS              : in branch_prediction;
            NState	        : out branch_prediction);
    end component;

begin
    
    -- for i in 0 to size-1 generate
    --     out_index(i) <= '1' when entry.pc(i) = pc_in and incluir = '0' else '0';
    --     endereco_out <= endereco(i) when achou = '1' else others <= '0';
    --     State <= State(i) when achou = '1' else others <= '0';
    -- end generate;
    -- Table_Generate: for index in 1 to size generate
    --     row(index);--.PC<= (others => '0');
    --     -- entry[index).jumpAddr <= (others => '0');
    --     -- entry[index.Predict <= NT2;
    -- end generate Table_Generate;

----------------------------------------------------------------------------------
-- 
-- Process de obtenção da entrada da tabela que satisfaz o branch
-- 
----------------------------------------------------------------------------------

    CheckEntrys:
    process(clk,rst)
        variable i          : integer   := 0;
        variable out_index  : std_logic_vector(size downto 1) := (others => '0');
    begin
        if rst = '1' then
            include_index <= (others => '0');
            out_index := (others => '0');
        elsif rising_edge(clk) then
            -- Busca pelas entradas na tabela
            for i in 1 to size loop
                if row(i).pc = pc_in then
                    out_index(i) := '1';
                else
                    out_index(i) := '0';
                    -- achou <= false;
                end if;
            end loop;
            entry_match <= out_index;

        end if;
    end process;
    -- achou <= or entry_match;  -- OR entre todos os bits
    temp(0) <= entry_match(0);
    or_generate: for ii in 1 to size-1 generate
       temp(ii) <= temp(ii-1) and entry_match(ii);
    end generate; 
    achou <= temp(size-1);
    pc_out <= row(to_integer(unsigned(entry_match))).jumpAddr when row(to_integer(unsigned(entry_match))).predict = T or row(to_integer(unsigned(entry_match))).predict = T2 else
              PC + x"00000004";

----------------------------------------------------------------------------------
-- 
-- Process de atualização da FSM
-- 
----------------------------------------------------------------------------------

    FSM_update:
    process(clk,rst,achou)
    begin
        if rst = '1' then
            em1 <= (others => '0'); -- Entry Match propagation reset
            em2 <= (others => '0'); -- Entry Match propagation reset
            if rising_edge(clk) then
                em1 <= entry_match;
                em2 <= em1;
                if (Oor(em2)) then --if (achou1 <= Oor(em2)) then -- If some row was matched
                    predicted <= row(to_integer(unsigned(em2))).Predict;
                end if;
            elsif falling_edge(clk) then
                if (Oor(em2)) then
                    row(to_integer((unsigned(em2)))).Predict <= prediction;
                end if;
            end if;
        end if;
    end process;

    FSM: preditor_desvio
    port map(
        clk =>          clk,
        rst =>          rst,
        taken_i =>      taken,
        CS =>           predicted,
        NState=>        prediction
    );
----------------------------------------------------------------------------------
-- 
-- Process de Inserção na tabela
-- 
----------------------------------------------------------------------------------

TableInsertion:
    process(clk, rst)
    begin
        if rising_edge(clk) then 
            if incluir = '1' then 
                row.PC(include_index)<=pc_incluir;
                include_index = include_index + 1;
            achou1 <= achou;
            --pc_save <= pc_in -x"00000004";
            end if;
        end if;
    end process;


end Behavioral;