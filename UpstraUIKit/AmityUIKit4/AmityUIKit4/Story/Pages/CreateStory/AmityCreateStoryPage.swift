//
//  AmityCreateStoryPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/15/23.
//

import SwiftUI
import AVKit
import AmitySDK

public struct AmityCreateStoryPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .cameraPage
    }
    
    let targetId: String
    let targetType: AmityStoryTargetType
    
    @State private var allowedCaptureVideoLength = 60.0
    private let cameraManager = CameraManager()
    private let segmentedPickerTitles: [String] = ["Photo", "Video"]
    
    @State private var selectedPickerIndex: Int = 0
    @State private var cameraMode: CameraOutputMode = .stillImage
    @State private var cameraFlashMode: CameraFlashMode = .off
    @State private var videoCaptureButtonSelected: Bool = false
    
    @StateObject private var pickerViewModel = ImageVideoPickerViewModel()
    @State private var showImageVideoPicker: Bool = false
    
    @State private var videoCaptureProgress: CGFloat = 0.0
    @State private var videoCaputreDuration: TimeInterval = 0
    @State private var videoCaptureTimer: Timer?
    
    @StateObject private var viewModel = AmityCreateStoryPageViewModel()
    
    public init(targetId: String, targetType: AmityStoryTargetType) {
        self.targetId = targetId
        self.targetType = targetType
        
        cameraManager.shouldRespondToOrientationChanges = false
        cameraManager.shouldFlipFrontCameraImage = true
    }
    
    public var body: some View {
        AmityView(configId: configId, config: { configDict in
            //
        }) { config in
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    CameraPreviewView(cameraManager: cameraManager)
                        .cornerRadius(14.0)
                        .onAppear {
                            cameraManager.askUserForCameraPermission { isAllowed in
                                if !isAllowed {
                                    let cameraStatus = cameraManager.currentCameraStatus()
                                    
                                    if cameraStatus == .notDetermined || cameraStatus == .accessDenied {
                                        let alertController = UIAlertController(title: AmityLocalizedStringSet.General.permissionRequired.localizedString, message: AmityLocalizedStringSet.General.cameraAccessDenied.localizedString, preferredStyle: .alert)
                                        
                                        let action = UIAlertAction(title: "OK", style: .default) { _ in
                                            alertController.dismiss(animated: true)
                                        }
                                        alertController.addAction(action)
                                        
                                        host.controller?.present(alertController, animated: true)
                                    }
                                }
                            }
                        }
                        
                        .accessibilityIdentifier(AccessibilityID.Story.AmityCreateStoryPage.cameraPreviewView)
                    
                    if cameraMode == .videoWithMic && videoCaptureButtonSelected {
                        Text("\(formatDuration(videoCaputreDuration))")
                            .applyTextStyle(.bodyBold(.white))
                            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            .background(Color.red)
                            .cornerRadius(4)
                            .frame(width: 60, height: 26)
                            .offset(y: 23)
                            .animation(nil)
                    }
                    
                    VStack {
                        HStack {
                            Image(AmityIcon.getImageResource(named: getElementConfig(elementId: .closeButtonElement, key: "close_icon", of: String.self) ?? ""))
                                .setModifier(offset: (x: 16, y: 16),
                                             contentMode: .fill,
                                             frame: CGSize(width: 32, height: 32))
                                .onTapGesture {
                                    host.controller?.dismiss(animated: true)
                                }
                                .accessibilityIdentifier(AccessibilityID.Story.AmityCreateStoryPage.closeButton)
                            
                            Spacer()
                            
                            Image(cameraFlashMode == .auto ? AmityIcon.flashOnIcon.getImageResource()
                                  : AmityIcon.flashOffIcon.getImageResource())
                            .setModifier(offset: (x: -16, y: 16),
                                         contentMode: .fill,
                                         frame: CGSize(width: 32, height: 32))
                            .onTapGesture {
                                toggleFlash()
                            }
                            .accessibilityIdentifier(AccessibilityID.Story.AmityCreateStoryPage.flashLightButton)
                        }
                        Spacer()
                        HStack{
                            Button {
                                showImageVideoPicker = true
                            } label: {
                                Image(AmityIcon.galleryIcon.getImageResource())
                                    .setModifier(offset: (x: 20, y: -40),
                                                 contentMode: .fill,
                                                 frame: CGSize(width: 40, height: 40))
                            }
                            .sheet(isPresented: $showImageVideoPicker) {
                                ImageVideoPicker(viewModel: pickerViewModel)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier(AccessibilityID.Story.AmityCreateStoryPage.mediaPickerButton)
                            
                            Spacer()
                            
                            if cameraMode == .stillImage {
                                getImageCaptureButtonView()
                            } else {
                                getVideoCaptureButtonView()
                            }
                            
                            Spacer()
                            
                            Button {
                                let cameraDevice = cameraManager.cameraDevice
                                cameraManager.cameraDevice = cameraDevice == .front ? .back : .front
                            } label: {
                                Image(AmityIcon.flipCameraIcon.getImageResource())
                                    .setModifier(offset: (x: -20, y: -40),
                                                 contentMode: .fill,
                                                 frame: CGSize(width: 40, height: 40))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier(AccessibilityID.Story.AmityCreateStoryPage.switchCameraButton)
                            
                        }
                    }
                }
                
                SegmentedPickerView(titles: segmentedPickerTitles, currentIndex: $selectedPickerIndex)
                    .frame(width: 244, height: 44)
                    .background(Color(UIColor(hex: "#292B32")))
                    .clipShape(RoundedRectangle(cornerRadius: 24.0))
                    .padding([.bottom, .top], 16)
                
            }
        }
        .onChange(of: selectedPickerIndex) { newValue in
            DispatchQueue.main.async {
                cameraMode = newValue == 0 ? .stillImage : .videoWithMic
                cameraManager.cameraOutputMode = cameraMode
            }
        }
        .onChange(of: pickerViewModel) { value in
            guard let selectedMedia = pickerViewModel.selectedMedia else {
                Log.add(event: .error, "Selected Media should not be nil.")
                return
            }
            
            if selectedMedia == UTType.image.identifier {
                let context = AmityCreateStoryPageBehaviour.Context(page: self, targetId: targetId, targetType: targetType, outputImage: (pickerViewModel.selectedImage, pickerViewModel.selectedMediaURL))
                AmityUIKitManagerInternal.shared.behavior.createStoryPageBehaviour?.goToDraftStoryPage(context: context)
            } else if selectedMedia == UTType.movie.identifier {
                let context = AmityCreateStoryPageBehaviour.Context(page: self, targetId: targetId, targetType: targetType, outputVideo: pickerViewModel.selectedMediaURL)
                AmityUIKitManagerInternal.shared.behavior.createStoryPageBehaviour?.goToDraftStoryPage(context: context)
            }
        }
        .onChange(of: viewModel.maxVideoDuration) { value in
            allowedCaptureVideoLength = value
        }
        .background(Color.black.ignoresSafeArea())
        
    }
    
    
    func getImageCaptureButtonView() -> some View {
        Button {
            guard cameraManager.cameraIsReady else { return }
            
            captureImage()
            
        } label: {
            Image(AmityIcon.cameraShutterIcon.getImageResource())
                .frame(width: 72, height: 72)
                .offset(x: 0, y: -32)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.Story.AmityCreateStoryPage.cameraShutterButton)
    }
    
    
    func getVideoCaptureButtonView() -> some View {
        Button {} label: {
            ZStack {
                Image(videoCaptureButtonSelected ?
                      AmityIcon.videoShutterRecordingIcon.getImageResource()
                      : AmityIcon.videoShutterIcon.getImageResource())
                Circle()
                    .trim(from: 0, to: videoCaptureProgress)
                    .stroke(
                        Color.red,
                        style: StrokeStyle(
                            lineWidth: 7.0,
                            lineCap: .square
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 67, height: 67)
            }
            .frame(width: 72, height: 72)
            .offset(x: 0, y: -32)
        }
        .overlay(
            GestureView(onTouchAndHoldStart: {
                guard cameraManager.cameraIsReady else { return }
                videoCaptureButtonSelected.toggle()
            },
            onTouchAndHoldEnd: {
                guard cameraManager.cameraIsReady else { return }
                videoCaptureButtonSelected.toggle()
            })
        )
        .onChange(of: videoCaptureButtonSelected) { isSelected in
            isSelected ? startRecordingVideo() : stopRecordingVideo()
        }
        .accessibilityIdentifier(AccessibilityID.Story.AmityCreateStoryPage.cameraShutterButton)
    }
    
    
    func captureImage() {
        cameraManager.capturePictureWithCompletion { result in
            switch result {
            case .failure:
                Log.add(event: .error, "Error occurred Cannot save picture.")
            case .success(let content):
                if let capturedData = content.asData.data,
                   let capturedImage = UIImage(data: capturedData),
                   let capturedImageURL = content.asData.url
                {
                    Log.add(event: .info, "Captured Image: \(capturedImage)")
                    Log.add(event: .info, "Captured ImageURL: \(capturedImageURL)")
                    
                    let context = AmityCreateStoryPageBehaviour.Context(page: self, targetId: targetId, targetType: targetType, outputImage: (capturedImage, capturedImageURL))
                    AmityUIKitManagerInternal.shared.behavior.createStoryPageBehaviour?.goToDraftStoryPage(context: context)
                }
            }
        }
    }
    
    
    func startRecordingVideo() {
        cameraManager.startRecordingVideo()
        startVideoCaptureTimer()
    }
    
    
    func stopRecordingVideo() {
        cameraManager.stopVideoRecording { (url, error) -> Void in
            if error != nil {
                Log.add(event: .error, "Error occurred Cannot save video.")
            }
            
            guard let url else {
                Log.add(event: .error, "Error occurred Cannot get save video URL.")
                return
            }
            Log.add(event: .info, "Recored Video File URL: \(url)")
            
            DispatchQueue.main.async {
                let context = AmityCreateStoryPageBehaviour.Context(page: self, targetId: targetId, targetType: targetType, outputVideo: url)
                AmityUIKitManagerInternal.shared.behavior.createStoryPageBehaviour?.goToDraftStoryPage(context: context)
            }
        }
        stopVideoCaptureTimer()
    }
    
    
    func startVideoCaptureTimer() {
        videoCaptureTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if videoCaputreDuration + 0.3 >= allowedCaptureVideoLength {
                videoCaptureButtonSelected.toggle()
            } else {
                videoCaputreDuration += 0.1
                withAnimation {
                    videoCaptureProgress += 1.0 / CGFloat(allowedCaptureVideoLength / 0.1)
                }
            }
        }
    }
    
    
    func stopVideoCaptureTimer() {
        videoCaptureProgress = 0.0
        videoCaputreDuration = 0.0
        videoCaptureTimer?.invalidate()
        videoCaptureTimer = nil
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        if let formattedString = formatter.string(from: duration) {
            return formattedString
        } else {
            return "00:00"
        }
    }
    
    func toggleFlash() {
        cameraManager.flashMode = cameraFlashMode == .off ? .auto : .off
        cameraFlashMode = cameraManager.flashMode
    }
    
}

class AmityCreateStoryPageViewModel: ObservableObject {
    @Published var maxVideoDuration: CGFloat = 60.0
    
    init() {
        Task { @MainActor in
            let contentSettings = try await AmityUIKitManagerInternal.shared.client.getContentSettings()
            if let duration = contentSettings.story?.videoSettings?.maxDurationSeconds {
                maxVideoDuration = duration
            }
        }
    }
}


struct CameraPreviewView: UIViewRepresentable {
    
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView()
        cameraManager.addPreviewLayerToView(view, newCameraOutputMode: CameraOutputMode.stillImage)
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // Nothing to update preview view
    }
}


extension Image {
    func setModifier(offset: (x: CGFloat , y: CGFloat), contentMode: ContentMode, frame: CGSize) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .frame(width: frame.width, height: frame.height)
            .offset(x: offset.x, y: offset.y)
    }
}
