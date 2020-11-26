




; Broches select
LEDS_PIN_INIT		EQU		0x3C		; 00111100 mask of all used leds
										;(internet leds only activates if bit 3 & 4 are 0)						
LEDS_FORWARD_PIN	EQU		0x3C		; 00111100 led1 & led2 on pin 5 & 6
LEDS_BACKWARD_PIN	EQU		0x00		; 00000000 internet1 & internet2 on pin 3 & 4 when 0
	
LEDS_ALL_PIN		EQU		0x30		; 00110000 Active all leds (Forward & backward)
LEDS_STOP_PIN		EQU		0x0C		; 00001100 Stop all leds




;GPIO_O_DR2R : The GPIODR2R register is the 2-mA drive control register; By default, all GPIO pins have 2-mA drive.


GPIO_PORTF_BASE		EQU		0x40025000	; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet de lm3s9B92.pdf)
GPIO_O_DIR   		EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)
GPIO_O_DR2R   		EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)
GPIO_O_DEN  		EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)



		AREA    |.text|, CODE, READONLY
		ENTRY	

		;; The EXPORT command specifies that a symbol can be accessed by other shared objects or executables.
		EXPORT	LEDS_INIT
		EXPORT	LEDS_FORWARD_ON
		EXPORT	LEDS_BACKWARD_ON
		EXPORT	LEDS_ON
		EXPORT	LEDS_OFF
		EXPORT 	LEDS_BACKWARD_INVERT
	
	
LEDS_INIT
        ldr r6, = GPIO_PORTF_BASE+GPIO_O_DIR    ;; 1 Pin du portF en sortie (broche 4 : 00010000)
        ldr r0, = LEDS_PIN_INIT 	
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = LEDS_PIN_INIT		
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DR2R	;; Choix de l'intensité de sortie (2mA)
        ldr r0, = LEDS_PIN_INIT			
        str r0, [r6]
		
		ldr r5, = GPIO_PORTF_BASE + (LEDS_PIN_INIT<<2)  ;; @data Register = @base + (mask<<2)
		
		BX	LR	; FIN du sous programme d'init.
	
	
LEDS_FORWARD_ON
	mov r0, #LEDS_FORWARD_PIN
	str r0, [r5]  												
	BX	LR
		
LEDS_BACKWARD_ON
	mov r0, #LEDS_BACKWARD_PIN
	str r0, [r5]  												
	BX	LR

LEDS_BACKWARD_INVERT
	ldr r0, [r5]
	CMP r0, #0
	BNE LEDS_BACKWARD_ON
	B	LEDS_OFF

LEDS_ON
	mov r0, #LEDS_ALL_PIN
	str r0, [r5]  												
	BX	LR
		
		
LEDS_OFF
	mov r0, #LEDS_STOP_PIN
	str r0, [r5]    		   
	BX	LR	


END