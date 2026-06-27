//
//  Base32.swift
//  Obsidium
//
//  Minimal RFC 4648 Base32 decoder. CryptoKit/Foundation do not provide one,
//  and otpauth:// secrets are always Base32-encoded, so we need our own.
//

import Foundation

enum Base32 {
    /// RFC 4648 §6 alphabet (A–Z, 2–7).
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")

    /// Reverse lookup: ASCII value -> 5-bit group value, or -1 if not in alphabet.
    private static let decodeTable: [Int8] = {
        var table = [Int8](repeating: -1, count: 128)
        for (index, char) in alphabet.enumerated() {
            table[Int(char.asciiValue!)] = Int8(index)
        }
        return table
    }()

    /// Decode a Base32 string into raw bytes.
    ///
    /// Tolerant of real-world input: case-insensitive, ignores `=` padding and
    /// whitespace. Returns `nil` if any other character is invalid or the bit
    /// length doesn't form whole bytes.
    static func decode(_ input: String) -> Data? {
        var buffer: UInt64 = 0      // accumulates decoded bits, MSB-first
        var bitsInBuffer = 0
        var output = [UInt8]()

        for scalar in input.unicodeScalars {
            // Skip padding and any whitespace.
            if scalar == "=" || CharacterSet.whitespaces.contains(scalar) {
                continue
            }

            // Uppercase ASCII letters only; reject anything outside the table.
            let value = scalar.value
            guard value < 128 else { return nil }
            let upper = (value >= 97 && value <= 122) ? value - 32 : value
            guard upper < 128 else { return nil }

            let groupValue = decodeTable[Int(upper)]
            guard groupValue >= 0 else { return nil }

            buffer = (buffer << 5) | UInt64(groupValue)
            bitsInBuffer += 5

            // Emit a byte whenever 8+ bits have accumulated.
            if bitsInBuffer >= 8 {
                bitsInBuffer -= 8
                let byte = UInt8((buffer >> UInt64(bitsInBuffer)) & 0xFF)
                output.append(byte)
            }
        }

        // Leftover bits must be zero padding (< 8 bits); non-zero means malformed.
        if bitsInBuffer > 0 {
            let mask = (UInt64(1) << UInt64(bitsInBuffer)) - 1
            if buffer & mask != 0 { return nil }
        }

        return Data(output)
    }
}
