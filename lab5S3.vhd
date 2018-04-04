----- DATAPATH
library ieee;
use ieee.std_logic_1164.all;
entity datapath is 
port (	
		clk : in std_logic;
		PW,iord,MR,MW,IW,DW,Rsrc,M2R,RW,AW,BW,Asrc1,Fset,Rew, reset_rf : in std_logic ;
		Asrc2 : in std_logic_vector(1 downto 0);
		op : in std_logic_vector(3 downto 0)
		);
end entity;
---------------
-- **** Component Entities ****

---- ALU 
library ieee;
use ieee.std_logic_1164.all;
entity alu is
	port(a,b:in std_logic_vector(31 downto 0);
		opcode: in std_logic_vector(3 downto 0);
		carry: in std_logic; ans:out std_logic_vector(31 downto 0);
		c,n,z,v:out std_logic);
end entity;
----------
------ SHIFTER
library ieee;
use ieee.std_logic_1164.all;
entity shifter is
	port(a:in std_logic_vector(31 downto 0);
		opcode: in std_logic_vector(1 downto 0);
		amount:in std_logic_vector(4 downto 0)
		ans:out std_logic_vector(31 downto 0);
		carry: out std_logic);
end entity;
---------
------ MULTIPLIER
entity multiplier is 
port ( a,b:in std_logic_vector(31 downto 0);
		c:out std_logic_vector(31 downto 0));
end entity;
---------
-------REGISTER FILE 	
library ieee;
use	ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;	
use ieee.numeric_std.all; -- for to_integer
entity Register_file is 
port( written_data : in std_logic_vector(31 downto 0);
	  read_address_1,read_address_2:in std_logic_vector(3 downto 0);
	  write_address: in std_logic_vector(3 downto 0);
	  clk,reset,write_enable: in std_logic;
	  out_data_1,out_data_2: out std_logic_vector(31 downto 0);
	  PC_output:out std_logic_vector(31 downto 0)); 
end entity;
-----
------- MEMORY	
library ieee;
use	ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;	
use ieee.numeric_std.all; -- for to_integer
entity memory is 
port( 
	  address : in std_logic_vector(17 downto 0);
	  write_data : in std_logic_vector(31 downto 0);
	  clk,write_enable,read_enable: in std_logic;
	  read_data : out std_logic_vector(31 downto 0)); 
end entity;
-----
------processor- memory path 
library ieee;
use ieee.std_logic_1164.all;
entity pm_path is 
port ( from_processor : in std_logic_vector(31 downto 0);
	   from_memory : in std_logic_vector(31 downto 0);
	   dt_type : in std_logic_vector( 5 downto 0 );  -- as given in slides opc is 6 bit;
	   byte_offset: in  std_logic_vector( 1 downto 0 );
	   to_processor : out std_logic_vector(31 downto 0);
	   to_memory : out std_logic_vector(31 downto 0);
	   write_enable : out std_logic_vector(3 downto 0));
end entity;

----------------------
-------------**************----------------

-- ****************** START OF ARCHITECTURE ********************

---------- ALU architecture
architecture behav of alu is
	signal s : std_logic_vector(31 downto 0);
	signal c31,c32 : std_logic;
	begin
		with opcode select s <= 
			-- LOGICAL
				a and b when "0000",
				a or b when "1100",
				a xor b when "0001",
				a and not b when "1110",
			-- ARITHMETIC
				a + b when "0100",
				a - b when "0010",
				b - a  when "0011",
				a + b + carry when "0101",
				a - b - carry when "0110",
				b - a - carry when "0111";
		ans<= s;
		-- FLAGS
		c31 <= a(31) xor b(31) xor s(31);
		c32 <= (a(31) and b(31)) or (a(31) and c(31)) or (b(31) and c(31));
		
		z <= '0' when s = 0 else '1';
		n <= s(31);
		v <= c31 xor c32;
		c <= c32;	

end architecture;

------------ SHIFTER 
architecture behav of shifter is
	signal zero : std_logic_vector(31 downto 0) := 0;
	signal one : std_logic_vector(31 downto 0) := "11111111111111111111111111111111";
	signal rotated: std_logic_vector(31 downto 0);
	begin
		ans <= 
			a when amount=0 else 
			a((31-amount) downto 0) & zero(amount-1 downto 0) when opcode = "00" else
			zero(amount-1 downto 0) & a(31 downto amount) when opcode = "01" else
			zero(amount-1 downto 0) & a(31 downto amount) when opcode = "10" and a(31)='0' else
			one(amount-1 downto 0) & a(31 downto amount) when opcode = "10" and a(31)='1' else
			rotated when opcode = "11";
		for i in 0 to 31 generate
			rotated(i) <= a((32+i-amount) mod 32);
		end generate;
		-----
		carry <= 
			'0' when amount=0 else 
			a(32-amount) when opcode = "00" else
			a(amount-1) when opcode = "01" or opcode = "10" or opcode="11"; 
			---- not confirm for carry in ROR
end architecture;

-----------MULTIPLIER
architecture behav of multiplier is 
	begin
	   c <= (a * b );
end architecture;

------------ REGISTER-FILE   
architecture behav of Register_file is 

	signal program_counter : std_logic_vector (31 downto 0);
	signal reg_array: array (0 to 15) of std_logic_vector(31 downto 0);
	begin 
		program_counter <= reg_array(15);
		PC_output <= program_counter;
		out_data_1 <=  reg_array(to_integer(unsigned(read_address_1)));
		out_data_2 <=  reg_array(to_integer(unsigned(read_address_2)));
		process(clk)
			if(clk = '1' and clk'event ) then
				if ( write_enable = '1' ) then 
					reg_array(to_integer(unsigned(write_address))) <= written_data ; --(I'm relying on your to_integer fn)
				end if ;

				if (reset = '1' )then 
					reg_array <= 0 ;
				end if ;
			end if ;
		end process;
end architecture;
-----------------
------------ MEMORY
architecture behav of memory is
	signal memory : array (0 to 2^32-1) of std_logic_vector(31 downto 0);
	begin
		process(clk)
			if(clk = '1' and clk'event) then
				if ( write_enable = '1' ) then 
					memory(to_integer(unsigned(address))) <= write_data; --(I'm relying on your to_integer fn)

				elsif (read_enable = '1') then 
					read_data <= memory(to_integer(unsigned(address)));
				end if ;
			end if ;
		end process;
end architecture;
-----------
------------ PROCESSOR MEMORY PATH
architecture behav of pm_path is
	signal amount : integer = 0; 
	begin
		to_processor <= -------!!!!!!! correct the dt_type values below !!!!!!
						from_memory when dt_type = "ldr" else -- ldr ----these dt_type or opcode is of no use below this line because as assumption we have to take care of only word not byte...
						
						"0000000000000000" & from_memory(15 downto 0) when dt_type = "ldrh" and byte_offset(1)="0" else -- ldrh
						from_memory(15 downto 0) & "0000000000000000" when dt_type = "ldrh" and byte_offset(1)="1" else
						
						"000000000000000000000000" & from_memory(7 downto 0) when dt_type = "ldrb" and byte_offset="00" else --ldrb
						"0000000000000000" & from_memory(15 downto 8) & "00000000" when dt_type = "ldrb" and byte_offset="01" else
						"00000000" & from_memory(23 downto 16) & "0000000000000000" when dt_type = "ldrb" and byte_offset="10" else
						from_memory(31 downto 24) & "000000000000000000000000" when dt_type = "ldrb" and byte_offset="11" else
						
						"0000000000000000" & from_memory(15 downto 0) when dt_type = "ldrsh" and from_memory(15)='0' and byte_offset(1)="0" else -- ldrsh
						"1111111111111111" & from_memory(15 downto 0) when dt_type = "ldrsh" and from_memory(15)='1' and byte_offset(1)="0" else
						from_memory(31 downto 16) & "0000000000000000" when dt_type = "ldrsh" and from_memory(31)='0' and byte_offset(1)="1" else
						from_memory(31 downto 16) & "1111111111111111" when dt_type = "ldrsh" and from_memory(31)='1' and byte_offset(1)="1" else
						
						"000000000000000000000000" & from_memory(7 downto 0) when dt_type = "ldrsb" and from_memory(7) = '0' and byte_offset="00" else --ldrsb
						"111111111111111111111111" & from_memory(7 downto 0) when dt_type = "ldrsb" and from_memory(7) = '1' and byte_offset="00" else
						"0000000000000000" & from_memory(15 downto 8) & "00000000" when dt_type = "ldrsb" and from_memory(15) = '0' and byte_offset="01" else
						"1111111111111111" & from_memory(15 downto 8) & "11111111" when dt_type = "ldrsb" and from_memory(15) = '1' and byte_offset="01" else
						"00000000" & from_memory(23 downto 16) & "0000000000000000" when dt_type = "ldrsb" and from_memory(23) = '0' and byte_offset="10" else
						"11111111" & from_memory(23 downto 16) & "1111111111111111" when dt_type = "ldrsb" and from_memory(23) = '1' and byte_offset="10" else
						from_memory(31 downto 24) & "000000000000000000000000" when dt_type = "ldrsb" and from_memory(31) = '0' and byte_offset="11" else
						from_memory(31 downto 24) & "111111111111111111111111" when dt_type = "ldrsb" and from_memory(31) = '1' and byte_offset="11";
		
		
		to_memory <= 
						from_processor when dt_type = "str" else --str
						from_processor(15 downto 0) & from_processor(15 downto 0) when dt_type = "strh" else -- strh
						from_processor(7 downto 0) & from_processor(7 downto 0) & from_processor(7 downto 0) & from_processor(7 downto 0) when dt_type = "strb"; --strb
						
		write_enable <= "1111" when dt_type = "str" else
						"0011" when dt_type = "strh" and byte_offset(1)="0" else ---strh
						"1100" when dt_type = "strh" and byte_offset(1)="1" else
						"0001" when dt_type = "strb" and byte_offset="00" else ---strb
						"0010" when dt_type = "strb" byte_offset="01" else
						"0100" when dt_type = "strb" byte_offset="10" else
						"1000" when dt_type = "strb" byte_offset="11";
end architecture;	
-----------------
--******* MAIN ARCH. OF DATAPATH ******** --
architecture behav of datapath is 

component alu
port(a,b:in std_logic_vector(31 downto 0);
		opcode: in std_logic_vector(3 downto 0);
		carry: in std_logic; ans:out std_logic_vector(31 downto 0);
		c,n,z,v:out std_logic);
end component;

component Register_file 
port( written_data : in std_logic_vector(31 downto 0);
	  read_address_1,read_address_2:in std_logic_vector(3 downto 0);
	  write_address: in std_logic_vector(3 downto 0);
	  clk,reset,write_enable: in std_logic;
	  out_data_1,out_data_2: out std_logic_vector(31 downto 0);
	  PC_output:out std_logic_vector(31 downto 0));
end component;

component memory
port( address:in std_logic_vector(3 downto 0);
	  write_data : in std_logic_vector(31 downto 0);
	  clk,write_enable,read_enable: in std_logic;
	  read_data : out std_logic_vector(31 downto 0));
end component;

component pm_path 
port ( from_processor : in std_logic_vector(31 downto 0);
	   from_memory : in std_logic_vector(31 downto 0);
	   dt_type : in std_logic_vector( 5 downto 0 );  -- as given in slides opc is 6 bit;
	   byte_offset: in  std_logic_vector( 1 downto 0 );
	   to_processor : out std_logic_vector(31 downto 0);
	   to_memory : out std_logic_vector(31 downto 0);
	   write_enable : out std_logic_vector(3 downto 0));
end component;

component shifter
port(	a:in std_logic_vector(31 downto 0);
		opcode: in std_logic_vector(1 downto 0);
		amount:in std_logic_vector(4 downto 0)
		ans:out std_logic_vector(31 downto 0);
		carry: out std_logic);
end component;

component multiplier
port ( a,b:in std_logic_vector(31 downto 0);
		c:out std_logic_vector(31 downto 0));
end component;

signal register_read_2 : std_logic_vector(3 downto 0);
signal DR,RES,WD,RD1,RD2,alu_op1,alu_op2,alu_ans,A,B,D,X,EX,S2,PC, mul_input1,mul_input2,mul_output: std_logic_vector(31 downto 0);
signal c_original,c_new,n,z,v,n_original,v_original,z_original : std_logic;
signal memory_ad,memory_wd,memory_rd, waste_pc : std_logic_vector(31 downto 0);
signal shift_amount : std_logic_vector(4 downto 0);
begin
	u1: alu
	port map 
	(
		a => alu_op1 ,
		b => alu_op2 ,
		opcode => op ,
		carry => c_original , -- i don't know what to write in carry
		ans => alu_ans ,
		c => c_new,
		n => n,
		z => z ,
		v => v 	
	);
	u2 : Register_file 
	port map 
	(	
		read_address_1 => ins(19 downto 16),
		read_address_2 => register_read_2,
		write_address => register_write,
		written_data => WD,
		out_data_1 => RD1,
		out_data_2 => RD2,
		clk => clk,
		reset => reset_rf,
		write_enable =>  RW , 
		PC_output => waste_pc
	);
	u3 : memory
	port map 
	(	
		address => memory_ad,
		write_data => memory_wd,
		read_data=> memory_rd,
		clk => clk,
		write_enable =>  MW,
		read_enable => MR
	);
	u4: pm_path
	 port map (
				dt_type => opcode_pm_path,
				from_processor => for_from_processor,
				from_memory =>for_from_memory,
				byte_offset => 0,
				to_processor => for_to_processor,
				to_memory => for_to_memory,
				write_enable => for_write_enable
				);
	u5: shifter
	port map (
			a => shift_input,
			opcode => ins(6 downto 5),
			amount => shift_amount,
			ans => D
			--carry: out std_logic
			);
	u6: multiplier		
	port map( 
			a => mul_input1,
			b => mul_input2,
			c => mul_output
			);
				
	PC <= alu_ans when PW = '1';
	-----memory signals
	memory_ad <=  pc  when iord = "00" else
				  RES when iord = "01" else
				  A ; -- this is for post increment
	memory_wd <= B;
	ins <= memory_rd when IW = '1' ;
	DR <= memory_rd when DW = '1';
	---
	
	---- alu operands
	alu_op1 <= pc when Asrc1 = '0' else
				A;
	
	alu_op2 <= B when Asrc2 = "000" else
			   "0000000000000000000000000000000100" when Asrc2 = "001" else
			  EX when Asrc2 = "010" else
			  S2 when Asrc2 = "011" else
			  D when Asrc2 = "100" ;
	------------
	EX <= "00000000000000000000" & ins(11 downto 0);
	S2 <= "000000" & ins(23 downto 0) & "00" when ins(23)="0" else
		  "111111" & ins(23 downto 0) & "00";'
	-------
	RES <= alu_ans when ReW = "01" else
		   mul_output when ReW = "10";
	S2 <= "00000000" & ins(23 downto 0);
	EX <= "0000000000000000000000" & ins(11 downto 0);
	
	--- register signals
	WD <= DR when M2R = '1' else
			RES;
	A <= RD1 when AW = '1' ;
	B <= RD2 when BW ='1' ;
	X <= RD2 when XW ='1' ;
	
	register_read_2 <= ins(3 downto 0) when Rsrc = "00" else
					   ins(15 downto 12) when Rsrc = "01" else
					   ins(11 downto 8) when Rsrc = "10";
	register_write <= ins(15 downto 12) when RWA = '0' else
					  ins(19 downto 16);
	-- flags
	c_original <= c_new when Fset = '1' ;
	v_original <= v when Fset = '1' ;
	z_original <= z when Fset = '1' ;
	n_original <= n when Fset = '1' ;
	
	---- shifter signals
	shift_amount<= 
				   '0' & ins (11 downto 8) when Ssrc1 = "00" else
				   ins(11 downto 7) when Ssrc1 = "01" else
				   X(4 downto 0) when Ssrc1 = "10" ; ---because we support only shift upto 31
	
	shift_input <= 	
				"000000000000000000000000" & ins(7 downto 0) when Ssrc1 = "00" else
				B when Ssrc1 = "01" or Ssrc1 = "10" ;
	
	--- multiplier signals
	mul_input1 <= A;
	mul_input2 <= D;
				

end architecture;
-------------------------------