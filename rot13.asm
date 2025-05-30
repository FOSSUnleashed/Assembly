
section .bss
	buffer: resb 512

section .text ; (4)
global _start ; (5)
_start:
	mov rax, 0 ; read(fd, buffer, size)
	mov rdi, 0 ; stdin
	mov rsi, buffer
	mov rdx, 512
	syscall

	; if (0 > read(...))
	cmp rax, 0
	jl read_error

	; while (rsi < result_of_read)
	mov rsi, 0
	loop:
	cmp rsi, rax
	jz success

		mov bh, [buffer + rsi]

		; if (in range of a-m -> n-z | n-z -> a-m | A-M -> N-Z | N-Z -> A-M
		cmp bh, 'A'
		jl inc
		cmp bh, 'N'
		jl shift_up

		cmp bh, 'Z'
		jle shift_down

		cmp bh, 'a'
		jl loop
		cmp bh, 'n'
		jl shift_up

		cmp bh, 'z'
		jle shift_down

		;;

		jmp inc

		shift_up: ; a-mA-M -> n-zN-Z
		add bh, 13

		jmp save

		shift_down: ; n-zN-Z -> a-mA-M
		sub bh, 13

		save:
		mov [buffer + rsi], bh
		inc:
		inc rsi

		jmp loop

	success:
	mov rdx, rax ; Put length in 3rd param
	mov rax, 1 ; write(1, buffer, rdx)
	mov rdi, 1 ; stdout
	mov rsi, buffer
	syscall
	
	jmp done
	
	read_error:

	done:

	int3 ; __trap_break

	mov rax, 60 ; exit(0)
	mov rdi, 0 ; 
	syscall

