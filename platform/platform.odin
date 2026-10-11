package platform

import "../buffer"
import "../render"
import "core:log"
import "core:os"
import rl "vendor:raylib"

WIDTH :: 1000
HEIGHT :: 700
TITLE :: "Zeus"

init :: proc(filename: string) {
	rl.InitWindow(WIDTH, HEIGHT, TITLE)
	defer rl.CloseWindow()

	buf := buffer.open(filename)
	defer buffer.close(&buf)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		render.render_buffer(buf)
		rl.EndDrawing()
	}
}
