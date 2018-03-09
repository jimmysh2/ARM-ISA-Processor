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
						PW=>'1';IW=>'1';MR=>1;iord=>0;Asrc1=>0;Asrc2=>1;op=>"opcode for add";
						
						--transitions
						state=>"0001" --rdAB
					-------
					-- rdAB
					when "0001" =>
						--signal values

						--transitions
						if(ins(27 downto 26)="00") then
							state=>"0010"; --arith
						elsif(ins(27 downto 26)="01") then
							state=>"0100"; --addr
						elsif(ins(27 downto 26)="10")
							state=>"1000"; --brn
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
		with ins select p =>
					z when "0000",
					not z when "0001",
					c when "0010",
					not c when "0011",
					-- and so on from slide 11-12 of lec 12
		
end architecture;
