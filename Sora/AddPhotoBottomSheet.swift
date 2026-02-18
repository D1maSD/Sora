//
//  AddPhotoBottomSheet.swift
//  Sora
//
//  Created by Dima Melnik on 2/12/26.
//

import SwiftUI
import AVFoundation
import Photos
import PhotosUI
import UniformTypeIdentifiers

enum AddPhotoSheetMode {
    case photo
    case video
}

struct AddPhotoBottomSheet: View {
    @Binding var selectedImage: UIImage?
    @Binding var selectedVideoURL: URL?
    var mode: AddPhotoSheetMode = .photo
    @Environment(\.dismiss) var dismiss
    
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var showCameraPermissionAlert = false
    @State private var showGalleryPermissionAlert = false
    
    private var isVideoMode: Bool { mode == .video }
    private var headerTitle: String { isVideoMode ? "Add video" : "Add photo" }
    private var takeButtonTitle: String { isVideoMode ? "Take a video" : "Take a photo" }
    
    var body: some View {
        ZStack {
            Color(hex: "#0D0D0F")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Заголовок
                    Text(headerTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 20)
                        .padding(.top, 40)
                        .padding(.bottom, 24)
                    
                    // Good examples контейнер
                    VStack(alignment: .leading, spacing: 5) {
                        // Тайтл с иконкой
                        HStack(alignment: .center, spacing: 8) {
                            Image("checkmarkGreen")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                            
                            Text("Good examples")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 10)
                        .padding(.trailing, 20)
                        .padding(.leading, 20)
                        VStack(alignment: .leading, spacing: 13) {
                        // Лейбл под тайтлом
                        Text("Clear face, neutral background, good lighting, different angles, high quality")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 20)
                        
                        // Картинка
                        Image("goodCards")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 15)
                            .padding(.bottom, 10)
                        }
                    }
                    .background(Color(hex: "#2B2D2F"))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // Bad examples контейнер
                    VStack(alignment: .leading, spacing: 5) {
                        // Тайтл с иконкой
                        HStack(alignment: .center, spacing: 8) {
                            Image("checkmarkRed")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                            
                            Text("Bad examples")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 10)
                        .padding(.trailing, 20)
                        .padding(.leading, 20)
                        VStack(alignment: .leading, spacing: 13) {
                            // Лейбл под тайтлом
                            Text("Hidden or covered face, blurry or dark images, poor lighting, distracting background")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 20)
                            
                            // Картинка
                            Image("badCards")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 15)
                                .padding(.bottom, 10)
                        }
                    }
                    .background(Color(hex: "#2B2D2F"))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    // Кнопки внизу - в одном HStack
                    HStack(spacing: 12) {
                        Button(action: {
                            checkCameraPermission()
                        }) {
                            Text(takeButtonTitle)
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(Color(hex: "#2F76BC"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(hex: "#111A24"))
                                .cornerRadius(28)
                        }
                        
                        Button(action: {
                            checkGalleryPermission()
                        }) {
                            Text("Take from gallery")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#6CABE9"),
                                            Color(hex: "#2F76BC")
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(28)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            if isVideoMode {
                VideoCameraPicker(selectedVideoURL: $selectedVideoURL, isPresented: $showCamera)
            } else {
                ImagePicker(selectedImage: $selectedImage, isPresented: $showCamera, sourceType: .camera)
            }
        }
        .sheet(isPresented: $showGallery) {
            if isVideoMode {
                VideoGalleryPicker(selectedVideoURL: $selectedVideoURL, isPresented: $showGallery)
            } else {
                ImagePicker(selectedImage: $selectedImage, isPresented: $showGallery, sourceType: .photoLibrary)
            }
        }
        .alert("Camera Access", isPresented: $showCameraPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(isVideoMode ? "Please allow camera access in Settings to record videos." : "Please allow camera access in Settings to take photos.")
        }
        .alert("Photo Library Access", isPresented: $showGalleryPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(isVideoMode ? "Please allow photo library access in Settings to select videos." : "Please allow photo library access in Settings to select photos.")
        }
        .onChange(of: selectedImage) { _, newImage in
            if newImage != nil { dismiss() }
        }
        .onChange(of: selectedVideoURL) { _, newURL in
            if newURL != nil { dismiss() }
        }
    }
    
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        showCameraPermissionAlert = true
                    }
                }
            }
        default:
            showCameraPermissionAlert = true
        }
    }
    
    private func checkGalleryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            showGallery = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        showGallery = true
                    } else {
                        showGalleryPermissionAlert = true
                    }
                }
            }
        default:
            showGalleryPermissionAlert = true
        }
    }
}

// MARK: - Video-only gallery picker (PHPicker .videos)
struct VideoGalleryPicker: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoGalleryPicker

        init(_ parent: VideoGalleryPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            guard let result = results.first else { return }
            let provider = result.itemProvider
            guard provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else { return }
            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, _ in
                guard let url = url else { return }
                let tempDir = FileManager.default.temporaryDirectory
                let destURL = tempDir.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: destURL)
                try? FileManager.default.copyItem(at: url, to: destURL)
                DispatchQueue.main.async {
                    self?.parent.selectedVideoURL = destURL
                }
            }
        }
    }
}

// MARK: - Video camera picker (UIImagePickerController camera, video)
struct VideoCameraPicker: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.movie.identifier]
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoCameraPicker

        init(_ parent: VideoCameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.isPresented = false
            if let url = info[.mediaURL] as? URL {
                let tempDir = FileManager.default.temporaryDirectory
                let destURL = tempDir.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: destURL)
                try? FileManager.default.copyItem(at: url, to: destURL)
                parent.selectedVideoURL = destURL
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

#Preview {
    AddPhotoBottomSheet(selectedImage: .constant(nil), selectedVideoURL: .constant(nil))
}
