package render

import "../buffer"
import rl "vendor:raylib"

render_buffer :: proc(buf: buffer.Buffer) {
	rl.DrawText(buf.c_string, 0, 0, 10, rl.WHITE)
}
