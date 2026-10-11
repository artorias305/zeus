package buffer

import "core:log"
import "core:os"
import "core:strings"

Buffer :: struct {
	data:       []byte,
	fp:         ^os.File,
	c_string:   cstring,
	cursor_row: uint,
	cursor_col: uint,
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
	b.cursor_row = 0
	b.cursor_col = 0
	return b
}

close :: proc(b: ^Buffer) {
	delete(b.data)
	delete(b.c_string)
}

line_count :: proc(b: Buffer) -> uint {
	count: uint = 1

	for c in b.data {
		if c == '\n' {
			count += 1
		}
	}

	return count
}

line_start :: proc(b: Buffer, row: uint) -> int {
	current_row: uint = 0

	for i := 0; i < len(b.data); i += 1 {
		if current_row == row {
			return i
		}

		if b.data[i] == '\n' {
			current_row += 1
		}
	}

	return len(b.data)
}

line_end :: proc(b: Buffer, row: uint) -> int {
	start := line_start(b, row)

	for i := start; i < len(b.data); i += 1 {
		if b.data[i] == '\n' {
			return i
		}
	}

	return len(b.data)
}

line_length :: proc(b: Buffer, row: uint) -> uint {
	start := line_start(b, row)
	end := line_end(b, row)
	return uint(end - start)
}

clamp_cursor :: proc(b: ^Buffer) {
	max_row := line_count(b^) - 1

	if b.cursor_row > max_row {
		b.cursor_row = max_row
	}

	max_col := line_length(b^, b.cursor_row)

	if b.cursor_col > max_col {
		b.cursor_col = max_col
	}
}

move_left :: proc(b: ^Buffer) {
	if b.cursor_col > 0 {
		b.cursor_col -= 1
		return
	}

	if b.cursor_row > 0 {
		b.cursor_row -= 1
		b.cursor_col = line_length(b^, b.cursor_row)
	}
}

move_right :: proc(b: ^Buffer) {
	current_line_length := line_length(b^, b.cursor_row)

	if b.cursor_col < current_line_length {
		b.cursor_col += 1
		return
	}

	if b.cursor_row + 1 < line_count(b^) {
		b.cursor_row += 1
		b.cursor_col = 0
	}
}

move_up :: proc(b: ^Buffer) {
	if b.cursor_row == 0 {
		return
	}

	b.cursor_row -= 1
	clamp_cursor(b)
}

move_down :: proc(b: ^Buffer) {
	if b.cursor_row + 1 >= line_count(b^) {
		return
	}

	b.cursor_row += 1
	clamp_cursor(b)
}

cursor_line :: proc(b: Buffer) -> uint {
	return b.cursor_row
}

cursor_column :: proc(b: Buffer) -> uint {
	return b.cursor_col
}
