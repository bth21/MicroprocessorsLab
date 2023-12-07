#include <xc.inc>

global	PWM_Setup

   
psect   udata_acs
   
max_PWM_dc:	    ds 1    ;reserving space for maximum PWM duty cycle
upper_lim_temp:	    ds 1    ;reserving space for upper temp limit
target_low_temp:    ds 1    ;reserving space for temp to return to full power
current_temp:	    ds 1    ;reserving space for current temp reading
   
psect pwm_code, class=CODE

PWM_Setup:
  
    movlw   0xFF
    movwf   max_PWM_dc	    ;setting max dc at FF
    movlw   0x35	    ;upper temp limit = 35C
    movwf   upper_lim_temp
    movlw   0x25	    ;return to full power at 0x19 (25C)
    movwf   target_low_temp 
    movf    ADRESH, W	    ;NEED TO FACTOR IN THAT THIS HAS BEEN CHANGED ALREADY!!!!! ;moving the ADC value (current temp) to current_temp
    movwf   current_temp
    
    movlw   0xFF	    ;PWM period - setting maximum 8bit period
    movwf   PR2		    ;PWM period set in PR2 reg
   
    clrf    CCPTMRS1	    ;use timer 2 for ccp4
    movlw   0x3C	    ;load the 2 LSBs set to pwm mode
    movwf   CCP4CON	    ;write to CCP4CON<5:4>
 
    bcf	    TRISG, 3	    ;setting pin 3 as output
    call    Update_PWM
 
    bsf	    T2CON, 2	    ;turning the timer 2 on
        
    return

    
Update_PWM:    
    
    movf    upper_lim_temp, W
    subwf   current_temp, W	    ;comparing if current temperature is greater than upper limit
    btfsc   STATUS, 0
    call    PWM_calc
    call    Low_Temp_Check
    return
    
    
PWM_calc:
    movlw   0x02		    ;**** this factor may need fine tuning ****
    mulwf   current_temp	    ;apply equation of PWM_dc = max_PWM - 2xcurrent temp > 35
    movf    PRODL, W		    ;move result to WREG
    subwf   max_PWM_dc, W
    
    movwf   CCPR4L		    ;set new PWM_dc
    return
    
Low_Temp_Check:
     
    movf    target_low_temp, W	    ;move current temp to WREG
    subwf   current_temp, W	    ;check if current temp is lower than 25C
    btfsc   STATUS, 0
    call    PWM_calc
    movf    target_low_temp, W	    ;move current temp to WREG
    subwf   current_temp, W	    ;check if current temp is lower than 25C
    btfsc   STATUS, 0
    return
    call    PWM_max		    ;set PWM max
    return
    
    
PWM_max:
    movf    max_PWM_dc, W	    ;set PWM duty cycle to 100% (LED is at max brightness)
    movwf   CCPR4L
    
    return

