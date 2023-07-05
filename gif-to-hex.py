import binascii

with open('file.gif', 'rb') as f:
    content = f.read()

hex_string = binascii.hexlify(content)
print(hex_string)
