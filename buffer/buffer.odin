package buffer

import "core:log"
import "core:os"
import "core:strings"

Buffer :: struct {
	data:     []byte,
	fp:       ^os.File,
	c_string: cstring,
}

open :: proc(filename: string) -> (b: Buffer) {
	file_data, err := os.read_entire_file(filename, context.allocator)
	if err != nil {
		if err == os.General_Error.Not_Exist {
			// If the file doesn't exist, create it
			fp, create_err := os.create(filename)
			if create_err != nil {
				log.fatalf("Error creating file: '%s'", filename)
			}
			b.data = transmute([]byte)string("")
			b.fp = fp
		} else {
			log.panic("wtf did u do")
		}
	} else {
		b.data = file_data
		fp, open_err := os.open(filename, {.Read, .Write})
		if open_err != nil {
			log.fatal("Error opening file: '%s", filename)
		}
		b.fp = fp
	}
	b.c_string = strings.clone_to_cstring(string(b.data), context.allocator)
	return b
}

close :: proc(b: ^Buffer) {
	delete(b.data)
	delete(b.c_string)
}
