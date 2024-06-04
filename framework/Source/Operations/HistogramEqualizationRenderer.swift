//
//  HistogramEqualizationRenderer.swift
//  CBVisualEffectBuiltins
//
//  Created by Vivienne Ko on 2024/5/29.
//

import Metal
import Foundation
import MetalPerformanceShaders

class HistogramEqualizationRenderer: MetalRenderer {
    
    override func render(
        inputFrameBuffer: [MTLTexture],
        outputFrameBuffer: MTLTexture?,
        parameters: Any? = nil
    ) {
        guard let targetTexture = outputFrameBuffer,
              let inputTexture = inputFrameBuffer.first
        else { return }
        
        guard let commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer()
        else { return }
        
        guard let device = self.metalDevice
        else { return }
        
        var histogramInfo = MPSImageHistogramInfo(
            numberOfHistogramEntries: 256,
            histogramForAlpha: false,
            minPixelValue: vector_float4(0,0,0,0),
            maxPixelValue: vector_float4(1,1,1,1))
             
        let calculation = MPSImageHistogram(device: device,
                                            histogramInfo: &histogramInfo)
        let bufferLength = calculation.histogramSize(forSourceFormat: inputTexture.pixelFormat)
        guard let histogramInfoBuffer = device.makeBuffer(length: bufferLength, options: [.storageModePrivate])
        else { return }
             
        calculation.encode(to: commandBuffer,
                           sourceTexture: inputTexture,
                           histogram: histogramInfoBuffer,
                           histogramOffset: 0)
        
        let equalization = MPSImageHistogramEqualization(device: device, histogramInfo: &histogramInfo)
        equalization.encodeTransform(to: commandBuffer, sourceTexture: inputTexture, histogram: histogramInfoBuffer, histogramOffset: 0)
        equalization.encode(commandBuffer: commandBuffer, sourceTexture: inputTexture, destinationTexture: targetTexture)
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    override func render(
        inputFrameBuffer: [MTLTexture],
        outputFrameBuffer: MTLTexture?,
        commandBuffer: MTLCommandBuffer,
        parameters: Any? = nil
    ) {
        guard let targetTexture = outputFrameBuffer,
              let inputTexture = inputFrameBuffer.first
        else { return }
        
        guard let device = self.metalDevice
        else { return }
        
        var histogramInfo = MPSImageHistogramInfo(
            numberOfHistogramEntries: 256,
            histogramForAlpha: false,
            minPixelValue: vector_float4(0,0,0,0),
            maxPixelValue: vector_float4(1,1,1,1))
             
        let calculation = MPSImageHistogram(device: device,
                                            histogramInfo: &histogramInfo)
        let bufferLength = calculation.histogramSize(forSourceFormat: inputTexture.pixelFormat)
        guard let histogramInfoBuffer = device.makeBuffer(length: bufferLength, options: [.storageModePrivate])
        else { return }
             
        calculation.encode(to: commandBuffer,
                           sourceTexture: inputTexture,
                           histogram: histogramInfoBuffer,
                           histogramOffset: 0)
        
        let equalization = MPSImageHistogramEqualization(device: device, histogramInfo: &histogramInfo)
        equalization.encodeTransform(to: commandBuffer, sourceTexture: inputTexture, histogram: histogramInfoBuffer, histogramOffset: 0)
        equalization.encode(commandBuffer: commandBuffer, sourceTexture: inputTexture, destinationTexture: targetTexture)
    }
    
}
