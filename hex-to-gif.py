import binascii

hex_string = ""

try:
    gif_bytes = binascii.unhexlify(hex_string)
except binascii.Error as e:
    print("binascii error:", e)
    exit()

with open('output.gif', 'wb') as f:
    f.write(gif_bytes)
