package platform

import "../buffer"
import "../render"
import "core:fmt"
import "core:os"
import rl "vendor:raylib"

WIDTH :: 1000
HEIGHT :: 700
TITLE :: "Zeus"

init :: proc(filename: string) {
	rl.InitWindow(WIDTH, HEIGHT, TITLE)
	defer rl.CloseWindow()

	rl.SetExitKey(.KEY_NULL)

	buf := buffer.open(filename)
	defer buffer.close(&buf)

	font := rl.LoadFontEx("./assets/fonts/jetbrains.ttf", i32(render.FONT_SIZE), nil, 0)

	rl.SetTextureFilter(font.texture, .POINT)

	for !rl.WindowShouldClose() {
		control_down := rl.IsKeyDown(.LEFT_CONTROL) || rl.IsKeyDown(.RIGHT_CONTROL)

		command_down := rl.IsKeyDown(.LEFT_SUPER) || rl.IsKeyDown(.RIGHT_SUPER)

		if (control_down || command_down) && rl.IsKeyPressed(.S) {
			if err := buffer.save(&buf); err != nil {
				fmt.eprintfln("Could not save file: %s", os.error_string(err))
			}
		}

		if rl.IsKeyPressed(.RIGHT) {
			buffer.move_right(&buf)
		} else if rl.IsKeyPressed(.LEFT) {
			buffer.move_left(&buf)
		} else if rl.IsKeyPressed(.UP) {
			buffer.move_up(&buf)
		} else if rl.IsKeyPressed(.DOWN) {
			buffer.move_down(&buf)
		}

		if rl.IsKeyPressed(.ENTER) {
			buffer.insert_newline(&buf)
		}

		if rl.IsKeyPressed(.BACKSPACE) {
			buffer.backspace(&buf)
		}

		if rl.IsKeyPressed(.DELETE) {
			buffer.delete_forward(&buf)
		}

		for character := rl.GetCharPressed(); character != 0; character = rl.GetCharPressed() {
			if character >= 32 && character != 127 && character != '\n' && character != '\r' {
				buffer.insert_rune(&buf, character)
			}
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		render.render_buffer(buf, font)

		rl.EndDrawing()
	}
}
