----------------------------------- bench filter-------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.math_real.all;



library modelsim_lib;
use modelsim_lib.util.all;


library lib_VHDL;
--library lib_SYNTH;
--Library C35_CORELIB;
--Use C35_CORELIB.Vcomponents.all;

entity bench_filter is
end entity;  -- bench_filter

architecture arch of bench_filter is

  component filter
    port(
      	    Filter_In    : in  std_logic_vector(7 downto 0);
        CLK         : in  std_logic;
        RESET       : in  std_logic;
        ADC_Eocb     : in  std_logic;
        ADC_Convstb : out std_logic;
        ADC_Rdb      : out std_logic;
        ADC_csb     : out std_logic;
        DAC_WRb      : out std_logic;
        DAC_csb      : out std_logic;
        LDACb        : out std_logic;
        CLRB         : out std_logic;
        Filter_Out  : out std_logic_vector(7 downto 0)) ;  
  end component;

  signal CLK        : std_logic := '0';
    signal RESET      : std_logic;
--    signal uC_Config  : std_logic_vector(15 downto 0);
    signal Filter_In  : std_logic_vector(7 downto 0):="00000000";
    signal Filter_Out : std_logic_vector(7 downto 0);
    signal ADC_eocb    : std_logic;
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
  constant filter_rom2 : tab_rom := 							-- coefficient du filtre passe_bas
  (0  => "00000000" , 1 => "00000100" , 2 => "00000001" , 3 => "11111101" ,
     --  0x0D               0x15               0x1F               0x2C
     4  => "11111110" , 5 => "00000100" , 6 => "00000101" , 7 => "11111100" ,
     --  0x3C               0x4D               0x61               0x75
     8  => "11111000" , 9 => "00000011" , 10 => "00001101" , 11 => "00000001" ,
     --  0x8A               0x9F               0xB3               0xC5
     12 => "11101010" , 13 => "11110100" , 14 => "00101110" , 15 => "01101010" ,
     --  0xD4               0xE1               0xE9               0xEE
     16 => "01101010" , 17 => "00101110" , 18 => "11110100" , 19 => "11101010" ,
     --  0xEE               0xE9               0xE1               0xD4
     20 => "00000001" , 21 => "00001101" , 22 => "00000011" , 23 => "11111000" ,
     --  0xC5               0xB3               0x9F               0x8A
     24 => "11111100" , 25 => "00000101" , 26 => "00000100" , 27 => "11111110" ,
     --  0x75               0x61               0x4D               0x3C
     28 => "11111101" , 29 => "00000001" , 30 => "00000100" , 31 => "00000000") ;
  --  0x2C               0x1F               0x15               0xD
  

begin

      DUT : filter
        port map (
            CLK        => CLK,
            RESET      => RESET,
            Filter_In  => Filter_In,
            Filter_Out => Filter_Out,
            ADC_Eocb    => ADC_eocb,
            ADC_Convstb => ADC_convstb,
            ADC_Rdb     => ADC_rdb,
            ADC_csb     => ADC_csb,
            DAC_Wrb     => DAC_wrb,
            DAC_csb     => DAC_csb,
            LDACb   => DAC_ldacb,
            CLRB    => DAC_clrb
            ) ;

    CLK   <= not(CLK) after 10 ns;
    RESET <= '1', '0' after 45 ns;

  
  ADC_convstb_delayed<= ADC_convstb'delayed(0 ns);
  ADC_eocb_delayed<= ADC_eocb'delayed(0 ns);


  ---- Test le bon fonctionnement du CNA;
      process_ADC : process(ADC_Convstb)
      begin
        if ADC_Convstb'event and ADC_Convstb = '0' then
          ADC_eocb <= '1', '0' after 300 ns, '1' after 400 ns;
        end if;
      end process process_ADC;


---- Espion
      spy_process: process
      begin  -- process spy_process
        init_signal_spy("/bench_filter/DUT/Accu_out", "accu_out",1,-1);
        init_signal_spy("/bench_filter/DUT/Buff_OE", "buff_OE",1,-1); 
       wait;
      end process spy_process;

      
      
 -- Time constraints verification 
  -- type   : combinational
  -- inputs : ADC_convstb
  -- outputs: 
--    verif_time: process
--      variable t : time;
--      
--    begin  
--     wait on ADC_convstb;
--      if ADC_convstb'event and ADC_convstb='0' then
--        t:= ADC_rdb'last_event;
--        assert t>= (30 ns)  report "new conversion should started 30 ns after a read" severity warning;
--        wait on ADC_convstb;
--        t:= ADC_convstb_delayed'last_event;
--        assert t>= (20 ns)  report "a conversion pulse is at least 20 ns" severity warning;
--        wait on ADC_eocb;
--        t:= ADC_convstb_delayed'last_event;
--        assert (t<= (420 ns) and t>= (20 ns))  report "eoc is enabled between 120 ns and 420 ns after a start conversion" severity warning;
--        wait on ADC_eocb;
--        t:= ADC_eocb_delayed'last_event;
--        assert (t<= (110 ns) and t>= (70 ns))  report "eoc pulse is at least 70 ns and at most 110 ns" severity warning;
--      end if;  
--    end process verif_time;

    
      
 -- Reponse impulsionnelle
--  Filter_in_rep_impuls: process 
--    variable j :natural range 0 to 31 ;
--    
--  begin  -- process Filter_in_rep_impuls
--	for i in 0 to 31 loop
--		--if enable = "01" then
--			wait until ADC_eocb='0';
--			j:=i;
--			if i=0  then
--			Filter_in<="00000001";
--			else
--			Filter_in<=(others=>'0');
--			end if;
--			wait until buff_OE='1';
--			--Completer le assert
--			assert (Accu_out(7 downto 0) = filter_rom(i) )  report "error rep_impul" severity error;
		--end if;
--	end loop;  -- i
-- end process Filter_in_rep_impuls;

-- -- Response indiciel
--  Filter_in_rep_indice: process
--	variable id : integer := 0;
  
--   begin
--		for i in 0 to 31 loop
		
--		  wait until ADC_eocb='0';
--		  Filter_in<="00000001";
--		  coeff_accu <= coeff_accu + filter_rom(i);
		  
--		  wait until buff_OE='1'; 
--		  assert (Accu_out(7 downto 0) = coeff_accu)  report "error rep_impul" severity error;
--		end loop;  -- i

-- end process Filter_in_rep_indice;


---- Calcul et Ecriture+Lecture des echantillons et sinus
 LECTURE: process
	 variable L: line;
	 file ENTREES : text open write_mode is "echantillon_sinus.dat";
     variable A: std_logic_vector(7 downto 0);	 -- variables à lire
     variable Fe: real := 1.2*1000000.0; --1.2M
     variable fsin : real := 300000.0; --300K
     variable Te : real := 1.0/Fe;
     variable t : real := -0.01;
 
  begin
     while(true) loop
     for i in 1 to 126 loop
	     wait until ADC_rdb = '0' and ADC_csb='0';
         A := conv_std_logic_vector( integer(50.0*SIN(2.0*MATH_PI*fsin*t)),8 ); -- calcul su sinus
         
         write(L, A);	-- ecriture des valeur dans le fichier
	     writeline(ENTREES, L);	 
	     
		 Filter_in <= A;	-- utilisation pour la simulation
	     t := t+Te;
	     -- report ">>>>>>>>>>>>>>>>>>>>>>>>> <<<<<<<<<<<<<<<<<" & integer'image(i);
		 if i = 126 then
			 --fsin := fsin - 1000.0;
	         fsin := fsin*0.5;
	         report "  >>>>>>>>>>>" & real'image(fsin) &" "& real'image(t);
	     end if;
     end loop; --for
    end loop; --while
  end process LECTURE;

      -- 
 ECRITURE: process
       variable L: line;
       variable C : std_logic_vector(7 downto 0) := "XXXXXXXX";
       file SORTIES: text open WRITE_MODE is "sorties_filtre.dat";
 begin
       wait until DAC_wrb='1' and DAC_csb='1';
       if DAC_ldacb='0' and DAC_clrb='1' then
		   write(L, Filter_Out);	-- écriture de S dans la ligne
		   writeline(SORTIES, L); -- écriture de la ligne dans le fichier
       else
		   write(L,C);	-- écriture de "00000000" dans la ligne
		   writeline(SORTIES, L); -- écriture de la ligne dans le fichier
       end if;
 end process ECRITURE;

      


    end architecture;  -- arch
