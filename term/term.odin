package term

import "core:c/libc"
import "core:fmt"
import "core:os"


Termios :: struct {
	c_iflag:  u32, // input modes
	c_oflag:  u32, // output modes
	c_cflag:  u32, // control modes
	c_lflag:  u32, // local modes
	c_cc:     [32]u8, // control characters
	c_ispeed: u64, // input speed
	c_ospeed: u64, // output speed 
}

TermDisInt :: distinct i32


STDIN_FILENO :: 0

// Define constants for terminal control
TCSANOW: u32 : 0x0000
ICANON: u32 : 0x0002
ECHO: u32 : 0x0008
ICRNL: u32 : 00000400
INLCR: u32 : 0000100

TermErrno :: enum {
	BufferIsZeroLen = 3644,
	BufferSizeOverLimit,
}

TermError :: union {
	TermErrno,
	TermDisInt,
}

// buffer max length may change
MAX_LEN :: 256


// prossible termios errors
EINTR: TermDisInt : 4
EINVL: TermDisInt : 22
ENOTTY: TermDisInt : 25


//Special charater keys to be processed differently
KEYS :: enum int {
	CTRL_C     = 3,
	CTRL_D     = 4,
	CTRL_P     = 16,
	CTRL_N     = 14,
	BACK_SPACE = 127,
}


// Character keys that kill the terminal process
QUIT_KEYS :: KEYS_SET{.CTRL_D, .CTRL_C}

NAVEGATION_KEYS :: KEYS_SET{.CTRL_N, .CTRL_P}

KEYS_SET :: bit_set[KEYS]


when ODIN_OS == .Windows {

} else when ODIN_OS == .Darwin {
	//TODO: need to test in Mac. :-(  I don't own one
	foreign import tlibc "system:System.framework"
} else {
	foreign import tlibc "system:c"
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
}


/*
Converts [TermDisInt] error code to string
*/
err_to_string :: proc(eno: TermDisInt) -> string {
	switch eno {
	case EINTR:
		return "The system call was interrupted by a signal"
	case EINVL:
		return "Invalid argument. This could indicate a problem with terminal setting modification"
	case ENOTTY:
		return "The File descriptor is not associated with a terminal"
	}
	return "Unable to decode ERROR"
}

read :: proc(buff: []byte) -> (read: int, err: TermError) {
	if len(buff) == 0 {
		return 0, TermErrno.BufferIsZeroLen
	} else if len(buff) > MAX_LEN {
		return 0, TermErrno.BufferSizeOverLimit
	}

	old_term: Termios
	if err := tcgetattr(STDIN_FILENO, &old_term); err != 0 {
		return 0, TermDisInt(err)
	}

	raw_term := old_term

	raw_term.c_lflag &~= (ICANON | ECHO)

	if err := tcsetattr(STDIN_FILENO, TCSANOW, &raw_term); err != 0 {
		return 0, TermDisInt(err)
	}

	length := 0
	exitos: bool
	for {
		c := libc.getchar()
		// c := getchar()

		switch KEYS(c) {
		//BUG: weird behavior here. check this keys are being read correctly
		case .CTRL_C, .CTRL_D:
			exitos = true
			if err := tcsetattr(STDIN_FILENO, TCSANOW, &old_term); err != 0 {
				return 0, TermDisInt(err)
			}
			break
		case .CTRL_P:
			fmt.println("PREVIOUS")
		case .CTRL_N:
			fmt.println("NEXT")
		case .BACK_SPACE:
			if length > 0 {
				// fmt.printf("%v %d\n", os.stdout, os.stdout)
				fmt.print("\b \b")
				_ = libc.fflush(libc.stdin)
				length -= 1
			}
			continue
		}

		// check key bindings
		// if _term_mode == .VIM {
		// }

		if c == '\n' {
			fmt.printf("\n")
			break
		}

		// keep to map character codes through development
		// fmt.printf("char : %d\n", c)
		fmt.printf("%c", c)

		buff[length] = byte(c)
		length += 1
	}


	if err := tcsetattr(STDIN_FILENO, TCSANOW, &old_term); err != 0 {
		return 0, TermDisInt(err)
	}

	if exitos {
		os.exit(0)
	} else {
		return length, nil
	}

}
