LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY CPLD_TK_Pie IS

PORT 
(
	
	BUS_A			: in     std_logic_vector(15 downto 0);
	BUS_D			: inout  std_logic_vector(7 downto 0) := (others => 'Z');
	BUS_MRQ		: in     std_logic;
	BUS_IORQ		: in     std_logic;
	BUS_RD		: in     std_logic;
	BUS_WR		: in     std_logic;
	
	BUS_RESET	: in     std_logic;
	
	BUS_ROMCS	: out    std_logic := 'Z';

	GPIO			: inout  std_logic_vector(23 downto 0) := (others => 'Z');
	
	GPIO_24		: out std_logic;
	GPIO_25		: out std_logic;
	GPIO_26		: out std_logic;
	GPIO_27		: out std_logic
						
);
END CPLD_TK_Pie;
--------------------------------------
ARCHITECTURE dataflow OF CPLD_TK_Pie IS

signal border			: std_logic;
signal vram				: std_logic;
signal port_BF3B		: std_logic;
signal port_FF3B		: std_logic;
signal port_7FFD			: std_logic;
signal reg_7ffd  			: std_logic_vector (7 downto 0) := (others=>'0');

signal write_to_shadow	: std_logic;
signal write_to_default	: std_logic;

-- latchs
signal latch 			: std_logic;
signal latch_a 		: std_logic_vector(15 downto 0);
signal latch_d 		: std_logic_vector(7 downto 0);



BEGIN

	-- ULAplus
	port_BF3B <= '0' when BUS_IORQ = '0' and BUS_WR = '0' and BUS_A(15 downto 14) = "10"  and BUS_A(7 downto 6) = "00"  and BUS_A(2) = '0' and BUS_A(0) ='1' else '1';
	port_FF3B <= '0' when BUS_IORQ = '0' and BUS_WR = '0' and BUS_A(15 downto 14) = "11"  and BUS_A(7 downto 6) = "00"  and BUS_A(2) = '0' and BUS_A(0) ='1' else '1';
	
	-- border
	border <= '0' when BUS_IORQ = '0'  and BUS_WR = '0' and BUS_A(0) = '0' else '1';
	-- listen port 0x7ffd
	port_7FFD <= '0' when BUS_IORQ = '0' and BUS_WR = '0' and BUS_A(15 downto 14) = "01"  and BUS_A(1 downto 0) = "01" else '1';
	
	-- get the reg_7ffd bits
	-- bit 5 = '1' - page disabled and write to port 7ffd ignored until next reset
	-- bit 3 = '0' - show normal screen
	-- bit 3 = '1' - show shadow screen from c000-ffff (page 7)
	-- bts 2-0 = "111" is shadow screen paged in c000
	reg_7ffd <= BUS_D when port_7FFD = '0';-- else (others=>'0') when BUS_RESET = '0';
	
	

	-- listen video area
	write_to_default <= '1' when BUS_MRQ = '0' and BUS_WR = '0' and BUS_A(15 downto 13) = "010" else '0';
	write_to_shadow  <= '1' when BUS_MRQ = '0' and BUS_WR = '0' and BUS_A(15 downto 13) = "110" and reg_7ffd(2 downto 0) = "111" else '0';
	vram <= '0' when write_to_default = '1' or write_to_shadow = '1' else '1';

	-- latchs
	latch <= '1' when border = '0' or vram = '0' or port_BF3B = '0' or port_FF3B = '0' else '0';

	process (latch)
	begin
		if rising_edge (latch) then
				latch_d <= BUS_D;
	
				if write_to_shadow = '1' then
					latch_a <=  '0' & reg_7ffd(3) & '1' & BUS_A(12 downto 0);
				else 
					latch_a <=  '0' & reg_7ffd(3) & '0' & BUS_A(12 downto 0);	
				end if;
			end if;
	end process;

	-- Latch for video
	GPIO(7 downto 0)  <= latch_d;
	GPIO(23 downto 8) <= latch_a;
	
	GPIO_24 <= vram;
	GPIO_25 <= border;
	GPIO_26 <= port_BF3B;
	GPIO_27 <= port_FF3B;
	
END dataflow;