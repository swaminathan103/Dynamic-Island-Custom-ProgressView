//
//  Home.swift
//  FileProgressView (iOS)
//
//  Created by Swaminathan Venkataraman on 8/28/23.
//

import SwiftUI

struct Home: View {
    @StateObject var progressBar = DynamicProgress()
    @State private var sampleProgress: CGFloat = 0
    
    var body: some View {
        Button("Download") {
            let config = ProgressConfig(title: "Your New File", progressImage: "arrow.up", expandedImage: "clock.badge.checkmark.fill", tint: .brandPrimary, rotationEnabled: true)
            progressBar.addProgressView(config: config)
        }
        .font(Font.title3.weight(.semibold))
        .foregroundColor(.white)
        .frame(width: 140, height: 35)
        .background(Color.brandPrimary)
        .cornerRadius(10)
        .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.top)
        .padding(.top, 100)
        .onReceive(Timer.publish(every: 0.01, on: .main, in: .default).autoconnect()) { _ in
            if progressBar.isAdded {
                sampleProgress += 0.4
                progressBar.updateProgressView(to: sampleProgress / 100)
            } else {
                sampleProgress = 0
            }
        }
        .blur(radius: progressBar.isAdded ? 2 : 0)
        .disabled(progressBar.isAdded)
        .statusBarHidden(progressBar.hideStatusBar)
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .preferredColorScheme(.light)
    }
}

class DynamicProgress: NSObject, ObservableObject {
    @Published var isAdded = false
    @Published var progress: CGFloat = 0
    @Published var hideStatusBar = false
    
    func addProgressView(config: ProgressConfig) {
        guard (rootVC().view.viewWithTag(300000) == nil) else {
            print("Already Added")
            return
        }
        let hostView = DynamicProgressView(config: config)
            .environmentObject(self)
        let hostingView = UIHostingController(rootView: hostView)
        
        hostingView.view.frame = screenSize()
        hostingView.view.backgroundColor = .clear
        hostingView.view.tag = 300000
        rootVC().view.addSubview(hostingView.view)
        isAdded = true
    }
    
    func updateProgressView(to: CGFloat) {
        progress = to
    }
    
    func removeProgressView() {
        if let view = rootVC().view.viewWithTag(300000) {
            view.removeFromSuperview()
            print("Removed")
            isAdded = false
        }
    }
    
    func screenSize() -> CGRect {
        guard let window = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .zero
        }
        
        return window.screen.bounds
    }
    
    func rootVC() -> UIViewController {
        guard let window = UIApplication.shared.connectedScenes.first as? UIWindowScene,  let root = window.windows.first?.rootViewController else {
            return .init()
        }
        
        return root
    }
}

struct DynamicProgressView: View {
    var config: ProgressConfig
    @EnvironmentObject var progressBar: DynamicProgress
    @State private var showProgress = false
    @State private var showAlert = false
    @State private var progress: CGFloat = 0
    
    var body: some View {
        Canvas { ctx, size in
            ctx.addFilter(.alphaThreshold(min: 0.5, color: .black))
            ctx.addFilter(.blur(radius: 5))
            
            ctx.drawLayer { context in
                var offset: CGFloat = 0
                
                if #available(iOS 16, *) {
                    offset = 18
                }
                for index in [1,2] {
                    if let resolvedImage = ctx.resolveSymbol(id: index) {
                        context.draw(resolvedImage, at: CGPoint(x: size.width / 2, y: offset + 11))
                    }
                }
            }
        } symbols: {
            ProgressComponents()
                .tag(1)
            
            ProgressComponents(isCircle: true)
                .tag(2)
        }
        .overlay(alignment: .top, content: {
            ProgressView()
                .offset(y: 11)
        })
        .overlay(alignment: .top, content: {
            AlertView()
        })
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showProgress = true
            }
        }
        .onReceive(progressBar.$progress) { updatedProgress in
            if updatedProgress < 1.0 {
                progress = updatedProgress
            }
            
            if (updatedProgress * 100).rounded() == 100.0 {
                showProgress = false
                showAlert = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    progressBar.hideStatusBar = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showAlert = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            progressBar.hideStatusBar = false
                        }
                        progressBar.removeProgressView()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func AlertView() -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            Capsule()
                .fill(.black)
                .frame(width: showAlert ? size.width : 126, height: showAlert ? size.height : 37)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .overlay() {
                    HStack( spacing: 13){
                        Image(systemName: config.expandedImage)
                            .symbolRenderingMode(.multicolor)
                            .font(.largeTitle)
                            .foregroundStyle(.white, .blue, .white)
                        HStack(spacing: 6){
                            Text ("Downloaded")
                                .font(.system(size: 13))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text(config.title)
                                .font(.system(size: 13))
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                        }
                        .lineLimit(1)
                        .contentTransition(.opacity)
                        .frame(maxWidth: .infinity,alignment: .leading)
                        .offset(y:12)
                    }
                    .padding (.horizontal, 12)
                    .blur(radius: showAlert ? 0: 5)
                    .opacity(showAlert ? 1 : 0)
                }
        }
        .frame(height: 65)
        .padding(.horizontal, 18)
        .offset(y: 11)
        .animation(.interactiveSpring(response: 0.5).delay(showAlert ? 0.3 : 0), value: showAlert)
    }
    
    @ViewBuilder
    func ProgressView() -> some View {
        ZStack {
            let rotation = (progress > 1 ? 1 : (progress < 0 ? 0 : progress))
            Image(systemName: config.progressImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .font(Font.system(size: 60, weight: .bold))
                .frame(width: 12, height: 12)
                .foregroundColor(config.tint)
                .rotationEffect(.degrees( config.rotationEnabled ? Double(rotation) * 360 : 0))
            
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.25), lineWidth: 4)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(config.tint, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 23, height: 23)
        }
        .frame(width: 37, height: 37)
        .frame(width: 126, alignment: .center)
        .offset(y: showProgress ? 45 : 0)
        .scaleEffect(showProgress ? 1 : 0.55, anchor: .center)
        .opacity(showProgress ? 1 : 0)
        .animation(.interactiveSpring(response: 0.5), value: showProgress)
    }
    
    @ViewBuilder
    func ProgressComponents(isCircle: Bool = false) -> some View {
        if isCircle {
            Circle()
                .fill(.black)
                .frame(width: 37, height: 37)
                .frame(width: 126, alignment: .center)
                .offset(y: showProgress ? 45 : 0)
                .scaleEffect(showProgress ? 1 : 0.55, anchor: .center)
                .animation(.interactiveSpring(response: 0.5), value: showProgress)
        } else {
            Capsule()
                .fill(.black)
                .frame(width: 126, height: 37)
        }
    }
}
