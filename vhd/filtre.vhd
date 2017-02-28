-----------------------------FILTRE.vhd----------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FILTER is
  port(Filter_In    : in  std_logic_vector(7 downto 0);
        CLK         : in  std_logic;
        RESET       : in  std_logic;
        ADC_Eocb     : in  std_logic;--Fin de conversion du ADC
        ADC_Convstb : out std_logic;--Start la conversion
        ADC_Rdb      : out std_logic;--Controle le level de l'impédance de sortie
        ADC_csb     : out std_logic;--Activation du port parallel
        DAC_WRb      : out std_logic;--Activation de l'écriture
        DAC_csb      : out std_logic;--Activation du port parallel
        LDACb        : out std_logic;--Activation de la load du signal d'entrée
        CLRB         : out std_logic;--CLEAR DAC
        Filter_Out  : out std_logic_vector(7 downto 0)) ;
end FILTER;

architecture A of FILTER is

  component ACCU
    port(Accu_in          : in  std_logic_vector(15 downto 0);
                Accu_ctrl : in  std_logic;
                CLK       : in  std_logic;
                RESET     : in  std_logic;
                Accu_out  : out std_logic_vector(20 downto 0)) ;
  end component;

  component BUFF
    port(Buff_in         : in  std_logic_vector(7 downto 0);
                Buff_OE  : in  std_logic;
                CLK      : in  std_logic;
                Reset    : in  std_logic;
                Buff_Out : out std_logic_vector(7 downto 0)) ;
  end component;

  component FSM
    port(CLK                            : in  std_logic;
                Reset                   : in  std_logic;
                ADC_Eocb                 : in  std_logic;
                ADC_Convstb             : out std_logic;
                ADC_Rdb                  : out std_logic;
                ADC_csb                 : out std_logic;
                DAC_WRb                  : out std_logic;
                DAC_csb                  : out std_logic;
                LDACb                    : out std_logic;
                CLRB                     : out std_logic;
                Rom_Address             : out std_logic_vector(4 downto 0);
                Delay_Line_Address      : out std_logic_vector(4 downto 0);
                Delay_Line_sample_shift : out std_logic;
                Accu_ctrl               : out std_logic;
                Buff_OE                 : out std_logic) ;
  end component;

  component MULT
    port(Mult_in_A        : in  std_logic_vector(7 downto 0);
                Mult_in_B : in  std_logic_vector(7 downto 0);
                Mult_out  : out std_logic_vector(15 downto 0)) ;
  end component;

  component DELAY_LINE
    port(Delay_Line_in                  : in  std_logic_vector(7 downto 0);
                Delay_Line_address      : in  std_logic_vector(4 downto 0);
                Delay_Line_sample_shift : in  std_logic;
                RESET                   : in  std_logic;
                CLK                     : in  std_logic;
                Delay_Line_out          : out std_logic_vector(7 downto 0)) ;
  end component;

  component ROM
    port(Rom_Address    : in  std_logic_vector(4 downto 0);
                Rom_out : out std_logic_vector(7 downto 0)) ;
  end component;

  component shift_register 
   port(clk, reset : in std_logic;
	shift_in : in std_logic;
	shift_out : out std_logic);
  end component;
 
  signal Delay_Line_sample_shift : std_logic;
  signal Accu_ctrl, Buff_OE      : std_logic;
  signal Delay_Line_out, Rom_out : std_logic_vector(7 downto 0);
  signal Mult_out                : std_logic_vector(15 downto 0);
  signal Accu_out                : std_logic_vector(20 downto 0);
  signal Rom_Address             : std_logic_vector(4 downto 0);
  signal Delay_Line_Address      : std_logic_vector(4 downto 0);
  signal ZERO                    : std_logic;
  signal adc_eoc_intern          : std_logic;
begin

  U1 : ROM port map (
    Rom_Address => Rom_Address,
    Rom_out     => Rom_out
    );

  U2 : Delay_Line port map (
    Delay_Line_in           => Filter_In,
    Delay_Line_Address      => Delay_Line_Address,
    Delay_Line_sample_shift => Delay_Line_sample_shift,
    CLK                     => CLK,
    RESET                   => RESET,
    Delay_Line_out          => Delay_Line_out
    );

  U3 : MULT port map (
    Mult_In_A => Delay_Line_out,
    Mult_In_B => Rom_out,
    Mult_out  => Mult_out
    );

  U4 : ACCU port map (
    Accu_In   => Mult_out,
    Accu_ctrl => Accu_ctrl,
    CLK       => CLK,
    RESET     => RESET,
    Accu_out  => Accu_out
    );

  U5 : BUFF port map (
    Buff_In  => Accu_out(19 downto 12),
    Buff_OE  => Buff_OE,
    CLK      => CLK,
    RESET    => RESET,
    Buff_out => Filter_Out
    );

  U6 : FSM port map (
    CLK                     => CLK,
    Reset                   => Reset,
    ADC_Eocb                 => adc_eoc_intern,
    ADC_Convstb             => ADC_Convstb,
    ADC_Rdb                  => ADC_Rdb,
    ADC_csb                 => ADC_csb,
    DAC_WRb                  => DAC_WRb,
    DAC_csb                  => DAC_csb,
    LDACb                    => LDACb,
    CLRB                     => CLRB,
    Rom_Address             => Rom_Address,
    Delay_Line_Address      => Delay_Line_Address,
    Delay_Line_sample_shift => Delay_Line_sample_shift,
    Accu_ctrl               => Accu_ctrl,
    Buff_OE                 => Buff_OE
    );
 
 U7 : shift_register port map (
   clk			=> clk,
   reset                => reset,
   shift_in             => adc_eocb,
   shift_out            => adc_eoc_intern
);		


end A;

