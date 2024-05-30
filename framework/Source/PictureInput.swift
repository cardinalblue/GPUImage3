#if canImport(UIKit)
import UIKit
#else
import Cocoa
#endif
import MetalKit

public class PictureInput: ImageSource {
    public let targets = TargetContainer()
    var internalTexture:Texture?
    var hasProcessedImage:Bool = false
    var internalImage:CGImage?

    let isTransient: Bool

    public init(image:CGImage, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait, isTransient: Bool = false) {
        internalImage = image
        self.isTransient = isTransient
    }
    
    #if canImport(UIKit)
    public convenience init(image:UIImage, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait, isTransient: Bool = false) {
        self.init(image: image.cgImage!, smoothlyScaleOutput: smoothlyScaleOutput, orientation: orientation, isTransient: isTransient)
    }
    
    public convenience init(imageName:String, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait) {
        guard let image = UIImage(named:imageName) else { fatalError("No such image named: \(imageName) in your application bundle") }
        self.init(image:image, smoothlyScaleOutput:smoothlyScaleOutput, orientation:orientation)
    }
    #else
    public convenience init(image:NSImage, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait) {
        self.init(image:image.cgImage(forProposedRect:nil, context:nil, hints:nil)!, smoothlyScaleOutput:smoothlyScaleOutput, orientation:orientation)
    }
    
    public convenience init(imageName:String, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait) {
        let imageName = NSImage.Name(imageName)
        guard let image = NSImage(named:imageName) else { fatalError("No such image named: \(imageName) in your application bundle") }
        self.init(image:image.cgImage(forProposedRect:nil, context:nil, hints:nil)!, smoothlyScaleOutput:smoothlyScaleOutput, orientation:orientation)
    }
    #endif
    
    /// Process the image and send it to the target
    ///
    /// - Note: Should not set synchronously to true under a StructuredConcurrency environment; the newTexture(cgImage:options:) may locked a thread in this case.
    /// For more details: https://www.notion.so/piccollage/await-newTexture-3962c12cc694452faeaa8210760898f4
    public func processImage(synchronously:Bool = false) {
        if let texture = internalTexture {
            if synchronously {
                self.updateTargetsWithTexture(texture)
                self.hasProcessedImage = true
            } else {
                DispatchQueue.global().async{
                    self.updateTargetsWithTexture(texture)
                    self.hasProcessedImage = true
                }
            }
        } else {
            let textureLoader = MTKTextureLoader(device: sharedMetalRenderingDevice.device)
            if synchronously {
                do {
                    let mtlTexture = try textureLoader.newTexture(cgImage:internalImage!, options: newTextureOptions)
                    internalImage = nil
                    let texture = makeTexture(with: mtlTexture)
                    self.internalTexture = texture
                    self.updateTargetsWithTexture(texture)
                    self.hasProcessedImage = true
                } catch {
                    fatalError("Failed loading image texture")
                }
            } else {
                textureLoader.newTexture(cgImage: internalImage!, options: newTextureOptions, completionHandler: { [weak self] (possibleTexture, error) in
                    guard let self else { return }
                    guard (error == nil) else { fatalError("Error in loading texture: \(error!)") }
                    guard let mtlTexture = possibleTexture else { fatalError("Nil texture received") }
                    self.internalImage = nil

                    let texture = makeTexture(with: mtlTexture)
                    self.internalTexture = texture
                    DispatchQueue.global().async{
                        self.updateTargetsWithTexture(texture)
                        self.hasProcessedImage = true
                    }
                })
            }
        }
    }

    public func processImage() async {
        if let texture = internalTexture {
            updateTargetsWithTexture(texture)
            hasProcessedImage = true
            return
        }

        guard let internalImage else { return }
        let textureLoader = MTKTextureLoader(device: sharedMetalRenderingDevice.device)
        do {
            let mtlTexture = try await textureLoader.newTexture(
                cgImage: internalImage,
                options: newTextureOptions
            )
            self.internalImage = nil

            let texture = makeTexture(with: mtlTexture)
            internalTexture = texture
            updateTargetsWithTexture(texture)
            hasProcessedImage = true
        } catch {
            assertionFailure("Failed loading image texture: \(error.localizedDescription)")
        }
    }

    public func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
        if hasProcessedImage {
            target.newTextureAvailable(self.internalTexture!, fromSourceIndex:atIndex)
        }
    }
}

// MARK: Private functions
extension PictureInput {

    private var newTextureOptions: [MTKTextureLoader.Option : Any] {
        [MTKTextureLoader.Option.SRGB : false]
    }

    private func makeTexture(with texture: MTLTexture) -> Texture {
        Texture(
            orientation: .portrait,
            texture: texture,
            timingStyle: isTransient ? .transientImage : .stillImage
        )
    }
}
