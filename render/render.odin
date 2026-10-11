package render

import "../buffer"
import rl "vendor:raylib"

render_buffer :: proc(buf: buffer.Buffer, font: rl.Font) {
	rl.DrawTextEx(font, buf.c_string, {0, 0}, 16, 0, rl.WHITE)
}
