//
//  ScannerView.swift
//  myscannerapp
//
//  Created by Rohan Prakash on 06/04/24.
//

import SwiftUI
import AVKit

struct ScannerView: View {
    @State private var isScanning:Bool = false
    @State private var session : AVCaptureSession = .init()
    @State private var qrOutput : AVCaptureMetadataOutput = .init()
    @State private var cameraPermission: Permission = .idle
    // error handling
    @State private var errorMessage: String = ""
    // button
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    //camera qr output delegate
    
    @StateObject private var qrDelegate = QRScannerDelegate()
    
    //scanned code
    @State private var scannedCode: String = ""
    
    @State private var showError: Bool = false
    var body: some View {
        VStack(spacing:8){
            Button{}
        label:{
            Image(systemName: "xmark")
                .font(.title3)
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
            Text("Place the QR code in the  scanner")
                .font(.title3)
                .foregroundColor(.black.opacity(0.8))
                .padding(.top,20)
            
            Text("Scanning will start automatically")
                .font(.callout)
                .foregroundColor(.gray)
            
            Spacer(minLength: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/)
            
            /// scanner
            
            GeometryReader{
                let size = $0.size
                
                ZStack{
                    
                    CameraView(frameSize: CGSize(width: size.width, height: size.width), session: $session)
                        .scaleEffect(0.97)
                    
                    ForEach(0...4, id: \.self){index in
                        let rotation = Double(index)*90
                        
                        RoundedRectangle(cornerRadius: 2, style: .circular)
                          .trim(from: 0.61, to:0.64)
                          .foregroundColor(.blue.opacity(0.3))
                          .rotationEffect(.init(degrees: rotation))
                    }
                    
                  
                    
                    
                }
                
                // squareshape
                .frame(width: size.width, height: size.width)
                // scanner animation
                .overlay(alignment: .top, content:{
                    Rectangle()
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        .frame(height: 2.5)
                        .shadow(color: .black.opacity(0.8), radius: 8 , x:0, y: isScanning ? 15 : -15)
                        .offset(y:isScanning ? size.width: 0)
                })
                
                // to make it center
                .frame(maxWidth: .infinity , maxHeight: .infinity)
                
            }
            .padding(.horizontal,45)
            
            Spacer(minLength: 15)
                //.alert(errorMessage, isPresented: $showError)
            
            Button{}
        label:{
            Image(systemName: "qrcode.viewfinder")
                .font(.largeTitle)
                .foregroundColor(.gray)
        }
            Spacer(minLength: 45)
        }
        .padding(15)
        //checking camera permission
        .onAppear(perform: checkCameraPermission)
        
//        .onChange(of: qrOutput.scannedCode)
        
       
        
    }
    func activateScannerAnimation(){
        withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses:true)){
            isScanning = true
        }
    }
    func checkCameraPermission(){
        Task{
            switch AVCaptureDevice.authorizationStatus(for: .video){
            case .authorized:
                cameraPermission = .approved
                setupCamera()
            case .notDetermined:
                if await AVCaptureDevice.requestAccess(for: .video){
                    cameraPermission = .approved
                    setupCamera()
                }
                else{
                    cameraPermission = .denied
                }
            case .denied, .restricted:
                cameraPermission = .denied
            default:break
            }
         
        }
    }
    //setting up camera
    func setupCamera(){
        do{
            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualWideCamera], mediaType: .video, position: .back).devices.first else{
                return
            }
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input), session.canAddOutput(qrOutput) else{
                return
            }
            session.beginConfiguration()
            session.addInput(input)
            session.addOutput(qrOutput)
            qrOutput.metadataObjectTypes = [.qr]
            // adding delegate to fetch qr
            qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            
            session.commitConfiguration()
            DispatchQueue.global(qos: .background).async{
                session.startRunning()}
        activateScannerAnimation()
        }

        catch{
            
        }
    }
    }


#Preview {
    ContentView()
}
