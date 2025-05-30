
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

section .text ; (4)
; strln: find NUL, replace is LF 0x0A, copy into sbuffer as we go
strln:
	; rdx is both the index into sbuffer, or the length of the string data into sbuffer
	; we are already 2 characters into sbuffer before we enter the function
	mov rdx, 2
	loop_str:
	; bl = character we are looking at
	mov r12, r13 ; r13 is the offset to the start of the current dirent struct
	add r12, 17 ; 19 is the offset from the start of the struct to the d_name member
	add r12, rdx
	mov bl, [buffer + r12] ; buffer[r13 + 17 + rdx]

	cmp bl, 0
	je done_str

	mov [sbuffer + rdx], bl
	inc rdx

	jmp loop_str

	done_str:
	mov bl, 0x0A ; Linefeed
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

			; r9 = size of the current struct (extracted from the d_size member)
			mov r9w, [buffer + r13 + 16]
			mov bl, [buffer + r13 + 18]
			add bl, 0x30
			mov [sbuffer], bl ; 4 == directory | 8 == regular file | : == symlink
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

