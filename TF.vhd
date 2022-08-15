library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;  

entity TF is
port (  sensor  : in STD_LOGIC; -- Sensor kendaraan pada jalan perdesaan
		  s		 : in STD_LOGIC;
        clk  	 : in STD_LOGIC;
        rst_n	 : in STD_LOGIC;
        A  		 : out STD_LOGIC_VECTOR(2 downto 0); -- Jalan Utama
		  B		 : out STD_LOGIC_VECTOR(2 downto 0) -- Jalan Perdesaan
   );
end TF;
architecture behavior of TF is
signal counter_1s: std_logic_vector(27 downto 0):= x"0000000";
signal delay_count:std_logic_vector(3 downto 0):= x"0";
signal delay_10s, delay_3s_B, delay_3s_A, lampu_merah_ENABLE, lampu_kuning1_ENABLE,lampu_kuning2_ENABLE: std_logic:='0'; 
-- delay 3s untuk lampu kuning
-- delay 10s untuk lampu merah
--lampu_kuning1 = lampu kuning pada jalan utama
--lampu_kuning2 = lampu kuning pada jalan perdesaan
signal clk_1s_enable: std_logic;
type FSM_States is (state1, state2, state3, state4, state5, state6);
-- state1 : A(Jalan Utama) kondisi hijau dan B(Jalan Perdesaan) kondisi merah
-- state2 : A kondisi kuning dan B kondisi merah
-- state3 : A kondisi merah dan B kondisi hijau
-- state4 : A kondisi merah dan B kondisi kuning
-- state5 : A dan B kuning
-- state6 : A dan B mati
signal current_state, next_state: FSM_States;

begin
process(clk,rst_n) 
begin
if(rst_n='0') then
 current_state <= state1;
elsif(rising_edge(clk)) then 
 current_state <= next_state; 
end if; 
end process;
 
process(current_state,sensor,s,delay_3s_B,delay_3s_A,delay_10s)
begin
case current_state is 
when state1 => -- Kondisi A hijau dan B merah
 lampu_merah_ENABLE <= '0';-- meniadakan counting delay merah
 lampu_kuning1_ENABLE <= '0';-- meniadakan counting delay kuning pada jalan utama
 lampu_kuning2_ENABLE <= '0';-- meniadakan counting delay kuning pada jalan perdesaan
 A <= "001"; -- A Kondisi hijau (merah = 100, kuning = 010, hijau = 001)
 B <= "100"; -- B Kondisi merah
 if(sensor = '1') then -- jika sensor mendeteksi ada kendaraan pada jalan perdesaan
  next_state <= state2; -- lampu merah pada jalan utama akan berubah menjadi kuning
 elsif(s = '1') then
  next_state <= state5;
 else 
  next_state <= state1; -- jika sensor TIDAK mendeteksi ada kendaraan pada jalan perdesaan maka state kembali ke default(Jalan utama hijau)
 end if;
 when state2 => -- ketika lampu kuning pada jalan utama dan merah pada jalan perdesaan
 A <= "010";
 B <= "100";
 lampu_merah_ENABLE <= '0';-- meniadakan counting delay merah
 lampu_kuning1_ENABLE <= '1';-- melakukan counting delay lampu kuning pada jalan utama
 lampu_kuning2_ENABLE <= '0';-- meniadakan counting delay kuning pada jalan perdesaan
 if(s = '1') then
  next_state <= state5;
 elsif(delay_3s_A='1') then -- jika delay count lampu kuning sudah 3s, maka lampu jalan utama akan menjadi merah dan lampu jalan perdesaan menjadi hijau
  next_state <= state3; 
 else 
  next_state <= state2; -- jika tidak, kondisi akan tetap sama hingga delay count sudah 3s
 end if;
when state3 => -- ketika lampu merah pada jalan utama dan hijau pada jalan perdesaan
 A <= "100";
 B <= "001";
 lampu_merah_ENABLE <= '1';-- melakukan counting delay untuk lampu merah
 lampu_kuning1_ENABLE <= '0';-- meniadakan counting delay kuning pada jalan utama
 lampu_kuning2_ENABLE <= '0';-- meniadakan counting delay kuning pada jalan perdesaan
 if(s = '1') then
  next_state <= state5;
elsif(delay_10s='1') then -- jika lampu merah pada jalan utama sudah 10s, maka lampu jalan perdesaan akan berubah menjadi kuning
  next_state <= state4;
 else 
  next_state <= state3; -- jika tidak, kondisi akan tetap sama hingga delay count sudah 10s
 end if;
when state4 => --ketika lampu merah pada jalan utama dan kuning pada jalan perdesaan
 A <= "100";
 B <= "010"; 
 lampu_merah_ENABLE <= '0'; -- meniadakan counting delay merah
 lampu_kuning1_ENABLE <= '0';-- meniadakan counting delay kuning pada jalan utama
 lampu_kuning2_ENABLE <= '1';-- melakukan counting delay kuning pada jalan utama
 if(s = '1') then
  next_state <= state5;
 elsif(delay_3s_B='1') then -- jika delay count lampu kuning sudah 3s, maka lampu jalan utama akan menjadi hijau dan lampu jalan perdesaan menjadi merah
 next_state <= state5;
 else 
 next_state <= state4; -- jika tidak, kondisi akan tetap sama hingga delay count sudah 3s
 end if;
 when state5 => --ketika lampu kuning
 A <= "010";
 B <= "010"; 
 if(clk='1') then
 next_state <= state6;
 else 
 next_state <= state5;
 end if;
 when state6 => --ketika lampu kuning
 A <= "000";
 B <= "000"; 
 if(s = '0') then
 next_state <= state1;
 elsif(clk = '1') then
 next_state <= state5;
 else 
 next_state <= state6;
 end if;
when others => next_state <= state1;
end case;
end process;

process(clk)
begin
if(rising_edge(clk)) then 
if(clk_1s_enable='1') then
 if(lampu_merah_ENABLE='1' or lampu_kuning1_ENABLE='1' or lampu_kuning2_ENABLE='1') then
  delay_count <= delay_count + x"1";
  if((delay_count = x"9") and lampu_merah_ENABLE ='1') then 
   delay_10s <= '1';
   delay_3s_A <= '0';
   delay_3s_B <= '0';
   delay_count <= x"0";
  elsif((delay_count = x"2") and lampu_kuning1_ENABLE= '1') then
   delay_10s <= '0';
   delay_3s_A <= '1';
   delay_3s_B <= '0';
   delay_count <= x"0";
  elsif((delay_count = x"2") and lampu_kuning2_ENABLE= '1') then
   delay_10s <= '0';
   delay_3s_A <= '0';
   delay_3s_B <= '1';
   delay_count <= x"0";
  else
   delay_10s <= '0';
   delay_3s_A <= '0';
   delay_3s_B <= '0';
  end if;
 end if;
 end if;
end if;
end process;

process(clk)
begin
if(rising_edge(clk)) then 
 counter_1s <= counter_1s + x"0000001";
 if(counter_1s >= x"0000003") then
 
  counter_1s <= x"0000000";
 end if;
end if;
end process;
clk_1s_enable <= '1' when counter_1s = x"0003" else '0';
end behavior;
