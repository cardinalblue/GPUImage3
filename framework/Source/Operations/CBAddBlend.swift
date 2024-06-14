//
//  CBAddBlend.swift
//
//
//  Created by Chiaote Ni on 2024/6/14.
//

import Foundation

// It's the same as the AddBlend in GPUImage.
// To create a separate class because the original design of GPUImage is not for executing under the async/await environment, and will easily cause a deadlock.
// For more details, see here: https://www.notion.so/piccollage/await-newTexture-3962c12cc694452faeaa8210760898f4
// Therefore, to run the processImage with async, this class override the newTextureAvailable function to achieve this goal to avoid the deadlock.
// Also, follow the implementation of LookupFilter, I create an blendImageInput for this filter, which allow us to use the same interface in PicCollage when we migrate from using GPUImage3 to using CBVisualEffectBuiltIn
public class CBAddBlend: BasicOperation {

    public var intensity: Float = 1 { didSet { uniformSettings["intensity"] = intensity } }

    public var blendImageInput: PictureInput? {
        willSet {
            inputTextures.removeValue(forKey: 1)
            blendImageInput?.removeAllTargets()
        }
        didSet {
            blendImageInput?.addTarget(self, atTargetIndex: 1)
        }
    }

    public init() {
        super.init(fragmentFunctionName:"addBlendFragment", numberOfInputs:2)
        ({
            intensity = 1
        })()
    }

    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt) {
        if fromSourceIndex == 1 {
            inputTextures[fromSourceIndex] = texture
            return
        }

        guard let blendImageInput, inputTextures[fromSourceIndex] == nil else {
            super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex)
            return
        }

        // DispatchSemaphore is Sendable and is a kind of async-safe scoped locking
        // Using NSLock will cause a warning in Xcode and doesn't work as expected at runtime.
        let lock = DispatchSemaphore(value: 0)
        Task {
            await blendImageInput.processImage()
            super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex)
            lock.signal()
        }
        lock.wait(timeout: .now() + 1)
    }
}
