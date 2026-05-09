library ieee;
use ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.all;

entity de10_lite_adc is
    port (clk : in std_logic;
          reset_n : in std_logic;
          sw : in std_logic_vector(4 downto 0);
          ready : out std_logic;
          command_ready          : out std_logic; 
          response_channel       : out std_logic_vector(4 downto 0); 
          response_data          : buffer std_logic_vector(11 downto 0);
          response_startofpacket : out std_logic;  
          response_endofpacket   : out std_logic;
          reg_data               : buffer std_logic_vector(11 downto 0);
          hex0                   : out std_logic_vector(6 downto 0);
          hex1                   : out std_logic_vector(6 downto 0);
          hex2                   : out std_logic_vector(6 downto 0)
         );
end entity;

architecture struct of de10_lite_adc is
component adc is
	port (
		adc_pll_clock_clk      : in  std_logic                     := '0';             --  adc_pll_clock.clk
		adc_pll_locked_export  : in  std_logic                     := '0';             -- adc_pll_locked.export
		clock_clk              : in  std_logic                     := '0';             --          clock.clk
		command_valid          : in  std_logic                     := '0';             --        command.valid
		command_channel        : in  std_logic_vector(4 downto 0)  := (others => '0'); --               .channel
		command_startofpacket  : in  std_logic                     := '0';             --               .startofpacket
		command_endofpacket    : in  std_logic                     := '0';             --               .endofpacket
		command_ready          : out std_logic;                                        --               .ready
		reset_sink_reset_n     : in  std_logic                     := '0';             --     reset_sink.reset_n
		response_valid         : out std_logic;                                        --       response.valid
		response_channel       : out std_logic_vector(4 downto 0);                     --               .channel
		response_data          : out std_logic_vector(11 downto 0);                    --               .data
		response_startofpacket : out std_logic;                                        --               .startofpacket
		response_endofpacket   : out std_logic                                         --               .endofpacket
	);
end component adc;
component pll IS
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC ;
		c1		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
END component pll;

component seg7 is
    port (
        iDIG : in std_logic_vector(3 downto 0);
        oSEG : out std_logic_vector(6 downto 0)
        );
end component seg7;

signal clk50, clk10 : std_logic;
signal resetint, locked : std_logic;
signal response_valid : std_LOGIC;

begin

    resetint <= not reset_n;
    
    
    
    -- The PLL
    pll0: pll
    port map (inclk0 => clk,
              areset => resetint,
              c0 => clk10,
              c1 => clk50,
              locked => locked
             );

    -- The ADC subsystem
    adc0: adc
    port map (
            adc_pll_clock_clk => clk10,                       -- 10 MHz from PLL (c1)
            adc_pll_locked_export => locked,                  -- locked from PLL
            clock_clk => clk50,                               -- 50 MHz from PLL (c0)
            command_valid => '1',                             -- always valid
            command_channel => SW,                            -- channel between 0 and 31
            command_startofpacket => '1',                     -- Always at 1
            command_endofpacket => '1',                       -- Always at 1
            command_ready => command_ready,
            reset_sink_reset_n => reset_n,
            response_valid => response_valid,
            response_channel => response_channel,
            response_data => response_data,
            response_startofpacket => response_startofpacket,
            response_endofpacket => response_endofpacket
           );

    -- Clock in the result
    process (clk) is
    begin
        if rising_edge(clk) then
            if response_valid = '1' then
                reg_data <= response_data;
            end if;
            ready <= response_valid;
        end if;
    end process;
    
    seg70 : seg7
    port map (iDIG => reg_data(3 downto 0),
              oSEG => hex0);
              
    seg71 : seg7
    port map (iDIG => reg_data(7 downto 4),
              oSEG => hex1);

    seg72 : seg7
    port map (iDIG => reg_data(11 downto 8),
              oSEG => hex2);
     
end architecture;
