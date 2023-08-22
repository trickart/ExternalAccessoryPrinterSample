//
//  PrinterManager.swift
//  ExternalAccessoryPrinterSample
//
//  Created by trickart on 2023/08/21.
//

import ExternalAccessory
import Foundation

final class PrinterManager {
    let accessoryManager: EAAccessoryManager

    private(set) var printers: [Printer] = []

    init(accessoryManager: EAAccessoryManager = .shared()) {
        self.accessoryManager = accessoryManager
    }

    func addPrinters() {
        for accessory in accessoryManager.connectedAccessories {
            guard !printers.contains(where: { $0.session.accessory == accessory }),
                  let printer = Printer(accessory: accessory, protocolString: "jp.star-m.starpro") else { continue }

            printers.append(printer)
        }
    }
}
