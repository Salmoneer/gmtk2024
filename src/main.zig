const std = @import("std");
const rl = @import("raylib");

const render_width: i32 = 320;
const render_height: i32 = 180;

const window_width: i32 = 1920;
const window_height: i32 = 1080;

const octaves: i32 = 2;

const num_sound_files: i32 = 25;

const note_names: [num_sound_files][*:0]const u8 = .{
    "./assets/audio/c3.mp3",
    "./assets/audio/c-3.mp3",
    "./assets/audio/d3.mp3",
    "./assets/audio/d-3.mp3",
    "./assets/audio/e3.mp3",
    "./assets/audio/f3.mp3",
    "./assets/audio/f-3.mp3",
    "./assets/audio/g3.mp3",
    "./assets/audio/g-3.mp3",
    "./assets/audio/a4.mp3",
    "./assets/audio/a-4.mp3",
    "./assets/audio/b3.mp3",
    "./assets/audio/c4.mp3",
    "./assets/audio/c-4.mp3",
    "./assets/audio/d4.mp3",
    "./assets/audio/d-4.mp3",
    "./assets/audio/e4.mp3",
    "./assets/audio/f4.mp3",
    "./assets/audio/f-4.mp3",
    "./assets/audio/g4.mp3",
    "./assets/audio/g-4.mp3",
    "./assets/audio/a5.mp3",
    "./assets/audio/a-5.mp3",
    "./assets/audio/b5.mp3",
    "./assets/audio/c5.mp3",
};

// // https://en.wikipedia.org/wiki/Piano_key_frequencies#List
// const frequencies: [12]f32 = .{
//     523.2511,
//     554.3653,
//     587.3295,
//     622.2540,
//     659.2551,
//     698.4565,
//     739.9888,
//     783.9909,
//     830.6094,
//     880.0000,
//     932.3275,
//     987.7666,
// };

const EngineState = struct {
    render_texture: rl.RenderTexture = undefined,

    piano_texture: rl.Texture = undefined,
    piano_end_texture: rl.Texture = undefined,

    piano_notes: [num_sound_files]rl.Sound = .{undefined} ** num_sound_files,
};

pub fn main() !void {
    rl.initWindow(window_width, window_height, "GMTK Jam 2024");
    defer rl.closeWindow();

    rl.initAudioDevice();
    defer rl.closeAudioDevice();

    rl.setTargetFPS(60);

    var es = EngineState{};

    es.render_texture = rl.RenderTexture.init(render_width, render_height);
    defer es.render_texture.unload();

    es.piano_texture = rl.Texture.init("./assets/textures/piano_octave.png");
    defer es.piano_texture.unload();

    es.piano_end_texture = rl.Texture.init("./assets/textures/piano_end.png");
    defer es.piano_end_texture.unload();

    for (0..num_sound_files) |i| {
        es.piano_notes[i] = rl.loadSound(note_names[i]);
    }

    while (!rl.windowShouldClose()) {
        const piano_width = octaves * es.piano_texture.width + es.piano_end_texture.width;
        const piano_height = es.piano_texture.height;

        const piano_x = @divExact(render_width, 2) - @divFloor(piano_width, 2);
        const piano_y = @divExact(render_height, 2) - @divFloor(piano_height, 2);

        const mouse_x = @divFloor(rl.getMouseX(), @divFloor(rl.getScreenWidth(), render_width));
        const mouse_y = @divFloor(rl.getMouseY(), @divFloor(rl.getScreenHeight(), render_height));

        const mouse_piano_x = mouse_x - piano_x;
        const mouse_piano_y = mouse_y - piano_y;

        const temp_octave = @min(@divFloor(mouse_piano_x, es.piano_texture.width), octaves - 1);
        const octave = if (temp_octave >= 0) @as(usize, @intCast(temp_octave)) else null;
        const note = if (mouse_piano_x < piano_width) get_piano_key(@mod(mouse_piano_x, es.piano_texture.width), mouse_piano_y, piano_width, piano_height) else null;

        if (rl.isMouseButtonPressed(.mouse_button_left) and note != null and octave != null) {
            const note_index = octave.? * 12 + note.?;
            rl.playSound(es.piano_notes[note_index]);
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        {
            es.render_texture.begin();
            defer es.render_texture.end();

            rl.clearBackground(rl.Color.blue);

            for (0..octaves) |i| {
                es.piano_texture.draw(piano_x + @as(i32, @intCast(i)) * @as(i32, es.piano_texture.width), piano_y, rl.Color.white);
            }

            es.piano_end_texture.draw(piano_x + octaves * @as(i32, es.piano_texture.width), piano_y, rl.Color.white);
        }

        const src = rl.Rectangle.init(
            0,
            0,
            @floatFromInt(render_width),
            @floatFromInt(-render_height),
        );

        const dst = rl.Rectangle.init(
            0,
            0,
            @as(f32, @floatFromInt(rl.getScreenWidth())),
            @as(f32, @floatFromInt(rl.getScreenHeight())),
        );

        es.render_texture.texture.drawPro(src, dst, rl.Vector2.zero(), 0, rl.Color.white);
    }

    for (0..num_sound_files) |i| {
        rl.unloadSound(es.piano_notes[i]);
    }
}

fn get_piano_key(x: i32, y: i32, w: i32, h: i32) ?usize {
    if (x < 2 or y < 2 or x >= w or y >= h) {
        return null;
    }

    if ((x <= 9 and y <= 33) or (x <= 13 and y >= 34)) {
        return 0;
    } else if (x >= 10 and x <= 17 and y <= 33) {
        return 1;
    } else if ((x >= 18 and x <= 25 and y <= 32) or (x >= 16 and y >= 34 and x <= 27 and y <= 55)) {
        return 2;
    } else if (x >= 26 and x <= 33 and y <= 33) {
        return 3;
    } else if ((x >= 34 and x <= 41 and y <= 32) or (x >= 30 and y >= 34 and x <= 41 and y <= 55)) {
        return 4;
    } else if ((x >= 44 and x <= 51 and y <= 33) or (x >= 44 and y >= 34 and x <= 55 and y <= 55)) {
        return 5;
    } else if (x >= 52 and x <= 59 and y <= 33) {
        return 6;
    } else if ((x >= 60 and x <= 67 and y <= 32) or (x >= 58 and y >= 34 and x <= 69 and y <= 55)) {
        return 7;
    } else if (x >= 68 and x <= 75 and y <= 33) {
        return 8;
    } else if ((x >= 76 and x <= 83 and y <= 32) or (x >= 73 and y >= 34 and x <= 85 and y <= 55)) {
        return 9;
    } else if (x >= 84 and x <= 91 and y <= 33) {
        return 10;
    } else if ((x >= 92 and x <= 99 and y <= 32) or (x >= 88 and y >= 34 and x <= 99 and y <= 55)) {
        return 11;
    }

    return null;
}
