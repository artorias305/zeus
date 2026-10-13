package buffer

import "core:log"
import "core:os"
import "core:strings"
import "core:unicode/utf8"

Buffer :: struct {
	data:       []byte,
	fp:         ^os.File,
	c_string:   cstring,
	cursor_row: uint,
	cursor_col: uint,
	dirty:      bool,
	line_count: uint,
}

open :: proc(filename: string) -> (b: Buffer) {
	file_data, err := os.read_entire_file(filename, context.allocator)

	if err != nil {
		if err == os.General_Error.Not_Exist {
			// If the file doesn't exist, create it
			fp, create_err := os.create(filename)
			if create_err != nil {
				log.fatalf("Error creating file '%s': %s", filename, os.error_string(create_err))
			}

			b.data = make([]byte, 0, context.allocator)
			b.fp = fp
		} else {
			log.fatalf("Error reading file '%s': %s", filename, os.error_string(err))
		}
	} else {
		b.data = file_data

		fp, open_err := os.open(filename, {.Read, .Write})
		if open_err != nil {
			log.fatalf("Error opening file '%s': %s", filename, os.error_string(open_err))
		}

		b.fp = fp
	}

	b.c_string = strings.clone_to_cstring(string(b.data), context.allocator)
	b.cursor_row = 0
	b.cursor_col = 0
	b.dirty = false

	line_count: uint = 0
	string_data := string(b.data)
	for line in strings.split_iterator(&string_data, "\n") {
		line_count += 1
	}
	b.line_count = line_count

	return b
}

close :: proc(b: ^Buffer) {
	if b.fp != nil {
		if err := os.close(b.fp); err != nil {
			log.errorf("Error closing file '%s': %s", os.name(b.fp), os.error_string(err))
		}

		b.fp = nil
	}

	delete(b.data, context.allocator)
	delete(b.c_string, context.allocator)
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
		_, width := utf8.decode_last_rune_in_bytes(
			b.data[line_start(b^, b.cursor_row):line_start(b^, b.cursor_row) + int(b.cursor_col)],
		)

		b.cursor_col -= uint(width)
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
		start := line_start(b^, b.cursor_row) + int(b.cursor_col)
		_, width := utf8.decode_rune_in_bytes(b.data[start:])

		b.cursor_col += uint(width)
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

set_cursor_position :: proc(b: ^Buffer, row, column: uint) {
	b.cursor_row = row
	b.cursor_col = column
	clamp_cursor(b)
}

rebuild_c_string :: proc(b: ^Buffer) {
	delete(b.c_string, context.allocator)
	b.c_string = strings.clone_to_cstring(string(b.data), context.allocator)
}

replace_range :: proc(b: ^Buffer, start, remove_count: int, insert: []byte) {
	new_data := make([]byte, len(b.data) - remove_count + len(insert), context.allocator)

	copy(new_data, b.data[:start])
	copy(new_data[start:], insert)
	copy(new_data[start + len(insert):], b.data[start + remove_count:])

	delete(b.data, context.allocator)

	b.data = new_data
	b.dirty = true

	rebuild_c_string(b)
}

insert_bytes :: proc(b: ^Buffer, bytes: []byte) {
	start := line_start(b^, b.cursor_row) + int(b.cursor_col)
	replace_range(b, start, 0, bytes)
}

insert_rune :: proc(b: ^Buffer, character: rune) {
	encoded, width := utf8.encode_rune(character)

	insert_bytes(b, encoded[:width])
	b.cursor_col += uint(width)
}

insert_newline :: proc(b: ^Buffer) {
	insert_bytes(b, []byte{'\n'})

	b.cursor_row += 1
	b.cursor_col = 0
}

backspace :: proc(b: ^Buffer) {
	if b.cursor_col > 0 {
		start := line_start(b^, b.cursor_row)
		cursor_index := start + int(b.cursor_col)

		_, width := utf8.decode_last_rune_in_bytes(b.data[start:cursor_index])

		replace_range(b, cursor_index - width, width, nil)

		b.cursor_col -= uint(width)
		return
	}

	if b.cursor_row > 0 {
		current_start := line_start(b^, b.cursor_row)
		previous_length := line_length(b^, b.cursor_row - 1)

		replace_range(b, current_start - 1, 1, nil)

		b.cursor_row -= 1
		b.cursor_col = previous_length
	}
}

delete_forward :: proc(b: ^Buffer) {
	start := line_start(b^, b.cursor_row) + int(b.cursor_col)
	end := line_end(b^, b.cursor_row)

	if start < end {
		_, width := utf8.decode_rune_in_bytes(b.data[start:end])
		replace_range(b, start, width, nil)
		return
	}

	if start < len(b.data) && b.data[start] == '\n' {
		replace_range(b, start, 1, nil)
	}
}

save :: proc(b: ^Buffer) -> os.Error {
	if b.fp == nil {
		return os.General_Error.Invalid_File
	}

	if _, err := os.seek(b.fp, 0, .Start); err != nil {
		return err
	}

	if _, err := os.write(b.fp, b.data); err != nil {
		return err
	}

	if err := os.truncate(b.fp, i64(len(b.data))); err != nil {
		return err
	}

	if err := os.flush(b.fp); err != nil {
		return err
	}

	if err := os.sync(b.fp); err != nil {
		return err
	}

	b.dirty = false
	return nil
}

has_unsaved_changes :: proc(b: Buffer) -> bool {
	return b.dirty
}

go_to_last_line :: proc(b: ^Buffer) {
	b.cursor_row = b.line_count
}

go_to_first_line :: proc(b: ^Buffer) {
	b.cursor_row = 0
}
