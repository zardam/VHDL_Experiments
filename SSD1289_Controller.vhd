library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.std_logic_unsigned.all;


entity SSD1289_Controller is
port(
	-- control
	clk			: in std_logic;
	rst   		: in std_logic;
	x				: in std_logic_vector(7 downto 0);
	y				: in std_logic_vector(8 downto 0);
	r				: in std_logic_vector(4 downto 0);
	g				: in std_logic_vector(5 downto 0);
	b				: in std_logic_vector(4 downto 0);
	enable		: in std_logic;
	busy			: out std_logic;

	-- lcd interface
	lcd_data			: out std_logic_vector(15 downto 0);
	lcd_dc			: out std_logic;
	lcd_rd			: out std_logic;
	lcd_wr			: out std_logic;
	lcd_cs			: out std_logic;
	lcd_rst			: out std_logic
	);
end SSD1289_Controller;

architecture Controller of SSD1289_Controller is
  type control is(reset, init, ready, send);
  signal    state      : control;
  constant  freq       : integer := 50; --system clock frequency in MHz
  
  	type initDataArray is array (0 to 81) of std_logic_vector(16 downto 0);
	constant initData : initDataArray := (
      '0' & x"0000", '1' & x"0001",
		'0' & x"0003", '1' & x"A8A4",
      '0' & x"000C", '1' & x"0000",
		'0' & x"000D", '1' & x"080C",
		'0' & x"000E", '1' & x"2B00",
		'0' & x"001E", '1' & x"00B7",
		'0' & x"0001", '1' & x"2B3F",
		'0' & x"0002", '1' & x"0600",
		'0' & x"0010", '1' & x"0000",
		'0' & x"0011", '1' & x"6070",
		'0' & x"0005", '1' & x"0000",
		'0' & x"0006", '1' & x"0000",
		'0' & x"0016", '1' & x"EF1C",
		'0' & x"0017", '1' & x"0003",
		'0' & x"0007", '1' & x"0233",
		'0' & x"000B", '1' & x"0000",
		'0' & x"000F", '1' & x"0000",
		'0' & x"0041", '1' & x"0000",
		'0' & x"0042", '1' & x"0000",
		'0' & x"0048", '1' & x"0000",
		'0' & x"0049", '1' & x"013F",
		'0' & x"004A", '1' & x"0000",
		'0' & x"004B", '1' & x"0000",
		'0' & x"0044", '1' & x"EF00",
		'0' & x"0045", '1' & x"0000",
		'0' & x"0046", '1' & x"013F",
		'0' & x"0030", '1' & x"0707",
		'0' & x"0031", '1' & x"0204",
		'0' & x"0032", '1' & x"0204",
		'0' & x"0033", '1' & x"0502",
		'0' & x"0034", '1' & x"0507",
		'0' & x"0035", '1' & x"0204",
		'0' & x"0036", '1' & x"0204",
		'0' & x"0037", '1' & x"0502",
		'0' & x"003A", '1' & x"0302",
		'0' & x"003B", '1' & x"0302",
		'0' & x"0023", '1' & x"0000",
		'0' & x"0024", '1' & x"0000",
		'0' & x"0025", '1' & x"8000",
		'0' & x"004f", '1' & x"0000",
		'0' & x"004e", '1' & x"0000"
		);
begin
  process(clk)
    variable clk_count : integer := 0;
  begin
  if rising_edge(clk) then
      case state is
        
		  when reset =>
          busy <= '1';
          if(clk_count < 5) then    -- (50000 * freq)) then    --wait 50 ms
            clk_count := clk_count + 1;
				lcd_rst <= '0';
            state <= reset;
          else                                   --power-up complete
            clk_count := 0;
				lcd_rst <= '1';
				lcd_rd <= '1';
				lcd_wr <= '1';
				lcd_cs <= '1';
            state <= init;
          end if;
          
        WHEN init =>
			busy <= '1';
			if (clk_count mod 2) = 0  then
				--busy <= '0';
				lcd_wr <= '0';
				lcd_cs <= '0';
				lcd_dc <= initData(clk_count/2)(16);
				lcd_data <= initData(clk_count/2)(15 downto 0);
			else
				--busy <= '1';
				lcd_wr <= '1';
			end if;	
			clk_count := clk_count + 1;
			if clk_count < 82*2 then
				state <= init;			
			else
				clk_count := 0;
				state <= ready;			
			end if;
			
        --wait for the enable signal and then latch in the instruction
        WHEN ready =>
			clk_count := 0;
          IF(enable = '1') THEN
            busy <= '1';
            state <= send;
          ELSE
				lcd_wr <= '1';
				lcd_cs <= '1';
				lcd_dc <= '1';
            busy <= '0';
            state <= ready;
          END IF;
        
        --send instruction to lcd        
        WHEN send =>
			busy <= '1';
			case clk_count is
				when 0 =>
					lcd_cs <= '0';
					lcd_dc <= '0';
					lcd_wr <= '0';
					lcd_data <= x"004e";
				when 1 =>
					lcd_wr <= '1';
				when 2 =>
					lcd_dc <= '1';
					lcd_wr <= '0';
					lcd_data <= "00000000" & x;
				when 3 =>
					lcd_wr <= '1';
				when 4 =>
					lcd_dc <= '0';
					lcd_wr <= '0';
					lcd_data <= x"004f";
				when 5 =>
					lcd_wr <= '1';
				when 6 =>
					lcd_dc <= '1';
					lcd_wr <= '0';
					lcd_data <= "0000000" & y;
				when 7 =>
					lcd_wr <= '1';
				when 8 =>
					lcd_dc <= '0';
					lcd_wr <= '0';
					lcd_data <= x"0022";
				when 9 =>
					lcd_wr <= '1';
				when 10 =>
					lcd_dc <= '1';
					lcd_wr <= '0';
					-- green & blue
					lcd_data <= r & g & b;
				when 11 =>
					lcd_wr <= '1';
				when others =>
					busy <= '0';
					state <= ready;
			end case;
			clk_count := clk_count + 1;
      END CASE;    
    
      --reset
      IF rst = '0'  THEN
          state <= reset;
      END IF;
    
    END IF;
  END PROCESS;
end Controller;
