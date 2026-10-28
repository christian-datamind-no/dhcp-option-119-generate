#!/usr/bin/env python3
"""Generate the hex value for DHCP option 119 (domain search list, RFC 3397).

Usage:
    ./dhcp-option-119-generate.py z1.prod.hotgarbagellc.net prod.hotgarbagellc.net hotgarbagellc.net
"""

import sys


def encode_domains(domains):
    """Encode domains per RFC 1035 section 4.1.4, using suffix compression pointers."""
    data = bytearray()
    # Maps a domain suffix (e.g. "hotgarbagellc.net") to its offset in data
    suffix_offsets = {}

    for domain in domains:
        labels = [label for label in domain.strip().rstrip(".").split(".") if label]

        for i in range(len(labels)):
            suffix = ".".join(labels[i:]).lower()

            if suffix in suffix_offsets:
                offset = suffix_offsets[suffix]
                data += bytes([0xC0 | (offset >> 8), offset & 0xFF])
                break

            label = labels[i].encode("ascii")
            if len(label) > 63:
                raise ValueError(f"Label '{labels[i]}' exceeds 63 characters")

            # Pointers can only address the first 0x3FFF bytes
            if len(data) <= 0x3FFF:
                suffix_offsets[suffix] = len(data)

            data.append(len(label))
            data += label
        else:
            data.append(0x00)

    return bytes(data)


def main():
    domains = sys.argv[1:]
    if not domains:
        print(f"Usage: {sys.argv[0]} <domain> [domain ...]", file=sys.stderr)
        sys.exit(1)

    hex_string = ":".join(f"{b:02x}" for b in encode_domains(domains))

    print("domains:")
    for domain in domains:
        print(f"  {domain}")
    print(f"hexString: {hex_string}")


if __name__ == "__main__":
    main()
