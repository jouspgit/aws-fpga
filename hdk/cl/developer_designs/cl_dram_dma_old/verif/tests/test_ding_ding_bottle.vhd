
-- Testbenches

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity counter_tb is -- counter alone
end entity;

architecture counter_tb_arch of counter_tb is

	-- Component Declaration
	component counter_8bits
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
	end component;

	-- Signals Declaration
	signal clk_tb 		: std_logic; 
	signal rst_tb 		: std_logic;
	signal valid_tb 	: std_logic;
	signal enbl_tb 		: std_logic;
	signal value_tb 	: unsigned(7 downto 0);


	begin
		--DUT Instantiation
		DUT : counter_8bits
			generic map (
				G_MAX => 256
			)
			port map( 
				clk 	=> clk_tb,
				rst 	=> rst_tb,
				cnt_valid 	=> valid_tb,
				cnt_enbl	=> enbl_tb,
				cnt_value 	=> value_tb
			);

		-- Clock Generation
		CLOCK : process
		begin
			clk_tb <= '1';
      		wait for 5 ns;
	     	clk_tb <= '0';
      		wait for 5 ns;
		end process;

		-- Stimulus Generation
		STIMULUS : process
		begin
			rst_tb <= '1';
			wait for 30 ns;
			rst_tb <='0';
			enbl_tb <= '1';
			wait for 400 ns;
			rst_tb <= '1';
			wait for 10 ns;
			rst_tb <= '0';
			wait;
		end process;

end architecture;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity algorithm_tb is
end entity;

architecture algorithm_tb_arch of algorithm_tb is

	component counter_8bits
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
	end component;

	component algorithm
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
	end component;

	-- Signals Declaration
	signal clk_tb 		: std_logic; 
	signal rst_tb 		: std_logic; 

	signal cnt_valid_tb : std_logic;
	signal ddb_valid_tb : std_logic;
	signal ready_tb 	: std_logic;
	signal enbl_tb 		: std_logic;

	signal cnt_tb 		: unsigned(7 downto 0);
	signal ddb_value_tb	: unsigned(7 downto 0);
	signal enbl_user_tb : std_logic;	


	begin

		-- Sync Signals Connection
		enbl_tb <= '1' when cnt_valid_tb ='1' and ready_tb ='1' else '0';

		--DUT Instantiation
		DUT1 : counter_8bits
			generic map (
				G_MAX => 256
			)
			port map( 
				clk 		=> clk_tb,
				rst 		=> rst_tb,
				cnt_valid 	=> cnt_valid_tb,
				cnt_enbl 	=> enbl_tb,
				cnt_value 	=> cnt_tb
			);

		DUT2 : algorithm
			port map( 
				clk 		=> clk_tb,
				rst 		=> rst_tb,
				cnt_value 	=> cnt_tb,
				cnt_ready	=> ready_tb,
				cnt_enbl 	=> enbl_tb,
				ddb_enbl	=> enbl_user_tb, -- user enables with this 
				ddb_valid	=> ddb_valid_tb,
				ddb_value 	=> ddb_value_tb);


		-- Clock Generation
		CLOCK : process
		begin	
			
			clk_tb <= '1';
  			wait for 5 ns;
     		clk_tb <= '0';
  			wait for 5 ns;
			
		end process;

		-- Stimulus Generation
		STIMULUS : process
		begin
			rst_tb 			<='1';
			wait for 30 ns;			-- 30ns of reset time (init)
			rst_tb 			<='0';
			enbl_user_tb 	<='1';
			wait for 200 ns; 		-- 200ns of normal execution
			rst_tb 			<='1';
			wait for 50 ns;  		-- 50ns of additional reset time
			rst_tb 			<='0';
			wait for 350 ns;		-- 350ns of normal execution
			enbl_user_tb 	<='0';
			wait for 50 ns;			-- 50ns of user disable
			enbl_user_tb 	<='1';
			wait;					-- continue ad infinitum
		end process;


end architecture;
