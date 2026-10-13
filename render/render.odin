package render

import "../buffer"
import "core:strings"
import rl "vendor:raylib"

FONT_SIZE: f32 = 16
CHAR_SPACING: f32 = 0

line_height :: proc(font: rl.Font) -> f32 {
	return f32(font.baseSize + font.baseSize / 2)
}

render_buffer :: proc(buf: buffer.Buffer, font: rl.Font, scroll_y: f32) {
	height := line_height(font)

	for row: uint = 0; row < buffer.line_count(buf); row += 1 {
		start := buffer.line_start(buf, row)
		end := buffer.line_end(buf, row)

		line := string(buf.data[start:end])
		line_cstring := strings.clone_to_cstring(line, context.temp_allocator)
		defer delete(line_cstring, context.temp_allocator)

		rl.DrawTextEx(
			font,
			line_cstring,
			{0, f32(row) * height - scroll_y},
			FONT_SIZE,
			CHAR_SPACING,
			rl.WHITE,
		)
	}

	row := buffer.cursor_line(buf)
	column := buffer.cursor_column(buf)

	start := buffer.line_start(buf, row)
	end := buffer.line_end(buf, row)
	cursor_index := start + int(column)

	prefix := string(buf.data[start:cursor_index])
	prefix_cstring := strings.clone_to_cstring(prefix, context.temp_allocator)
	defer delete(prefix_cstring, context.temp_allocator)

	prefix_size := rl.MeasureTextEx(font, prefix_cstring, FONT_SIZE, CHAR_SPACING)

	cursor_x := prefix_size.x
	cursor_y := f32(row) * height - scroll_y

	cell_size := rl.MeasureTextEx(font, "M", FONT_SIZE, CHAR_SPACING)

	rl.DrawRectangle(i32(cursor_x), i32(cursor_y), i32(cell_size.x), i32(FONT_SIZE), rl.WHITE)

	if cursor_index < end {
		character := string(buf.data[cursor_index:cursor_index + 1])
		character_cstring := strings.clone_to_cstring(character, context.temp_allocator)
		defer delete(character_cstring, context.temp_allocator)

		rl.DrawTextEx(
			font,
			character_cstring,
			{cursor_x, cursor_y},
			FONT_SIZE,
			CHAR_SPACING,
			rl.BLACK,
		)
	}
}
