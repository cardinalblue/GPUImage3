//
//  CBRescaleEffect.swift
//
//
//  Created by Chiaote Ni on 2024/5/2.
//

import Foundation
import Metal

public class CBRescaleEffect: BasicOperation {
    // 0 ~ 4000
    public var targetWidth: Int = 1000
    // 0 ~ 4000
    public var targetHeight: Int = 1000
    // 0 ~ 4000
    public var maxLength: Int = 1000

    public init() {
        super.init(fragmentFunctionName: "passthroughFragment", numberOfInputs: 1)
    }

    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt) {
        guard fromSourceIndex == 0 else {
            assertionFailure("sourceIndex out of range")
            return
        }
        guard let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer() else {
            return
        }

        defer {
            textureInputSemaphore.signal()
        }
        let _ = textureInputSemaphore.wait(timeout:DispatchTime.distantFuture)
        
        let outputSize = calculateTargetSize(from: texture)
        let outputTexture = Texture(
            device: sharedMetalRenderingDevice.device,
            orientation: texture.orientation,
            pixelFormat: texture.texture.pixelFormat,
            width: Int(outputSize.width),
            height: Int(outputSize.height),
            timingStyle: texture.timingStyle
        )

        inputTextures[0] = texture
        internalRenderFunction(commandBuffer: commandBuffer, outputTexture: outputTexture)
        commandBuffer.commit()

        removeTransientInputs()
        updateTargetsWithTexture(outputTexture)
    }

    private func calculateTargetSize(from texture: Texture) -> CGSize {
        let textureSize = CGSize(
            width: CGFloat(texture.texture.width),
            height: CGFloat(texture.texture.height)
        )
        let textureMaxLength = max(textureSize.width, textureSize.height)

        let widthResizeRatio = maxLength > 0
        ? CGFloat(maxLength) / textureMaxLength
        : min(1.0, CGFloat(targetWidth) / CGFloat(textureSize.width))

        let heightResizeRatio = maxLength > 0
        ? CGFloat(maxLength) / textureMaxLength
        : min(1.0, CGFloat(targetHeight) / CGFloat(textureSize.height))

        let width = textureSize.width * widthResizeRatio
        let height = textureSize.height * heightResizeRatio

        return CGSize(width: width, height: height)
    }
}
