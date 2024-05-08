import UIKit
import GPUImage

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!

    var picture: PictureInput!

    private var kirakiraFilter: Kirakira!
    private var isExecuting: Bool = false
    private var queue = DispatchQueue(label: "yoyoyo")

    private var sliders = [UISlider]()

    override func viewDidLoad() {
        super.viewDidLoad()
        renderView.contentMode = .scaleAspectFit
        renderView.colorPixelFormat = .bgra8Unorm

        // set up sliders for the kirakira effect
        let saturationSlider = makeSlider(minimumValue: 0.0, maximumValue: 1.0, value: 0.5, action: #selector(saturationSliderValueChanged))
        let centerSaturationSlider = makeSlider(minimumValue: 0.0, maximumValue: 1.0, value: 0.3, action: #selector(centerSaturationSliderValueChanged))
        let equalMinHueSlider = makeSlider(minimumValue: 0.0, maximumValue: 1.0, value: 0.54, action: #selector(equalMinHueSliderValueChanged))
        let equalMaxHueSlider = makeSlider(minimumValue: 0.0, maximumValue: 1.0, value: 0.0, action: #selector(equalMaxHueSliderValueChanged))
        let equalSaturationSlider = makeSlider(minimumValue: 0.0, maximumValue: 1.0, value: 0.15, action: #selector(equalSaturationSliderValueChanged))
        let equalBrightnessSlider = makeSlider(minimumValue: 0.0, maximumValue: 5.0, value: 2.8, action: #selector(equalBrightnessSliderValueChanged))
        let speedSlider = makeSlider(minimumValue: 0.0, maximumValue: 10.0, value: 0.0, action: #selector(speedSliderValueChanged))
        let rayLengthSlider = makeSlider(minimumValue: 0.0, maximumValue: 1.0, value: 0.5, action: #selector(rayLengthSliderValueChanged))
        let startAngleSlider = makeSlider(minimumValue: 0.0, maximumValue: 360.0, value: 45.0, action: #selector(startAngleSliderValueChanged))
        let sparkleExposureSlider = makeSlider(minimumValue: -1.0, maximumValue: 1.0, value: 0.1, action: #selector(sparkleExposureSliderValueChanged))
        let minHueSlider = makeSlider(minimumValue: 0.0, maximumValue: 1.0, value: 0.0, action: #selector(minHueSliderValueChanged))
        let maxHueSlider = makeSlider(minimumValue: 0.0, maximumValue: 1.0, value: 1.0, action: #selector(maxHueSliderValueChanged))
        let noiseInfluenceSlider = makeSlider(minimumValue: 0.0, maximumValue: 1.0, value: 1.0, action: #selector(noiseInfluenceSliderValueChanged))
        let increasingRateSlider = makeSlider(minimumValue: 0.0, maximumValue: 1.0, value: 0.03, action: #selector(increasingRateSliderValueChanged))
        let sparkleAmountSlider = makeSlider(minimumValue: 0.0, maximumValue: 1.0, value: 1.0, action: #selector(sparkleAmountSliderValueChanged))
        let frameRateSlider = makeSlider(minimumValue: 1.0, maximumValue: 120.0, value: 60.0, action: #selector(frameRateSliderValueChanged))
        let blurSlider = makeSlider(minimumValue: 0.0, maximumValue: 120.0, value: 0.0, action: #selector(blurSliderValueChanged))

        // set up labels for the sliders
        let saturationLabel = makeLabel(text: "Saturation")
        let centerSaturationLabel = makeLabel(text: "Center Saturation")
        let equalMinHueLabel = makeLabel(text: "Equal Min Hue")
        let equalMaxHueLabel = makeLabel(text: "Equal Max Hue")
        let equalSaturationLabel = makeLabel(text: "Equal Saturation")
        let equalBrightnessLabel = makeLabel(text: "Equal Brightness")
        let speedLabel = makeLabel(text: "Speed")
        let rayLengthLabel = makeLabel(text: "Ray Length")
        let startAngleLabel = makeLabel(text: "Start Angle")
        let sparkleExposureLabel = makeLabel(text: "Sparkle Exposure")
        let minHueLabel = makeLabel(text: "Min Hue")
        let maxHueLabel = makeLabel(text: "Max Hue")
        let noiseInfluenceLabel = makeLabel(text: "Noise Influence")
        let increasingRateLabel = makeLabel(text: "Increasing Rate")
        let sparkleAmountLabel = makeLabel(text: "Sparkle Amount")
        let frameRateLabel = makeLabel(text: "Frame Rate")
        let blurLabel = makeLabel(text: "Blur")

        sliders = [
            saturationSlider,
            centerSaturationSlider,
            equalMinHueSlider,
            equalMaxHueSlider,
            equalSaturationSlider,
            equalBrightnessSlider,
            speedSlider,
            rayLengthSlider,
//            startAngleSlider,
            sparkleExposureSlider,
//            minHueSlider,
//            maxHueSlider,
            noiseInfluenceSlider,
            increasingRateSlider,
            sparkleAmountSlider,
            frameRateSlider,
            blurSlider
        ]

        let labels = [
            saturationLabel,
            centerSaturationLabel,
            equalMinHueLabel,
            equalMaxHueLabel,
            equalSaturationLabel,
            equalBrightnessLabel,
            speedLabel,
            rayLengthLabel,
//            startAngleLabel,
            sparkleExposureLabel,
//            minHueLabel,
//            maxHueLabel,
            noiseInfluenceLabel,
            increasingRateLabel,
            sparkleAmountLabel,
            frameRateLabel,
            blurLabel
        ]

        zip(labels, sliders)
            .enumerated()
            .forEach { index, views in
            let slider = views.1
            let label = views.0
                view.addSubview(slider)
                slider.translatesAutoresizingMaskIntoConstraints = false
                slider.heightAnchor.constraint(equalToConstant: 20).isActive = true
                slider.widthAnchor.constraint(equalToConstant: 120).isActive = true
                slider.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20 + 40 * CGFloat(index)).isActive = true
                slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true

                view.addSubview(label)
                label.translatesAutoresizingMaskIntoConstraints = false
                label.heightAnchor.constraint(equalToConstant: 30).isActive = true
                label.centerYAnchor.constraint(equalTo: slider.centerYAnchor).isActive = true
                label.trailingAnchor.constraint(equalTo: slider.leadingAnchor, constant: -10).isActive = true
            }

        // add a reset button to reset the parameters of the kirakira effect on the bottom left corner
        let resetButton = UIButton()
        resetButton.setTitle("Reset", for: .normal)
        resetButton.setTitleColor(.cyan, for: .normal)
        resetButton.addTarget(self, action: #selector(resetKirakiraParameters), for: .touchUpInside)
        view.addSubview(resetButton)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true

        applyKiraKira()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        processImage()
    }

    private func applyGrain() {
        let grainFilter = Grain()
        grainFilter.strength = 9.0 / 100.0
        grainFilter.time = 1.1

        picture = PictureInput(image: UIImage(named:"WID-small.jpg")!)
        picture --> grainFilter --> renderView
        picture.processImage()
    }

    private func applyKiraKira() {
        let jsonFileNames = [
            "Kirakira_Flashlight",
            "Kirakira_Diamond",
            "Kirakira_Rainbow",
            "Kirakira_Barbie",
            "Kirakira_Golden",
            "Kirakira_Glamour"
        ]
        let parameters = { () -> Kirakira.Parameters in
            let jsonFileName = jsonFileNames[4] + ".json"
            let jsonData = try! Data(contentsOf: Bundle.main.url(forResource: jsonFileName, withExtension: nil)!)
            let parameters = try! Kirakira.Parameters(with: jsonData)
            return parameters
        }()

        let filter = Kirakira(with: parameters)
        kirakiraFilter = filter

        picture = PictureInput(image: UIImage(named:"IMG_1492.PNG")!)
        picture --> kirakiraFilter --> renderView
//        picture.processImage()
    }

    private func loadGoldParameter() -> Kirakira.Parameters {
        let jsonFileName = "Kirakira_Golden.json"
        let jsonData = try! Data(contentsOf: Bundle.main.url(forResource: jsonFileName, withExtension: nil)!)
        let parameters = try! Kirakira.Parameters(with: jsonData)
        return parameters
    }

    private func makeSlider(minimumValue: Float, maximumValue: Float, value: Float, action: Selector) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = minimumValue
        slider.maximumValue = maximumValue
        slider.value = value
        slider.addTarget(self, action: action, for: .valueChanged)
        return slider
    }

    private func makeLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12)
        label.textColor = .cyan
        return label
    }
}

// functions for sliders to control the parameters of the kirakira effect
extension ViewController {

    private func processImage() {
        if isExecuting { return }
        isExecuting = true

        picture.processImage(synchronously: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.isExecuting = false
            self.picture.processImage(synchronously: false)
        }
    }

    @objc private func resetKirakiraParameters() {
        let parameters = loadGoldParameter()
        kirakiraFilter.saturation = parameters.saturation
        kirakiraFilter.centerSaturation = parameters.centerSaturation
        kirakiraFilter.equalMinHue = parameters.equalMinHue
        kirakiraFilter.equalMaxHue = parameters.equalMaxHue
        kirakiraFilter.equalSaturation = parameters.equalSaturation
        kirakiraFilter.equalBrightness = parameters.equalBrightness
        kirakiraFilter.speed = parameters.speed
        kirakiraFilter.rayLength = parameters.rayLength
        kirakiraFilter.startAngle = parameters.startAngle
        kirakiraFilter.sparkleExposure = parameters.sparkleExposure
        kirakiraFilter.minHue = parameters.minHue
        kirakiraFilter.maxHue = parameters.maxHue
        kirakiraFilter.noiseInfluence = parameters.noiseInfluence
        kirakiraFilter.increasingRate = parameters.increasingRate
        kirakiraFilter.sparkleAmount = parameters.sparkleAmount
        kirakiraFilter.frameRate = parameters.frameRate
        kirakiraFilter.blur = parameters.blur
        processImage()

        // reset the sliders with the parameters

        let values = [
            parameters.saturation,
            parameters.centerSaturation,
            parameters.equalMinHue,
            parameters.equalMaxHue,
            parameters.equalSaturation,
            parameters.equalBrightness,
            parameters.speed,
            parameters.rayLength,
//            Float(parameters.startAngle),
            parameters.sparkleExposure,
//            parameters.minHue,
//            parameters.maxHue,
            parameters.noiseInfluence,
            parameters.increasingRate,
            parameters.sparkleAmount,
            parameters.frameRate,
            Float(parameters.blur)
        ]

        zip(sliders, values).forEach { slider, value in
            slider.value = value
        }
    }

    @objc private func saturationSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.saturation = sender.value
        processImage()
    }

    @objc private func centerSaturationSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.centerSaturation = sender.value
        processImage()
    }

    @objc private func equalMinHueSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.equalMinHue = sender.value
        processImage()
    }

    @objc private func equalMaxHueSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.equalMaxHue = sender.value
        processImage()
    }

    @objc private func equalSaturationSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.equalSaturation = sender.value
        processImage()
    }

    @objc private func equalBrightnessSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.equalBrightness = sender.value
        processImage()
    }

    @objc private func speedSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.speed = sender.value
        processImage()
    }

    @objc private func rayLengthSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.rayLength = sender.value
        processImage()
    }

    @objc private func startAngleSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.startAngle = Int(sender.value)
        processImage()
    }

    @objc private func sparkleExposureSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.sparkleExposure = sender.value
        processImage()
    }

    @objc private func minHueSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.minHue = sender.value
        processImage()
    }

    @objc private func maxHueSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.maxHue = sender.value
        processImage()
    }

    @objc private func noiseInfluenceSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.noiseInfluence = sender.value
        processImage()
    }

    @objc private func increasingRateSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.increasingRate = sender.value
        processImage()
    }

    @objc private func sparkleAmountSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.sparkleAmount = sender.value
        processImage()
    }

    @objc private func frameRateSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.frameRate = sender.value
        processImage()
    }

    @objc private func blurSliderValueChanged(_ sender: UISlider) {
        kirakiraFilter.blur = Int(sender.value)
        processImage()
    }
}
