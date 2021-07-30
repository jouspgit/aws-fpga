library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--input and outputs
entity counter_8bits is -- Slave
	generic (
		G_MAX : integer
	);
	port (
		cnt_value	: out unsigned(7 downto 0);
	 	cnt_valid	: out std_logic;
		cnt_enbl	: in std_logic;

		rst			: in std_logic;
		clk			: in std_logic
	);
end entity;

-- actual body
architecture counter_8bits_arch of counter_8bits is
	-- internal signal declaration
	signal cnt_value_o : unsigned(7 downto 0);

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				cnt_value_o <= "00000001";
			elsif (cnt_enbl = '1') and (cnt_value_o < G_MAX) then
				cnt_value_o <= cnt_value_o + 1;
			end if;
		end if;
	end process;

	cnt_value <= cnt_value_o;
	cnt_valid <= not rst;

end architecture;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity algorithm is --Slave
	port(
		-- counter (input)
		cnt_value	: in  unsigned(7 downto 0);
		cnt_ready	: out std_logic;
		cnt_enbl	: in  std_logic;

		-- ding ding bottle (output)
		ddb_value	: out unsigned(7 downto 0);
		ddb_valid	: out std_logic;
		ddb_enbl	: in  std_logic;

		clk			: in std_logic;
		rst			: in std_logic
	);
end entity;

architecture algorithm_arch of algorithm is

-- Functions -------------------------------------------------------------------
function sum_hex( v : unsigned ) return unsigned is
	variable result_v : unsigned(3 downto 0);
begin
	result_v := "0000";
	for i in 0 to v'length/4-1 loop
		result_v := result_v + v((i+1)*4-1 downto i*4);
	end loop;
	return result_v;
end function;

-- Signals ---------------------------------------------------------------------
signal alg_0_in 		: unsigned(7 downto 0);
signal alg_0_enbl		: std_logic;
signal alg_0_ready		: std_logic;

signal alg_0_sum_hex	: unsigned(3 downto 0);
signal alg_0_mult3		: unsigned(9 downto 0);
signal alg_0_quo		: unsigned(3 downto 0);

----

signal alg_1_in 		: unsigned(7 downto 0);
signal alg_1_valid		: std_logic;
signal alg_1_ready		: std_logic;

signal alg_1_sum_hex	: unsigned(3 downto 0);
signal alg_1_quo		: unsigned(3 downto 0);

signal alg_1_rem		: unsigned(7 downto 0);
signal alg_1_conda		: std_logic;
signal alg_1_cond7		: std_logic;

----

signal alg_2_in		: unsigned(7 downto 0);
signal alg_2_valid		: std_logic;
signal alg_2_ready		: std_logic;

signal alg_2_conda		: std_logic;
signal alg_2_cond7		: std_logic;

signal alg_2_out		: unsigned(7 downto 0);

----

signal alg_3_out		: unsigned(7 downto 0);
signal alg_3_valid		: std_logic;
signal alg_3_ready		: std_logic;


begin

-- Counter Interface (cnt) -----------------------------------------------------
cnt_ready <= alg_0_ready;
--------------------------------------------------------------------------------

-- Algorithm (alg) -------------------------------------------------------------
-- This algorithm performs a ding ding bottle on the counter value.
--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--
alg_0_in		<= cnt_value;
alg_0_enbl		<= cnt_enbl;

alg_0_sum_hex	<= sum_hex(alg_0_in);
alg_0_mult3		<= "00"&((alg_0_in sll 2) + alg_0_in);	-- multiply by 3 
alg_0_quo		<= alg_0_mult3(6 downto 3); 			-- shift right by 3
alg_0_ready <= alg_1_ready;	
process (clk)
begin
	if rising_edge(clk) then
		if rst = '1' then
			alg_1_valid <= '0';
		elsif alg_1_ready = '1' then
			alg_1_valid <= alg_0_enbl;
		end if;

		if alg_1_ready = '1' then
			alg_1_in		<= alg_0_in;
			alg_1_sum_hex	<= alg_0_sum_hex;
			alg_1_quo		<= alg_0_quo;
		end if;
		
	end if;
end process;


alg_1_rem		<= alg_1_in(7 downto 0); -- remainder by 256 (in unsigned) : free so no pipeline.

alg_1_conda 	<= '1' when (alg_1_in(3 downto 0) = x"A") or (alg_1_sum_hex = x"A") or (alg_1_rem = x"A") else '0';
alg_1_cond7 	<= '1' when (alg_1_in(3 downto 0) = x"7") or (alg_1_sum_hex = x"7") or (alg_1_quo(3 downto 0)= x"7") else '0';
alg_1_ready <= alg_2_ready;

process (clk)
begin
	if rising_edge(clk) then
		if rst = '1' then
			alg_2_valid <= '0';
		elsif alg_2_ready = '1' then
			alg_2_valid <= alg_1_valid;
		end if;

		if alg_2_ready = '1' then
			alg_2_in		<= alg_1_in;
			alg_2_conda	<= alg_1_conda;
			alg_2_cond7 	<= alg_1_cond7;
		end if;
		
	end if;
end process;


alg_2_out <=
	"10101010" when (    alg_2_conda and not alg_2_cond7) = '1' else
	"00100010" when (not alg_2_conda and     alg_2_cond7) = '1' else
	"11111111" when (    alg_2_conda and     alg_2_cond7) = '1' else
	alg_2_in;

alg_2_ready <= alg_3_ready;
process (clk)
begin
	if rising_edge(clk) then
		if rst = '1' then
			alg_3_valid <= '0';
		elsif alg_3_ready = '1' then
			alg_3_valid <= alg_2_valid;
		end if;

		if alg_3_ready = '1' then
			alg_3_out <= alg_2_out;
		end if;
		
	end if;
end process;

--------------------------------------------------------------------------------

-- Ding Ding Bottle Interface (ddb) --------------------------------------------

ddb_value 	<= alg_3_out;
ddb_valid 	<= alg_3_valid;
alg_3_ready	<= ddb_enbl or not alg_3_valid;
--------------------------------------------------------------------------------

end architecture;
