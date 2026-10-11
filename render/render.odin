package render

import "../buffer"
import "core:strings"
import rl "vendor:raylib"

FONT_SIZE: f32 = 16
LINE_HEIGHT: f32 = 20
CHAR_SPACING: f32 = 0

render_buffer :: proc(buf: buffer.Buffer, font: rl.Font) {
	rl.DrawTextEx(font, buf.c_string, {0, 0}, FONT_SIZE, CHAR_SPACING, rl.WHITE)

	row := buffer.cursor_line(buf)
	column := buffer.cursor_column(buf)

	start := buffer.line_start(buf, row)
	end := buffer.line_end(buf, row)

	prefix := string(buf.data[start:start + int(column)])
	prefix_cstring := strings.clone_to_cstring(prefix, context.allocator)
	defer delete(prefix_cstring)

	prefix_size := rl.MeasureTextEx(font, prefix_cstring, FONT_SIZE, CHAR_SPACING)

	cursor_x := prefix_size.x
	cursor_y := f32(row) * LINE_HEIGHT

	rl.DrawRectangle(i32(cursor_x), i32(cursor_y), 2, i32(FONT_SIZE), rl.WHITE)
}
