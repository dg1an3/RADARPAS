;*****************************************************************************
;
;  Copyright (C) 1984, 1985 Logitech.
;		 All Rights Reserved.
;
;  Permission is hereby granted to registered users to use or
;  abstract the following program in the implementation of
;  customized versions. This permission does not include the
;  right to redistribute the source code of this program.
;
;  LOGITECH SA.  CH-1143 Apples,  Switzerland
;
; MODULA-2/86(tm) Run-Time Support (RTS)
;
; Module:	RTS.ASM
;		Mainline of MODULA-2/86 Run-Time Support
;
; Version:	8086 processor, RAM-based,  MS-DOS 2.0 and later
;
; Release:	1.20 - 14-Nov-1985
;
; History:	30-Oct-85 1.20: reading of RTS parameter corrected
;		  and error messages improved, initialization of
;		  error_code corrected, recognition of insufficient
;		  memory for stack before Modula-2 program is started
;		  (Comp_Stack, Load_Err_Mem), RTS stack size reduced,
;		  RTS stack also used for taking dump
;		01-Nov-85 1.20: break vector on AT
;		14-Nov-85 1.20: break vector on AT removed
;
;*****************************************************************************
;
; process descriptors are always allocated at a paragraph address 
;
;*****************************************************************************

CGROUP	group	code
DGROUP	group	data
SGROUP	group	stack

	assume	CS:	CGROUP
	assume	DS:	DGROUP
	assume	ES:	NOTHING
	assume	SS:	SGROUP

	include RTS.INC


;*****************************************************************************

; EXPORT QUALIFIED
;   (* data: variables *)
	public	PC_ID
	public	critical_section
	public	START_MEM, MEM_SIZE
	public	m2_start_mark
	public	m2_end_mark
	public	RTS_PROCESS
	public	cur_proc_addr
	public	cur_process
	public	BASE_PAGE_PTR;
	public	base_page
	public	SAVED_DISK, RTS_DISK
	public	device_mask
	public	error_code
	public	term_proc_addr
	public	old_NMI_vector

;   (* code: procedures, labels *)
	public	DUMMY_ISR
	public	AFTER_RESIDENT
	public	RTS_DS
	public	SYS_RESET
	public	TERMINATE
	public	COMP_STACK
	public	WRITE
	public	WRITE_MSG
	public	WRITE_LN
	public	WRITE_STATUS
	public	NORM_ADDR
	public	GET_CURR_DISK
	public	SELECT_DISK

;   (* stack: end mark *)
	public	rts_stack_end

;***********************************************************************
code	segment public	'code'

;?????????????????????????????????????????????????????????????????????????????
IF FOR_LOD2EXE
; loader not used
;?????????????????????????????????????????????????????????????????????????????
ELSE
;?????????????????????????????????????????????????????????????????????????????
; FROM LOADER IMPORT
	extrn	LoadProg:NEAR		; resident loader
	extrn	Load_Err_Mem: near	; message "insufficient memory"
ENDIF
;?????????????????????????????????????????????????????????????????????????????

; FROM SERVICES IMPORT
	extrn	RTS_BRANCH:NEAR 	; interrupt dispatcher
	extrn	DIV_BY_ZERO:NEAR	; divide by zero handler
	extrn	NMI_server:near 	; interrupts from 8087
	extrn	BREAK:NEAR		; break interrupt handler,
					; vector 1BH
	extrn	STOPPED_23:NEAR 	; ctrl-C interrupt handlers
				 	; vector 23H
; FROM TRANSFER IMPORT
	extrn	REST_I_V:NEAR		; restore interrupt vectors
	extrn	GET_INTERRUPT_MASK:NEAR ; reads the current interrupt mask
	extrn	SET_INTERRUPT_MASK:NEAR ; restores the interrupt mask
; FROM DBUG IMPORT
	extrn	DEBUGGER : near

code	ends
;*****************************************************************************


;*****************************************************************************
data	segment public	'data'

; Workspace of the MAIN process, starting with RTS:

		org	0

cur_process	label	ProcessDescriptor

BASE_PAGE	db	100H dup (?)	; required for the Main-Module
; BASE_PAGE has to be at offset 0 !!!!!!!

; RTS_PROCESS has to be on paragraph boundary. keep it here, and never
; insert any definitions between BASE_PAGE and RTS_PROCESS
RTS_PROCESS	ProcessDescriptor <>

cur_proc_addr	dd	?	; pointer to current process


TOP_OF_MEMORY	equ	word ptr BASE_PAGE+2
				; last RAM paragraph, +1. Set up by DOS loader
TRANS_COM_SIZE	DW	?	; transient part of COMMAND.COM, in paragraphs;
				; differs between DOS 2.X and DOS 3.X.
END_OF_MEMORY	DW	?	; high end of disposable memory (with transient
				;  part of COMMAND.COM taken into account)

RTS_SIZE	DW	?	; set to m2_start_mark - RTS address (i.e. CS).    
m2_start_mark	dw	?	; this two variables show the region of
m2_end_mark	dw	?	; possibly loaded m2 programs

USED_MEM	dw	MAX_MEM_FOR_M2 * 64   
				; corrected to m2_end_mark - m2_start_mark.
FREE_MEM	dw	0	; corrected to END_OF_MEMORY - m2_end_mark.


START_MEM	dw	?	; points behind the loaded modula program
MEM_SIZE	dw	?	; number of available paragraphs at START_MEM

DOS		dd	?	; jump to DOS
START_ADDR	dd	?	; start address of Modula program (.LOD file)
term_proc_addr	dd	term_procedure	; termination procedure

RTS_PARAM_ID	DB	0	; RTSparameter identifier

DOS_VERSION_NR		DW	?	; Result of DOSCALL 30H
PC_ID			db	0FFH	; machine identification
critical_section	dd	?	; pointer to critical section flag
					; of DOS; 

; - saved interrupt vectors -
old_NMI_vector	dd	?
OLD_RTS_VECTOR	dd	?
OLD_DIV0_VECTOR dd	?
OLD_INTO_VECTOR dd	?
OLD_BREAK_VECTOR_23 dd	    ?
old_break_vector dd	 ?
old_interrupt_controller_mask	dw	?
device_mask	dw	?	; initial value is the old interrupt mask
				; of the interrupt controller
				; a device may be enabled/disabled, by setting
				; the corresponding bit to 0/1
				; two functions to do operations on this mask
				; are provided:
				;    get_device_status, set_device_status

error_code	dw	1	; return code to DOS, set upon termination
				; of RTS, using DOS function 4CH
				; initially set to 1 for load errors,
				; reset to 0 just before the Modula-2
				; program is started
				; two functions to set/get the value are
				; provided:
				;    set_error_code, get_error_code

set_CW8087	dw	360H	; init 8087 with interrupts
get_CW8087	dw	0

BASE_PAGE_PTR	dd	BASE_PAGE	; ptr to program segment prefix
MAIN_SP 	dw	?
MAIN_SS 	dw	?

START_DISK	db	?
RTS_DISK	db	?
SAVED_DISK	DB	?

; string constants and jump or index tables
SOME_ERROR	DB	'===> $'

NORMAL_MSG	DB	'normal termination$'
WARNED_MSG	DB	'warning$'
STOP_MSG	DB	'stopped$'
ASSERT_MSG	DB	'wrong assertion$'
HALT_MSG	DB	'HALT called$'
CASE_MSG	DB	'case-tag error$'
STACK_MSG	DB	'stack overflow$'
HEAP_MSG	DB	'heap overflow$'
FCT_ERR_MSG	DB	'function return error$'
ADDR_OVF_MSG	DB	'address overflow$'
REAL_OVF_MSG	DB	'real overflow$'
real_udf_msg	db	'real underflow$'
bad_op_msg	db	'bad operand$'
CARD_OVF_MSG	DB	'cardinal overflow$'
INTEGER_OVF_MSG DB	'integer overflow$'
RANGE_ERR_MSG	DB	'range error$'
ZERO_DIV_MSG	DB	'division by zero$'
PROC_END_MSG	DB	'coroutine end$'
LOAD_MSG	DB	'cannot load$'
CALL_MSG	DB	'unsuccessfull program call$'
NO_PROG_MSG	DB	'program not found$'
NO_MOD_MSG	DB	'module not found$'
INCOMPAT_MSG	DB	'incompatible module keys$'
BAD_FILE_MSG	DB	'bad structure in file$'
ILL_INSTR_MSG	DB	'illegal instruction encountered$'
ILL_FCT_MSG	DB	'illegal RTS call$'
NO_MORE_ISR	DB	'too many concurrent IO-Processes$'

		even
STATUS_MSG	DW	NORMAL_MSG, WARNED_MSG, STOP_MSG, ASSERT_MSG
		DW	HALT_MSG, CASE_MSG, STACK_MSG, HEAP_MSG
		DW	FCT_ERR_MSG, ADDR_OVF_MSG, REAL_OVF_MSG
		dw	real_udf_msg,bad_op_msg,CARD_OVF_MSG 
		DW	INTEGER_OVF_MSG, RANGE_ERR_MSG, ZERO_DIV_MSG
		DW	PROC_END_MSG, LOAD_MSG, CALL_MSG
		DW	NO_PROG_MSG, NO_MOD_MSG, INCOMPAT_MSG, BAD_FILE_MSG
		DW	ILL_INSTR_MSG, ILL_FCT_MSG, NO_MORE_ISR

; RTS parameter error messages
param_err_msg	db	'** Error in M2 parameter: $'

;?????????????????????????????????????????????????????????????????????????????
IF FOR_LOD2EXE
insuff_mem_msg	db	'** Insufficient memory$'
;?????????????????????????????????????????????????????????????????????????????
ELSE
PARAM_EXPCT_MSG	DB	'"u" or "f" expected$'
EQUAL_EXPCT_MSG DB	'"=" expected$'
DIGIT_EXPCT_MSG DB	'Digit expected$'
TOO_HIGH_MSG	DB	'Value too high$'
ENDIF
;?????????????????????????????????????????????????????????????????????????????

TOO_FEW_MEM_MSG DB	'Not enough memory available$'
DOS_TOO_OLD_MSG DB	'** M2 requires DOS 2.0 or later to run$'

data ends
;*****************************************************************************


;*****************************************************************************
stack	segment stack	'stack'

; The stack is used to load and start the Modula-2 program
; and, in case, to take a dump. The Modula-2 program itself
; uses a different stack. 512 bytes of stack are sufficient.

	db	200h dup (?)	; MS-DOS loader will set up stack
rts_stack_end	label	word

stack	ends
;*****************************************************************************


;*****************************************************************************
BIOS	SEGMENT AT	0F000H

	ORG	0FFFEH

ID	DB	?

BIOS	ENDS
;*****************************************************************************


;*****************************************************************************
code segment public	'code'

; We return to DOS through a jump to location 0 of the Program Segment Prefix
; There is no explicit release of memory or stack reset.

; After loading of the RTS, memory has the following structure:
; 0000H   .. 03FFH	    : interrupt vectors
; 0400H   .. DOS_END	    : resident portion of DOS
; DOS_END .. DOS_END + 0FFH : Program Segment Prefix (PSP), set up by DOS
; DOS_END + 100H .. xx	    : Code of RTS
; xx .. yy		    : Data of RTS  ( xx = RTS_DS)
; yy .. zz		    : Stack of RTS
; zz .. end_of_memory - 17K : free memory  ( zz = START_MEM)
; last 17K of RAM	    : DOS command interpreter (COMMAND.COM)

;?????????????????????????????????????????????????????????????????????????????
IF FOR_LOD2EXE

	MTptr	dd	?		; initial module table

	MDescr	struc			; Module Table Entry
	MDname	db	24 dup (?)	; module name
	MDkey	db	6 dup (?)	; key
	MDproc	dw	?		; offset of procedure table
	MDcode	dw	?		; base of code
	MDdata	dw	?		; base of data
	MDprogid dw	?		; 'owner' program id
	MDnext	dd	?		; forward link
	MDprev	dd	?		; backward link
	MDescr	ends

	FFP	dw	?		; first free para
	USEDMEM DW	MAX_MEM_FOR_M2 * 64
	FREEMEM DW	0
	PARAMID DB	0
ENDIF
;?????????????????????????????????????????????????????????????????????????????

RTS_DS	DW	?		; We need a way to set the DS later on

RTS_START:			; start address of the RTS

	push	DS		; base of PSP
	; read and store data-segment of RTS:
	mov	ax,DGROUP
	mov	ES,ax		; point to data segment
	mov	RTS_DS,ax	; (make it easy to access later, in ISR's)
	; copy the PSP into the privat variable BASE_PAGE:
	mov	di,offset BASE_PAGE
	mov	si,0
	mov	cx,size BASE_PAGE
	cld
	rep movsb		; copy PSP into BASE_PAGE
	mov	DS,ax		; now switch to RTS data segment
	; store return point:
	pop	word ptr DOS+2	; set up exit vector, which
	mov	word ptr DOS,0	; goes to PSP:0

;?????????????????????????????????????????????????????????????????????????????
IF FOR_LOD2EXE
; shove the command line over and insert a phoney program name..
	mov	si,80h
	mov	cl,byte ptr [si]
	add	byte ptr [si],2 	; we're going to insert 2 chars
	xor	ch,ch
	add	si,cx			; point to last byte
	lea	di,byte ptr [si+2]	; we'll need room for two more..
	std
	rep movsb			; (whoosh)
	mov	al,'a'
	stosb
	mov	al,' '
	stosb
	cld

; initialize variables USED_MEM, FREE_MEM and RTS_PARAM_ID with respective
; values passed to the LOD2EXE utility (or default values):
	MOV	AX,	      USEDMEM
	MOV	USED_MEM,     AX
	MOV	AX,	      FREEMEM
	MOV	FREE_MEM,     AX
	MOV	AL,	      PARAMID
	MOV	RTS_PARAM_ID, AL
;?????????????????????????????????????????????????????????????????????????????
ELSE
; parse RTS parameters and replace the parameter string in the base page
; Command Line String with spaces. This is done in order for the 'Keyboard'
; and 'DBXInOut' modules, as well as the RTS Loader, to work correctly.
;
; EBNF Syntax assumed for RTSname&Parameters :
; (the RTSname is not contained in the base page)
;
; RTSname&Parameters = RTSnamespace{space}[parameter_string].
; parameter_string   = "/"RTSparameter
; RTSparameter	     = memory_parameter
; memory_parameter   = used_memory|free_memory.
; used_memory	     = ("U"|"u")"="amount.
; free_memory	     = ("F"|"f")"="amount.
; amount	     = digit[digit[digit[digit]]].
; digit 	     = "0"| ... |"9".
; space 	     = " ".
;
; amount stands for amount of memory (in Kilo bytes) to be used 
; respectively to be kept free.

;	skip leading spaces:
	XOR	CH,	CH
	MOV	SI,	80H
	MOV	CL,	DS:[SI] 	; length of command line string
	INC	SI			; set to first character of string
	TEST	CL,	CL
	JNZ	SKIP_SPACES
	JMP	END_RTS_PARAMETERS	; no RTSparameter specified

SKIP_SPACES:
	LODSB
	CMP	AL, ' '
	LOOPE	SKIP_SPACES

	JNZ	PARSE_DELIMITER
	JMP	END_RTS_PARAMETERS	; no RTSparameter specified

;	parse madatory parameter_string delimiter '/':
PARSE_DELIMITER:
	CMP	AL, '/'
	JE	PARSE_RTS_PARAM
	JMP	END_RTS_PARAMETERS	; no RTSparameter specified

PARSE_RTS_PARAM:
	MOV	DX,	OFFSET PARAM_EXPCT_MSG
	LODSB
	test	cx,	cx
	JZ	RTS_PARAM_ERROR		; "u" or "f" expected
					
;	capitalize RTS parameter identifier (alphabetic), save it and
;	check if memory_parameter identifier:
	CMP	AL,	'a'
	JB	CAP_OK
	SUB	AL,	20H
CAP_OK: MOV	RTS_PARAM_ID	,AL
	CMP	AL,	'U'
	JE	PARSE_MEM_PARAM
	CMP	AL,	'F'
	JNE	RTS_PARAM_ERROR		; "u" or "f" expected

;	parse rest of memory_parameter:
PARSE_MEM_PARAM:
	MOV	DX,	OFFSET EQUAL_EXPCT_MSG
	LODSB
	DEC	CX
	JZ	RTS_PARAM_ERROR		; "=" expected
					
;	parse '=':
	CMP	AL, '='
	JNE	RTS_PARAM_ERROR		; "=" expected
					
;	parse amount:
	MOV	DX,	OFFSET DIGIT_EXPCT_MSG
	XOR	AH,	AH		; AL is loaded with digit
	LODSB				; load first digit
	DEC	CX
	JZ	RTS_PARAM_ERROR		; digit expected
	XOR	DI,	DI		; used to compute memory_amount
	MOV	BX,	10		; decimal digit weight
READ_AMOUNT:	
	MOV	DX,	OFFSET DIGIT_EXPCT_MSG
	SUB	AL,	'0'
	JB	RTS_PARAM_ERROR		; digit expected
	CMP	AL,	9	      
	JA	RTS_PARAM_ERROR		; digit expected
	PUSH	AX
	MOV	AX,	DI
	MUL	BX
	MOV	DX,	OFFSET TOO_HIGH_MSG
	JC	RTS_PARAM_ERROR		; value higher than 65'535
	POP	DI
	ADD	DI,	AX
	JC	RTS_PARAM_ERROR		; value higher than 65'535
	XOR	AH,	AH		; AL is loaded with digit
	LODSB				; load next digit
	CMP	AL,	' '
	JE	CHECK_AMOUNT
	LOOP	READ_AMOUNT

;	compare amount with MAX_MEM_FOR_M2 (see RTS.INC)
CHECK_AMOUNT:
	CMP	DI,	MAX_MEM_FOR_M2
	JA	RTS_PARAM_ERROR		; value too high

;	transform amount into paragraphs and store it into USED_MEM 
;	respectively FREE_MEM:
	MOV	CL,	6
	SHL	DI,	CL
	CMP	RTS_PARAM_ID, 'U'
	JNE	SET_FREE_MEM
	MOV	USED_MEM, DI
	JMP	END_MEM_PARAMETERS
SET_FREE_MEM:
	MOV	FREE_MEM, DI
END_MEM_PARAMETERS:
;	overwrite parameter_string with spaces
	MOV	DI,	81H
	SUB	SI,	DI		; length of RTSparameter, incl. 
	MOV	CX,	SI		; leading spaces
	MOV	AL,	' '
REP	STOSB

ENDIF
;?????????????????????????????????????????????????????????????????????????????

	JMP	END_RTS_PARAMETERS
RTS_PARAM_ERROR:
	; error in RTS parameter (or because of its value)
	push	dx
	mov	dx, offset param_err_msg
	call	write_msg
	pop	dx
RTS_ERROR_EXIT:
	; write error message to screen, jump to SYS_RESET
	CALL	WRITE_MSG
	CALL	WRITE_LN
	JMP	SYS_RESET
END_RTS_PARAMETERS:

	; get DOS version number:
	MOV	AH,	30H
	INT	OS
	MOV	DOS_VERSION_NR, AX
	CMP	AL,	2
	JNB	GET_PC_ID
	MOV	DX,	OFFSET DOS_TOO_OLD_MSG
	JMP	RTS_ERROR_EXIT

	; get machine identification:
GET_PC_ID:
	push	es
	mov	ax, bios
	mov	es, ax
	mov	al, es:ID
	mov	PC_ID, al
	pop	es

	; get address of critical section flag of DOS:
	call	Get_Critical_Section

	; Find the current disk:
	CALL	GET_CURR_DISK
	mov	START_DISK,	al	; save for Postmortem dump
	mov	RTS_DISK,	al

	STI			; Allow interruptions

;-------------------------------------------------------
;	      Initial Memory Allocation
;-------------------------------------------------------
;	compute TRANS_COM_SIZE:
	CMP	BYTE PTR DOS_VERSION_NR,2
	JA	DOS_3
	MOV	TRANS_COM_SIZE, 	DOS_2_COM_SIZE
	JMP	COMPUTE_END_OF_MEMORY
DOS_3:	MOV	TRANS_COM_SIZE, 	DOS_3_COM_SIZE

;	compute END_OF_MEMORY:
COMPUTE_END_OF_MEMORY:
	MOV	AX,	TOP_OF_MEMORY

	cmp	RTS_PARAM_ID, 0
	jne	goon
	SUB	AX,	TRANS_COM_SIZE
	; no parameter specified, so keep command.com in memory
goon:
	MOV	END_OF_MEMORY,	AX

;	compute m2_start_mark:	      
	mov	m2_start_mark,	SS	; bottom of last segment ..
	mov	AX,	sp
	mov	cl,	4
	shr	AX,	cl		; plus paragraphs of stack..
	add	AX,	10		; (plus fudge factor..)
	add	m2_start_mark,	AX	; ..gives first free paragraph
					;   after the RTS
	mov	BX, m2_start_mark

; process USED_MEM:
;	compute memory allocated to RTS available to MODULA-2 appl.:
	MOV	AX,	END_OF_MEMORY
	SUB	AX,	BX
;	check if RTS memory_parameter used_memory was specified:
	CMP	RTS_PARAM_ID,	'U'
	JE	CHECK_MEMORY
	CMP	RTS_PARAM_ID,	'F'
	JNE	CHECK_MAX_MEM_FOR_M2
;	reserve the highest paragraph of USED_MEM for memory control block
;	built by DOS when another DOS application, invoked by a DOSCALL,
;	claims FREE_MEM:
	DEC	AX
	JMP	CHECK_MAX_MEM_FOR_M2
;	check if enough memory available:
CHECK_MEMORY:
	CMP	AX,	USED_MEM
	JNB	USED_MEM_OK
	MOV	DX,	OFFSET TOO_FEW_MEM_MSG
	JMP	RTS_PARAM_ERROR		; not enough memory available
;	compare memory available with MAX_MEM_FOR_M2 (see RTS.INC)
CHECK_MAX_MEM_FOR_M2:
	MOV	DI,	MAX_MEM_FOR_M2
	MOV	CL,	6
	SHL	DI,	CL
	CMP	AX,	DI
	JNA	CORRECT_USED_MEM
	MOV	AX,	DI
;	set USED_MEM:
CORRECT_USED_MEM:
	MOV	USED_MEM, AX
USED_MEM_OK:
	MOV	AX,	USED_MEM

;	compute m2_end_mark:
	ADD	BX,	AX
	MOV	m2_end_mark, BX

; process FREE_MEM; correct USED_MEM and m2_end_mark:
;	compute memory left to dispose of in any case:
	MOV	CX,	END_OF_MEMORY
	SUB	CX,	BX
;	check if RTS memory parameter free_mem was specified:
	CMP	RTS_PARAM_ID,	'F'
	JNE	CORRECT_FREE_MEM
;	check if enough memory available:
	DEC	CX			; for DOS memory control block
	CMP	CX,	FREE_MEM
	JNB	CORRECT_FREE_MEM
;	USED_MEM may also be disposed of:
	ADD	CX,	USED_MEM
	CMP	CX,	FREE_MEM
	JNB	CORRECT_MARKS
	MOV	DX,	OFFSET TOO_FEW_MEM_MSG
	JMP	RTS_PARAM_ERROR		; too few memory left
CORRECT_MARKS:
	MOV	AX,	END_OF_MEMORY
	SUB	AX,	FREE_MEM
	DEC	AX			; for DOS memory control block
	MOV	m2_end_mark, AX
	SUB	AX,	m2_start_mark
	MOV	USED_MEM, AX
	JMP	COMPUTE_RTS_SIZE
CORRECT_FREE_MEM:			
	MOV	FREE_MEM, CX

;	compute RTS_SIZE:
COMPUTE_RTS_SIZE:
	MOV	BX,	m2_start_mark
	MOV	CX,	WORD PTR DOS+2	; PSP Segment address 
	SUB	BX,	CX
	MOV	RTS_SIZE, BX

;	deallocate from RTS any memory not needed
	ADD	BX,	AX
	MOV	AH,	4AH
	MOV	ES,	CX
	INT	OS
	PUSH	DS
	POP	ES
FREE_MEM_OK:

; compute START_MEM:
IF FOR_LOD2EXE
;	START_MEM points to the start of the heap: 
	MOV	BX,	FFP
ELSE
;	START_MEM will be updated by loader:
	MOV	BX,	m2_start_mark
ENDIF
	MOV	START_MEM, BX
      
; compute MEM_SIZE:
	MOV	AX,	m2_end_mark
	SUB	AX,	BX
	MOV	MEM_SIZE,  AX		  





; initialize cur_proc_addr with normalized address of RTS_PROCESS
; where the offset is calculated to 0 (if not ERROR !!!!!!!)
	mov	bx,ds
	mov	ax,offset rts_process
	call	norm_addr
	mov	word ptr cur_proc_addr,ax
	mov	word ptr cur_proc_addr + 2,bx

;?????????????????????????????????????????????????????????????????????????????
IF FOR_LOD2EXE
; get module table pointer, find start address
	les	bx, MTptr
	mov	m2_start_mark, ES
	mov	word ptr RTS_PROCESS.PD_MOD_TABLE, bx
	mov	word ptr RTS_PROCESS.PD_MOD_TABLE+2,ES
	mov	si, ES:MDproc[bx]		; get offset to proc table
	mov	ES, ES:MDcode[bx]		; code segment (of proc tab)
	mov	AX, ES:word ptr 2[si]		; get starting offset
	mov	word ptr START_ADDR, ax
	mov	word ptr START_ADDR+2, ES
;?????????????????????????????????????????????????????????????????????????????
ELSE
;?????????????????????????????????????????????????????????????????????????????
; Load the Modula-2 program to run. It will be loaded at START_MEM and
; START_MEM will be updated to point behind that loaded program:
;
	mov	ax,RTS_PROCESS.PD_PROG_ID	; AX = current prog id
	mov	dx,word ptr RTS_PROCESS.PD_MOD_TABLE
	mov	cx,word ptr RTS_PROCESS.PD_MOD_TABLE+2	; CX:DX = old mod tab
	call	LoadProg			; load it and return error
						; code in BX (0=ok).
	mov	word ptr RTS_PROCESS.PD_MOD_TABLE,dx
	mov	word ptr RTS_PROCESS.PD_MOD_TABLE+2,cx	; CX:DX = new mod tab
	mov	word ptr START_ADDR,di
	mov	word ptr START_ADDR+2,ES	; ES:DI = start address
	test	bx,bx				; load ok?
	jz	LOADED				;   yes
	jmp	SYS_RESET				;   no
ENDIF
;?????????????????????????????????????????????????????????????????????????????

LOADED:
; At this point START_MEM is the first free paragraph after code and data
; of the Modula program. This space will be used for heap (starting at
; the lowest address) and for stack (starting at the high end of memory).

; Switch to real run-time stack. The stack of the main process is set
; to the end of the free memory:
	MOV	AX,	MEM_SIZE
	MOV	BX,	START_MEM
	CALL	COMP_STACK		; BX becomes SS, AX becomes SP
	cmp	bx,	0
	jnz	stack_ok
;?????????????????????????????????????????????????????????????????????????????
IF FOR_LOD2EXE
	mov	dx,	offset insuff_mem_msg
	jmp	RTS_ERROR_EXIT
;?????????????????????????????????????????????????????????????????????????????
ELSE
;?????????????????????????????????????????????????????????????????????????????
	call	Load_Err_Mem		; insufficient memory
	jmp	sys_reset
ENDIF
;?????????????????????????????????????????????????????????????????????????????
stack_ok:
	MOV	MAIN_SS, BX
	MOV	MAIN_SP, AX
	MOV	SS, BX			; No need to disable Interrupts,
	MOV	SP, AX			; the processor does it here


;-------------------------------------------------------
; Fill in the Default Process Descriptor:
;-------------------------------------------------------

	; First we put the Return Address in RTS on the
	; Stack. It will be used in case of an error
	; in the Main program.
	PUSHF
	PUSH	CS
	MOV	AX,	OFFSET	AFTER_RESIDENT
	PUSH	AX
	PUSH	BP


	; Now put all the significant registers at
	; their places in P.D:
	PUSHF
	POP	RTS_PROCESS.PD_FLAGS
	MOV	RTS_PROCESS.PD_SP, SP
	MOV	RTS_PROCESS.PD_SS, SS
	MOV	RTS_PROCESS.PD_DS, DS

	; and the initial values for the heap managment:
	MOV	AX,	START_MEM			; Paragraph addr
	MOV	word ptr RTS_PROCESS.PD_HEAP_BASE + 2,AX ; first para of heap
	MOV	word ptr RTS_PROCESS.PD_HEAP_TOP + 2,AX ; top para. of heap
	; Only the minimum is done here, to be as
	; independant from the implementation of the
	; heap manager as possible. See also NEW_PROCESS

	; Set all the values needed for TRANSFER
	; and error handling:
	MOV	RTS_PROCESS.PD_dbug_status,0	; for debugger
	MOV	word ptr RTS_PROCESS.PD_PROG_END,	SP
	MOV	word ptr RTS_PROCESS.PD_PROG_END+2,	SS


;-------------------------------------------------------
; Prepare the interrupt system:
;-------------------------------------------------------

	CALL	GET_INTERRUPT_MASK
	MOV	rts_process.PD_PRIO_MASK, 0		; no priority
	MOV	old_interrupt_controller_mask,AX	; save it
	mov	device_mask, AX 		; initial value

	; Compute physical address of RTS vector:
	mov	bx,RTS_INT*4
	MOV	AX, 0
	MOV	ES, AX

	; Set entry point for RTS-interrupt-vector:
	MOV	AX,	ES: [BX]		; Save the old value
	MOV	word ptr OLD_RTS_VECTOR,		AX
	MOV	AX,	ES: 2[BX]
	MOV	word ptr OLD_RTS_VECTOR + 2,	AX
	MOV	ES:word ptr [BX], offset RTS_BRANCH
	MOV	ES:word ptr 2[BX], CS		; Set the new-one

	; Interrupt vector 0, used for 'divide by zero':
	mov	bx,0*4
	mov	ax,ES:[bx]	; Save the old value
	mov	word ptr OLD_DIV0_VECTOR, ax
	mov	ax,ES:2[bx]
	mov	word ptr OLD_DIV0_VECTOR	+ 2,ax
	mov	ES:word ptr 2[bx], CS	; Set the new-one
	mov	ES:word ptr[bx], offset DIV_BY_ZERO

	; Interrupt vector 4 (used for INTO) has also
	; to point to the RTS:
	mov	bx,4*4
	MOV	AX, ES:[bx]		; Save the old value
	MOV	word ptr OLD_INTO_VECTOR, AX
	MOV	AX, ES:2[bx]
	MOV	word ptr OLD_INTO_VECTOR	+ 2,	AX
	MOV	ES:word ptr [bx], offset RTS_BRANCH
	MOV	ES:word ptr 2[bx], CS		; Set the new-one
	; Note, that there is no special entry for the
	; interrupt on overflow. The calling program
	; has to set the function code in AX as for the
	; other RTS calls. Needed, because an overflow
	; may occur in several error conditions
	; (INTEGER, CARDINAL, SUBRANGE...)

	; Interrupt vector 2, used for '8087 interrupts':
	esc	1cH,BX		; FNINIT: clear and init 8087
	esc	0DH,set_CW8087	; FLDCW: set ctrl word interrupt enabled
	esc	0FH,get_CW8087	; FNSTCW: read it again
; save old value in any case, it is always restored 
	mov	bx,2*4
	mov	ax,ES:[bx]	; Save the old value
	mov	word ptr old_NMI_vector, ax
	mov	ax,ES:2[bx]
	mov	word ptr old_NMI_vector + 2,ax
	mov	ax,set_CW8087	; simulate WAIT (dont execute it!!)
	mov	ax,set_CW8087
	mov	ax,set_CW8087
	mov	ax,set_CW8087
	cmp	ax,get_CW8087	; if equal, the 8087 is assumed present
	jne	No8087
; install interrupt service routine only if 8087 is present
	mov	ES:word ptr 2[bx], CS	; Set the new-one
	mov	ES:word ptr[bx], offset NMI_server
No8087:

	; Interrupt vector 1BH used for BREAK
	; has also to point to the RTS:
	mov	bx, 4 * 1BH
	MOV	AX, ES:[bx]		; Save the old value
	MOV	word ptr old_break_vector, AX
	MOV	AX, ES:2[bx]
	MOV	word ptr old_break_vector + 2,	     AX
	MOV	ES:word ptr [bx], offset BREAK
	MOV	ES:word ptr 2[bx], CS		; Set the new-one

	; Interrupt vector 23H (used for ^C) has also
	; to point to the RTS:
	mov	bx,4*23H
	MOV	AX, ES:[bx]		; Save the old value
	MOV	word ptr OLD_BREAK_VECTOR_23, AX
	MOV	AX, ES:2[bx]
	MOV	word ptr OLD_BREAK_VECTOR_23 + 2,	AX
	MOV	ES:word ptr [bx], offset stopped_23
	MOV	ES:word ptr 2[bx], CS		; Set the new-one



;-------------------------------------------------------
; Call the MODULA program:
;-------------------------------------------------------

	xor	ax,	ax			; AX = 0
		; reset error_code:
	mov	word ptr error_code,	ax	; error_code = 0
		; For debugger, to detect first
		; procedure in calling sequence:
	mov	bp,	ax			; BP = 0

CALL_RESIDENT:
	CALL	START_ADDR			; call loaded program

; We are back from the MODULA program.

AFTER_RESIDENT: 
	; if program terminated normally, we came here not through
	; an interrupt, but by a RET instruction (therefore interrupts
	; are enabled:
	CLI
	MOV	DS, RTS_DS			; restore data segment

	; Restore the old interrupt vectors for every IO-Process,
	; waiting on an interrupt:
	mov	ax,word ptr cur_proc_addr + 2
	mov	es,ax
; May 30'85 V 1.14
;   not necessary and even wrong for termination procedures,
;   that check on current program identifier, which still
;   should remain 1
;	mov	ES:CUR_PROCESS.PD_PROG_ID, 0
;			 ; 0 as program id is a sort of a joker.

	; Restore the old Interrupt Mask:
	mov	ES:CUR_PROCESS.PD_PRIO_MASK, 0	; no priority
	MOV	AX,	old_interrupt_controller_mask
	CALL	SET_INTERRUPT_MASK

	CALL	REST_I_V

	; set break vector to a dummy interrupt service routine,
	; because the following write functions will enable
	; interrupts; we don't want to be interrupted by a ^break
	mov	ax, 0
	mov	es, ax
	mov	bx, 4 * 1BH
	MOV	ES:word ptr [bx], offset DUMMY_ISR
	MOV	ES:word ptr 2[bx], CS		; Set the new-one

	mov	ax,word ptr cur_proc_addr + 2
	mov	es,ax
	MOV	AX,ES: CUR_PROCESS.PD_STATUS
	test	ax,ax
	jz	RTS_END 			; 0 = No error
	mov	error_code, 1			; indicates status<>normal
	CALL	WRITE_LN
	MOV	DX,OFFSET SOME_ERROR
	CALL	WRITE_MSG
	MOV	BX,ES:CUR_PROCESS.PD_STATUS
	CALL	WRITE_STATUS
	CALL	WRITE_LN
	; It is safer to return to DOS and possibly reload the
	; RTS rather then restarting its execution, since the
	; code might have been overwritten.

;-------------------------------------------------------
; Back from the MODULA program:
;-------------------------------------------------------

RTS_END:

CallTermProc:
;============
; this 'procedure' is the equivalent to 'CallTermProc' in module
; 'System'. It has to be repeated here, because the termination
; of the base layer does not pass through module 'Program', and
; therefore 'System.CallTermProc' is not called

	mov	ds,rts_ds	; set data segment
	mov	ax,word ptr term_proc_addr + 2	; segement addr
	mov	bx,cs
	cmp	ax,bx
	je	CallTermProc_end	; OwnTermProc
	call	term_proc_addr	; invoke termination procedure
	jmp	CallTermProc
CallTermProc_end:

; Restore the modified interrupt vectors
;	mov	ds,rts_ds
	MOV	AX,	0
	MOV	ES,	AX
	MOV	BX,	RTS_INT*4
	MOV	AX,word ptr OLD_RTS_VECTOR		; The RTS entry
	MOV	ES:word ptr [BX],AX
	MOV	AX,word ptr OLD_RTS_VECTOR + 2
	MOV	ES:word ptr [BX]+2,AX
	MOV	AX,word ptr OLD_DIV0_VECTOR		; The entry for DIV0
	MOV	ES:word ptr 0, AX
	MOV	AX,word ptr OLD_DIV0_VECTOR	+ 2
	MOV	ES:word ptr 2, AX
	MOV	AX,word ptr OLD_INTO_VECTOR		; The entry for INTO
	MOV	ES:word ptr 16, AX
	MOV	AX,word ptr OLD_INTO_VECTOR	+ 2
	MOV	ES:word ptr 18, AX
	MOV	AX,word ptr old_NMI_vector	; The entry for NMI
	MOV	ES:word ptr 4*2, AX
	MOV	AX,word ptr old_NMI_vector + 2
	MOV	ES:word ptr 4*2 + 2, AX

	mov	bx, 4 * 1BH			; vector 1BH
	MOV	AX,word ptr old_break_vector	; The entry for BREAK
	MOV	ES:word ptr [BX], AX
	MOV	AX,word ptr old_break_vector + 2
	MOV	ES:word ptr [BX] + 2, AX

	MOV	AX,word ptr OLD_BREAK_VECTOR_23 ; The entry for BREAK 23H
	MOV	ES:word ptr 4*23H, AX
	MOV	AX,word ptr OLD_BREAK_VECTOR_23 + 2
	MOV	ES:word ptr 4*23H + 2, AX

	; select the same drive that was selected at beginning:
	MOV	DL,	START_DISK
	CALL	SELECT_DISK

SYS_RESET:

	mov	ax, error_code	; only lower byte
	mov	ah, 4CH 	; highbyte of error_code discarded
	int	os
;	jmp	DOS		; Back to DOS


;-------------------------------------------------------
;	Termination procedure, called after end of main
;	program. If System announced one, then this is
;	called, else an empty procedure is called
;-------------------------------------------------------
Term_Procedure	proc far		; MUST be FAR !!!!!
		ret
Term_Procedure	endp


; We arrive here, when a program is terminated (exept level 0) or
; if any error had occured. In the former case, status is 'normal',
; in the latter case the error-code is set in the Status-field of
; Current Process Descriptor.



TERMINATE:
;=========
	MOV	DS, RTS_DS

	; Free the resources, managed by RTS:
	CALL	REST_I_V			; only Interrupt Vectors

	; Call the debugger in any case. It will take an
	; action according to status and presence or absence
	; of a run-time debugger:
	CALL	DEBUGGER

TERMINATION:
	MOV	DS,	CS:RTS_DS
	mov	ax,word ptr cur_proc_addr + 2
	mov	ds,ax
	; Prepare return:
	MOV	SS,word ptr CUR_PROCESS.PD_PROG_END+2
	MOV	SP,word ptr CUR_PROCESS.PD_PROG_END
	POP	BP	; BP of Father Program

DUMMY_ISR:	; we use the following IRET also for
		; a dummy interrupt service routine

	IRET		; from here we go either to Get_Old_Program
			; or to After_Resident


;------------------------------------------------------
; Some Utilities:
;------------------------------------------------------


;	public	COMP_STACK
COMP_STACK:
	; Upon Entry:
	;  AX holds size of free memory (in paragraphs)
	;  BX holds (paragraph) start address of free memory
	; Upon Exit:
	;  AX holds SP and BX holds SS
	;  If there is not enough space for a minimal stack,
	;  BX is set to 0 (a value it never has otherwise)
	;  indicating "not enough memory". This routine must
	;  not raise a stack overflow, because the dump would
	;  be bad. The caller must take the appropriate action.
	; Policy:
	;  Set STACK to the end of memory. Check if
	;  there is room for a minimal stack.
	CMP	AX,	1000H
	JBE	SMALL_MEM
	; There is more than 64K of free memory:
	SUB	AX,	1000H
	ADD	BX,	AX
			; Set SS to end of memory - 64K
	MOV	AX,	0
			; and SP to 0
	RET
SMALL_MEM:
	; Less than 64K of free memory
	; SS is start of free memory
	MOV	CL,	4
	SHL	AX,	CL
		; SP is length * 16
	CMP	AX,	SP_INI_SIZE + SP_RESERVE + 4
		; 4 is for the call of the Modula program
	JAE	LARGE_ENOUGH
	xor	bx,	bx	; set BX to 0
		; Not enough for initial stack and
		; for some reserve!
LARGE_ENOUGH:
	RET




;	public	WRITE

WRITE:
; The character to be printed is in DL
	MOV	AH,	2	; Console Output
	INT	OS
	RET

;	public	WRITE_MSG

WRITE_MSG:
; The address of the message is in DS:DX
	MOV	AH,	9	; Print String
	INT	OS
	RET

;	public	WRITE_LN

WRITE_LN:
	MOV	DL,	0DH	; Print CR
	CALL WRITE
	MOV	DL,	0AH	; Print LF
	CALL WRITE
	RET

;	public	WRITE_STATUS

WRITE_STATUS:
	; prints on the screen the meaning of a
	; program status (passed in BL):
	push	bx
	MOV	DL, ' '
	CALL	WRITE
	pop	bx
	xor	bh,bh
	ADD	BX, BX
	MOV	DX, STATUS_MSG [BX]
	CALL	WRITE_MSG
	RET


;	public	NORM_ADDR
	
NORM_ADDR:
	; To normalize a address with segment and offset,
	; i.e the segment value is as large as possible
	; and the offset is smaller than 16.
	; Upon entry:
	;  BX holds the old segment and AX the old offset.
	; Upon exit:
	;  BX holds the normalized segment and AX the offset.
	;  If an overflow occurs, the 'CF' flag is set.
	MOV	DX,	AX
	AND	AX,	0FH
	MOV	CL,	4
	SHR	DX,	CL
	ADD	BX,	DX
	RET


;	public	GET_CURR_DISK

Get_Critical_Section:
	push	es
	push	bx
	mov	ah,	34H
	int	OS
	mov	word ptr critical_section, BX
	mov	word ptr critical_section + 2, ES
	pop	bx
	pop	es
	ret
	

GET_CURR_DISK:
	; gets the currently logged in disk and stores
	; the value in the variable 'SAVED_DISK'
	mov	ah,	25
	int	OS
	mov	SAVED_DISK,	al
	ret

;	public	SELECT_DISK

SELECT_DISK:
; the drive to be selected is passed in DL
	mov	ah,	14
	int	OS
	ret


code ends

;*****************************************************************************




	end RTS_START	; defines startaddress of the RTS
