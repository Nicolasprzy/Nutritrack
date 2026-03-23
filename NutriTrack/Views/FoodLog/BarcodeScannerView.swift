import SwiftUI
import AVFoundation

#if os(iOS)
// MARK: - Scanner AVFoundation (iOS uniquement)

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var codeScanne: String?
    @Binding var isPresented: Bool
    var onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: BarcodeScannerView

        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }

        func didFind(barcode: String) {
            parent.codeScanne = barcode
            parent.onScan(barcode)
            parent.isPresented = false
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didFind(barcode: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?

    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configurerSession()
        ajouterUI()
    }

    private func configurerSession() {
        let session = AVCaptureSession()
        captureSession = session

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            afficherErreur("Caméra indisponible")
            return
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }

        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [
            .ean8, .ean13, .qr, .upce, .code128, .code39
        ]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func ajouterUI() {
        // Viseur central
        let viseur = UIView()
        viseur.layer.borderColor = UIColor(Color.nutriGreen).cgColor
        viseur.layer.borderWidth = 2
        viseur.layer.cornerRadius = 12
        viseur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viseur)

        NSLayoutConstraint.activate([
            viseur.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            viseur.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            viseur.widthAnchor.constraint(equalToConstant: 250),
            viseur.heightAnchor.constraint(equalToConstant: 150)
        ])

        // Label instruction
        let label = UILabel()
        label.text = "Pointez le code-barres vers le viseur"
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: viseur.bottomAnchor, constant: 24),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func afficherErreur(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.frame = view.bounds
        view.addSubview(label)
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput objects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        captureSession?.stopRunning()

        if let object = objects.first as? AVMetadataMachineReadableCodeObject,
           let code = object.stringValue {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didFind(barcode: code)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
}

#else

// MARK: - Fallback macOS (AVFoundation pas disponible pour scanner)

struct BarcodeScannerView: View {
    @Binding var codeScanne: String?
    @Binding var isPresented: Bool
    var onScan: (String) -> Void

    @State private var codeSaisi: String = ""

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Scanner de code-barres")
                .font(.nutriTitle2)

            Text("Le scan caméra est disponible sur iPhone/iPad.\nSaisissez le code-barres manuellement :")
                .font(.nutriBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Code-barres (ex: 3017620425035)", text: $codeSaisi)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 320)

            HStack {
                Button("Annuler") { isPresented = false }
                    .buttonStyle(.bordered)

                Button("Rechercher") {
                    if !codeSaisi.trimmingCharacters(in: .whitespaces).isEmpty {
                        onScan(codeSaisi)
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.nutriGreen)
                .disabled(codeSaisi.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(Spacing.xl)
        .frame(width: 400, height: 350)
    }
}

#endif
