------------------------------FSM.vhd----------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity FSM is
  port(Clk                      : in  std_logic;
       Reset                    : in  std_logic;
       ADC_Eocb                 : in  std_logic;
       ADC_Convstb              : out std_logic;
       ADC_Rdb                  : out std_logic;
       ADC_csb                  : out std_logic;
       DAC_WRb                  : out std_logic;
       DAC_csb                  : out std_logic;
       LDACb                    : out std_logic;
       CLRb                     : out std_logic;
       Rom_Address              : out std_logic_vector(4 downto 0);
       Delay_Line_Address       : out std_logic_vector(4 downto 0);
       Delay_Line_sample_shift  : out std_logic;
       Accu_ctrl                : out std_logic;
       Buff_OE                  : out std_logic) ;
end FSM;
-- Machine à états contrôlant le filtre numérique.



architecture A of FSM is

type STATE is (INIT,READ_FIRST,READ,RTRN);
signal current_state : STATE;
signal next_state : STATE;
signal s_Rom_Address:unsigned(4 downto 0);
signal s_Delay_Line_Address:unsigned(4 downto 0);
signal count_next:unsigned(4 downto 0);
signal count:unsigned(4 downto 0);

begin
Rom_Address<=std_logic_vector(s_Rom_Address);
Delay_Line_Address<=std_logic_vector(s_Delay_Line_Address);
    FSM_NEXT_STATE: process(clk, reset)
	
	begin
	if(clk'event and clk='1') then
		if(reset='1') then 
		current_state <= INIT;
		count<="00000";
		else
		current_state<=next_state;
		count<=count_next;
		end if;
	end if;
    end process;


    P_FSM: process(current_state, ADC_Eocb,count)
    	
	begin			
		ADC_Convstb <='1';	
		ADC_Rdb <='1';
		ADC_csb <='1';
       		DAC_WRb <='1';
      		DAC_csb <='1';
       		LDACb <='0'; 
		CLRb  <='1';
		s_Rom_Address <="00000";    
		s_Delay_Line_Address <="00000";        
		Delay_Line_sample_shift <='0';
		Accu_ctrl <='1'; 
		Buff_OE <='0';
		count_next<="00000";
		
		case current_state is

			when INIT =>
				ADC_Convstb <='0';--ajouter un compteur pour tempo
				if (not(count = "00010")) then
					count_next <= count + "00001";
					next_state <= INIT;
				else
					ADC_Convstb <='0';
					count_next <= "00000";
--					if (ADC_Eocb='0') then 
					next_state <= READ_FIRST;
--					else next_state <= INIT;
--					end if;
				end if;
			when READ_FIRST =>
				Delay_Line_sample_shift <='1';
				s_Delay_Line_Address<=count;
				s_Rom_Address <=count;
				count_next<=count+1;
				next_state <= READ; 	
			when READ =>	
				Accu_ctrl <='0';
				if (count = "11111") then
					s_Delay_Line_Address<=count;
					s_Rom_Address <=count;
					next_state <= RTRN;
				else
					s_Delay_Line_Address<=count;
					s_Rom_Address <=count;
					count_next<=count+1;
					
					next_state <= READ;
				end if;
			when RTRN =>
				Buff_OE <='1';
				ADC_csb <='0';
				ADC_Rdb <='0';
       				DAC_WRb <='0';
      				DAC_csb <='0';
      				next_state <= INIT;
		end case;
	end process;
end A;
