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

	font := rl.LoadFontEx("./assets/fonts/jetbrains.ttf", 16, nil, 0)
	rl.SetTextureFilter(font.texture, .BILINEAR)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		render.render_buffer(buf, font)
		rl.EndDrawing()
	}
}
