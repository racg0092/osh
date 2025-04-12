#+build windows
package term


import "core:fmt"
import "core:io"
import "core:os"
import "core:sys/windows"


//Special charater keys to be processed differently
KEYS :: enum int {
	CTRL_C     = 3,
	CTRL_D     = 4,
	CTRL_P     = 16,
	CTRL_N     = 14,
	BACK_SPACE = 8,
	ENTER      = 13,
}

orig_mode: windows.DWORD
stdout_om: windows.DWORD // possible settings for stdout handler

enable_raw_mode :: proc() {
	stdin := windows.GetStdHandle(windows.STD_INPUT_HANDLE)

	assert(stdin != windows.INVALID_HANDLE_VALUE)

	ok := windows.SetConsoleMode(stdin, orig_mode)
	assert(bool(ok))

	raw := orig_mode
	raw &= ~windows.ENABLE_ECHO_INPUT
	raw &= ~windows.ENABLE_LINE_INPUT

	ok = windows.SetConsoleMode(stdin, raw)
	assert(bool(ok))

}

flush :: proc() {
	h_stdout := windows.GetStdHandle(windows.STD_INPUT_HANDLE)
	ok := windows.FlushFileBuffers(h_stdout)
	assert(bool(ok), "failed to flush buffer")
}


disable_raw_mode :: proc() {
	stdin := windows.GetStdHandle(windows.STD_INPUT_HANDLE)
	assert(stdin != windows.INVALID_HANDLE_VALUE)

	ok := windows.SetConsoleMode(stdin, orig_mode)
	assert(bool(ok))
}


get_char :: proc() -> i32 {
	in_stream := os.stream_from_handle(os.stdin)
	ch, error := io.read_byte(in_stream)

	assert(error == io.Error(0), "error reading character")

	return i32(ch)
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
