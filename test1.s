	;; RK 12/2012 - Evalbot (Cortex M3 de Texas Instrument)
	;; Les deux LEDs sont initialement allumées
	;; Ce programme lis l'état du bouton poussoir 1 connectée au port GPIOD broche 6
	;; Si bouton poussoir fermé ==> fait clignoter les deux LED1&2 connectée au port GPIOF broches 4&5.
   	
		AREA    |.text|, CODE, READONLY
 
; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_I2C EQU		0x00001000

; Broches select

I2C_BASE 			EQU 	0x40021000
	
I2CMTPR_BASE		EQU		0x00000001
I2CMCS_BASE			EQU		0x00000020
I2C_OTHER_BASE		EQU 	0x00000000
	
; blinking frequency
DUREE   			EQU     0x002FFFFF


	  	ENTRY
		EXPORT	__functionTest
__functionTest

		ldr r6, = SYSCTL_PERIPH_I2C
		
        mov r0, #0xFFFFFFF  					;; Enable clock sur GPIO D et F où sont branchés les leds (0x28 == 0b101000)
		; ;;														 									      (GPIO::FEDCBA)
        
		str r0, [r6]
		
		; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
		nop	   									;; tres tres important....
		nop	   
		nop	   									;; pas necessaire en simu ou en debbug step by step...
	
	
		; page 803 of sheet
		; ------- 	CONFIGURATION I2C
		
		
		; ------- END CONFIGURATION I2C
		

		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CLIGNOTTEMENT

		str r3, [r6]  							;; Allume LED1&2 portF broche 4&5 : 00110000 (contenu de r3)

ReadState

		ldr r10,[r7]
		CMP r10,#0x00
		BNE ReadState

loop
        str r2, [r6]    						;; Eteint LED car r2 = 0x00      
        ldr r1, = DUREE 						;; pour la duree de la boucle d'attente1 (wait1)

wait1	subs r1, #1
        bne wait1

        str r3, [r6]  							;; Allume LED1&2 portF broche 4&5 : 00110000 (contenu de r3)
        ldr r1, = DUREE							;; pour la duree de la boucle d'attente2 (wait2)

wait2   subs r1, #1
        bne wait2

        b loop       
		
; I2C SINGLE TRANSMISSION
; write slave address to I2CMSA
; write data to I2CMDR
; read I2CMCS
; if != 0 loop on read
; write ---0-111 to 12CMCS
; read I2CMCS
; if != 0 loop on read


		
		nop		
		END 