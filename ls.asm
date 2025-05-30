
; 78 == getdents(fd, *dirent, sz)
; 217 == getdents64(fd, *dirent, sz)
; note: dirent in this contenxt is linux-specific, not the one readdir provides!
; 2 == open()
; 3 == close()

section .bss
	sbuffer: resb 512

section .data
	buffer: times 256 db '.',0

; check return values, but only once, we don't need to keep any
; open returns -1 on fail
; getdents64 returns -1 on fail, 0 on done, >0 bytes for size of directory entity
; keep the fd (it'll probably be 3 TBH)
; 

section .text ; (4)
strln:
	; rdx is length of string
	; find NUL, replace is LF 0x0A
	mov rdx, 2
	; buffer + r13 + 19 + rdx
	loop_str:
	; ch = character we are looking
	mov r12, r13
	add r12, 17
	add r12, rdx
	mov bl, [buffer + r12]

	cmp bl, 0
	je done_str

	mov [sbuffer + rdx], bl
	inc rdx

	jmp loop_str

	done_str:
	mov bl, 0x0A
	mov [sbuffer + rdx], bl
	inc rdx

	ret
	

global _start ; (5)
_start:
	mov rax, 2 ; open('.', 0)
	lea rdi, buffer
	mov rsi, 0
	syscall

	cmp rax, -1
	je error

	mov r15, rax

	loop:

		; getdents64(fd, buffer, 512)
		mov rdi, r15 ; rdi = fd
		lea rsi, buffer
		mov rdx, 512
		mov rax, 217
		syscall

		cmp rax, -1
		je error

		cmp rax, 0
		je done

		; r14 = length of data
		; r13 = index
		mov r14, rax
		mov r13, 0

			inner:
			; inode[8]
			; junk[8]
			; size[2]
			; type[1]
			; name[nul]

			; r9 = size
			mov r9w, [buffer + r13 + 16]
			mov bl, [buffer + r13 + 18]
			add bl, 0x30
			mov [sbuffer], bl
			mov bl, 0x20 ; space
			mov [sbuffer + 1], bl ; space

			call strln ; note: sets rdx to the value for write

			mov rax, 1 ; write
			mov rdi, 1 ; stdout
			lea rsi, [sbuffer]
			syscall

			; r13 += size[2]
			add r13, r9
			cmp r13, r14
		jl inner

	jmp loop

	error:

	done:

;	int3
	mov rax, 60 ; exit(0)
	mov rdi, 0 ; (12)
	syscall

