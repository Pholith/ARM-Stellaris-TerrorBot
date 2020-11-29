	;; RK 12/2012 - Evalbot (Cortex M3 de Texas Instrument)
	;; Les deux LEDs sont initialement allumées
	;; Ce programme lis l'état du bouton poussoir 1 connectée au port GPIOD broche 6
	;; Si bouton poussoir fermé ==> fait clignoter les deux LED1&2 connectée au port GPIOF broches 4&5.
   	
		AREA    |.text|, CODE, READONLY
 
; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)



; The GPIODATA register is the data register
GPIO_PORTE_BASE		EQU		0x40024000		; GPIO Port E

; configure the corresponding pin to be an output

; Digital enable register
; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  		EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

; Pul_up
GPIO_I_PUR   		EQU 	0x00000510  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

BUMPER				EQU 	0x03		; 000000011, Bumper 1 & 2

; blinking frequency
LED_BLINK_FREQ 		EQU     0x001FFFFF


		

	  	ENTRY
		EXPORT	__main
		
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		IMPORT	MOTEUR_SET_SPEED_R0				
	
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arrière
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arrière
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche
	
		
		IMPORT	LEDS_INIT
		IMPORT	LEDS_FORWARD_ON
		IMPORT	LEDS_BACKWARD_ON
		IMPORT	LEDS_BACKWARD_INVERT
		IMPORT	LEDS_ON
		IMPORT	LEDS_OFF

		IMPORT	WAIT_R8
		
; Register usage : 
;	r0: Utils
;	r1: Utils
;	r2:	Unused
;	r3:	Unused
;	r4:	Bumper 1
;	r5:	Leds address
;	r6:	Engines address
;	r7:	Unused
;	r8:	Used by Timers.s
;	r9:	Time calculation


__main	

		; ;; Enable the Port F & D & E peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
		; ;;									
		ldr r1, = SYSCTL_PERIPH_GPIO  			;; RCGC2
		mov r0, #0x00000038  					;; Enable clock sur GPIO F où sont branchés les leds												 									      (GPIO::FEDCBA)
        str r0, [r1]
		
		; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
		nop	   									;; tres tres important....
		nop	   
		nop	   									;; pas necessaire en simu ou en debbug step by step...
	
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATIONS SOUS PROGRAMME
		
		BL MOTEUR_INIT
		mov	r0, #0x199	
		BL MOTEUR_SET_SPEED_R0
		
		BL LEDS_INIT		
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration
		
		

	
	
		
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION des bumpers

		ldr r1, = GPIO_PORTE_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BUMPER		
        str r0, [r1]
		
		ldr r1, = GPIO_PORTE_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BUMPER	
        str r0, [r1]
		
		ldr r4, = GPIO_PORTE_BASE + (BUMPER<<2)  ;; @data Register = @base + (mask<<2) ==> bumpers
		
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration bumpers 
		
		
		
		
		
		
		
		
		
		
		

		;;PART 1 : Starting 
		
		BL LEDS_FORWARD_ON
		
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_ON
		
		BL MOTEUR_DROIT_INVERSE
		BL MOTEUR_GAUCHE_INVERSE
		
		mov r9, #0x00 ;reset timer
		
ReadState		
		;;PART 2 : Waiting for bumper impact. 
		
		add r9, #3		; add 3 operation time elapsed
		
		ldr r10,[r4]		
		CMP r10,#0x03			
		BEQ ReadState	;// if (current bumper value == no bumper are colliding) goto ReadState;



		
		BL LEDS_OFF
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_OFF
		
		;;Wait a bit
		ldr r8, = 0x002FFFFF 						
		BL WAIT_R8


		;;PART 3 : Come back to orginnal position

		;;Go back
		
		BL LEDS_BACKWARD_ON
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_ON
		BL MOTEUR_DROIT_INVERSE		
		BL MOTEUR_GAUCHE_INVERSE

		;;Wait until the bot is back to original position and blink leds

		mov r1, r9 ; Store total time to wait into r0
		
loop_moveBack		
		ldr r8, = LED_BLINK_FREQ	
		subs r1, r8					; totalTime -= blinkTime 
		BL WAIT_R8 	 				; wait 1 blink	
		
		BL LEDS_BACKWARD_INVERT 	; blink leds. (Modify R0)		
		ldr r8, =LED_BLINK_FREQ			
		CMP r1, r8					
		BGT loop_moveBack				; if totalTime > blinkTime: goto loopBack
		
		mov r8, r1
		BL WAIT_R8					; wait remaining time

  
		;;PART 4 : RUN
		
		BL LEDS_OFF
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_OFF
		
		;;Wait a bit
		ldr r8, = 0x003FFFFF 						
		BL WAIT_R8
		

		
		;;RUN
		
		BL LEDS_FORWARD_ON
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_ON
		BL MOTEUR_DROIT_INVERSE		
		BL MOTEUR_GAUCHE_INVERSE		
		
		mov	r0, #0x0C8			;set the speed	
		BL MOTEUR_SET_SPEED_R0
		
		ASR  r8, r9, #0x02 	; divide the distance by 2
		BL WAIT_R8
		
	
	
		BL LEDS_OFF
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_OFF
		
		nop		
		END 