def generate_sequence_from_notes(input_file_path):
    note_lines = []
    
    with open(input_file_path, 'r') as f:
        for line in f:
            print ("==", line)
            line = line.strip()
            if not line or len(line.split()) != 3:
                continue
            note, count, octave = line.split()
            if note.upper() not in ['A', 'B', 'C', 'D', 'E', 'F', 'G']:
                continue
            try:
                count = int(count)
            except ValueError:
                continue
            note_lines.extend([[note.upper(), octave]] * count)

    output = []
    for idx, note in enumerate(note_lines):
        output.append(f"{idx}:  {{ octave, note }} = {{ 3'b{note[1]}, {note[0]} }};")

    return '\n'.join(output)


if __name__ == "__main__":
    input_path = "./input.txt"
    result = generate_sequence_from_notes(input_path)
    print(result)