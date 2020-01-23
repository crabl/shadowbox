//
//  AppDelegate.swift
//  Shadowbox
//
//  Created by Chris Rabl on 1/21/20.
//  Copyright © 2020 Coulee. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    if self.hasScreenRecordingPermission() {
      self.captureScreenRegionToClipboard()
    }
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  func hasScreenRecordingPermission() -> Bool {
    let stream = CGDisplayStream(
      dispatchQueueDisplay: CGMainDisplayID(),
      outputWidth: 1,
      outputHeight: 1,
      pixelFormat: Int32(kCVPixelFormatType_32BGRA),
      properties: nil,
      queue: DispatchQueue.global(),
      handler: { _, _, _, _ in }
    )

    return stream != nil
  }
  
  func captureScreenRegionToClipboard() {
    let task = Process()
    task.launchPath = "/usr/sbin/screencapture"
    task.arguments = ["-i", "-c"]
    task.terminationHandler = { (task) in
      print(task.isRunning)
      if (!task.isRunning) {
        if let clipboardImage = self.getImageFromClipboard() {
          let image = self.addShadowToImage(image: clipboardImage, blurSize: 12)
          self.copyImageToClipboard(image: image)
        }
      }
      
      self.terminateAppFromMainThread()
    }
    
    do {
      try task.run()
    } catch {
      self.terminateAppFromMainThread()
    }
  }
  
  private func terminateAppFromMainThread() {
    // must only ever terminate from main thread
    DispatchQueue.main.async {
      NSApp.terminate(self)
    }
  }
  
  private func getImageFromClipboard() -> NSImage? {
    let pasteboard = NSPasteboard.general
    
    if let data = pasteboard.data(forType: .png) {
      return NSImage(data: data)
    }
    
    return nil
  }
  
  func addShadowToImage(image: NSImage, blurSize: CGFloat) -> NSImage {
    let shadowColor = NSColor(white:0.0, alpha:0.6).cgColor
    let resultSize = NSSize(width: image.size.width + blurSize * 2, height: image.size.height + blurSize * 2)
    
    var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
    
    
    let context = CGContext(data: nil,
                            width: Int(resultSize.width),
                            height: Int(resultSize.height),
                            bitsPerComponent: imageRef!.bitsPerComponent,
                            bytesPerRow: 0,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    
    // create shadow with light source directly above the image (no offset)
    context.setShadow(offset: CGSize(width: 0, height: 0),
                      blur: blurSize,
                      color: shadowColor)
    
    context.draw(imageRef!,
                 in: CGRect(x: blurSize, y: blurSize, width: image.size.width, height: image.size.height),
                 byTiling:false)
    
    return NSImage(cgImage: context.makeImage()!, size: resultSize)
  }
  
  
  func copyImageToClipboard(image: NSImage) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.writeObjects([image])
  }
}
