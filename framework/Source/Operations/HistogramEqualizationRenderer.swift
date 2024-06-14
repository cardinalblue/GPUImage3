//
//  HistogramEqualizationRenderer.swift
//  CBVisualEffectBuiltins
//
//  Created by Vivienne Ko on 2024/5/29.
//

import Metal
import Foundation
import MetalPerformanceShaders

final class HistogramEqualizationRenderer {
    
    func render(
        inputFrameBuffer: [MTLTexture],
        outputFrameBuffer: MTLTexture?,
        parameters: Any? = nil
    ) {

        let device = sharedMetalRenderingDevice.device
        let commandQueue = sharedMetalRenderingDevice.commandQueue

        guard
            let targetTexture = outputFrameBuffer,
            let inputTexture = inputFrameBuffer.first,
            let commandBuffer = commandQueue.makeCommandBuffer()
        else {
            return
        }

        var histogramInfo = MPSImageHistogramInfo(
            numberOfHistogramEntries: 256,
            histogramForAlpha: false,
            minPixelValue: vector_float4(0,0,0,0),
            maxPixelValue: vector_float4(1,1,1,1))

        let calculation = MPSImageHistogram(
            device: device,
            histogramInfo: &histogramInfo
        )
        let bufferLength = calculation.histogramSize(forSourceFormat: inputTexture.pixelFormat)
        guard let histogramInfoBuffer = device.makeBuffer(
            length: bufferLength,
            options: [.storageModePrivate]
        ) else { return }

        calculation.encode(
            to: commandBuffer,
            sourceTexture: inputTexture,
            histogram: histogramInfoBuffer,
            histogramOffset: 0
        )
        
        let equalization = MPSImageHistogramEqualization(device: device, histogramInfo: &histogramInfo)
        equalization.encodeTransform(to: commandBuffer, sourceTexture: inputTexture, histogram: histogramInfoBuffer, histogramOffset: 0)
        equalization.encode(commandBuffer: commandBuffer, sourceTexture: inputTexture, destinationTexture: targetTexture)
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
