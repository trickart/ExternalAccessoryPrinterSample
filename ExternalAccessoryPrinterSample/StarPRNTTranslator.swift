//
//  StarPRNTTranslator.swift
//  ExternalAccessoryPrinterSample
//
//  Created by trickart on 2023/08/22.
//

import CoreGraphics
import Foundation

final class StarPRNTTranslator {
    static func rasterImageCommand(from cgImage: CGImage) -> [UInt8] {
        let width = cgImage.width
        let mod = width % 8
        let shortage = (8 - mod) % 8
        let fixedWidth = (width + shortage) / 8

        let height = cgImage.height

        let xL = UInt8(fixedWidth % 256)
        let xH = UInt8(fixedWidth / 256)
        let yL = UInt8(height % 256)
        let yH = UInt8(height / 256)

        let command: [UInt8] = [
            0x1b, 0x1d, 0x53, // ESC GS S
            0x01, // m=1
            xL, xH, // xL xH
            yL, yH, // yL yH
            0x00, // n=0
        ]
        let bitMap = bitMapBytes(from: cgImage)
        return command + bitMap
    }

    static func bitMapBytes(from cgImage: CGImage) -> [UInt8] {
        let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
        guard bytesPerPixel == 4 || bytesPerPixel == 2 else {
            print("not support bytes per pixel is not 4. per pixel: \(cgImage.bitsPerPixel), per component: \(cgImage.bitsPerComponent)")
            return []
        }

        guard let data = cgImage.dataProvider?.data,
              let pointer = CFDataGetBytePtr(data) else { return [] }

        let width = cgImage.width
        let height = cgImage.height

        // 8の倍数でしか指定できないので詰めるpixel数を計算している
        let mod = width % 8
        let shortage = (8 - mod) % 8
        let left = shortage / 2
        let right = shortage - left

        var buffer: [Bool] = []

        for y in 0..<height {
            buffer.append(contentsOf: [Bool](repeating: false, count: left))
            for x in 0..<width {
                let offset = (x + (y * width)) * bytesPerPixel
                if bytesPerPixel == 4 {
                    buffer.append(binarizeByLuminance(red: pointer[offset], green: pointer[offset + 1], blue: pointer[offset + 2]))
                } else {
                    buffer.append(pointer[offset] <= 0x7F)
                }
            }
            buffer.append(contentsOf: [Bool](repeating: false, count: right))
        }

        var bytes: [UInt8] = []

        for offset in stride(from: 0, to: buffer.count, by: 8) {
            bytes.append(
                UInt8((buffer[offset] ? 0b1000_0000 : 0b0000_0000)
                      + (buffer[offset + 1] ? 0b0100_0000 : 0b0000_0000)
                      + (buffer[offset + 2] ? 0b0010_0000 : 0b0000_0000)
                      + (buffer[offset + 3] ? 0b0001_0000 : 0b0000_0000)
                      + (buffer[offset + 4] ? 0b0000_1000 : 0b0000_0000)
                      + (buffer[offset + 5] ? 0b0000_0100 : 0b0000_0000)
                      + (buffer[offset + 6] ? 0b0000_0010 : 0b0000_0000)
                      + (buffer[offset + 7] ? 0b0000_0001 : 0b0000_0000))
            )
        }

        return bytes
    }

    static func binarizeByLuminance(red: UInt8, green: UInt8, blue: UInt8) -> Bool {
        // https://en.wikipedia.org/wiki/Luma_(video)#Rec._601_luma_versus_Rec._709_luma_coefficients
        let luminance = 0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue)
        // 印字するときのbitを立てるので暗い方をtrueにする
        return luminance <= 0x7f
    }
}

