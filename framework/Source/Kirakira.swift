//
//  Kirakira.swift
//  GPUImage
//
//  Created by Jim Wang on 2024/3/29.
//  Copyright © 2024 Red Queen Coder, LLC. All rights reserved.
//

import Foundation

public class Kirakira: OperationGroup {

    public enum ColorMode: Int, Codable {
        case white = 0
        case random = 1
    }

    public struct Parameters {
        public var colorMode: ColorMode
        public var saturation: Float
        public var centerSaturation: Float
        public var equalMinHue: Float
        public var equalMaxHue: Float
        public var equalSaturation: Float
        public var equalBrightness: Float
        public var speed: Float
        public var rayCount: Int
        public var rayLength: Float
        public var startAngle: Int
        public var sparkleExposure: Float
        public var minHue: Float
        public var maxHue: Float
        public var noiseInfluence: Float
        public var increasingRate: Float
        public var sparkleScale: Float
        public var sparkleAmount: Float
        public var frameRate: Float
        public var blur: Int

        public init(
            colorMode: ColorMode = .random,
            saturation: Float = 0.3,
            centerSaturation: Float = 0.3,
            equalMinHue: Float = 0.75,
            equalMaxHue: Float = 0.083,
            equalSaturation: Float = 0.15,
            equalBrightness: Float = 2.0,
            speed: Float = 7.5,
            rayCount: Int = 2,
            rayLength: Float = 0.08,
            startAngle: Int = 45,
            sparkleExposure: Float = 0.0,
            minHue: Float = 0.0,
            maxHue: Float = 1.0,
            noiseInfluence: Float = 1.0,
            increasingRate: Float = 0.3,
            sparkleScale: Float = 0.7,
            sparkleAmount: Float = 0.4,
            frameRate: Float = 60,
            blur: Int = 0
        ) {
            self.colorMode = colorMode
            self.saturation = saturation
            self.centerSaturation = centerSaturation
            self.equalMinHue = equalMinHue
            self.equalMaxHue = equalMaxHue
            self.equalSaturation = equalSaturation
            self.equalBrightness = equalBrightness
            self.speed = speed
            self.rayCount = rayCount
            self.rayLength = rayLength
            self.startAngle = startAngle
            self.sparkleExposure = sparkleExposure
            self.minHue = minHue
            self.maxHue = maxHue
            self.noiseInfluence = noiseInfluence
            self.increasingRate = increasingRate
            self.sparkleScale = sparkleScale
            self.sparkleAmount = sparkleAmount
            self.frameRate = frameRate
            self.blur = blur
        }
    }

    // MARK: Properties

    public var colorMode: ColorMode = .random {
        didSet {
            updateSaturation()
            updateSparkleSaturation()
        }
    }
    // For saturation effect
    public var saturation: Float = 0.3 {
        didSet { updateSaturation() }
    }
    // For sparkles effect
    public var centerSaturation: Float = 0.3 {
        didSet { updateSparkleSaturation() }
    }
    public var equalMinHue: Float = 0.75 {
        didSet { sparklesEffect.equalMinHue = equalMinHue }
    }
    public var equalMaxHue: Float = 0.083 {
        didSet { sparklesEffect.equalMaxHue = equalMaxHue }
    }
    public var equalSaturation: Float = 0.15 {
        didSet { sparklesEffect.equalSaturation = equalSaturation }
    }
    public var equalBrightness: Float = 2.0 {
        didSet { sparklesEffect.equalBrightness = equalBrightness }
    }
    public var speed: Float = 7.5 {
        didSet { sparklesEffect.speed = speed }
    }
    public let rayCount: Int
    public var rayLength: Float = 0.08 {
        didSet { sparklesEffect.rayLength = rayLength }
    }
    public var startAngle: Int = 45 {
        didSet { sparklesEffect.startAngle = startAngle }
    }
    public var sparkleExposure: Float = 0.0 {
        didSet { sparklesEffect.sparkleExposure = sparkleExposure }
    }
    public var minHue: Float = 0.0 {
        didSet { sparklesEffect.minHue = minHue }
    }
    public var maxHue: Float = 1.0 {
        didSet { sparklesEffect.maxHue = maxHue }
    }
    public var noiseInfluence: Float = 1.0 {
        didSet { sparklesEffect.noiseInfluence = noiseInfluence }
    }
    public var increasingRate: Float = 0.3 {
        didSet { sparklesEffect.increasingRate = increasingRate }
    }
    public var sparkleScale: Float = 0.7 {
        didSet { sparklesEffect.sparkleScale = sparkleScale }
    }
    public var sparkleAmount: Float = 0.4 {
        didSet { sparklesEffect.sparkleAmount = sparkleAmount}
    }
    public var frameRate: Float = 60 {
        didSet { sparklesEffect.frameRate = frameRate }
    }
    // For the blur effect
    public var blur: Int = 0 {
        didSet { blurEffect.blurRadiusInPixels = Float(blur) }
    }

    // MARK: Effects

    private let sparklesEffect: Sparkles
    private let blurEffect = GaussianBlur()
    private let saturationEffect = SaturationAdjustment()
    private let addBlend = AddBlend()

    public init(with parameters: Parameters) {
        self.rayCount = parameters.rayCount
        self.sparklesEffect = Sparkles(rayCount: parameters.rayCount)
        super.init()

        ({
            colorMode = parameters.colorMode
            saturation = parameters.saturation
            centerSaturation = parameters.centerSaturation
            equalMinHue = parameters.equalMinHue
            equalMaxHue = parameters.equalMaxHue
            equalSaturation = parameters.equalSaturation
            equalBrightness = parameters.equalBrightness
            speed = parameters.speed
            rayLength = parameters.rayLength
            startAngle = parameters.startAngle
            sparkleExposure = parameters.sparkleExposure
            minHue = parameters.minHue
            maxHue = parameters.maxHue
            noiseInfluence = parameters.noiseInfluence
            increasingRate = parameters.increasingRate
            sparkleScale = parameters.sparkleScale
            sparkleAmount = parameters.sparkleAmount
            frameRate = parameters.frameRate
            blur = parameters.blur
        })()

        self.configureGroup { input, output in
            input
            --> sparklesEffect
            --> blurEffect
            --> saturationEffect
            saturationEffect.addTarget(addBlend, atTargetIndex: 1)

            input
            --> addBlend
            --> output
        }
    }
}

private extension Kirakira {
    func updateSaturation() {
        saturationEffect.saturation = saturation * Float(colorMode.rawValue)
    }

    func updateSparkleSaturation() {
        sparklesEffect.centerSaturation = centerSaturation * Float(colorMode.rawValue)
    }
}

public extension Kirakira.Parameters {

    init(with jsonData: Data) throws {
        let decoder = JSONDecoder()
        let parameters = try decoder.decode(Kirakira.Parameters.self, from: jsonData)
        self = parameters
    }
}

extension Kirakira.Parameters: Decodable {

    fileprivate enum CodingKeys: String, CodingKey {
        case equalMinHue
        case equalMaxHue
        case equalSaturation
        case equalBrightness
        case speed
        case rayCount
        case rayLength
        case sparkleExposure
        case blur
        case colorMode
        case saturation
        case centerSaturation
        case minHue
        case maxHue
        case noiseInfluence
        case increasingRate
        case startAngle
        case sparkleAmount
        case frameRate
        case sparkleScale
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        equalMinHue = try container.decodeParamValue(Float.self, forKey: .equalMinHue)
        equalMaxHue = try container.decodeParamValue(Float.self, forKey: .equalMaxHue)
        equalSaturation = try container.decodeParamValue(Float.self, forKey: .equalSaturation)
        equalBrightness = try container.decodeParamValue(Float.self, forKey: .equalBrightness)
        speed = try container.decodeParamValue(Float.self, forKey: .speed)
        rayCount = try container.decodeParamValue(Int.self, forKey: .rayCount)
        rayLength = try container.decodeParamValue(Float.self, forKey: .rayLength)
        sparkleExposure = try container.decodeParamValue(Float.self, forKey: .sparkleExposure)
        blur = try container.decodeParamValue(Int.self, forKey: .blur)
        colorMode = try container.decodeParamValue(Kirakira.ColorMode.self, forKey: .colorMode)
        saturation = try container.decodeParamValue(Float.self, forKey: .saturation)
        centerSaturation = try container.decodeParamValue(Float.self, forKey: .centerSaturation)
        minHue = try container.decodeParamValue(Float.self, forKey: .minHue)
        maxHue = try container.decodeParamValue(Float.self, forKey: .maxHue)
        noiseInfluence = try container.decodeParamValue(Float.self, forKey: .noiseInfluence)
        increasingRate = try container.decodeParamValue(Float.self, forKey: .increasingRate)
        startAngle = try container.decodeParamValue(Int.self, forKey: .startAngle)
        sparkleAmount = try container.decodeParamValue(Float.self, forKey: .sparkleAmount)
        frameRate = try container.decodeParamValue(Float.self, forKey: .frameRate)
        sparkleScale = try container.decodeParamValue(Float.self, forKey: .sparkleScale)
    }
}

private extension KeyedDecodingContainer<Kirakira.Parameters.CodingKeys> {

    enum ParamValueKeys: String, CodingKey {
        case value
    }

    func decodeParamValue<T: Decodable>(
        _ type: T.Type,
        forKey key: Kirakira.Parameters.CodingKeys
    ) throws -> T {
        try nestedContainer(keyedBy: ParamValueKeys.self, forKey: key)
            .decode(T.self, forKey: .value)
    }
}
