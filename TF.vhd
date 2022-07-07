library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;  

entity TF is
port (  sensor  : in STD_LOGIC; -- Sensor kendaraan pada jalan perdesaan
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
--lampu_kuning1 = lampu kuning pada jalan perdesaan
signal clk_1s_enable: std_logic;
type FSM_States is (AH_BM, AK_BM, AM_BH, AM_BK);
-- AH_BM : A(Jalan Utama) kondisi hijau dan B(Jalan Perdesaan) kondisi merah
-- AK_BM : A kondisi kuning dan B kondisi merah
-- AM_BH : A kondisi merah dan B kondisi hijau
-- AM_BK : A kondisi merah dan B kondisi kuning
signal current_state, next_state: FSM_States;

begin
process(clk,rst_n) 
begin
if(rst_n='0') then
 current_state <= AH_BM;
elsif(rising_edge(clk)) then 
 current_state <= next_state; 
end if; 
end process;
 
process(current_state,sensor,delay_3s_B,delay_3s_A,delay_10s)
begin
case current_state is 
when AH_BM => -- Kondisi A hijau dan B merah
 lampu_merah_ENABLE <= '0';-- meniadakan counting delay merah
 lampu_kuning1_ENABLE <= '0';-- meniadakan counting delay kuning pada jalan utama
 lampu_kuning2_ENABLE <= '0';-- meniadakan counting delay kuning pada jalan perdesaan
 A <= "001"; -- A Kondisi hijau (merah = 100, kuning = 010, hijau = 001)
 B <= "100"; -- B Kondisi merah
 if(sensor = '1') then -- jika sensor mendeteksi ada kendaraan pada jalan perdesaan
  next_state <= AK_BM; -- lampu merah pada jalan utama akan berubah menjadi kuning
 else 
  next_state <= AH_BM; -- jika sensor TIDAK mendeteksi ada kendaraan pada jalan perdesaan maka state kembali ke default(Jalan utama hijau)
 end if;
when AK_BM => -- ketika lampu kuning pada jalan utama dan merah pada jalan perdesaan
 A <= "010";
 B <= "100";
 lampu_merah_ENABLE <= '0';-- meniadakan counting delay merah
 lampu_kuning1_ENABLE <= '1';-- melakukan counting delay lampu kuning pada jalan utama
 lampu_kuning2_ENABLE <= '0';-- meniadakan counting delay kuning pada jalan perdesaan
 if(delay_3s_A='1') then -- jika delay count lampu kuning sudah 3s, maka lampu jalan utama akan menjadi merah dan lampu jalan perdesaan menjadi hijau
  next_state <= AM_BH; 
 else 
  next_state <= AK_BM; -- jika tidak, kondisi akan tetap sama hingga delay count sudah 3s
 end if;
when AM_BH => -- ketika lampu merah pada jalan utama dan hijau pada jalan perdesaan
 A <= "100";
 B <= "001";
 lampu_merah_ENABLE <= '1';-- melakukan counting delay untuk lampu merah
 lampu_kuning1_ENABLE <= '0';-- meniadakan counting delay kuning pada jalan utama
 lampu_kuning2_ENABLE <= '0';-- meniadakan counting delay kuning pada jalan perdesaan
 if(delay_10s='1') then -- jika lampu merah pada jalan utama sudah 10s, maka lampu jalan perdesaan akan berubah menjadi kuning
  next_state <= AM_BK;
 else 
  next_state <= AM_BH; -- jika tidak, kondisi akan tetap sama hingga delay count sudah 10s
 end if;
when AM_BK => --ketika lampu merah pada jalan utama dan kuning pada jalan perdesaan
 A <= "100";
 B <= "010"; 
 lampu_merah_ENABLE <= '0'; -- meniadakan counting delay merah
 lampu_kuning1_ENABLE <= '0';-- meniadakan counting delay kuning pada jalan utama
 lampu_kuning2_ENABLE <= '1';-- melakukan counting delay kuning pada jalan utama
 if(delay_3s_B='1') then -- jika delay count lampu kuning sudah 3s, maka lampu jalan utama akan menjadi hijau dan lampu jalan perdesaan menjadi merah
 next_state <= AH_BM;
 else 
 next_state <= AM_BK; -- jika tidak, kondisi akan tetap sama hingga delay count sudah 3s
 end if;
when others => next_state <= AH_BM;
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