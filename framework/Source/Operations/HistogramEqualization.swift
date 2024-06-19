//
//  HistogramEqualization.swift
//
//
//  Created by Chiaote Ni on 2024/6/4.
//

import Foundation

public class HistogramEqualization: ImageProcessingOperation {
    public var maximumInputs: UInt = 1
    public let targets = TargetContainer()
    public let sources = SourceContainer()

    private var renderer = HistogramEqualizationRenderer()
    private let textureInputSemaphore = DispatchSemaphore(value: 1)

    private var inputTexture: Texture?

    public func transmitPreviousImage(to target: any ImageConsumer, atIndex: UInt) {}

    public func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt) {
        guard fromSourceIndex == 0 else {
            assertionFailure("sourceIndex out of range")
            return
        }

        let _ = textureInputSemaphore.wait(timeout:DispatchTime.distantFuture)
        defer {
            textureInputSemaphore.signal()
        }

        let frameTexture = texture.texture
        let size = CGSize(
            width: CGFloat(frameTexture.width),
            height: CGFloat(frameTexture.height)
        )
        guard let outputTexture = Texture(
            device: sharedMetalRenderingDevice.device,
            orientation: texture.orientation,
            pixelFormat: texture.texture.pixelFormat,
            width: Int(size.width),
            height: Int(size.height),
            timingStyle: texture.timingStyle
        ) else {
            assertionFailure("CommandBuffer or Texture creation failed")
            removeTransientInputs()
            updateTargetsWithTexture(texture)
            return
        }

        inputTexture = texture
        renderer.render(
            inputFrameBuffer: [frameTexture],
            outputFrameBuffer: outputTexture.texture
        )
        inputTexture = nil

        removeTransientInputs()
        updateTargetsWithTexture(outputTexture)
    }
}
