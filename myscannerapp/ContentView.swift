import SwiftUI
import SplineRuntime

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var scannedCode = ""
    @State private var result = ""
    
    let arrayOfStringsToCompare = ["Abu@78sqw", "Bjq502@mps", "pld@10dfr3"]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                OnBoard3DView()
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)

                VStack(spacing: 50) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                    } else {
                        Text("Upload the QR Code")
                            .font(.title)
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                    }

                    Button(action: { self.isImagePickerPresented.toggle() }) {
                        Text("Select Image")
                            .font(.title2)
                            .frame(width: 250, height: 20)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
                .padding()
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(selectedImage: self.$selectedImage, completionHandler: self.uploadImage)
                }
                
                Text(result)
                    .padding()
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    func uploadImage(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            self.result = "Failed to convert image to data"
            return
        }
        
        let networkManager = NetworkManager()
        networkManager.uploadImage(imageData: imageData) { responseCode in
            DispatchQueue.main.async {
                self.scannedCode = responseCode
                self.result = self.arrayOfStringsToCompare.contains(responseCode) ?
                              "Response matches one of the strings in the array" :
                              "Response does not match any string in the array"
            }
        }
    }
}

struct NetworkManager {
    func uploadImage(imageData: Data, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "https://api.qrserver.com/v1/read-qr-code/") else {
            completion("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpeg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Error: \(error)")
                completion("Error")
                return
            }
            
            guard let data = data else {
                completion("No data")
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                   let symbolArray = jsonArray.first?["symbol"] as? [[String: Any]],
                   let firstSymbol = symbolArray.first,
                   let dataValue = firstSymbol["data"] as? String {
                    completion(dataValue)
                } else {
                    completion("Invalid JSON format")
                }
            } catch {
                completion("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let completionHandler: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
                parent.completionHandler(uiImage)
            }

            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct OnBoard3DView: View {
    var body: some View {
        let url = URL(string: "https://build.spline.design/4F69S7Z7MQ0bsbmeLSID/scene.splineswift")!
        try? SplineView(sceneFileURL: url)
            .ignoresSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
