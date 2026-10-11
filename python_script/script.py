# Read your existing imageData.h and extract the numbers
with open('imageData.h', 'r') as f:
    content = f.read()

# Extract numbers from the array (assuming format: char imageData[] = {59,56,58,...};)
# Find everything between { and }
start = content.find('{') + 1
end = content.find('}')
numbers_string = content[start:end]

# Split by comma and convert to integers
pixels = [int(x.strip()) for x in numbers_string.split(',') if x.strip()]

print(f"Found {len(pixels)} pixel values")

# Now write formatted version
values_per_line = 16

with open('imageData_formatted.h', 'w') as f:
    f.write('#ifndef IMAGEDATA_H\n')
    f.write('#define IMAGEDATA_H\n\n')
    f.write('#include "xil_types.h"\n\n')
    f.write('// Image data: 512x512 pixels\n')
    f.write('u8 imageData[512*512] __attribute__((aligned(32))) = {\n')
    
    for i in range(0, len(pixels), values_per_line):
        line_data = pixels[i:i+values_per_line]
        # Add row comment every 512 values
        if i % 512 == 0:
            f.write(f'\n    // Row {i//512}\n')
        f.write('    ' + ', '.join(map(str, line_data)) + ',\n')
    
    f.write('};\n\n')
    f.write('#endif\n')

print("Done! Check imageData_formatted.h")