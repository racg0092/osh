#+build linux, darwin
package term

import "core:c/libc"
import "core:fmt"
import "core:os"

//Special charater keys to be processed differently
KEYS :: enum int {
	CTRL_C     = 3,
	CTRL_D     = 4,
	CTRL_P     = 16,
	CTRL_N     = 14,
	BACK_SPACE = 127,
	ENTER      = 10,
}


orig_mode: Termios


disable_raw_mode :: proc() {
	err := tcsetattr(STDIN_FILENO, TCSANOW, &orig_mode)
	assert(err == 0, "error returning terminal to normal mode")
}


enable_raw_mode :: proc() {
	get_error := tcgetattr(STDIN_FILENO, &orig_mode)
	assert(get_error == 0, "error getting terminal attributes")

	raw_term := orig_mode

	raw_term.c_lflag &~= (ICANON | ECHO)

	set_err := tcsetattr(STDIN_FILENO, TCSANOW, &raw_term)
	assert(set_err == 0, "error setting raw terminal attributes")
}


flush :: proc() {
	_ = libc.fflush(libc.stdin)
}

when ODIN_OS == .Linux {
	foreign import tlibc "system:c"
} else when ODIN_OS == .Darwin {
	foreign import tlibc "system:System.framework"
}

@(default_calling_convention = "c")
foreign tlibc {
	//Get terminal attributes. This is linked to the termios libc library
	tcgetattr :: proc(fd: u32, termios: ^Termios) -> int ---
	//Set terminal attributes. This is linked to the termios libc library
	tcsetattr :: proc(fd: u32, optional_actions: u32, termios: ^Termios) -> int ---
	// getchar :: proc() -> int ---
	__errno_location :: proc() -> ^int ---
	// strerror :: proc(errnum: int) -> ^u8 ---
	// fflush :: proc(stream: i32) -> i32 ---
}


get_char :: proc() -> i32 {
	c := libc.getchar()
	return c
}


read :: proc(buff: []byte) -> (read: int, err: TermError) {
	if len(buff) == 0 {
		return 0, TermErrno.BufferIsZeroLen
	} else if len(buff) > MAX_LEN {
		return 0, TermErrno.BufferSizeOverLimit
	}
	enable_raw_mode()
	defer disable_raw_mode()

	read, err = handle_keys(buff)

	return read, err
}
