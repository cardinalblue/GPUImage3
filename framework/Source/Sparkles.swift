//
//  Sparkles.swift
//  GPUImage_iOS
//
//  Created by Chiaote Ni on 2024/4/25.
//  Copyright © 2024 Red Queen Coder, LLC. All rights reserved.
//

import Foundation

public class Sparkles: OperationGroup {

    public enum ColorMode: Int {
        case white = 0
        case random = 1
    }

    // MARK: - Properties

    // Noise
    public var speed: Float = 7.5 {
        didSet { perlinNoiseEffect.speed = speed }
    }
    public var frameRate: Float = 60 {
        didSet { perlinNoiseEffect.frameRate = frameRate }
    }
    public var time: Float = 0 {
        didSet { perlinNoiseEffect.time = time }
    }
    // LightExtractor
    public var equalMinHue: Float = 0.75 {
        didSet { lightExtractorEffect.equalMinHue = equalMinHue }
    }
    public var equalMaxHue: Float = 0.083 {
        didSet { lightExtractorEffect.equalMaxHue = equalMaxHue }
    }
    public var equalSaturation: Float = 0.15 {
        didSet { lightExtractorEffect.equalSaturation = equalSaturation }
    }
    public var equalBrightness: Float = 2.0 {
        didSet { lightExtractorEffect.equalBrightness = equalBrightness }
    }
    public var minHue: Float = 0.0 {
        didSet { lightExtractorEffect.minHue = minHue }
    }
    public var maxHue: Float = 1.0 {
        didSet { lightExtractorEffect.maxHue = maxHue }
    }
    public var noiseInfluence: Float = 1.0 {
        didSet { lightExtractorEffect.noiseInfluence = noiseInfluence }
    }
    public var increasingRate: Float = 0.3 {
        didSet { lightExtractorEffect.increasingRate = increasingRate }
    }
    public var sparkleAmount: Float = 1.0 {
        didSet { lightExtractorEffect.luminanceThreshold = 1.0 - sparkleAmount * 0.5}
    }
    // DirectionalBlurs
    public var rayLength: Float = 0.08 {
        didSet { updateDirectionalShines() }
    }
    public var startAngle: Int = 45 {
        didSet { updateDirectionalShines() }
    }
    public var sparkleExposure: Float = 0.0 {
        didSet { updateDirectionalShines() }
    }
    // Saturation
    public var centerSaturation: Float = 1.3 {
        didSet { saturationEffect.saturation = centerSaturation }
    }

    // MARK: - Effects

    // light map
    private let perlinNoiseEffect = CBPerlineNoise()
    private let lightExtractorEffect = CBKirakiraLightExtractor()

    // center texture
    private let firstBoxBlurEffect = GaussianBlur()
    private let hsvValueEffect = CBHSV()
    private let firstDilationEffect = CBDilation()
    private let secondDilationEffect = CBDilation()
    private let exposureEffect = ExposureAdjustment()
    private let blurEffect = GaussianBlur()
    private let saturationEffect = SaturationAdjustment()

    // sparkle ray
    private let rayCount: Int
    private let directionalShines: [DirectionalShine]
    private let addBlendEffects: [AddBlend]
    private var erosionEffect = CBErosion()

    deinit {
        let effects: [ImageProcessingOperation] = [
            perlinNoiseEffect,
            lightExtractorEffect,
            firstBoxBlurEffect,
            hsvValueEffect,
            firstDilationEffect,
            secondDilationEffect,
            exposureEffect,
            blurEffect,
            saturationEffect,
            erosionEffect
        ] + directionalShines + addBlendEffects
        effects.forEach { $0.resetPipeline() }
    }

    public init(rayCount: Int = 2) {
        self.rayCount = rayCount
        // NOTE: Do not use Array(repeat:count:) here
        // It will create only one instance and set it up in all element slots, which does not work for our scenario.
        self.directionalShines = Array(0...rayCount)
            .map { _ in DirectionalShine() }
        self.addBlendEffects = Array(0...rayCount)
            .map { _ in AddBlend() }
        super.init()

        ({equalMinHue = 0.75})()
        ({equalMaxHue = 0.083})()
        ({equalSaturation = 0.15})()
        ({equalBrightness = 2.0})()
        ({speed = 7.5})()
        ({rayLength = 0.08})()
        ({sparkleExposure = 0.0})()
        ({minHue = 0.0})()
        ({maxHue = 1.0})()
        ({noiseInfluence = 1.0})()
        ({increasingRate = 0.3})()
        ({startAngle = 45})()
        ({sparkleAmount = 1.0})()
        ({frameRate = 60})()
        ({centerSaturation = 1.3})()

        erosionEffect.steps = 6
        erosionEffect.texelSize = 3
        hsvValueEffect.value = 0.7
        firstDilationEffect.steps = 5
        firstDilationEffect.texelStep = 3
        firstDilationEffect.mode = 1
        secondDilationEffect.steps = 8
        secondDilationEffect.texelStep = 3
        secondDilationEffect.mode = 1
        firstBoxBlurEffect.blurRadiusInPixels = 5
        blurEffect.blurRadiusInPixels = 5

        setUpPipeline()
        updateDirectionalShines()
    }
}

// MARK: - Private functions
extension Sparkles {

    private func updateDirectionalShines() {
        let intervalDegree: Float = 180.0 / Float(rayCount)
        for i in 0 ..< rayCount {
            directionalShines[i].degree = Float(startAngle) + (Float(i) * intervalDegree)
            directionalShines[i].rayLength = rayLength
            directionalShines[i].sparkleExposure = 2 + sparkleExposure
        }
    }

    private func setUpPipeline() {
        configureGroup { input, output in

            input
            --> perlinNoiseEffect
            perlinNoiseEffect.addTarget(lightExtractorEffect, atTargetIndex: 1)

            input
            --> lightExtractorEffect    // lightMapTexture
            --> firstDilationEffect
            --> hsvValueEffect
            --> secondDilationEffect
            --> exposureEffect
            --> blurEffect
            --> saturationEffect        // centerTexture

            lightExtractorEffect
            --> erosionEffect           // erodedLightTexture

            var node: ImageProcessingOperation = saturationEffect

            for i in 0 ..< rayCount {
                let addBend = addBlendEffects[i]
                let directionalShine = directionalShines[i]

                erosionEffect --> directionalShine // rayTexture
                directionalShine.addTarget(addBend, atTargetIndex: 1)

                node --> addBend // sparkleTexture
                node = addBend
            }

            node
            --> output
        }
    }
}
