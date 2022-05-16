def ca65_byte_literal(value):
  return "$%02x" % (value & 0xFF)

def ca65_word_literal(value):
  return "$%04x" % (value & 0xFFFF)

def ca65_comment(text):
    return f"; {text}"

def ca65_label(label_name):
    return f"{label_name}:"

def pretty_print_table(raw_bytes, output_file, width=16):
  """ Formats a byte array as a big block of ca65 literals

  Just for style purposes, I'd like to collapse the table so that 
  only so many bytes are printed on each line. This is nicer than one 
  giant line or tons of individual .byte statements.
  """
  formatted_bytes = [ca65_byte_literal(byte) for byte in raw_bytes]
  for table_row in range(0, int(len(formatted_bytes) / width)):
    row_text = ", ".join(formatted_bytes[table_row * width : table_row * width + width])
    print("  .byte %s" % row_text, file=output_file)

  final_row = formatted_bytes[int(len(formatted_bytes) / width) * width : ]
  if len(final_row) > 0:
    final_row_text = ", ".join(final_row)
    print("  .byte %s" % final_row_text, file=output_file)