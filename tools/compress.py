#!/usr/bin/env python3
import itertools
from dataclasses import dataclass, field

@dataclass
class Pointer:
    offset: int
    length: int
    data: [int]

@dataclass
class DataBlock:
    length: int
    data: [int]

def matching_bytes(iterator, candidate_list):
    count = 0
    for i in range(0, len(candidate_list)):
        if iterator.__next__() != candidate_list[i]:
            return count
        count += 1
    return count

def find_longest_match(sliding_window, candidate_bytes):
    current_offset = 0
    current_max_length = 0
    for i in reversed(range(0,len(sliding_window))):
        iterator = itertools.cycle(sliding_window[i:])
        match_length = matching_bytes(iterator, candidate_bytes)
        if match_length > current_max_length:
            current_max_length = match_length
            current_offset = len(sliding_window) - i
        if match_length == len(candidate_bytes):
            return current_offset, current_max_length
    return current_offset, current_max_length

def lz77_packets(original_bytes, max_offset, max_length):
    written_bytes = []
    bytes_to_compress = list(original_bytes)
    packets = []

    # one iteration, haven't written the loop body yet
    while len(bytes_to_compress) > 0:
        candidate_bytes = bytes_to_compress[0:max_length]
        sliding_window = written_bytes[-min(max_offset, len(written_bytes)):]
        matched_offset, matched_length = find_longest_match(sliding_window, candidate_bytes)
        if matched_length == 0:
            # no match was found, emit a data packet
            data_bytes = bytes_to_compress[0:1]
            packets.append(DataBlock(length=1,data=data_bytes))
            # adjust our working lists for the next iteration
            written_bytes.extend(data_bytes)
            bytes_to_compress = bytes_to_compress[1:]
        else:
            # a match was found, emit a pointer to the matched data
            referenced_bytes = bytes_to_compress[0:matched_length]
            packets.append(Pointer(offset=matched_offset,length=matched_length, data=referenced_bytes))
            # adjust our working lists for the next iteration
            written_bytes.extend(referenced_bytes)
            bytes_to_compress = bytes_to_compress[matched_length:]
    return packets

def pop_adjacent_data_packets(packet_list):
    data_packets = []
    while len(packet_list) > 0:
        if isinstance(packet_list[0], DataBlock):
            data_packets.append(packet_list.pop(0))
        elif isinstance(packet_list[0], Pointer) and packet_list[0].length == 1:
            data_packets.append(packet_list.pop(0))
        else:
            return data_packets
    return data_packets

def collapse_data_packets(original_packets, max_data_packet_length):
    collapsed_packets = []
    packets_to_consider = list(original_packets)
    while len(packets_to_consider) > 0:
        candidate_data_packets = pop_adjacent_data_packets(packets_to_consider)
        if len(candidate_data_packets) == 0:
            # This referenced pointer is too big to collapse efficiently
            collapsed_packets.append(packets_to_consider.pop(0))
        elif len(candidate_data_packets) == 1:
            # This is a single data packet, and cannot be made any smaller
            collapsed_packets.extend(candidate_data_packets)
        else:
            # Each data block header is 1 byte. If we have two single-byte pointers, then converting them
            # into a single data block *adds* data. So, if we're going to collapse a run of 2
            # packets, we only want to do so when that run contains one DataBlock already.
            if len(candidate_data_packets) == 2 and isinstance(candidate_data_packets[0], Pointer) and isinstance(candidate_data_packets[1], Pointer):
                # These two pointer bytes are more efficient as they are, do not collapse them
                collapsed_packets.extend(candidate_data_packets)
            else:
                # we got 2 or more data packets in a row, collapse them into combined data packets,
                # up to the max length for each
                data_bytes = []
                for packet in candidate_data_packets:
                    data_bytes.extend(packet.data)
                while len(data_bytes) > 0:
                    packet_data = data_bytes[0:8]
                    data_bytes = data_bytes[8:]
                    collapsed_packets.append(DataBlock(length=len(packet_data),data=packet_data))
    return collapsed_packets

def raw_bytes_from_packets(packets):
    byte_array = []
    for packet in packets:
        if isinstance(packet, Pointer):
            pointer_byte = (packet.offset << 3) | packet.length - 1
            byte_array.append(pointer_byte)
        if isinstance(packet, DataBlock):
            data_header = packet.length - 1 # effective offset of 0
            byte_array.append(data_header)
            byte_array.extend(packet.data)
    return byte_array

def compress_lz77(byte_array):
    packets = lz77_packets(byte_array, 31, 8)
    collapsed_packets = collapse_data_packets(packets, 8)
    return raw_bytes_from_packets(collapsed_packets)
    
def delta_encode(byte_array):
    delta_encoded_bytes = byte_array[0:1]
    bytes_to_encode = byte_array[1:]
    while len(bytes_to_encode) > 0:
        previous_byte = delta_encoded_bytes[len(delta_encoded_bytes)-1]
        original_byte = bytes_to_encode.pop(0)
        delta = original_byte - previous_byte
        delta_encoded_bytes.append(delta)
    return delta_encoded_bytes

# Tries all known compression methods. Returns the compressed data and a type byte. Chooses
# the smallest possible result, regardless of complexity.
def compress_smallest(byte_array):
    uncompressed = byte_array
    # return 0, uncompressed # FOR DEBUGGING, don't compress at all
    plain_lz77 = compress_lz77(byte_array)

    best_length = min(len(uncompressed), len(plain_lz77))

    if best_length == len(uncompressed):
        return 0, uncompressed
    if best_length == len(plain_lz77):
        return 1, plain_lz77

if __name__ == '__main__':
    # DEBUG TEST THINGS
    test_array = [0, 0, 0, 1, 2, 3, 4, 5, 2, 2, 2, 4, 2, 6, 5, 1, 2, 4, 0, 0, 0, 0, 1, 1, 2, 1, 1, 1, 0, 0, 0]

    # just for testing, later this module should act like a library
    from ca65 import pretty_print_table, ca65_label, ca65_byte_literal, ca65_word_literal
    import sys
    print("Original bytes with length %d: " % len(test_array))
    pretty_print_table(test_array, output_file=sys.stdout)

    delta_array = delta_encode(test_array)
    print("Delta-encoded bytes with length %d: " % len(delta_array))
    pretty_print_table(delta_array, output_file=sys.stdout)

    compressed_array = compress_lz77(test_array)
    print("Compressed original bytes with length %d: " % len(compressed_array))
    pretty_print_table(compressed_array, output_file=sys.stdout)

    compressed_delta_array = compress_lz77(delta_array)
    print("Compressed delta-encoded bytes with length %d: " % len(compressed_delta_array))
    pretty_print_table(compressed_delta_array, output_file=sys.stdout)


