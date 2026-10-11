package main

import "./platform"
import "core:fmt"
import "core:os"

main :: proc() {
	if len(os.args) != 2 {
		fmt.eprintfln("Usage: %s <filename>", os.args[0])
		return
	}

	platform.init(os.args[1])
}
