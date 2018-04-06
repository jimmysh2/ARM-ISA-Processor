----- CONTROLLER
library ieee;
use ieee.std_logic_1164.all;
entity controller is 
port (	
		clk : in std_logic; ins : in std_logic_vector(31 downto 0);
		PW,iord,MR,MW,IW,DW,Rsrc,M2R,RW,AW,BW,Asrc1,Fset,Rew, reset_rf : out std_logic ;
		Asrc2 : out std_logic_vector(1 downto 0);
		op : out std_logic_vector(3 downto 0));
end entity;
----
---- Main controller
library ieee;
use ieee.std_logic_1164.all;
entity main is 
port (	
		clk,p : in std_logic; ins : in std_logic_vector(31 downto 0); 
		PW,iord,MR,MW,IW,DW,Rsrc,M2R,RW,AW,BW,Asrc1,Fset,Rew, reset_rf : out std_logic ;
		Asrc2 : out std_logic_vector(1 downto 0);
		op : out std_logic_vector(3 downto 0));
end entity;
----
---- B controller
library ieee;
use ieee.std_logic_1164.all;
entity Bctrl is 
port (	
		clk,c,v,n,z : in std_logic; ins : in std_logic_vector(3 downto 0);
		p : out std_logic );
end entity;

-- IR
library ieee;
use ieee.std_logic_1164.all;
entity Ins_decoder is 
port ( 
		ins: in std_logic_vector(32 downto 0);
		class:out std_logic_vector(1 downto 0);
		sub_class:out std_logic_vector(4 downto 0));
end entity;
----
---- 'Actrl' is not needed as it is embedded in main controller
--library ieee;
--use ieee.std_logic_1164.all;
--entity Actrl is 
--port (	
--		clk : in std_logic; ins : in std_logic_vector(31 downto 0);
--		op : out std_logic_vector(3 downto 0));
--end entity;
----

---------------
-- ************ START OF ARCHITECTURE **********
architecture behav of main is
	signal state : std_logic_vector(3 downto 0);
	begin
		
		process(clk)
			if(clk='1' and clock'event) then
				---here come the states (from slide 30-33 of lec 12)
				case state is

					-- fetch
					when "0000" =>
						--signal values
						PW<='1';IW<='1';MR<=1;iord<=0;Asrc1<=0;Asrc2<=1;op<="opcode for add";
						
						--transitions
						state<="0001" --rdAB
					-------
					-- rdAB
					when "0001" =>
						--signal values
							PW <= '1' ; IW <='1';MR<='1';iord<='0';Asrc1<='0';Asrc2<='1';op<="0100";
							
						--transitions
						if(ins(27 downto 26)="00") then
							state<="0010"; --arith
						elsif(ins(27 downto 26)="01") then
							state<="0100"; --addr
						elsif(ins(27 downto 26)="10")
							state<="1000"; --brn
						end if;
						---arith
					when "0010" => 
							---signal values 
								resW<='1';Fset<=p;Asrc1 <= '1' ; Asrc2='0';op<=ins(24 downto 21);
							---transitions
								if(ins(27 downto 26) = "00") then
									state<= "0011"; --wrRF
								end if;
								
						---wrRF
					when "0011" =>
							---signal values
								M2R<='0';RW<=p;
							
							---transitions 
							if(ins(27 downto 26) = "00") then
								state <= "0000";
							end if;
						---addr
					when  "0100" =>
							---signal values
								resW<='1';Asrc1<='1';Asrc2<="10";
								if(ins(23)='1') then 
									op<="0100";
								else
									op<="0010";
								end if;
							---transitions
							if(ins(27 downto 26) = "01" and ins(20) = '0' ) then
								state <= "0101" ; ---wrM
							elsif (ins(27 downto 26) = "01" and ins(20) = '1' ) then
								state<= "0111"; ----rdM
							end if;
						----wrM
					when "0101" =>
							----signal values
								iord<='1';MW<=p;
							
							----transitions
								if(ins(27 downto 26) = "01" and ins(20) = '0' ) then
									state<="0000";
								end if;
						----rdM
					when "0110" => 
							-----signal 
								DW<='1';MR<='1';iord<='1';
							-----transitions
								if(ins(27 downto 26) = "01" and ins(20) = '1' ) then
									state<="0111";
								end if;
						---M2RF	
					when "0111" =>
						---signal 
						M2R<='1';RW<=p;				
						----transitions
							if(ins(27 downto 26) = "01" and ins(20) = '1' ) then
								state<="0000";
							end if;
						----brn
					when "1000" => 
						---signal
							PW<=p;Asrc1<='0';Asrc2<="11";op<="0100";
						---transitions
							if(ins(27 downto 26) = "10") then
								state<="0000";
							end if;
					-------
					---similarly do below for all the states
					
				end case;
			end if;		
		end process;
end architecture;
----------
architecture behav of Bctrl is
	begin
		with ins select p <=
					z when "0000",
					not z when "0001",
					c when "0010",
					not c when "0011",
					n when "0100",
					not n when "0101",
					v when "0110",
					not v when "0111",
					c and not z when "1000",
					not ( c and not z ) when "1001",
					n xor v when "1010",
					not(n xor v)  when "1011",
					(n xor v) and not z when "1100",
					not ((n xor v) and not z ) when "1101",
					'1' when others;
					
				
					-- and so on from slide 11-12 of lec 12
		
end architecture;
----architecture
architecture behav of Ins_decoder is 
signal class_1 :std_logic; 

begin
class_1<="00" when ( ins(27 downto 26) = "00" and  (ins(25) or (ins(25)= '0' and (ins(4)='0' or (ins(7)='0' and ins(4)='1'))))) else
		"01" when ( ins(27 downto 23) = "00000" and ins(7 downto 4)="1001") else 
		"10" when (ins(27 downto 26) = "01" or (ins(27 downto 26)="00" and ins(11 downto 7)="00001" and ins(4)='1' and not(ins(6 downto 5)="00"))) else
		"11" when ins(27 downto 26) = "10";
sub_class<= 	
end architecture; of instruction decoder

