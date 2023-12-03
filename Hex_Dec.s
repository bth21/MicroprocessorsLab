#include <xc.inc>

global  Hex_Dec_Setup, Conversion
extrn	LCD_Write_Hex
    
psect	udata_acs	     ; reserve data space in access ram
one_low:	    ds 1
one_high:	    ds 1
ten:		    ds 1
high_res_1:	    ds 1
low_res_1:	    ds 1
high_res_cross:	    ds 1
low_res_cross:	    ds 1
low_res1_16x8:	    ds 1
high_res1_16x8:	    ds 1
low_res2_16x8:	    ds 1
high_res2_16x8:	    ds 1
extr_1:		    ds 1    ;first digit stored here
extr_2:		    ds 1    ;second digit stored here
extr_3:		    ds 1    ;third digit stored here

low_res_24x8_1:	    ds 1
high_res_24x8_1:    ds 1
low_res_24x8_2:	    ds 1
high_res_24x8_2:    ds 1
low_res_24x8_3:	    ds 1
high_res_24x8_3:    ds 1
carry:		    ds 1

 
psect	Hextodec_code,class=CODE

Hex_Dec_Setup:
    
    movlw   0xF6	    ;low byte of the multiplication constant
    movwf   one_low	    ;converts hex to decimal for 000-999
    movlw   0x28
    movwf   one_high
    movlw   0x0A	    ;high byte of the multiplication constant
    movwf   ten
   
    
Conversion:
    call    Multiply_16x16
    call    Extraction_1    ;obtaining first digit
    call    Multiply_24x8_1
    call    Extraction_2    ;obtaining second digit
    call    Multiply_24x8_2
    call    Extraction_3    ;obtaining third digit
    
    movf    extr_1, W	    ;combining low byte of conversion
    movwf   ADRESH	    ;moving to ADRESH for LCD display
    
    movf    extr_2, W	    ;combining high byte of conversion
    swapf   WREG
    addwf   extr_3, W
    movwf   ADRESL	    ;moving to ADRESL for LCD display
    
    return
    
Multiply_16x16:		    ;obtains the first byte of the hex number in decimal
    
    movf    one_low, W 
    mulwf   ADRESL
    
    movff   PRODH, high_res_1
    movff   PRODL, low_res_1
    
    movf    one_high, W
    mulwf   ADRESH
    
    movff   PRODH, high_res_cross
    movff   PRODL, low_res_cross
    
    movf    one_low, W
    mulwf   ADRESH
    
    movf    PRODL, W
    addwf   high_res_1, F
    movf    PRODH, W
    addwfc  low_res_cross, F
    clrf    WREG
    addwfc  high_res_cross, F
    
    movf    one_high, W
    mulwf   ADRESL
    
    movf    PRODL, W
    addwf   high_res_1, F
    movf    PRODH, W
    addwfc  low_res_cross, F
    clrf    WREG
    addwfc  high_res_cross, F	    ;solution to mult 16x16 stored as: HRC(00) LRC HR1 LR1
    
    return
    
Multiply_24x8_1:

    movf    low_res_1, W	    ;multiplying least sig byte of 16x16 by 10
    mulwf   ten
    
    movff   PRODH, high_res_24x8_1
    movff   PRODL, low_res_24x8_1
    
    movf    high_res_1, W	    ;multiplying second least sig byte by 10
    mulwf   ten
    
    movff   PRODH, high_res_24x8_2
    movff   PRODL, low_res_24x8_2
    
    movf    high_res_24x8_1, W	    ;adding most sig byte from first mult to least sig byte from second mult
    addwf   low_res_24x8_2, 1, 0
    
    movlw   0x00
    addwfc  carry, 1, 0		    ;storing carry bit from this addition in 'carry'
    
    movf    low_res_cross, W	    ;multiplying third least sig byte from 16x16 by 10
    mulwf   ten
    
    movff   PRODH, high_res_24x8_3
    movff   PRODL, low_res_24x8_3
    
    
    movf    high_res_24x8_2, W	    ;adding most sig byte from second mult to least sig byte from third mult
    addwf   low_res_24x8_3, 1, 0
    movf    carry, W		    ;adding the carry bit from above also
    addwf   low_res_24x8_3
    
    movlw   0x00		    ;adding second carry bit to MSB - almost always gonna be 0
    addwfc  high_res_24x8_3, 1, 0   ;solution to mult 24x8 stored as: HR3(00) LR3 LR2 LR1
    
    return
 
Multiply_24x8_2:

    movf    low_res_24x8_1, W	    ;multiplying least sig byte of 16x16 by 10
    mulwf   ten
    
    movff   PRODH, high_res_24x8_1
    movff   PRODL, low_res_24x8_1
    
    movf    low_res_24x8_2, W	    ;multiplying second least sig byte by 10
    mulwf   ten
    
    movff   PRODH, high_res_24x8_2
    movff   PRODL, low_res_24x8_2
    
    movf    high_res_24x8_1, W	    ;adding most sig byte from first mult to least sig byte from second mult
    addwf   low_res_24x8_2, 1, 0
    
    movlw   0x00
    addwfc  carry, 1, 0		    ;storing carry bit from this addition in 'carry'
    
    movf    low_res_24x8_3, W	    ;multiplying third least sig byte from 16x16 by 10
    mulwf   ten
    
    movff   PRODH, high_res_24x8_3
    movff   PRODL, low_res_24x8_3
    
    
    movf    high_res_24x8_2, W	    ;adding most sig byte from second mult to least sig byte from third mult
    addwf   low_res_24x8_3, 1, 0
    movf    carry, W		    ;adding the carry bit from above also
    addwf   low_res_24x8_3
    
    movlw   0x00		    ;adding second carry bit to MSB - almost always gonna be 0
    addwfc  high_res_24x8_3, 1, 0   ;solution to mult 24x8 stored as: HR3(00) LR3 LR2 LR1
    
    return
    
Extraction_1:
    
    movf    low_res_cross, W	    ;first decimal digit stored as first byte in low_res_cross
    andlw   0xF0		    ;andlw with 11110000 (F0) to obtain only first byte
    swapf   WREG		    ;swap digits around
    movwf   extr_1		    ;contains the first digit of the hex number in decimal
    
    movf    low_res_cross, W	    ;andlw with 00001111 (0F) to ready for next multiplication
    andlw   0x0F
    movwf   low_res_cross	    ;resave new MSB to RAM 
      
    return
    
 
Extraction_2:
    
    movf    low_res_24x8_3, W	    ;first decimal digit stored as first byte in low_res_24x8_3
    andlw   0xF0		    ;andlw with 11110000 (F0) to obtain only first byte
    swapf   WREG		    ;swap digits around
    movwf   extr_2		    ;contains the second digit of the hex number in decimal
    
    movf    low_res_24x8_3, W	    ;andlw with 00001111 (0F) to ready for next multiplication
    andlw   0x0F
    movwf   low_res_24x8_3	    ;resave new MSB to RAM 
      
    return
 
Extraction_3:
    
    movf    low_res_24x8_3, W	    ;first decimal digit stored as first byte in low_res_24x8_3
    andlw   0xF0		    ;andlw with 11110000 (F0) to obtain only first byte
    swapf   WREG		    ;swap digits around
    movwf   extr_3		    ;contains the third digit of the hex number in decimal
      
    return   


    
    
    
   