;*****************************************************************
;
;  Copyrigth (C) 1984, 1985 Logitech.
;		 All Rights Reserved.
;
;  Permission is hereby granted to registered users to use or
;  abstract the following program in the implementation of
;  customized versions. This permission does not include the
;  right to redistribute the source code of this program.
;
;  LOGITECH SA.  CH-1143 Apples, Switzerland
;
; MODULA-2/86(tm) Run-Time Support (RTS)
;
; Module:	TRANSFER.ASM
;		Handles Interrupts and Processes
;
; Version:	8086 processor, RAM-based, MS-DOS 2.0 and later
;
; Release:	1.20 - 14-Nov-85
;
; History:	01-Oct-85 1.20: improved (IO)TRANSFER,
;		  Install_ISR, UninstallISR
;		31-Oct-85 1.20: NEWPROCESS improved and initial
;		  stack test corrected, break handling moved to
;		  module SERVICES.ASM
;		14-Nov-85 1.20: CLD before REP MOVS etc
;
;*****************************************************************


CGROUP	group	code
DGROUP	group	data

	assume	CS:	CGROUP
	assume	DS:	DGROUP
	assume	ES:	NOTHING
	assume	SS:	NOTHING

	include	RTS.INC


;*****************************************************************

; EXPORT QUALIFIED
	public	GET_INTERRUPT_MASK
	public	SET_INTERRUPT_MASK
	public	SEND_EOI
	public	TRANSFER
	public	IOTRANSFER
	public	NEWPROCESS
	public	MON_ENTRY, MON_EXIT
	public	LISTEN
	public	get_device_status
	public	set_device_status
	public	REST_I_V
	public	FREE_INT_VECT
	public	Install_ISR
	public	Uninstall_ISR

;*****************************************************************

data	segment	public	'data'

; FROM RTS IMPORT
	extrn	cur_proc_addr:dword
	extrn	device_mask:word
	extrn	cur_process:word

data	ends

;*****************************************************************

code	segment	public	'code'

; FROM RTS IMPORT
	extrn	RTS_DS:word		; part of code segment
	extrn	NORM_ADDR:near
	extrn	TERMINATE:near

; FROM SERVICES IMPORT
	extrn	SAVE_CPU_INFO:near
	extrn	STACK_OVF:near

code	ends

;*****************************************************************

data segment public	'data'

; Here are the definitions related to Interrupts. These original
; values are valid for IBM-PC / IBM-XT. If you run the Modula-2/86
; System on another hardware, it is possible, that the values in the
; declarations below, three routines 'GET_INTERRUPT_MASK, 'SEND_EOI',
; 'SET_INTERRUPT_MASK and as well as some code inside 'TRANSFER' and
; 'COM_ISR' are to be modified.

; The following points should be checked out:
; a) Is there an interrupt controller in your machine (chip number is
;    typically 8259)? The declarations and the three routines below
;    handle this interrupt controller. If no such chip is present, the
;    values of the declarations have no importance and the corresponding
;    part in the three routines has to be selected.
; b) Is Input/Output to the interrupt controller done through I/O-ports
;    or is it memory-mapped (i.e. the registers of the interrupt controller
;    have fixed memory addresses)? Select the corresponding part in the
;    three routines.
; c) Which ports are used for the interrupt controller, or which memory
;    addresses are used (if memory-mapped)? Change the declarations
;    accordingly.
; d) How are the priorities distributed? In the array 'PRIORITY_MASKS'
;    below there is the interrupt mask for every priority level.
;    A priority is the number that can be given to a Modula-2 module (in
;    the module header, e.g: MODULE CriticalRegion [7]; to give priority 7).
;    The given priority is used as an index in the array 'PRIORITY_MASKS'
;    to select the corresponding interrupt mask.

; NOTE WELL: The Modula-2 Run-Time-Support does read the interrupt mask,
;	even if you do not intend to use IOTRANSFER or priority modules.
;	If this distributed version does not correspond to the character-
;	istics of your machine, the required adaptation must be done.
;	Alternatively you can select the part in the three routines that
;	has to be used if no interrupt controller is present.



	MASK_8259	EQU	21H
	; Port address of control word 1 in Interrupt Controller.
	; This port is used to read and write the interrupt mask.
	; See routines 'GET_INTERRUPT_MASK' and 'SET_INTERRUPT_MASK'
	; below.

	CTRL_W2_8259	EQU	20H
	; Port address of control word 2 in Interrupt Controller.
	; This port is used to send the End-Of-Interrupt code.
	; See routine SEND_EOI below.

	IO_SEGMENT	EQU	0H
	; Segment-Register value to access memory-mapped I/O ports.
	; For machines without memory mapping, this value has no
	; meaning.

	EOI_8259	EQU	20H
	; End-Of-Interrupt code for the Interrupt Controller.
	; Used in routine SEND_EOI below.

	MAX_PRIO_LEVEL	EQU	07H
	; Maximum priority handled by the Run-Time-Support.
	; Priority levels are: 0..MAX_PRIO_LEVEL.
	; If this value is changed, the corresponding parameter
	; in the compiler parameter module has to be adapted too
	; (compiler module 'COMPPARA').

PRIORITY_MASKS	DB	80H,0C0H,0E0H,0F0H,0F8H,0FCH,0FEH,0FFH
	; This ARRAY holds for every priority level the
	; priority mask, which has to become effective
	; during execution of a priority module.
	; The values in this mask may be modified, to
	; implement any desired priority schema.
	; Priority 0 corresponds to the first element in
	; this array, priority 7 to the last.
	; no priority corresponds to a mask with all bits zero

data	ends

;*****************************************************************

code segment public	'code'


; Insert statements of procedure bodies at marked positions!
; These positions are marked:

;**** Here the code of GET_INTERRUPT_MASK has been inserted :
;**** Here the code of SET_INTERRUPT_MASK has been inserted :
;**** Here the code of SEND_IO has been inserted :

;**** End of insertion

; This solution has been chosen to avoid procedure call overhead
; in such time critical routines as TRANSFER ,IOTRANSFER, ISR.


;------------------------------------------------------------
;	public	GET_INTERRUPT_MASK

; This routine returns in AX the currently valid interrupt mask.
; The following registers may be used here: AX, DX, DI, ES.
; If other registers are used, they must be saved and restored.

; The following code sequence has to be used on a hardware
; with I/O through port, where the port address is below 100H:
GET_INTERRUPT_MASK	proc	near
	IN	AL,	MASK_8259
	XOR	AH,	AH
	RET
GET_INTERRUPT_MASK	endp

; The following code sequence has to be used on a hardware
; with I/O through port, where the port address is above 100H:
;GET_INTERRUPT_MASK	proc	near
;	MOV	DX,	MASK_8259
;	IN	AL,	DX
;	XOR	AH,	AH
;	RET
;GET_INTERRUPT_MASK	endp

; The following code sequence has to be used on a hardware
; with memory-mapped Input/Output:
;GET_INTERRUPT_MASK	proc	near
;	MOV	AX,	IO_SEGMENT
;	MOV	ES,	AX
;	MOV	DI,	MASK_8259
;	MOV	AL,	ES: [DI]
;	XOR	AH,	AH
;	RET
;GET_INTERRUPT_MASK	endp

; If your application program does not use interrupts nor
; priority modules, or if there is no interrupt controller
; present, this routine may return a dummy constant value.
; In that case, the code here could be:
; GET_INTERRUPT_MASK	 proc	 near
;	MOV	AX,	0
;	RET
; GET_INTERRUPT_MASK	 endp


;------------------------------------------------------------
;	public	SET_INTERRUPT_MASK

; This routine sends the interrupt mask to the interrupt
; controller.
; the mask sent to the interrupt controller is the logical OR
; of the device_mask and the given priority mask in AL.
; The following registers may be used here: AX, DX, DI, ES.
; If other registers are used, they must be saved and restored.

; The following code sequence has to be used on a hardware
; with I/O through port, where the port address is below 100H:
SET_INTERRUPT_MASK     proc    near
	mov	es, rts_ds
	or	ax, es: device_mask
	OUT	MASK_8259,	AL
	RET
SET_INTERRUPT_MASK     endp

; The following code sequence has to be used on a hardware
; with I/O through port, where the port address is above 100H:
;SET_INTERRUPT_MASK	proc	near
;	mov	es, rts_ds
;	or	ax, es: device_mask
;	MOV	DX,	MASK_8259
;	OUT	DX,	AL
;	RET
;SET_INTERRUPT_MASK	endp

; The following code sequence has to be used on a hardware
; with memory-mapped Input/Output:
;SET_INTERRUPT_MASK	proc	near
;	mov	es, rts_ds
;	or	ax, es: device_mask
;	MOV	DI,	IO_SEGMENT
;	MOV	ES,	DI
;	MOV	DI,	MASK_8259
;	MOV	ES: [DI],	AL
;	RET
;SET_INTERRUPT_MASK	endp

; If your application program does not use interrupts nor
; priority modules, or if there is no interrupt controller
; present, this routine may be dummy.
; In that case, the code here could be:
; SET_INTERRUPT_MASK	 proc	 near
;	RET
; SET_INTERRUPT_MASK	 endp


;------------------------------------------------------------
;	public	SEND_EOI

; This routine sends an END-OF-INTERRUPT code (EOI) to the
; interrupt controller.
; The following registers may be used here: AX, DX, DI, ES.
; If other registers are used, they must be saved and restored.

; The following code sequence has to be used on a hardware
; with I/O through port, where the port address is below 100H:
SEND_EOI	proc	near
	MOV	AL,	EOI_8259
	OUT	CTRL_W2_8259,	AL
	RET
SEND_EOI	endp

; The following code sequence has to be used on a hardware
; with I/O through port, where the port address is above 100H:
;SEND_EOI	proc	near
;	MOV	AL,	EOI_8259
;	MOV	DX,	CTRL_W2_8259
;	OUT	DX,   AL
;	RET
;SEND_EOI	endp

; The following code sequence has to be used on a hardware
; with memory-mapped Input/Output:
;SEND_EOI	proc	near
;	MOV	DI,	IO_SEGMENT
;	MOV	ES,	DI
;	MOV	DI,	CTRL_W2_8259
;	MOV	ES: BYTE PTR  [DI],	EOI_8259
;	RET
;SEND_EOI	endp

; If your application program does not use interrupts nor
; priority modules, or if there is no interrupt controller
; present, this routine may be dummy.
; In that case, the code here could be:
; SEND_EOI	 proc	 near
;	RET
; SEND_EOI	 endp


;------------------------------------------------------------
;*********** end of user modifyable part ********************
;------------------------------------------------------------

code	ends

;*****************************************************************

data segment public	'data'

ISR_OWNER	dw	NBR_ISR dup ( NIL_CARD )
; This array holds for every free Interrupt Service Routine (ISR)
; the value NIL_CARD. For every used ISR it holds the base address
; of the process descriptor of the interrupt process that currently
; owns it.

data	ends

;*****************************************************************

code segment public	'code'

;	public	TRANSFER

TRANSFER:
;========
	;  on entry   ES = rts_ds

	; get IRET params from stack:
	pop	bx		; IP
	pop	dx		; CS
	pop	si		; FLAGS
	; BX:DX:SI = IP:CS:FLAGS of current (old) process

	; get base of current (old) process:
	mov	ax,ds		; save DS temporarily
	mov	cx,es:word ptr cur_proc_addr + 2
	mov	ds,cx		; base of current (old) process
	; DS = CX = base of current (old) process (ADR of p.d.)

	; save registers into p.d. of current (old) process:
	mov	cur_process.pd_ds,ax	; save DS
	mov	cur_process.pd_bp,bp	; save BP
	mov	cur_process.pd_ss,ss	; save SS
	mov	cur_process.pd_ip,bx	; save IP
	mov	cur_process.pd_cs,dx	; save CS
	mov	cur_process.pd_flags,si ; save FLAGS

	; Load the address of the new process variable
	; (given by the 2nd parameter of TRANSFER)
	; and save the correct value for SP:
	pop	di
	mov	cur_process.pd_sp,sp	; save SP, value is correct!
	pop	ds
	; DS:DI = ADR of new process variable

;	jmp	transfer_body0

TRANSFER_BODY0:   ; common part of TRANSFER and IOTRANSFER
	; ES = rts_ds
	; CX = base of current (old) process (ADR of p.d.)
	; DS:DI = ADR of new process variable indicating the
	;	  process to be activated
	; BX:DX:SI = IP:CS:FLAGS of current (old) process

	; Load the base of the new process to be activated:
	mov	ax, word ptr [di] + 2	; base of new process
	; AX = base of new process (ADR of p.d.) to be activated

	; Load the address of the old process variable
	; (given by the 1st parameter of TRANSFER)
	; and store the base of the current (old) process:
	pop	di
	pop	ds
	; DS:DI = ADR of old process variable
	mov	word ptr [di] +2,cx
	mov	word ptr [di],0

	; set DS to base of new process to be activated:
	mov	ds,ax		; base of new process
	; DS = base of new process (ADR of p.d.)

	; restore IRET parameters onto stack:
	push	si		; FLAGS
	push	dx		; CS
	push	bx		; IP

TRANSFER_BODY:
	; This is the part of TRANSFER, that is used for all transfer
	; functions: TRANSFER, IOTRANSFER, Interrupt Service Routines.
	;
	; ES = rts_ds
	; DS = base of new process (ADR of p.d.) to be activated

	; set address of new process into cur_proc_addr
	mov	ES: word ptr cur_proc_addr +2,DS
	mov	ES: word ptr cur_proc_addr,0

	mov	ax,cur_process.pd_prio_mask

;**** Here the code of SET_INTERRUPT_MASK has been inserted:
	or	ax, es: device_mask
	out	mask_8259,al
;**** End of insertion

	; restore the machine state for the new process:
	mov	ax,ds	; base of new process
	mov	ss,ax	; change stack pointers to restore regs
	mov	sp,0
	mov	es,ax	; needed later to restore from ES:0
	pop	ax
	pop	cx
	pop	dx
	pop	bx
	pop	bp	; sp must not be changed
	pop	bp
	pop	si
	pop	di
	pop	ds
	pop	ss
	MOV	sp, es:word ptr cur_process.PD_SP
	MOV	es, es:word ptr cur_process.PD_ES
	IRET		; resume the new process!

;	END TRANSFER
;------------------------------------------------------------

; Interrupt service routines:
; ==========================
; There is a fix number of interrupts, that can be treated simultanously.
; Here we allow up to 8 or 16 interrupts at a time, depending on the
; value of 'NBR_ISR'.
; The routines ISRn are the entry points to the common Interrupt
; Service Routine (COM_ISR).
; Every routine is 4 bytes long. This fact is used implicitly in
; COM_ISR, IOTRANSFER, Install_ISR, and Unistall_ISR. The Call to
; COM_ISR allows the identification of the Interrupt Vector (return
; address of the Call).

ISR0:	NOP
	CALL COM_ISR
ISR1:	NOP
	CALL COM_ISR
ISR2:	NOP
	CALL COM_ISR
ISR3:	NOP
	CALL COM_ISR
ISR4:	NOP
	CALL COM_ISR
ISR5:	NOP
	CALL COM_ISR
ISR6:	NOP
	CALL COM_ISR
ISR7:	NOP
	CALL COM_ISR

IF	NBR_ISR / 8
	; This block of 8 Interrupt Service Routines has to be repeated for
	; every additional Interrupt Controller (8259):

ISR8:	NOP
	CALL COM_ISR
ISR9:	NOP
	CALL COM_ISR
ISR10:	NOP
	CALL COM_ISR
ISR11:	NOP
	CALL COM_ISR
ISR12:	NOP
	CALL COM_ISR
ISR13:	NOP
	CALL COM_ISR
ISR14:	NOP
	CALL COM_ISR
ISR15:	NOP
	CALL COM_ISR

ENDIF


COM_ISR:
	; Common part of the Interrupt Service Routines
	; Save all the registers, except SP (has yet to be adjusted)
	; and CS, IP, Flags. They are on the stack and will be
	; used directly there (in the IRET of the next TRANSFER):
	push	ax
	push	ds
	mov	ax,rts_ds
	mov	ds,ax
	mov	ds,word ptr cur_proc_addr + 2
	; DS = base of current process (ADR of p.d.)
	; AX = rts_ds
	pop	cur_process.pd_ds
	pop	cur_process.pd_ax
	MOV	CUR_PROCESS.PD_BX,	BX
	MOV	CUR_PROCESS.PD_CX,	CX
	MOV	CUR_PROCESS.PD_DX,	DX
	MOV	CUR_PROCESS.PD_BP,	BP
	MOV	CUR_PROCESS.PD_DI,	DI
	mov	cur_process.pd_si,	si
	MOV	CUR_PROCESS.PD_SS,	SS
	MOV	CUR_PROCESS.PD_ES,	ES
	mov	es,ax		; set ES to rts_ds
	; find the interrupt vector:
	POP	BX		; return address of ISRn
	SUB	BX, OFFSET ISR1
	shr	bx,1
	; BX = word index into ISR_OWNER (2 * nr of ISR)

	; complete the update of the current process descriptor:
	mov	cur_process.pd_sp,sp
	mov	bp,sp		; take bp to address stack
	mov	ax,[bp]
	mov	cur_process.pd_ip,ax
	mov	ax,[bp]+2
	mov	cur_process.pd_cs,ax
	mov	ax,[bp]+4
	mov	cur_process.pd_flags,ax

	; load address of old (interrupted) process variable from
	; the p.d. of the new (driver) process to be activated, and
	; store base of current (old) process in old process variable
	mov	dx,ds
	; DX = base of current (old) process (ADR of p.d.)
	mov	ax,es:ISR_OWNER[bx]
	mov	ds,ax
	; DS = AX = base of new (driver) process (ADR of p.d.)
	lds	di, dword ptr cur_process.pd_int_proc
	; DS:DI = ADR of old process variable where to save the
	;	  base of the current (old) process (ADR of p.d.)
	mov	word ptr [di] +2,dx
	mov	word ptr [di],0
	mov	ds,ax		; restore base of new process

; Send a EOI to the 8259:

;**** Here the code of SEND_EOI has been inserted:
	mov	al,EOI_8259
	out	ctrl_w2_8259,al
;**** End of insertion
	; at the end of the following TRANSFER we are performing
	; an IRET, which enables the interrupts.

	; check for permanently installed Interrupt Service Routine,
	; test most significant bit of cur_process.pd_int_vect:
	mov	ax,	8000H	; most significant bit
	test	cur_process.pd_int_vect,	ax
	jnz	perm_isr1	; shortcut if permanently installed

; The ISR for this process has not been installed permanently,
; so an IOTRANSFER is only valid for 1 single interruption:

	mov	cx,es		; save rts_ds
	; free the entry in ISR_OWNER:
	mov	ax,	nil_card
	mov	es:ISR_OWNER[bx],	ax
	; restore the original interrupt vector:
	mov	si,	pd_old_isr	; loads offset in structure!
	; DS:SI points to original vector value (in p.d.)
	mov	di,	cur_process.pd_int_vect
	SHL	di,	1
	SHL	di,	1
	xor	ax,	ax	; AX = 0
	mov	es,	ax
	; ES:SI points to interrupt vector
	movsw
	movsw
	mov	es,cx		; restore rts_ds

perm_isr1:

	; Now, we're ready for a TRANSFER
	; parameters are set as follows:
	; ES = rts_ds
	; DS = base of new process (ADR of p.d.) to be activated
	JMP	TRANSFER_BODY


;	END Interrupt Service Routines
;------------------------------------------------------------

;	public	IOTRANSFER

IOTRANSFER:
;==========
	;  on entry   ES = rts_ds

	; get IRET params from stack:
	pop	bx		; IP
	pop	dx		; CS
	pop	si		; FLAGS
	; BX:DX:SI = IP:CS:FLAGS of current (old) process

	; get base of current (old) process:
	mov	ax,ds		; save DS temporarily
	mov	cx,es:word ptr cur_proc_addr + 2
	mov	ds,cx		; base of current (old) process
	; DS = CX = base of current (old) process (ADR of p.d.)

	; save registers into p.d. of current (old) process:
	mov	cur_process.pd_ds,ax	; save DS
	mov	cur_process.pd_bp,bp	; save BP
	mov	cur_process.pd_ss,ss	; save SS
	mov	cur_process.pd_ip,bx	; save IP
	mov	cur_process.pd_cs,dx	; save CS
	mov	cur_process.pd_flags,si ; save FLAGS

	; check for permanently installed Interrupt Service Routine,
	; test most significant bit of cur_process.pd_int_vect:
	mov	ax,	8000H	; most significant bit
	test	cur_process.pd_int_vect,	ax
	jnz	perm_isr2	; shortcut if permanently installed

; no ISR has been installed permanently for the current process:

	; find a unused Interrupt Service Routine (ISR),
	; represented by a free entry in the array ISR_OWNER:

	MOV	DI,	OFFSET ISR_OWNER
	MOV	AX,	NIL_CARD
	MOV	CX,	NBR_ISR
	INC	CX		; Increment it, so we can test for 0
	CLD
	REPNE	SCASW		; Scan the array for a NIL
	SUB	DI, 2		; It has already been incremented
	mov	ax, OFFSET ISR_OWNER
	SUB	DI,ax		; word index into ISR_OWNER

	CMP	CL,	0
	JNE	FREE_INT_V
	; There is no more free Interrupt Service Routine:
	mov	ds,cur_process.pd_ds	; restore old ds for save_cpu_info,
	push	si		; FLAGS ; and restore IRET parameters
	push	dx		; CS	; onto stack
	push	bx		; IP
	call	save_cpu_info	; also sets DS to base of current process
	MOV	CUR_PROCESS.PD_STATUS, INT_ERR_CODE
	JMP	TERMINATE

free_int_v:
	; DI = word index of the first free entry in ISR_OWNER
	; (nr of ISR * 2)

	; Put the base of the current (driver) process
	; (ADR of p.d.) in the array ISR_OWNER:
	mov	es:ISR_OWNER[di],ds

	; get interrupt vector number, save it for later
	; and compute vector offset:
	mov	bp,bx		; save BX (old IP)
	pop	bx		; interrupt vector number
	mov	cur_process.pd_int_vect,	bx

	; Save the requested interrupt vector:
	mov	cx,es		; save rts_ds
	SHL	BX,	1
	SHL	BX,	1	; offset of interrupt vector
	xor	ax,	ax	; AX = 0
	MOV	ES,	AX
	MOV	AX,	ES: [BX]
	MOV	word ptr CUR_PROCESS.PD_OLD_ISR,	AX
	MOV	AX,	ES: [BX] + 2
	MOV	word ptr CUR_PROCESS.PD_OLD_ISR + 2,	AX

	; Set the new interrupt vector:
	mov	ax,	di
	SHL	ax,1	; AX = nr of ISR * 4
	ADD	ax,	OFFSET	ISR0
	; Implicit use of the fact, that the ISRn have a size
	; of 4 Bytes! CS:AX is the address of the corresponding
	; Interrupt Service Routine
	MOV	ES: [BX],	ax
	MOV	ES: [BX] + 2,	CS

	mov	es,cx		; restore rts_ds
	mov	cx,ds		; restore CX to DS
	mov	bx,bp		; restore BX to old IP
	; ES = rts_ds
	; DS = CX = base of current (old) process (ADR of p.d.)
	; BX:DX:SI = IP:CS:FLAGS of current (old) process
	jmp	installed

perm_isr2:
	; remove the unused parameter from the stack:
	pop	di		; interrupt vector number (not used)

installed:
	; ES = rts_ds
	; DS = CX = base of current (old) process (ADR of p.d.)
	; BX:DX:SI = IP:CS:FLAGS of current (old) process

	; Load the address of the new process variable
	; (given by the 2nd parameter of IOTRANSFER)
	; and save the correct value for SP:
	pop	di
	mov	cur_process.pd_sp,sp	; save SP, value is correct!
	pop	ax
	; AX:DI = ADR of new process variable

	; Set in the p.d. of the current (driver) process,
	; where to save the running process, when the
	; interrupt will occur. It is the address given
	; by the 2nd parameter of IOTRANSFER.
	mov	word ptr cur_process.pd_int_proc,di
	mov	word ptr cur_process.pd_int_proc+2,ax
	; Load the address of the new process variable into DS:DI
	mov	ds,ax
	; DS:DI = ADR of new process variable

	; Execute a normal TRANSFER
	; parameters are set as follows:
	; ES = rts_ds
	; CX = base of current (old) process (ADR of p.d.)
	; DS:DI = ADR of new process variable indicating the
	;	  process to be activated
	; BX:DX:SI = IP:CS:FLAGS of current (old) process
	jmp	transfer_body0	; No return to here

;	END IOTRANSFER

;------------------------------------------------------------

;	public	NEWPROCESS

NEWPROCESS proc near

	call	save_cpu_info
	; DS = base of current process (ADR of p.d.)
	PUSH	BP
	MOV	BP,	SP

	; compute base of new process (ADR of p.d.):
	MOV	AX,	[BP] + 14	; Offset of process workspace
	MOV	BX,	[BP] + 16	; Segment of it
	ADD	AX, 15	; set P.D. to paragraph boundary
			; 15 is to round up (worst case)
	call	norm_addr
		; Upon return:
		;	BX = normalised Segment of
		;	     workspace
		;	AX = Offset, < 16

		; the number of lost bytes is the complement of
		; AX to 15, i.e. equal to 15 - AX

	; check the size of the workspace:
	mov	si, [bp]	+ 12	; size of workspace
	; the workspace must at least be able to contain some
	; 'lost bytes' (15 in the worst case), the process
	; descriptor, the 'free list header' (10 bytes) for the
	; heap, a minimal stack reserve, and the initial stack
	; setup (on the very bottom of the stack):
	cmp	si, 15+(size ProcessDescriptor)+10+sp_reserve+sp_ini_size
	ja	enough
	pop	bp		; correct stack if error
	jmp	stack_ovf

enough:
	; subtract lost bytes ( = 15 - AX):
	sub	si, 15
	add	si, ax
	; size must be even (stack base value for SP):
	and	si, 0fffeH	; truncate to even
	; SI = real size of workspace

	; Return the base of the new process (ADR of p.d.)
	; in the PROCESS VAR parameter:
	mov	dx,	ds		; save current process
	xor	ax,	ax		; AX = 0
	lds	di, dword ptr [BP] + 8	; addr of VAR parameter
	MOV	[di],	ax		; still AX = 0 (paragraph boundary)
	MOV	[di] + 2,	bx	; base of new process (ADR of p.d.)

	; initialise the new process descriptor with zeros:
	mov	es,	bx
	mov	di,	ax	 	; still AX = 0 (paragraph boundary)
	; ES:DI = address of new process descriptor
	mov	cx,	(size ProcessDescriptor) / 2
	CLD
	rep	stosw			; still AX = 0
	; DI = size ProcessDescriptor
	mov	es,	dx		; restore current process in ES
	mov	ds,	bx
	; ES = base of current process (ADR of p.d.)
	; DS = BX = base of new process (ADR of p.d.)
	;	  = stack and heap segment of new process

	; put NILs in the Free List header (right after the p.d.)
	; and set the initial values for the heap managment:
	MOV	WORD PTR [di] + 0, NIL_OFF
	MOV	WORD PTR [di] + 2, NIL_SEG
	MOV	WORD PTR [di] + 4, NIL_OFF
	MOV	WORD PTR [di] + 6, NIL_SEG
	MOV	WORD PTR [di] + 8, ax	; still AX = 0, size of
					; free element (redundant)
	MOV	word ptr cur_process.PD_HEAP_BASE + 2, BX
	MOV	word ptr cur_process.PD_HEAP_TOP + 2, BX
	MOV	word ptr cur_process.PD_HEAP_BASE, di
	add	di, 10		; add size of a 'FreeListElement'
	MOV	word ptr cur_process.PD_HEAP_TOP, di
	; See comment under 'Fill in the Default
	; Process Descriptor'. For a new process
	; however, we must fully install an empty heap,
	; since we can not call 'InstallHeap' as
	; done in the initialization of the module
	; Storage for the MAIN process.

	; SP has to be set after the return block that we
	; are going to put at the bottom of the stack:
	SUB	si,	SP_INI_SIZE
	; DS:SI (= BX:SI) is the initial top of stack for the new process.
	MOV	cur_process.PD_SP, si	; set SP and SS in new descriptor
	MOV	cur_process.PD_SS, BX

	; Copy the Program End Stack:
	MOV	AX,ES:word ptr CUR_PROCESS.PD_PROG_END
	MOV	word ptr cur_process.PD_PROG_END,	AX
	MOV	AX,ES:word ptr CUR_PROCESS.PD_PROG_END+2
	MOV	word ptr cur_process.PD_PROG_END+2,	AX

	; Copy the program IDs from the current process:
	MOV	AX,ES:CUR_PROCESS.PD_PROG_ID
	MOV	cur_process.PD_PROG_ID,	AX
	MOV	AX,ES:CUR_PROCESS.PD_SHARED_ID
	MOV	cur_process.PD_SHARED_ID,	AX

	; Copy the Module Table Header:
	MOV	AX,ES:word ptr CUR_PROCESS.PD_MOD_TABLE
	MOV	word ptr cur_process.PD_MOD_TABLE,	AX
	MOV	AX,ES:word ptr CUR_PROCESS.PD_MOD_TABLE+2
	MOV	word ptr cur_process.PD_MOD_TABLE+2,	AX

	; Copy the father process:
	MOV	AX,ES:word ptr CUR_PROCESS.PD_FATHER_PROC
	MOV	word ptr cur_process.PD_FATHER_PROC,	AX
	MOV	AX,ES:word ptr CUR_PROCESS.PD_FATHER_PROC+2
	MOV	word ptr cur_process.PD_FATHER_PROC+2,	AX
	; Check if the father process is NIL, in which
	; case we have to put the addr of the current p.d.:
	CMP	AX,NIL_SEG
	JNE	SAME_FATHER
	; put the current process as father:
	xor	ax,	ax		; AX = 0 (paragraph boundary)
	MOV	word ptr cur_process.PD_FATHER_PROC,	AX
	MOV	word ptr cur_process.PD_FATHER_PROC + 2,	ES
SAME_FATHER:

	; Set the start address and the flags for the new process:
	MOV	AX,	[BP] + 18	; IP (from parameter)
	MOV	BX,	[BP] + 20	; CS (from parameter)
	MOV	CX,ES:CUR_PROCESS.PD_FLAGS ; FLAGS (from current process)
	; put it on top of the initial stack, for an IRET:
	MOV	[SI] + 0,	AX	; IP
	MOV	[SI] + 2,	BX	; CS
	MOV	[SI] + 4,	CX	; FLAGS
	; put it into the new process descriptor:
	MOV	cur_process.PD_IP,	AX	; IP
	MOV	cur_process.PD_CS,	BX	; CS
	MOV	cur_process.PD_FLAGS,	CX	; FLAGS
	; put it again into the new stack for PROCESS_END and RTD:
	inc	ax			; for PROCESS_END and RTD
	MOV	[SI] + 10,	AX	; start IP + 1
	MOV	[SI] + 12,	BX	; CS
	MOV	[SI] + 14,	CX	; FLAGS

	; Prepare the error return on the new stack for PROCESS_END:
	MOV	word ptr [SI] + 6, OFFSET PROCESS_END
	MOV	word ptr [SI] + 8, CS
	; A process should never terminate!

	xor	ax,	ax		; AX = 0
	mov	[si] + 16, ax		; for PROCESS_END and RTD

; Because the process descriptor has been filled with zeros above,
; the following 5 assignements may be left out:
	; Set dbug status for debugger:
;	MOV	cur_process.PD_dbug_status, ax	; still AX = 0

	; Set Status to Normal:
;	MOV	cur_process.PD_STATUS,	AX	; still AX = 0

	; Set dynamic link to 0, used by the
	; debugger to detect end of calling sequence:
;	MOV	cur_process.PD_BP,	AX	; still AX = 0

	; Set the initial priority mask to 'no priority' ( = zero):
;	MOV	cur_process.PD_PRIO_MASK, ax	; still AX = 0

	; mark p.d. for no permanently installed ISR:
;	mov	cur_process.pd_int_vect, ax	; still AX = 0

	; restore DS and BP of the current process and return:
	MOV	DS,	es:CUR_PROCESS.PD_DS
	POP	BP
	IRET
NEWPROCESS endp
;------------------------------------------------------------


PROCESS_END:
;===========
; We arrive here, when the code of a process is executed and a
; return from its code is performed. Since a process is not called
; like a procedure, but started through a TRANSFER, this situation
; is illegal:
	mov	es,CS:rts_ds
	call	save_cpu_info
	mov	bp,sp
	add	bp,6	; set bp for debugger
	MOV	CUR_PROCESS.PD_STATUS,	PROCESS_END_CODE
	JMP	TERMINATE

;------------------------------------------------------------


;	public	MON_ENTRY, MON_EXIT

MON_ENTRY:
;=========
; Upon entry: BX holds requested priority level.
; The interrupt controller is set to disable all
; interrupts of the requested or lower levels.
	; check the parameter:
	CMP	BX,	MAX_PRIO_LEVEL
	JBE	LEVEL_OK
	MOV	BX,	MAX_PRIO_LEVEL
LEVEL_OK:
	POP	SI		; remove return block
	POP	DX
	POP	CX
	; save old mask:
	MOV	DS,	ES: word ptr cur_proc_addr + 2
	PUSH	cur_process.pd_prio_mask
	MOV	al, es: priority_masks [bx]
;	xor	ah, ah
	MOV	CUR_PROCESS.PD_PRIO_MASK,	AX

;**** Here the code of SET_INTERRUPT_MASK has been inserted:
	or	ax, es: device_mask
	out	mask_8259,al
;**** End of insertion

	PUSH	CX		; restore return block
	PUSH	DX
	PUSH	SI
	IRET


MON_EXIT:
;========
; Restore the mask that has been saved on the stack
; at the entry to that procedure. Note that changes
; in the interrupt mask that occured during execution
; of this 'priority procedure' are not conserved!
; If interrupts are treated with IOTRANSFER, such
; changes should never occur.

	POP	SI		; remove return block
	POP	DX
	POP	CX
	POP	AX		; old mask
	MOV	DS,	ES: word ptr cur_proc_addr + 2
	MOV	CUR_PROCESS.PD_PRIO_MASK,	AX
;**** Here the code of SET_INTERRUPT_MASK has been inserted:
	or	ax, es: device_mask
	out	mask_8259,al
;**** End of insertion
	PUSH	CX		; restore return block
	PUSH	DX
	PUSH	SI
	IRET


;	public	LISTEN

LISTEN:
;======
; This function lowers the priority and enables interrupts
; temporarily. Note that changes in the interrupt mask that
; occur during the execution of pending interrupts are not
; conserved, the old mask is restored at the end! If
; interrupts are treated with IOTRANSFER, such changes
; should never occur.
	mov	bx,	ds	; save DS
	MOV	DS,	ES: word ptr cur_proc_addr + 2
	PUSH	cur_process.pd_prio_mask	; save it
	XOR	AX,	AX
	MOV	CUR_PROCESS.PD_PRIO_MASK,	AX
	CALL	SET_INTERRUPT_MASK	; unmask all bits
	STI			; Allow all interrupts
	NOP			; (there is a one-instruction lag)
	MOV	CX,	20H
LISTEN_AGAIN:
	DEC	CX		; we have to wait longer, to give
				; all pending interrupts a chance
	JNZ	LISTEN_AGAIN
	CLI
	POP	AX
	MOV	CUR_PROCESS.PD_PRIO_MASK,	AX
	CALL	SET_INTERRUPT_MASK	; restore old mask
	mov	ds,	bx	; restore DS
	IRET

;------------------------------------------------------------


get_device_status:
;=================
; this function returns the status (enabled or disabled) of a device
;   upon entry: CX holds the device number [0..maxdevice]
;			this is the bit number of the device in the
;			interrupt controller mask
;   upon exit:	BX holds the inverse bit value in the device_mask
;			BX = 1 (TRUE ) -> enabled
;			BX = 0 (FALSE) -> disabled

;	IF device IN device_mask THEN
;	  enabled := FALSE;
;	ELSE
;	  enabled := TRUE;
;	END;

	call	save_cpu_info
	mov	ds, rts_ds
	mov	ax, 1
	shl	ax, cl
	test	device_mask, ax
	jz	enabled
	xor	bx, bx
	jmp	end_get
enabled:
	mov	bx, 1
end_get:
	iret



set_device_status:
;=================
; this function sets the status (enable or disable) of a device
;   upon entry: CX holds the device number [0..maxdevice]
;			this is the bit number of the device in the
;			interrupt controller mask
;		BX holds the inverse bit value to write into the device_mask
;			BX = 1 (TRUE ) -> enable
;			BX = 0 (FALSE) -> disable

;	IF enable THEN
;	  EXCL(device_mask, device)
;	ELSE
;	  INCL(device_mask, device)
;	END;
;	SetInterruptMask(cur_process.prio_mask)

	call	save_cpu_info
	mov	es, rts_ds
	mov	ax, 1
	shl	ax, cl
disable:				; set the bit
	or	es:device_mask, ax
	or	bx, bx			; CMP BX, 0
	jz	end_set
enable:					; clear the bit
	not	ax
	and	es:device_mask, ax
end_set:
	mov	ax, cur_process.pd_prio_mask
	call	set_interrupt_mask
	iret

;------------------------------------------------------------

FREE_1_VECT proc near
; Free an ISR, restore the original value of the
; corresponding interrupt vector, and mark p.d. for
; no permanently installed ISR.

; Upon entry:
	; ES = rts_ds
	; DS = base of interrupt process that owns this ISR
	; BX = word index into ISR_OWNER (2 * nr of ISR)
; Upon exit:
	; ES is destroyed, DS and BX are unchanged
	; also destroyed are AX, DI, SI

	; free the entry in ISR_OWNER:
	mov	ax,	nil_card
	mov	es:ISR_OWNER[bx],	ax
	; restore the original interrupt vector:
	mov	si,	pd_old_isr	; loads offset in structure!
	; DS:SI points to original vector value (in p.d.)
	mov	di,	cur_process.pd_int_vect
	SHL	di,	1
	SHL	di,	1
	xor	ax,	ax	; AX = 0
	mov	es,	ax
	; ES:SI points to interrupt vector
	movsw
	movsw

	; mark p.d. for no permanently installed ISR:
;	xor	ax,	ax	; AX = 0
	; AX = 0
	mov	cur_process.pd_int_vect,	ax
	ret
FREE_1_VECT endp


;	public	REST_I_V

REST_I_V proc near
;=================
; Free all ISR owned by the current program and restore the
; original values of the corresponding interrupt vectors

	; on entry DS = rts_ds

	mov	dx,	ds	; save rts_ds
	mov	ds,	word ptr cur_proc_addr + 2
	mov	cx,	CUR_PROCESS.PD_PROG_ID
	; CX = prog_id of current program (process)
	mov	bx,	NBR_ISR
	shl	bx,	1
	; BX = word index into ISR_OWNER (2 * nr of ISR)
	mov	es,	dx	; restore ES with rts_ds
NEXT_I_V:
	dec	bx
	dec	bx
	mov	ax,	es:ISR_OWNER[bx]
	cmp	ax,	NIL_CARD
	je	I_V_DONE	; no owner, ISR unused
	mov	ds,	ax
	; DS = base of interrupt process that owns this ISR
	mov	ax,	CUR_PROCESS.PD_PROG_ID
	; AX = prog_id of owning program (process)
	cmp	ax,	cx	; free ISR if it is owned
	JE	FREE_THIS_ONE	; by the current program
	CMP	CX,	0	; 0 is used as a joker:
	JNE	I_V_DONE	; free all ISR if 0

FREE_THIS_ONE:
	; ES = rts_ds
	; DS = base of interrupt process that owns this ISR
	; BX = word index into ISR_OWNER (2 * nr of ISR)
	; free this ISR, it is owned by the current program:
	CALL FREE_1_VECT	; destroys rts_ds in ES
	mov	es,	dx	; restore ES with rts_ds

I_V_DONE:
	CMP	bx,	0
	JNE	NEXT_I_V
	mov	ds,	dx	; restore DS with rts_ds
	RET
REST_I_V endp


;	public	FREE_INT_VECT

FREE_INT_VECT:
;=============
	; Restores the old Interrupt Vectors of all entries, used by the
	; current program.
	call	save_cpu_info
	CALL REST_I_V
	IRET

;------------------------------------------------------------

;	public	Install_ISR

Install_ISR:
;==========
	; install an ISR permanently for a process
	; input parameters:
	; DX = base of process (ADR of p.d.)
	; BX = interrupt vector number

	; on entry ES = rts_ds

	; find a unused Interrupt Service Routine (ISR),
	; represented by a free entry in the array ISR_OWNER:
	MOV	DI,	OFFSET ISR_OWNER
	MOV	AX,	NIL_CARD
	MOV	CX,	NBR_ISR
	INC	CX		; Increment it, so we can test for 0
	CLD
	REPNE	SCASW		; Scan the array for a NIL
	SUB	DI, 2		; It has already been incremented
	mov	ax, OFFSET ISR_OWNER
	SUB	DI,ax		; word index into ISR_OWNER

	CMP	CL,	0
	JNE	FREE_INT_V1
	; There is no more free Interrupt Service Routine:
	call	save_cpu_info	; also sets DS to base of current process
	MOV	CUR_PROCESS.PD_STATUS, INT_ERR_CODE
	JMP	TERMINATE

free_int_v1:
	; DI = word index of the first free entry in ISR_OWNER
	; (nr of ISR * 2)

	push	ds	; save ds
	mov	ds, dx	; base of process (ADR of p.d.)

	; Put the base of the current (driver) process
	; (ADR of p.d.) in the array ISR_OWNER:
	mov	es:ISR_OWNER[di],ds

	; save interrupt vector number and mark p.d. for
	; permanently installed ISR, setting the most
	; significant bit of cur_process.pd_int_vect:
	or	bx,	8000H	; set most significant bit
	mov	cur_process.pd_int_vect,	bx

	; Save the requested interrupt vector:
	SHL	BX,	1
	SHL	BX,	1	; offset of interrupt vector
	xor	ax,	ax	; AX = 0
	MOV	ES,	AX
	MOV	AX,	ES: [BX]
	MOV	word ptr CUR_PROCESS.PD_OLD_ISR,	AX
	MOV	AX,	ES: [BX] + 2
	MOV	word ptr CUR_PROCESS.PD_OLD_ISR + 2,	AX

	; Set the new interrupt vector:
	mov	ax,	di
	SHL	ax,1	; AX = nr of ISR * 4
	ADD	ax,	OFFSET	ISR0
	; Implicit use of the fact, that the ISRn have a size
	; of 4 Bytes! CS:AX is the address of the corresponding
	; Interrupt Service Routine
	MOV	ES: [BX],	ax
	MOV	ES: [BX] + 2,	CS

	pop	ds	; restore ds
	iret

;	END Install_ISR


;	public	Uninstall_ISR

Uninstall_ISR:
;============
	; uninstall an ISR installed permanently for a process
	; input parameters:
	; DX = base of process (ADR of p.d.)

	; on entry ES = rts_ds

	push	ds	; save ds
	mov	ds, dx	; base of process (ADR of p.d.)

	; check for permanently installed Interrupt Service Routine,
	; test most significant bit of cur_process.pd_int_vect:
	mov	bx,	cur_process.pd_int_vect
	mov	ax,	8000H	; most significant bit
	test	bx,	ax
	jnz	perm_isr3

	; no permantly installed ISR for this process:
	pop	ds
	call	save_cpu_info	; also sets DS to base of current process
	MOV	CUR_PROCESS.PD_STATUS, INT_ERR_CODE
	JMP	TERMINATE

perm_isr3:
	; use interrupt vector to find nr of ISR used
	; for this process:
	shl	bx,	1
	shl	bx,	1	; offset of interrupt vector
	mov	cx,	es	; save rts_ds
	xor	ax,	ax	; AX = 0
	mov	es,	ax
	mov	bx,	es:word ptr [bx]
	; BX = offset of ISR used
	sub	bx,	OFFSET ISR0
	shr	bx,	1
	; Implicit use of the fact, that the ISRn have a size
	; of 4 Bytes! BX = nr of ISR * 2.
	mov	es,	cx	; restore rts_ds

	; BX = word index into ISR_OWNER (2 * nr of ISR)
	; DS = base of process (ADR of p.d.)
	; ES = rts_ds

	; free ISR and restore the original interrupt vector:
	call	FREE_1_VECT

	pop	ds	; restore ds
	iret

;	END Uninstall_ISR
;------------------------------------------------------------

code	ends

;*****************************************************************

	end
