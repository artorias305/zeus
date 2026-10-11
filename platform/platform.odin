package platform

import "../buffer"
import "../render"
import rl "vendor:raylib"

WIDTH :: 1000
HEIGHT :: 700
TITLE :: "Zeus"

init :: proc(filename: string) {
	rl.InitWindow(WIDTH, HEIGHT, TITLE)
	defer rl.CloseWindow()

	buf := buffer.open(filename)
	defer buffer.close(&buf)

	font := rl.LoadFontEx("./assets/fonts/jetbrains.ttf", 16, nil, 0)
	rl.SetTextureFilter(font.texture, .BILINEAR)

	for !rl.WindowShouldClose() {
		if rl.IsKeyPressed(.RIGHT) {
			buffer.move_right(&buf)
		} else if rl.IsKeyPressed(.LEFT) {
			buffer.move_left(&buf)
		} else if rl.IsKeyPressed(.UP) {
			buffer.move_up(&buf)
		} else if rl.IsKeyPressed(.DOWN) {
			buffer.move_down(&buf)
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		render.render_buffer(buf, font)

		rl.EndDrawing()
	}
}
