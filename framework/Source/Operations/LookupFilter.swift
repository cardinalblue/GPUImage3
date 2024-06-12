import Foundation

public class LookupFilter: BasicOperation {
    public var intensity:Float = 1.0 {
        didSet { uniformSettings["intensity"] = intensity }
    }
    public var lookupImage:PictureInput? { // TODO: Check for retain cycles in all cases here
        didSet { lookupImage?.addTarget(self, atTargetIndex:1) }
    }

    private let accessQueue = DispatchQueue(label: "com.LookupFilter")

    public init() {
        super.init(fragmentFunctionName:"lookupFragment", numberOfInputs:2)
        
        ({intensity = 1.0})()
    }

    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt) {
        let function = super.newTextureAvailable
        accessQueue.async { [weak self] in
            guard let self else { return }
            guard self.inputTextures[1] == nil, let lookupImage else {
                function(texture, fromSourceIndex)
                return
            }
            lookupImage.processImage() {
                function(texture, fromSourceIndex)
            }
        }
    }
}
