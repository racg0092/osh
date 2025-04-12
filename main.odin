package osh


import "core:fmt"
import "core:strings"
import "term"

main :: proc() {
	arr: [124]byte
	for {
		fmt.print("osh >> ")
		r, e := term.read(arr[:])
		if e != nil {
			fmt.println(e)
			break
		}
		content := arr[:r]
		fmt.printf("%s\n", content)
		s, clone_error := strings.clone_from_bytes(content)
		if clone_error != nil {
			fmt.println(clone_error)
			break
		}

		if s == "exit" {
			break
		}
	}
}
