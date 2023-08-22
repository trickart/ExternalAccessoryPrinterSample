//
//  ViewController.swift
//  ExternalAccessoryPrinterSample
//
//  Created by trickart on 2023/08/21.
//

import UIKit

private let crlf: [UInt8] = [0x0e, 0x0a]
private let paperCut: [UInt8] = [0x1b, 0x64, 0x03]

final class ViewController: UIViewController {
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var textFiled: UITextField!

    private let manager = PrinterManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        updatePrinters()
    }

    @IBAction private func updateButtonTapped(_ sender: Any) {
        updatePrinters()
    }

    @IBAction private func printButtonTapped(_ sender: Any) {
        manager.printers.forEach { printer in
            printer.write([0x30, 0x0e, 0x0a, 0x1b, 0x64, 0x03])
        }
    }

    @IBAction private func textButtonTapped(_ sender: Any) {
        let text = textFiled.text ?? ""
        let hello = Array(text.data(using: .shiftJIS)!)

        manager.printers.forEach { printer in
            printer.write(hello + crlf + paperCut)
        }
    }

    @IBAction private func imageButtonTapped(_ sender: Any) {
        let image = UIImage(named: "iosdc_2023")!.cgImage!
        let iosdc = StarPRNTTranslator.rasterImageCommand(from: image)

        manager.printers.forEach { printer in
            printer.write(iosdc + crlf + paperCut)
        }
    }

    private func updatePrinters() {
        manager.addPrinters()
        label.text = "connected: \(manager.printers.count)"
    }
}

