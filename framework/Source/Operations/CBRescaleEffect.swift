//
//  CBRescaleEffect.swift
//
//
//  Created by Chiaote Ni on 2024/5/2.
//

import Foundation
import Metal

public class CBRescaleEffect: BasicOperation {
    // 1 ~ 4000
    public var targetDimension: Int = 1024

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

        let _ = textureInputSemaphore.wait(timeout:DispatchTime.distantFuture)
        defer {
            textureInputSemaphore.signal()
        }
        
        let outputSize = calculateTargetSize(from: texture)
        guard let outputTexture = Texture(
            device: sharedMetalRenderingDevice.device,
            orientation: texture.orientation,
            pixelFormat: texture.texture.pixelFormat,
            width: Int(outputSize.width),
            height: Int(outputSize.height),
            timingStyle: texture.timingStyle
        ) else {
            assertionFailure("CommandBuffer or Texture creation failed")
            removeTransientInputs()
            updateTargetsWithTexture(texture)
            return
        }

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
        let textureTargetDimension = max(textureSize.width, textureSize.height)
        let widthResizeRatio = targetDimension > 0 ? CGFloat(targetDimension) / textureTargetDimension : 1.0
        let heightResizeRatio = targetDimension > 0 ? CGFloat(targetDimension) / textureTargetDimension : 1.0

        let width = textureSize.width * widthResizeRatio
        let height = textureSize.height * heightResizeRatio

        return CGSize(width: width, height: height)
    }
}
