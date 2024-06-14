import Foundation

public class LookupFilter: BasicOperation {
    public var intensity:Float = 1.0 { didSet { uniformSettings["intensity"] = intensity } }
    public var lookupImage:PictureInput? { // TODO: Check for retain cycles in all cases here
        didSet {
            inputTextures.removeValue(forKey: 1)
            lookupImage?.addTarget(self, atTargetIndex:1)
        }
    }

    public init() {
        super.init(fragmentFunctionName:"lookupFragment", numberOfInputs:2)
        
        ({intensity = 1.0})()
    }

    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt) {
        if fromSourceIndex == 1 {
            inputTextures[fromSourceIndex] = texture
            return
        }

        // DispatchSemaphore is Sendable and is a kind of async-safe scoped locking
        // Using NSLock will cause a warning in Xcode and doesn't work as expected at runtime.
        let lock = DispatchSemaphore(value: 0)
        if let lookupImage, inputTextures[fromSourceIndex] == nil {
            Task {
                await lookupImage.processImage()
                super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex)
                lock.signal()
            }
        } else {
            super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex)
        }
        lock.wait()
    }
}
