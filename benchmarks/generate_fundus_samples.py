"""
Pure Python (zero dependency) Synthetic Fundus Image Generator.
Writes standard 24-bit RGB BMP and PPM images directly to data/synthetic.
"""
import os
import math
import struct
import random

def write_bmp(filepath, width, height, rgb_grid):
    # BMP file header (14 bytes) and DIB header (BITMAPINFOHEADER - 40 bytes)
    row_padding = (4 - (width * 3) % 4) % 4
    image_size = (width * 3 + row_padding) * height
    file_size = 54 + image_size

    # BMP Header
    bmp_header = struct.pack('<2sIHHI', b'BM', file_size, 0, 0, 54)
    # DIB Header
    dib_header = struct.pack('<IIIHHIIIIII', 40, width, height, 1, 24, 0, image_size, 2835, 2835, 0, 0)

    with open(filepath, 'wb') as f:
        f.write(bmp_header)
        f.write(dib_header)
        # Rows in BMP are stored bottom to top
        for y in range(height - 1, -1, -1):
            row_bytes = bytearray()
            for x in range(width):
                r, g, b = rgb_grid[y][x]
                row_bytes.extend([b, g, r]) # BGR order
            row_bytes.extend([0] * row_padding)
            f.write(row_bytes)

def generate_fundus_samples():
    out_dir = os.path.join(os.path.dirname(__file__), 'data', 'synthetic')
    os.makedirs(out_dir, exist_ok=True)
    
    W, H = 512, 512
    cx, cy, r_ret = 256, 256, 220
    od_x, od_y, od_r = 140, 256, 36
    fov_x, fov_y, fov_r = 335, 256, 20

    random.seed(42)

    for grade in range(5):
        for sample_idx in range(1, 4):
            # Create pixel buffer
            pixels = [[[0, 0, 0] for _ in range(W)] for _ in range(H)]

            for y in range(H):
                for x in range(W):
                    dist_center = math.sqrt((x - cx)**2 + (y - cy)**2)
                    if dist_center <= r_ret:
                        # Retinal base pigment
                        falloff = 1.0 - 0.25 * (dist_center / r_ret)
                        r = int(190 * falloff)
                        g = int(85 * falloff)
                        b = int(22 * falloff)

                        # Optic Disc
                        dist_od = math.sqrt((x - od_x)**2 + (y - od_y)**2)
                        if dist_od <= od_r:
                            r, g, b = 245, 220, 110

                        # Fovea
                        dist_fov = math.sqrt((x - fov_x)**2 + (y - fov_y)**2)
                        if dist_fov <= fov_r:
                            r, g, b = int(r * 0.70), int(g * 0.65), int(b * 0.60)

                        # Vascular Arcade branches
                        # Arc 1 (Superior)
                        arc1_y = od_y - math.sin(max(0, (x - od_x)) / 220.0 * math.pi) * 110.0
                        if x >= od_x - 10 and abs(y - arc1_y) < 3.5:
                            r, g, b = int(r * 0.45), int(g * 0.25), int(b * 0.20)

                        # Arc 2 (Inferior)
                        arc2_y = od_y + math.sin(max(0, (x - od_x)) / 220.0 * math.pi) * 110.0
                        if x >= od_x - 10 and abs(y - arc2_y) < 3.5:
                            r, g, b = int(r * 0.45), int(g * 0.25), int(b * 0.20)

                        pixels[y][x] = [min(255, max(0, r)), min(255, max(0, g)), min(255, max(0, b))]

            # Inject Grade-Specific Lesions
            # Microaneurysms
            if grade >= 1:
                for _ in range(6 + grade * 5):
                    mx = random.randint(180, 420)
                    my = random.randint(140, 370)
                    for dy in range(-2, 3):
                        for dx in range(-2, 3):
                            if 0 <= my+dy < H and 0 <= mx+dx < W and (dx*dx + dy*dy) <= 4:
                                pixels[my+dy][mx+dx] = [60, 10, 8]

            # Hard Exudates & Hemorrhages
            if grade >= 2:
                for _ in range(8 + grade * 4):
                    hx = random.randint(280, 390)
                    hy = random.randint(200, 310)
                    for dy in range(-3, 4):
                        for dx in range(-3, 4):
                            if 0 <= hy+dy < H and 0 <= hx+dx < W and (dx*dx + dy*dy) <= 9:
                                pixels[hy+dy][hx+dx] = [252, 245, 95]

                for _ in range(6 + grade * 6):
                    hmx = random.randint(160, 420)
                    hmy = random.randint(140, 380)
                    for dy in range(-4, 5):
                        for dx in range(-4, 5):
                            if 0 <= hmy+dy < H and 0 <= hmx+dx < W and (dx*dx + dy*dy) <= 16:
                                pixels[hmy+dy][hmx+dx] = [50, 5, 5]

            # Neovascularization (Grade 4)
            if grade >= 4:
                for _ in range(12):
                    nx = od_x + random.randint(-25, 25)
                    ny = od_y + random.randint(-25, 25)
                    for step in range(15):
                        px = int(nx + step * math.cos(step * 0.5))
                        py = int(ny + step * math.sin(step * 0.5))
                        if 0 <= py < H and 0 <= px < W:
                            pixels[py][px] = [75, 12, 10]

            bmp_filename = f'DR_Grade{grade}_Sample{sample_idx:02d}.bmp'
            bmp_path = os.path.join(out_dir, bmp_filename)
            write_bmp(bmp_path, W, H, pixels)

    print(f"[SUCCESS] Generated synthetic fundus BMP benchmarks across Grades 0-4 in: {out_dir}")

if __name__ == '__main__':
    generate_fundus_samples()
