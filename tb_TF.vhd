LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- Testbench VHDL code for traffic light controller 
ENTITY tb_TF IS
END tb_TF;

ARCHITECTURE behavior OF tb_TF IS 
    -- Component Declaration for the traffic light controller 
    COMPONENT TF
    PORT(
         sensor : IN  std_logic;
         clk : IN  std_logic;
         rst_n : IN  std_logic;
         A : OUT  std_logic_vector(2 downto 0);
         B : OUT  std_logic_vector(2 downto 0)
        );
    END COMPONENT;
   signal sensor : std_logic := '0';
   signal clk : std_logic := '0';
   signal rst_n : std_logic := '0';
  --Outputs
   signal A : std_logic_vector(2 downto 0);
   signal B : std_logic_vector(2 downto 0);
   constant clk_period : time := 10 ns;
BEGIN
 -- Instantiate the traffic light controller 
   trafficlightcontroller : TF PORT MAP (
          sensor => sensor,
          clk => clk,
          rst_n => rst_n,
          A => A,
          B => B
        );
   -- Clock process definitions
   clk_process :process
   begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
   end process;
   stim_proc: process
   begin    
  rst_n <= '0';
  sensor <= '0';
      wait for clk_period*5;
  rst_n <= '1';
  wait for clk_period*10;
  sensor <= '1';
  wait for clk_period*5;
  sensor <= '0';
      wait;
   end process;

END;