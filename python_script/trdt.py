from PIL import Image

# This map converts your FPGA's ASCII symbols into brightness (0-255)
chars = "$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/\\|()1{}[]?-_+~<>i!lI;:,\"^`'. "
char_map = {c: int(i * (255 / len(chars))) for i, c in enumerate(reversed(chars))}

# Open the file and tell it to ignore characters it doesn't understand
with open('putty.log', 'r', encoding="utf-8", errors="ignore") as f:
    lines = [line.strip() for line in f.readlines() if line.strip()]

if not lines:
    print("The file is empty or could not be read.")
else:
    height = len(lines)
    width = max(len(line) for line in lines)
    
    # Create a new Grayscale image
    img = Image.new('L', (width, height))

    for y, line in enumerate(lines):
        for x, char in enumerate(line):
            # Map the character to a brightness value
            pixel_val = char_map.get(char, 127) # Default to gray if unknown
            img.putpixel((x, y), pixel_val)

    img.save('blurred_result.png')
    print(f"Success! Image saved as blurred_result.png ({width}x{height})")