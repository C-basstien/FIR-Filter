library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;



library modelsim_lib;
use modelsim_lib.util.all;
--Library C35_CORELIB;
--Use C35_CORELIB.Vcomponents.all;

-- Indiquer ici quelle bibliothèque du filtre à utiliser 
-- (VHDL, après synthèse, après placement et routage)
library lib_VHDL;
--library lib_SYNTH;

entity bench_top is
end entity;  -- bench_top

architecture arch of bench_top is

    component filter
        port (
            Filter_In  : in  std_logic_vector(7 downto 0);
            CLK        : in  std_logic;
            RESET      : in  std_logic;
            ADC_eocb    : in  std_logic;
            ADC_convstb : out std_logic;
            ADC_rdb     : out std_logic;
            ADC_csb     : out std_logic;
            DAC_wrb     : out std_logic;
            DAC_csb     : out std_logic;
            ldacb   : out std_logic;
            clrb    : out std_logic;
            Filter_Out : out std_logic_vector(7 downto 0)          
            ) ;
    end component;

    signal CLK        : std_logic := '0';
    signal RESET      : std_logic;
--    signal uC_Config  : std_logic_vector(15 downto 0);
    signal Filter_In  : std_logic_vector(7 downto 0);
    signal Filter_Out : std_logic_vector(7 downto 0);
    signal ADC_eocb    : std_logic := '1';
    signal ADC_convstb : std_logic;
    signal ADC_rdb     : std_logic;
    signal ADC_csb     : std_logic;
    signal DAC_wrb     : std_logic;
    signal DAC_csb     : std_logic;
    signal DAC_ldacb   : std_logic;
    signal DAC_clrb    : std_logic;
    signal Buff_OE    : std_logic;
    signal ADC_convstb_delayed,ADC_eocb_delayed        : std_logic;
    signal Accu_out   : std_logic_vector(20 downto 0);
    type     tab_rom is array (0 to 31) of std_logic_vector(7 downto 0);
  constant filter_rom : tab_rom :=
    (0   => "00001101" , 1 => "00010101" , 2 => "00011111" , 3 => "00101100" ,
      --  0x0D               0x15               0x1F               0x2C
      4  => "00111100" , 5 => "01001101" , 6 => "01100001" , 7 => "01110101" ,
      --  0x3C               0x4D               0x61               0x75
      8  => "10001010" , 9 => "10011111" , 10 => "10110011" , 11 => "11000101" ,
      --  0x8A               0x9F               0xB3               0xC5
      12 => "11010100" , 13 => "11100001" , 14 => "11101001" , 15 => "11101110" ,
      --  0xD4               0xE1               0xE9               0xEE
      16 => "11101110" , 17 => "11101001" , 18 => "11100001" , 19 => "11010100" ,
      --  0xEE               0xE9               0xE1               0xD4
      20 => "11000101" , 21 => "10110011" , 22 => "10011111" , 23 => "10001010" ,
      --  0xC5               0xB3               0x9F               0x8A
      24 => "01110101" , 25 => "01100001" , 26 => "01001101" , 27 => "00111100" ,
      --  0x75               0x61               0x4D               0x3C
      28 => "00101100" , 29 => "00011111" , 30 => "00010101" , 31 => "00001101") ;
  --  0x2C               0x1F               0x15               0xD
  
begin

    DUT : filter
        port map (
            CLK        => CLK,
            RESET      => RESET,
            Filter_In  => Filter_In,
            Filter_Out => Filter_Out,
            ADC_eocb    => ADC_eocb,
            ADC_convstb => ADC_convstb,
            ADC_rdb     => ADC_rdb,
            ADC_csb     => ADC_csb,
            DAC_wrb     => DAC_wrb,
            DAC_csb     => DAC_csb,
            ldacb   => DAC_ldacb,
            clrb    => DAC_clrb
            ) ;


    CLK   <= not(CLK) after 10 ns;
    RESET <= '1', '0' after 15 ns;
    --ADC_eocb <= '1', '0' after 100 ns;
 	Filter_in <= "00000000" ,"01111100"after 100 ns; 

      

   -- purpose: time c
   --constraints verification 
   -- type   : combinational
   -- inputs : ADC_convstb
   -- outputs: 
   verif_time: process 
     variable t : time;
   begin  -- process verif_time
      wait on ADC_convstb;
     if ADC_convstb'event and ADC_convstb='0' then
     	ADC_eocb <= '1', '0' after 400 ns;
       t:= ADC_rdb'last_event; -- Calcule le temps depuis la dernière conversion
       assert t>= (30 ns)  report "new conversion starts 30 ns after a read" severity warning;
       --if (t< (30 ns)) then ADC_eocb <= '0', '1' after 110 ns;
       --end if;
      
     -- A completer
     --ADC_eocb <= '0';
     	


     end if;
  
   end process verif_time;

    

-- observation de signaux internes
    spy_process: process
      begin  -- process spy_process
       init_signal_spy("/bench_top/DUT/Accu_out", "accu_out",1,-1);
       init_signal_spy("/bench_top/DUT/Buff_OE", "buff_OE",1,-1);
      
         wait;
      end process spy_process;
 

      

end architecture;  -- arch
