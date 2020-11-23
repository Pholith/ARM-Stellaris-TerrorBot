


		AREA    |.text|, CODE, READONLY
		ENTRY	

		;; The EXPORT command specifies that a symbol can be accessed by other shared objects or executables.
		EXPORT	WAIT_R8
		
		
		
		

WAIT_R8 				;;Wait for r8 Duration

wait_a_bit	subs r8, #1
        bne wait_a_bit
		BX	LR




END