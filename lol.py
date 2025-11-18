import ffmpeg

def mp4_to_gif(
    input_path,
    output_path,
    start_time,
    duration=None,
    fps=30
):
    palette_path = "palette.png"

    # -------------------------
    # 1) Generate palette
    # -------------------------
    video_in = ffmpeg.input(input_path, ss=start_time, t=duration)

    # Global filter graph
    palette = ffmpeg.filter(
        [video_in],
        "fps", fps
    )
    palette = ffmpeg.filter([palette], "scale", -1, -1)
    palette = ffmpeg.filter([palette], "palettegen")

    out1 = ffmpeg.output(palette, palette_path)
    out1 = out1.overwrite_output()
    out1.run()

    # -------------------------
    # 2) Generate GIF using palette
    # -------------------------
    video_in2 = ffmpeg.input(input_path, ss=start_time, t=duration)
    palette_in = ffmpeg.input(palette_path)

    # chain: fps → scale → paletteuse (two-input)
    gif = ffmpeg.filter(
        [video_in2],
        "fps", fps
    )
    gif = ffmpeg.filter([gif], "scale", -1, -1)
    gif = ffmpeg.filter([gif, palette_in], "paletteuse")

    out2 = ffmpeg.output(gif, output_path, loop=0)
    out2 = out2.overwrite_output()
    out2.run()

    print("GIF saved to:", output_path)


# Example usage
mp4_to_gif(
    r"S:\Coding\Flutter\locally\lib\features\wholesale_seller\home\presentation\widgets\Splash Screen.mp4",
    r"S:\Coding\Flutter\locally\assets\splash\final.gif",
    start_time=0.5,
    duration=6,
    fps=25
)
