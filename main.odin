package osh


import "core:fmt"
import "term"

main :: proc() {
	fmt.print("osh >> ")
	arr: [124]byte
	r, e := term.read(arr[:])
	if e != nil {
		fmt.println(e)
	}
	content := arr[:r]
	fmt.printf("%s\n", content)
}
