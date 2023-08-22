//
//  Printer.swift
//  ExternalAccessoryPrinterSample
//
//  Created by trickart on 2023/08/21.
//

import ExternalAccessory
import Foundation

class Printer: NSObject {
    let session: EASession

    var bytes: [UInt8] = []

    init?(accessory: EAAccessory, protocolString: String) {
        guard let session = EASession(accessory: accessory, forProtocol: protocolString),
              let inputStream = session.inputStream,
              let outputStream = session.outputStream else { return nil }

        self.session = session
        super.init()

        inputStream.delegate = self
        outputStream.delegate = self
        inputStream.schedule(in: .current, forMode: .default)
        outputStream.schedule(in: .current, forMode: .default)
        inputStream.open()
        outputStream.open()
    }

    deinit {
        session.inputStream?.close()
        session.outputStream?.close()
        session.inputStream?.remove(from: .current, forMode: .default)
        session.outputStream?.remove(from: .current, forMode: .default)
        session.inputStream?.delegate = nil
        session.outputStream?.delegate = nil
    }

    func write(_ bytes: [UInt8]) {
        self.bytes.append(contentsOf: bytes)

        guard let outputStream = session.outputStream,
              outputStream.hasSpaceAvailable else { return }

        write(to: outputStream)
    }

    private func write(to stream: OutputStream) {
        let length = stream.write(&bytes, maxLength: bytes.count)

        if length < 0 {
            print("error!")
        } else if length == 0 {
            print("full.")
        } else {
            if length != bytes.count {
                print("write data was split.")
            }
            bytes = Array(bytes.dropFirst(length))
        }
    }
}

extension Printer: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            break
        case .hasBytesAvailable:
            guard let inputStream = aStream as? InputStream else {
                print("unknown bytes")
                return
            }

            var bytes: [UInt8] = Array(repeating: 0, count: 1024)
            let length = inputStream.read(&bytes, maxLength: 1024)
        case .hasSpaceAvailable:
            guard let outputStream = aStream as? OutputStream,
                  !bytes.isEmpty else { return }

            write(to: outputStream)
        case .errorOccurred:
            break
        case .endEncountered:
            break
        default:
            print("unknown event \(eventCode)")
            break
        }
    }
}
