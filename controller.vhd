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
		PW,iord,MR,MW,IW,DW,Rsrc,M2R,RW,AW,BW,Asrc1,Fset,Rew, reset_rf, MOW : out std_logic ;
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

		--- concurrent part
		--0000	fetch
		--0001	rdAB_FOR_DP
		--0010	rdX for dp
		--0011  Shift/rotate operand2
		--0100	Perform DP operation. Set flags if required.
		--0101	Write result into register Rd of register file,
		--0110 read in DT
		--0111 for shift in DT
		--1000 for DP and (read rd in case of store)
		--1001 DT-5
		--1010 DT-6
		--0000 fetch
		
		-- branch
		-- 1011 and 1100 bl
		-- 1101 add offset to pc
		
		-- multiply
		-- 1110 read rn rs
		-- 1111 read rm if mla and perform multiplication
		-- 10000 perform addition if mla (conditional)
		-- 10001 write result into rd
		
		with state select PW <=
								'1' when "00000", -- fetch
								'1' when "01100", 
								'1' when "01101";
								 
		with state select IW <=
								'1' when "",
		with state select DW <=
								'1' when state="01001" and sub_class='1',
		 Asrc1 <=
								"01" when state = "00100" else
								"01" when state = "01000" else
								"00" when state = "00000" else
								"00" when state = "01100" else
								"00" when state = "01101" else
								"10" when state = "10000";
								
								
		
		Asrc2 <=				
								"001" when state = "00000" else
								"001" when state = "01100" else
								"100" when state = "00100" else
								"010" when state = "01000" and variant="00" else
								"100" when state = "01000" and variant="01" else
								"011" when state = "01101" else
								"000" when state = "10000";
								
		with state select iord <=
								"01" when state="01001" and pre_increment='1' else
								"10" when state="01001" and pre_increment='0' else
								;
		with state select Rew <=
								"01" when "10000",
								"10" when "1111";
		M2R <=
								"00" when state="01001" and write_back='1' else
								"01" when state="01010" and sub_class='1' else
								"10" when state="01011" else
								"00" when state="10001";
		 AW <=
								'1' when state = "00001" else 
								'1' when state = "00110" else
								'0' when state = "01000" else
								'1' when state = "01110"
								;
		 BW <=
								'1' when state = "00001" or state="01000" else 
								'0' when (state = "00110" and variant="00") else
								'1' when (state = "00110" and variant="01") else
								'1' when state = "01110" else
								'1' when state = "01111" and ins(21)='1';
		 XW <=
		
						'1' when state = "00010" else
						;
		RWA  <=
					"00" when state= "00101" and not(sub_class="10") else
					"01" when state="01001" and write_back='1' else
					"00" when state="01010" and sub_class='1' else
					"10" when state="01011" else
					"01" when state="10001";
		
		Rsrc1 <= '1' when state="01110" else
				 '0';
		Rsrc <=
					"10" when state="00010" else
					"00" when state="00110" else 
					"01" when state="01000" and sub_class='0' else
					"01" when state="01110" else
					"00" when state="01111" and ins(21)='1';
					
		Fset <=
								'1' when state = "00100" and ins(20)='1' and p ='1';
		Ssrc1 <=
								"00" when state="00011" and variant = "00" else
								"01" when state="00011" and variant = "01" else
								"10" when state="00011" and variant = "10" else
								"01" when state ="00111" and variant = "01" else       ---imm_reg
								"00" when state ="00111" and variant = "00"            ---imm_imm
								;
		ReW <= 		"01" when state="01000" or state="00100" else
					;
		MR <= 	'1' when state="01001" and sub_class='1' else
				;
		MW <= 	'1' when state="01001" and sub_class='0' else
				;
		RW <=	'1' when state="01001" and write_back='1' else
				'1' when state="01010" and sub_class='1' else
				'1' when state="01011" else
				'1' when state="10001";
				
		op <= 	"0100" when state="00000" else
				ins(24 downto 21) when state="00100" else
				"0100" when state="01000" and ins(23) = '1' else
				"0010" when state="01000" and ins(23) = '0' else
				"0100" when state="01100" else
				"0100" when state="01101" else
				"0100" when state="10000";
								
		MOW <= '1' when state="01111" else
			   '0';
		---- sequential part
		process(clk)
			if(clk='1' and clock'event) then
				---here come the states (from slide 30-33 of lec 12)
				case state is

					-- fetch
					when "0000" =>
						--transitions
						if(class = "DP")
							state <= "00001" --rdAB
						elsif(class = "DT")
							state <= "00110" --rdAB
						elsif(class = "Branch" and sub_class="branch_link")
							state <= "01011";
						elsif(class = "Branch")
							state <= "01101";
						elsif(class = "mul")
							state <= "01110";
						end if;
					-------
					-- rdAB
					when "0001" =>
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
							---transitions
								if(ins(27 downto 26) = "00") then
									state<= "0011"; --wrRF
								end if;
								
						---wrRF
					when "0011" =>
							---transitions 
							if(ins(27 downto 26) = "00") then
								state <= "0000";
							end if;
						---addr
					when  "0100" =>
							---transitions
							if(ins(27 downto 26) = "01" and ins(20) = '0' ) then
								state <= "0101" ; ---wrM
							elsif (ins(27 downto 26) = "01" and ins(20) = '1' ) then
								state<= "0111"; ----rdM
							end if;
						----wrM
					when "0101" =>
							----transitions
								if(ins(27 downto 26) = "01" and ins(20) = '0' ) then
									state<="0000";
								end if;
						----rdM
					when "0110" => 
							-----transitions
								if(ins(27 downto 26) = "01" and ins(20) = '1' ) then
									state<="0111";
								end if;
						---M2RF	
					when "0111" =>			
						----transitions
							if(ins(27 downto 26) = "01" and ins(20) = '1' ) then
								state<="0000";
							end if;
						----brn
					when "1000" => 
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
signal class1 : std_logic_vector(1 downto 0); 

begin
class1<="00" when ( ins(27 downto 26) = "00" and  (ins(25) or (ins(25)= '0' and (ins(4)='0' or (ins(7)='0' and ins(4)='1'))))) else
		"01" when ( ins(27 downto 23) = "00000" and ins(7 downto 4)="1001") else 
		"10" when (ins(27 downto 26) = "01" or (ins(27 downto 26)="00" and ins(11 downto 7)="00001" and ins(4)='1' and not(ins(6 downto 5)="00"))) else
		"11" when ins(27 downto 26) = "10";
class <= class1;

--load store branch_link
--write_back pre_increment

sub_class <= ins(20);

complete_sub_class <=   "000" when ins(27 downto 26)="01" and ins(20)='1' and ins(22)='0' else
						"001" when ins(27 downto 26)="01" and ins(20)='0' and ins(22)='0' else
						"100" when ins(27 downto 26)="01" and ins(20)='1' and ins(22)='1' else
						"101" when ins(27 downto 26)="01" and ins(20)='0' and ins(22)='1' else
						"010" when ins(27 downto 26)="00" and ins(20)='1' and class1="01" else
						"011" when ins(27 downto 26)="00" and ins(20)='0' and class1="01" else

variant <=  "00" when ins(27 downto 26) = "00" and (ins(25)='1' or (class1="01" and ins(22)='1')) else
			"00" when ins(27 downto 25) = "010" else
			"01" when ins(27 downto 25) = "000" and ins(4)='0' else
			"01" when ins(27 downto 25) = "011" else
			"10" when ins(27 downto 25) = "000" and ins(4)='1' and ins(7)='0';
						
end architecture;
