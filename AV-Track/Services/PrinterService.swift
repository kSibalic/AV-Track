//
//  PrinterService.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 15.03.2026..
//

import Foundation
import UIKit

@MainActor
@Observable
final class PrinterService {
    static let shared = PrinterService()
    
    var isPrinting = false
    var printError: String?
    
    private init() {}
    
    func printLabel(image: UIImage, ipAddress: String) async {
        isPrinting = true
        printError = nil
        
        guard let paddedImage = padImageToSquare(image: image),
              let cgImage = paddedImage.cgImage else {
            self.printError = "Invalid label image format."
            self.isPrinting = false
            return
        }
        
        await Task.detached(priority: .userInitiated) {
            let channel = BRLMChannel(wifiIPAddress: ipAddress)
            let result = BRLMPrinterDriverGenerator.open(channel)
            
            guard result.error.code == .noError, let driver = result.driver else {
                Task { @MainActor in
                    self.printError = "Failed to connect to printer at \(ipAddress). Ensure it is turned on and on the same Wi-Fi."
                    self.isPrinting = false
                }
                return
            }
            
            defer { driver.closeChannel() }
            
            guard let settings = BRLMPTPrintSettings(defaultPrintSettingsWith: .PT_E550W) else {
                Task { @MainActor in
                    self.printError = "Failed to initialize PT-E550W print settings."
                    self.isPrinting = false
                }
                return
            }
            
            // Hardcode 24mm tape size for now
            // TODO: Allow user to choose between different tape sizes
            settings.labelSize = .width24mm
            settings.autoCut = true
            settings.halfCut = true
            settings.resolution = .normal
            settings.scaleMode = .fitPageAspect
            settings.hAlignment = .center
            settings.vAlignment = .center
            
            let printResult = driver.printImage(with: cgImage, settings: settings)
            
            Task { @MainActor in
                if printResult.code != .noError {
                    self.printError = "Printing failed (Error Code: \(printResult.code.rawValue))"
                }
                self.isPrinting = false
            }
        }.value
    }
    
    private func padImageToSquare(image: UIImage) -> UIImage? {
        let sideLength = max(image.size.width, image.size.height)
        let targetSize = CGSize(width: sideLength, height: sideLength)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: targetSize))
        
        let origin = CGPoint(
            x: (targetSize.width - image.size.width) / 2,
            y: (targetSize.height - image.size.height) / 2
        )
        image.draw(in: CGRect(origin: origin, size: image.size))
        
        let paddedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return paddedImage
    }
}
