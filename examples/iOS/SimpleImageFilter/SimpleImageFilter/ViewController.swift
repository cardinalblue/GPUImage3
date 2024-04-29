import UIKit
import GPUImage

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!

    var picture: PictureInput!

    override func viewDidLoad() {
        super.viewDidLoad()
        renderView.contentMode = .scaleAspectFit
        renderView.colorPixelFormat = .bgra8Unorm
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        applyKiraKira()
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
        let jsonFileName = [
            "Kirakira_Flashlight",
            "Kirakira_Diamond",
            "Kirakira_Rainbow",
            "Kirakira_Barbie",
            "Kirakira_Golden",
            "Kirakira_Glamour"
        ]
        let parameters = { () -> Kirakira.Parameters in
//            let jsonFileName = jsonFileName[2] + ".json"
//            let jsonData = try! Data(contentsOf: Bundle.main.url(forResource: jsonFileName, withExtension: nil)!)
//            let parameters = try! Kirakira.Parameters(with: jsonData)
//            return parameters
            return Kirakira.Parameters(
                colorMode: .random,
                saturation: 0.5,
                centerSaturation: 0.3,
                equalMinHue: 0.54,
                equalMaxHue: 0,
                equalSaturation: 0.15,
                equalBrightness: 2.8,
                rayLength: 0.5,
                sparkleExposure: 0.1,
                minHue: 0,
                maxHue: 1,
                noiseInfluence: 1,
                increasingRate: 0.03,
                sparkleAmount: 0.6,
                blur: 0
            )
        }()
        let filter = Kirakira(with: parameters)

        picture = PictureInput(image: UIImage(named:"WID-small.jpg")!)
        picture --> filter --> renderView
        picture.processImage()
    }
}

