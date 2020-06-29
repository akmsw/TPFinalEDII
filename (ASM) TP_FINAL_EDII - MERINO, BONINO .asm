;                   TRABAJO PRÁCTICO FINAL INTEGRADOR
;               FCEFyN - UNC - INGENIERÍA EN COMPUTACIÓN
;                        ELECTRÓNICA DIGITAL II
;
;                          "TECLADO MUSICAL"
;
;INTEGRANTES:	*MERINO, MATEO		    -	41232347
;		*BONINO, FRANCISCO IGNACIO  -	41279796


;-------------------LIBRERÍAS---------------------------------------------------

	#INCLUDE    <P16F887.INC>

	    LIST    P = 16F887

;-------------------CONFIGURACIÓN PIC-------------------------------------------

	__CONFIG    _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
	__CONFIG    _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;-------------------DECLARACIÓN DE VARIABLES------------------------------------

	  COMPAS    EQU	    0x20	    ;Variable que cuenta la cantidad de compases que pasaron.
	    LOOP    EQU	    0x21	    ;Variable para bucles.
       METRONOMO    EQU	    0x23	    ;Variable para prender/apagar el metrónomo.
      PORTB_TEMP    EQU	    0x24	    ;Variable que almacena temporalmente la lectura de PORTB.
	      I1    EQU	    0x25
	      I2    EQU	    0x26
	      I3    EQU	    0x27
         LECTURA    EQU     0x28	    ;Variable que almacena la lectura de puerto serie.
	DISPLAY1    EQU     0x30	    ;Variables para los valores de los displays.
	DISPLAY2    EQU     0x31
	DISPLAY3    EQU     0x32
        DISPLAY4    EQU     0x33
        DISPLAY5    EQU     0x34
        DISPLAY6    EQU     0x35
      DISPLAYMUX    EQU	    0x36	    ;Variable para el multiplexado de los displays.
	  W_TEMP    EQU	    0x37	    ;Variables para salvar contexto.
     STATUS_TEMP    EQU	    0x38
     GUARDA_DATO    EQU	    0x39	    ;Variable para guardar los datos recibidos por el puerto serie.
     TRANSMISION    EQU	    0x40	    ;Variable para decidir si transmitir o no por puerto serie.
       RECEPCION    EQU	    0x41	    ;Variable para decidir si recibir o no por puerto serie.

		    ORG	    0x00
		    GOTO    CONFIGURAR

		    ORG	    0x04
		    GOTO    RUT_IN

;-------------------CONFIGURACIÓN REGISTROS-------------------------------------

		    ORG	    0x05
      CONFIGURAR    MOVLW   B'11011000'	    ;Configuramos INTCON habilitando GIE, INTE, RBIE y PEIE
		    MOVWF   INTCON	    ;(todas las fuentes de interrupción).
		    BANKSEL OPTION_REG
		    MOVLW   B'10000111'	    ;Configuramos OPTION_REG deshabilitando resistencias de
		    MOVWF   OPTION_REG	    ;pull-up en PORTB, con prescaler en 1:256 para TMR0.
		    BANKSEL IOCB	    ;Configuramos IOCB para tener interrupciones en RB<7:1>.
		    MOVLW   B'11111110'
		    MOVWF   IOCB

;------------------CONFIGURACIÓN RX PUERTO SERIE--------------------------------

		    BANKSEL RCSTA	    ;CONFIGURACIÓN PARA RECEPCIÓN
		    BCF	    RCSTA,SPEN      ;Desactivamos el puerto serie al inicio del programa.
		    BCF	    RCSTA,RX9       ;La recepción será de 8 bits.

;------------------CONFIGURACIÓN TX PUERTO SERIE--------------------------------

		    BANKSEL TXSTA	    ;CONFIGURACIÓN PARA TRANSMISIÓN
		    BCF	    TXSTA,TX9       ;La transmisión será de 8 bits.
		    BCF	    TXSTA,SYNC      ;La transmisión será asíncrona.
		    BSF	    TXSTA,BRGH      ;La transmisión será de alta velocidad.
		    BANKSEL BAUDCTL
		    BCF	    BAUDCTL,BRG16   ;8 bits para el baud-rate.
		    BANKSEL SPBRG
		    MOVLW   .25		    ;Cargamos un '25' en SPBRG para trabajar con 9600 baudios.
		    MOVWF   SPBRG

;-------------------CONFIGURACIÓN DE PUERTOS DE I/O-----------------------------

		    BANKSEL TRISA	    ;Seteamos PORTA, PORTC, PORTD y PORTE como salida.
		    MOVLW   B'10000000'
		    MOVWF   TRISA
		    MOVLW   B'10000000'
		    MOVWF   TRISC
		    MOVLW   B'10000000'
		    MOVWF   TRISD
		    CLRF    TRISE
		    MOVLW   0xFF	    ;Seteamos PORTB como entrada digital, y configuramos
		    MOVWF   TRISB	    ;PORTA y PORTE como outputs digitales.
		    BANKSEL ANSELH
		    CLRF    ANSELH
		    CLRF    ANSEL
		    BANKSEL PORTC	    ;Limpiamos todos los puertos antes de trabajar.
    		    CLRF    PORTA
		    CLRF    PORTC
		    CLRF    PORTD
		    CLRF    PORTE

;-------------------INICIALIZACIÓN DE VARIABLES---------------------------------

		    MOVLW   .8		    ;Cargamos '8' en la variable contadora para compases (~500[ms]).
		    MOVWF   COMPAS
		    CLRF    METRONOMO	    ;Ponemos en '0' a METRONOMO.
		    CLRF    DISPLAYMUX	    ;Ponemos en '0' a la variable para multiplexar displays y de
		    CLRF    GUARDA_DATO	    ;almacenamiento por puerto serie.
		    CLRF    DISPLAY1	    ;Limpiamos los displays.
		    CLRF    DISPLAY2
		    CLRF    DISPLAY3
		    CLRF    DISPLAY4
		    CLRF    DISPLAY5
		    CLRF    DISPLAY6
		    GOTO    INICIO	    ;Fin de configuración. Vamos a INICIO.

;-------------------TABLAS------------------------------------------------------

  TABLA_DISPLAYS    ADDWF   PCL,1	    ;Tabla para multiplexación de displays.
		    RETLW   B'11111110'	    ;Prendemos RC0.
		    RETLW   B'11111101'	    ;Prendemos RC1.
		    RETLW   B'11111011'	    ;Prendemos RC2.
		    RETLW   B'11110111'	    ;Prendemos RC3.
		    RETLW   B'11101111'	    ;Prendemos RC4.
		    RETLW   B'11011111'	    ;Prendemos RC5.

     TABLA_NOTAS    ADDWF   PCL,1	    ;Tabla con notas musicales en cifrado americano.
		    RETLW   0x3D	    ;Sol    (G)
		    RETLW   0x71	    ;Fa	    (F)
		    RETLW   0x79	    ;Mi     (E)
		    RETLW   0x5E	    ;Re	    (D)
		    RETLW   0x39	    ;Do	    (C)
		    RETLW   0x7C	    ;Si	    (B)
		    RETLW   0x77	    ;La     (A)

;-------------------MAIN--------------------------------------------------------

	  INICIO    GOTO    REFRESH	    ;Multiplexado de displays constante.
	 REFRESH    MOVLW   0xFF	    ;Control de valores a mostrar por los displays.
		    MOVWF   PORTC
		    MOVLW   0x30
		    MOVWF   FSR
		    MOVF    DISPLAYMUX,0
		    ADDWF   FSR,1
		    MOVF    INDF,0
		    MOVWF   PORTA
		    MOVF    DISPLAYMUX,0    ;Multiplexación de displays.
		    CALL    TABLA_DISPLAYS
		    MOVWF   PORTC
		    INCF    DISPLAYMUX,1
		    MOVLW   .6
		    SUBWF   DISPLAYMUX,0
		    BTFSC   STATUS,Z
		    CLRF    DISPLAYMUX

;-------------------TEST TX-----------------------------------------------------

		    BTFSC   PORTA,7	    ;Testeamos RA7 para ver activar o desactivar
		    GOTO    INICIO_RX	    ;la transmisión por puerto serie. Si RA7 está en '1',
		    GOTO    TX_TEST	    ;entonces testeamos el pulsador para RX.

	 TX_TEST    BTFSC   RECEPCION,0	    ;Si estamos recibiendo, no podemos transmitir.
		    GOTO    INICIO
		    BTFSC   TRANSMISION,0   ;En base al estado del bit '0' del registro de control
		    GOTO    TX_OFF	    ;de transmisión, decidimos si usar o dejar de usar el
		    GOTO    TX_ON	    ;el modo 'grabar'.
		    GOTO    INICIO

	   TX_ON    BSF	    PORTE,1	    ;Si lo vamos a usar, habilitamos el puerto serie y el transmisor.
		    BSF	    RCSTA,SPEN
		    BANKSEL TXSTA
		    BSF	    TXSTA,TXEN
		    BANKSEL PORTA
		    BSF	    TRANSMISION,0
		    CALL    DELAY300MS
		    GOTO    INICIO

	  TX_OFF    MOVLW   0x3E	    ;Si lo vamos a dejar de usar, mandamos un bit informando
		    MOVWF   TXREG	    ;que dejaremos de transmitir, y deshabilitamos todo.
		    BANKSEL TXSTA
		    BTFSS   TXSTA,TRMT
		    GOTO    $-1
		    BANKSEL PORTE
		    BCF	    PORTE,1
		    BCF	    RCSTA,SPEN
		    BANKSEL TXSTA
		    BCF	    TXSTA,TXEN
		    BANKSEL PORTA
		    BCF	    TRANSMISION,0
		    CALL    DELAY300MS
		    GOTO    INICIO

;-------------------TEST RX-----------------------------------------------------

       INICIO_RX    BTFSC   TRANSMISION,0   ;Si estamos transmitiendo, no podemos recibir.
		    GOTO    INICIO
		    BTFSC   PORTD,7	    ;Testeamos RA7 para ver activar o desactivar
		    GOTO    INICIO	    ;la recepción por puerto serie. Si RD7 está en '1',
		    GOTO    RC_TEST	    ;salimos. Si fue pulsado, decidimos si usar o no RX.

	 RC_TEST    BTFSC   RECEPCION,0	    ;Tomamos la decisión en base al bit '0' del registro
		    GOTO    RC_OFF	    ;de control de recepción, con el mismo criterio que
    		    GOTO    RC_ON	    ;para la transmisión.
		    CALL    DELAY300MS	    ;Delay para eliminar rebote de los pulsadores.

	   RC_ON    BSF	    PORTE,0	    ;Si vamos a recibir una partitura, entonces
		    BCF	    INTCON,T0IE	    ;deshabilitamos el metrónomo.
		    BCF	    PORTE,2
		    BCF	    METRONOMO,0
		    BANKSEL PIE1
		    BSF	    PIE1,RCIE;
		    BANKSEL PORTA           ;Si queremos usarlo, habilitamos las interrupciones por RX,
		    BSF	    RCSTA,SPEN	    ;el puerto serie y el receptor.
		    BSF	    RCSTA,CREN
		    BSF	    RECEPCION,0
		    CALL    DELAY300MS
		    GOTO    INICIO

	  RC_OFF    BCF	    PORTE,0	    ;Si queremos dejar de recibir por puerto serie,
		    BANKSEL PIE1	    ;deshabilitamos todo y habilitamos nuevamente las
		    BCF	    PIE1,RCIE;	    ;interrupciones por TMR0 para seguir con el
		    BANKSEL PORTA	    ;metrónomo desde donde estaba.
		    BCF	    RCSTA,CREN
		    BCF	    RCSTA,SPEN
		    BCF	    RECEPCION,0
		    CALL    DELAY300MS
		    GOTO    INICIO

;-------------------DELAY-------------------------------------------------------

      DELAY300MS    MOVLW   .3		    ;Retardo por software de ~300[ms] con la función
		    MOVWF   I3		    ;de antirrebote.
          BUCLE3    MOVLW   .131
		    MOVWF   I2
          BUCLE2    MOVLW   .255
		    MOVWF   I1
          BUCLE1    DECFSZ  I1
		    GOTO    BUCLE1
		    DECFSZ  I2
		    GOTO    BUCLE2
		    DECFSZ  I3
		    GOTO    BUCLE3
		    RETURN

;-------------------RUTINA INTERRUPCIÓN-----------------------------------------

	  RUT_IN    MOVWF   W_TEMP          ;Salvamos contexto.
		    SWAPF   STATUS,W
		    MOVWF   STATUS_TEMP
		    BTFSC   INTCON,RBIF	    ;Si la interrupción fue por RB<7:1>, voy a la rutina
		    GOTO    PORTB_IN	    ;de interrupción por RB<7:1>. 
		    BTFSC   INTCON,INTF	    ;Si fue por RB0, voy a la de RB0.
		    GOTO    RB0_IN
		    BTFSC   INTCON,T0IF	    ;Si fue por TMR0, voy a la de TMR0.
		    GOTO    TMR0_IN
		    BTFSC   PIR1,RCIF	    ;Si fue por recepción por puerto serie, voy a la de RX.
		    GOTO    RECEP_IN
		    RETFIE		    ;Si fue un falso positivo, vuelvo sin hacer nada.

;-------------------INTERRUPCIÓN RB<7:1>----------------------------------------

	PORTB_IN    BTFSC   PORTB,1	    ;Asignamos a W el valor correspondiente a la nota
		    GOTO    TEST_RB2	    ;según la tecla presionada. Luego, buscamos en
		    MOVLW   .4		    ;la tabla el valor a mostrar.
		    GOTO    SHOW
	TEST_RB2    BTFSC   PORTB,2
		    GOTO    TEST_RB3
		    MOVLW   .3
		    GOTO    SHOW
	TEST_RB3    BTFSC   PORTB,3
		    GOTO    TEST_RB4
		    MOVLW   .2
		    GOTO    SHOW
	TEST_RB4    BTFSC   PORTB,4
		    GOTO    TEST_RB5
		    MOVLW   .1
		    GOTO    SHOW
	TEST_RB5    BTFSC   PORTB,5
		    GOTO    TEST_RB6
		    MOVLW   .0
		    GOTO    SHOW
	TEST_RB6    BTFSC   PORTB,6
		    GOTO    TEST_RB7
		    MOVLW   .6
		    GOTO    SHOW
	TEST_RB7    BTFSC   PORTB,7
		    GOTO    FIN_RB_IN
		    MOVLW   .5
	    SHOW    CALL    TABLA_NOTAS
		    BTFSS   TRANSMISION,0   ;Si está activado el modo de transmisión, mostramos
		    GOTO    MOSTRAR	    ;la nota por PORTD y la mandamos por el puerto serie.
		    MOVWF   TXREG
	 MOSTRAR    MOVWF   PORTD	    ;Si no está activado el modo de transmisión, sólo
		    GOTO    FIN_RB_IN	    ;mostramos la nota por PORTD.

;-------------------INTERRUPCIÓN RB0--------------------------------------------

	  RB0_IN    BTFSC   METRONOMO,0	    ;Chequeamos si queremos usar el metrónomo
		    GOTO    METRONOMO_OFF   ;o salir del mismo.
		    GOTO    METRONOMO_ON

    METRONOMO_ON    BTFSC   RECEPCION,0
		    GOTO    FIN_RB0_IN
		    BSF	    METRONOMO,0	    ;Si lo queremos usar, activamos las interrupciones
		    BSF     INTCON,T0IE	    ;por TMR0, cargamos TMR0 con '1' para que cuente ~65[ms]
		    MOVLW   .1		    ;y cada 8 vueltas (~500[ms]) actualizamos el valor del
		    MOVWF   TMR0	    ;LED de metrónomo.
		    GOTO    FIN_RB0_IN

   METRONOMO_OFF    BCF	    METRONOMO,0	    ;Si lo queremos apagar, limpiamos PORTC para apagar
		    BCF     PORTE,2	    ;el LED, y desactivamos las interrupciones por TMR0,
		    BCF     INTCON,T0IE	    ;inhabilitando así el metrónomo.
		    GOTO    FIN_RB0_IN

;-------------------INTERRUPCIÓN TMR0-------------------------------------------

	 TMR0_IN    DECFSZ  COMPAS,1	    ;Contamos ~500[ms] y toggleamos el LED utilizado
		    GOTO    RELOAD	    ;para marcar el ritmo.
		    MOVLW   .8
		    MOVWF   COMPAS
		    BTFSS   PORTE,2
		    GOTO    PRENDER
		    GOTO    APAGAR

	 PRENDER    BSF     PORTE,2
	            GOTO    RELOAD

	  APAGAR    BCF     PORTE,2

	  RELOAD    MOVLW   .1
		    MOVWF   TMR0
		    GOTO    FIN_TMR0_IN

;-------------------INTERRUPCIÓN RX---------------------------------------------

	RECEP_IN    BCF	    PIR1,RCIF
		    BCF	    PORTE,2
		    MOVF    RCREG,W	    ;Leemos lo que recibimos por puerto serie,
	            SUBLW   0x47	    ;lo decodificamos, lo buscamos en la tabla
		    CALL    TABLA_NOTAS	    ;y lo guardamos en LECTURA. Con direccionamiento
		    MOVWF   LECTURA	    ;indirecto almacenamos los valores en los
		    MOVLW   0x30	    ;displays correspondientes.
		    MOVWF   FSR
		    MOVF    GUARDA_DATO,0
		    ADDWF   FSR,1
		    MOVF    LECTURA,0
		    MOVWF   INDF
		    INCF    GUARDA_DATO,1
		    MOVF    GUARDA_DATO,0
		    SUBLW   .6
		    BTFSC   STATUS,Z
		    CLRF    GUARDA_DATO
		    GOTO    FIN_RX_IN

;-------------------FIN RUTINA INTERRUPCIÓN-------------------------------------

       FIN_RB_IN    MOVF    PORTB,0	    ;Limpiamos flag de interrupción por RB<7:1>,
		    BCF	    INTCON,RBIF	    ;devolvemos contexto y salimos.
		    CALL    DEV_CONTEXT
		    RETFIE

      FIN_RB0_IN    CALL    DEV_CONTEXT	    ;Devolvemos contexto, limpiamos flag de
		    BCF	    INTCON,INTF	    ;interrupción por RB0 y salimos.
		    RETFIE

     FIN_TMR0_IN    CALL    DEV_CONTEXT	    ;Devolvemos contexto, limpiamos flag de
		    BCF	    INTCON,T0IF	    ;interrupción por TMR0 y salimos.
		    RETFIE

       FIN_RX_IN    CALL    DEV_CONTEXT	    ;Devolvemos contexto y salimos.
		    RETFIE

     DEV_CONTEXT    SWAPF   STATUS_TEMP,W   ;Devolvución de contexto.
		    MOVWF   STATUS
		    SWAPF   W_TEMP,F
		    SWAPF   W_TEMP,W
		    RETURN

		    END