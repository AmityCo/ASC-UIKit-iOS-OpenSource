//
//  AmityCameraPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/15/23.
//

import SwiftUI
import AVKit

struct AmityCameraPage: AmityPageView {
    @EnvironmentObject var host: SwiftUIHostWrapper
    
    var id: PageId {
        .cameraPage
    }
    
    let targetId: String
    var avatar: UIImage?
    
    let cameraManager = CameraManager()
    let segmentButtonTitles: [String] = ["Photo", "Video"]
    
    @State private var selectedSemgnetIndex: Int = 0
    @State private var cameraMode: CameraOutputMode = .stillImage
    @State private var cameraFlashMode: CameraFlashMode = .off
    @State private var videoCaptureButtonSelected: Bool = false
    
    @StateObject private var pickerViewModel = ImageVideoPickerViewModel()
    @State private var showImageVideoPicker: Bool = false
    
    @State private var videoCaptureprogress: CGFloat = 0.0
    @State private var videoCaputreDuration: TimeInterval = 0
    @State private var videoCapturetimer: Timer?
    
    init(targetId: String, avatar: UIImage?) {
        self.targetId = targetId
        self.avatar = avatar
    }
    
    public var body: some View {
        AmityView(configType: .page(configId), config: { configDict in
            //
        }) { config in
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    CameraPreviewView(cameraManager: cameraManager)
                        .cornerRadius(14.0)
                    
                    if cameraMode == .videoWithMic && videoCaptureButtonSelected {
                        Text("\(formatDuration(videoCaputreDuration))")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            .background(Color.red)
                            .cornerRadius(4)
                            .frame(width: 60, height: 26)
                            .offset(y: 23)
                            .animation(nil)
                    }
                    
                    VStack {
                        HStack {
                            Image(AmityIcon.backgroundedCloseIcon.getImageResource())
                                .setModifier(offset: (x: 16, y: 16),
                                             contentMode: .fill,
                                             frame: CGSize(width: 32, height: 32))
                                .onTapGesture {
                                    host.controller?.dismiss(animated: true)
                                }
        
                            Spacer()
                            Image(cameraFlashMode == .on ? AmityIcon.flashOnIcon.getImageResource()
                                  : AmityIcon.flashOffIcon.getImageResource())
                                .setModifier(offset: (x: -16, y: 16),
                                             contentMode: .fill,
                                             frame: CGSize(width: 32, height: 32))
                                .onTapGesture {
                                    toggleFlash()
                                }
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
                        }
                    }
                }
                
                SegmentedPickerView(titles: segmentButtonTitles, currentIndex: $selectedSemgnetIndex)
                    .frame(width: 244, height: 44)
                    .background(AmityColor.darkGray.getColor())
                    .clipShape(RoundedRectangle(cornerRadius: 24.0))
                    .padding([.bottom, .top], 16)
                    
            }
        }
        .onChange(of: selectedSemgnetIndex) { newValue in
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
                let context = CameraPageBehavior.Context(page: self, targetId: targetId, avatar: avatar, outputImage: (pickerViewModel.selectedImage, pickerViewModel.selectedMediaURL))
                AmityUIKitManagerInternal.shared.behavior.cameraPageBehaviour?.goToStoryCreationPage(context: context)
            } else if selectedMedia == UTType.movie.identifier {
                let context = CameraPageBehavior.Context(page: self, targetId: targetId, avatar: avatar, outputVideo: pickerViewModel.selectedMediaURL)
                AmityUIKitManagerInternal.shared.behavior.cameraPageBehaviour?.goToStoryCreationPage(context: context)
            }
        }
        .background(Color.black.ignoresSafeArea())

    }
    
    
    func getImageCaptureButtonView() -> some View {
        Button {
            guard cameraManager.cameraIsReady else { return }
            
            captureImage()
            
            turnOffFlash()
        } label: {
            Image(AmityIcon.cameraShutterIcon.getImageResource())
                .setModifier(offset: (x: 0, y: -32),
                             contentMode: .fill,
                             frame: CGSize(width: 72, height: 72))
        }
    }
    
    
    func getVideoCaptureButtonView() -> some View {
        Button {
            guard cameraManager.cameraIsReady else { return }
            
            videoCaptureButtonSelected.toggle()
            captureVideo()
            
            if videoCaptureButtonSelected {
                startVideoCaptureTimer()
            } else {
                stopVideoCaptureTimer()
            }
        } label: {
            Image(videoCaptureButtonSelected ?
                  AmityIcon.videoShutterRecordingIcon.getImageResource()
                  : AmityIcon.videoShutterIcon.getImageResource())
                .setModifier(offset: (x: 0, y: -32),
                         contentMode: .fill,
                         frame: CGSize(width: 72, height: 72))
                .overlay(
                    Circle()
                        .trim(from: 0, to: videoCaptureprogress)
                        .stroke(
                            Color.red,
                            style: StrokeStyle(
                                lineWidth: 7.0,
                                lineCap: .square
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(nil)
                        .offset(y: -32)
                        
                )
        }
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
                    
                    let context = CameraPageBehavior.Context(page: self, targetId: targetId, avatar: avatar, outputImage: (capturedImage, capturedImageURL))
                    AmityUIKitManagerInternal.shared.behavior.cameraPageBehaviour?.goToStoryCreationPage(context: context)
                }
            }
        }
    }
    
    
    func captureVideo() {
        if videoCaptureButtonSelected {
            cameraManager.startRecordingVideo()
        } else {
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
                    let context = CameraPageBehavior.Context(page: self, targetId: targetId, avatar: avatar, outputVideo: url)
                    AmityUIKitManagerInternal.shared.behavior.cameraPageBehaviour?.goToStoryCreationPage(context: context)
                }
            }
        }
    }
    
    
    func startVideoCaptureTimer() {
        videoCaptureprogress = 0.0
        
        videoCapturetimer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { timer in
            withAnimation {
                if videoCaptureprogress >= 1.0 {
                    videoCaptureprogress = 0.0
                    videoCaptureButtonSelected.toggle()
                    videoCaputreDuration = 0.0
                    
                    captureVideo()
                    timer.invalidate()
                } else {
                    videoCaptureprogress += 1.0 / (60.0 / 0.001)
                    
                    let secondsCounter = Int(videoCaptureprogress * 60.0)
                    if secondsCounter != Int(videoCaputreDuration) {
                        videoCaputreDuration += 1
                    }
                }
            }
        }
    }
    
    
    func stopVideoCaptureTimer() {
        videoCaptureprogress = 0.0
        videoCaputreDuration = 0.0
        videoCapturetimer?.invalidate()
        videoCapturetimer = nil
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
    
    // Camera Flash
    func turnOnFlash() {
        cameraManager.flashMode = .on
        cameraFlashMode = cameraManager.flashMode
    }
    
    func turnOffFlash() {
        cameraManager.flashMode = .off
        cameraFlashMode = cameraManager.flashMode
    }
    
    func toggleFlash() {
        cameraManager.flashMode = cameraFlashMode == .off ? .on : .off
        cameraFlashMode = cameraManager.flashMode
    }
    
}

#Preview {
    AmityCameraPage(targetId: "", avatar: nil)
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
