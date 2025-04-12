package term

import "core:fmt"
import "core:os"


ModeType :: distinct u8

TermMode :: enum ModeType {
	NORMAL = 0,
	INSERT,
	SELECT,
}

// set different modes like vim
MODE: TermMode = TermMode.NORMAL

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


// Character keys that kill the terminal process
QUIT_KEYS :: KEYS_SET{.CTRL_D, .CTRL_C}

NAVEGATION_KEYS :: KEYS_SET{.CTRL_N, .CTRL_P}

KEYS_SET :: bit_set[KEYS]


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


handle_keys :: proc(buff: []byte) -> (read: int, error: TermError) {

	length := 0
	exitos: bool
	loop: for {
		c := get_char()
		//NOTE: for when i need to see the code of a character they can vary between OS
		// fmt.printf("\n%d == %c\n", c, c)

		switch KEYS(c) {
		case .CTRL_C, .CTRL_D:
			exitos = true
			break loop
		case .CTRL_P:
			fmt.println("PREVIOUS")
		case .CTRL_N:
			fmt.println("NEXT")
		case .BACK_SPACE:
			if length > 0 {
				// fmt.printf("%v %d\n", os.stdout, os.stdout)
				// fmt.print("\x1b[D\x1b[P")
				fmt.printf("%s%s", ANSI_CURSOR_BACK, ANSI_DEL_CHAR)
				length -= 1
				flush()
			}
			continue
		case .ENTER:
			fmt.printf("\n")
			break loop
		}

		fmt.printf("%c", c)

		buff[length] = byte(c)
		length += 1
	}

	if exitos {
		disable_raw_mode()
		os.exit(0)
	} else {
		return length, nil
	}
}
