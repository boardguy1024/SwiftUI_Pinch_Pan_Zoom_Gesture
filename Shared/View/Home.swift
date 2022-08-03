//
//  Home.swift
//  SwiftUI_Pinch_Pan_Zoom_Gesture
//
//  Created by park kyung seok on 2022/08/02.
//

import SwiftUI

struct Home: View {
    var body: some View {
        
        VStack {
            Image("Post1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: getRect().width - 30, height: 250)
                .cornerRadius(15)
                .addPinchZoom()
        
        }
        .padding()
        
        
        
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}

extension View {
    
    // .addPinchZoom() で呼び出せるようになる
    
    func addPinchZoom() -> some View {
        return PinchZoomContext {
            self
        }
    }
}

// Viewを引数に渡して、このstruct自身が ViewBuilderで渡されたViewの処理をする
struct PinchZoomContext<Content: View>: View {
    
    var content: Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    
    @State var offset: CGPoint = .zero
    @State var scale: CGFloat = 0
    
    // Gestureが始まったposition
    @State var scalePosition: CGPoint = .zero
    
    var body: some View {
        // ここでは UIKit Gestureを使う

        content
            .overlay(
                GeometryReader { proxy in
                    let size = proxy.size
                    
                    ZoomGesture(size: size, scale: $scale, offset: $offset, scalePosition: $scalePosition)

                }
            )
            .scaleEffect(1 + scale, anchor: .init(x: scalePosition.x, y: scalePosition.y))
        
        
        
    }
}


struct ZoomGesture: UIViewRepresentable {
    
    var size: CGSize
    
    @Binding var scale: CGFloat
    @Binding var offset: CGPoint
    
    // Gestureが始まったposition
    @Binding var scalePosition: CGPoint
    
    func makeUIView(context: Context) -> UIView {
        
        let view = UIView()
        view.backgroundColor = .clear
        
        // Gestureを追加
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator,
                                                    action: #selector(context.coordinator.handlePinch(sender:)))
        
        view.addGestureRecognizer(pinchGesture)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    // Coordinatorと紐付け
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    
    // GestureのHandler
    class Coordinator: NSObject {
        
        
        var parent: ZoomGesture
        
        init(parent: ZoomGesture) {
            self.parent = parent
        }
        
        @objc
        func handlePinch(sender: UIPinchGestureRecognizer) {
            
            // Scaleを計算
            
            // Gestureが始まった || 変更中
            if sender.state == .began || sender.state == .changed {
                
                // scaleは 1をベースとしているので
                parent.scale = (sender.scale - 1)
                
                // gestureが始まった座標をとり、scalePointに計算
                // 370 / 370 = 1 ,
                // 50(左に近い) / 370 = 0.135...
                
                let scalePointX = sender.location(in: sender.view).x / sender.view!.frame.width
                let scalePointY = sender.location(in: sender.view).y / sender.view!.frame.height

                // scalePointX ( 0...1 ) scalePointY ( 0...1 )
                let point: CGPoint = .init(x: scalePointX, y: scalePointY)
                
                // pinchが始まった初回だけそのpointを親に渡す ( zoomをしながら指を動かしても 初回の座標でのみzoomができるようにしたいため
                parent.scalePosition = parent.scalePosition == .zero ? point : parent.scalePosition
            } else {
                // それ以外の場合には　元に戻す
                withAnimation(.easeInOut(duration: 0.35)) {
                    parent.scale = 0
                    parent.scalePosition = .zero
                }
            }
        }
    }
}



extension View {
    
    func getRect() -> CGRect {
        return UIScreen.main.bounds
    }
}











// カスタムのViewBuilderを作ってみた！
// 参考URL: https://inon29.hateblo.jp/entry/2020/04/11/121141
@resultBuilder struct CustomViewBuilder {
    static func buildBlock<Content>(_ content: Content) -> Content where Content: View {
        return content
    }
    
    static func buildBlock<C0, C1>(_ c0: C0, _ c1: C1) -> TupleView<(C0, C1)> where C0: View, C1: View {
        return TupleView((c0, c1))
    }
}


struct MyVStack<Content>: View where Content: View {
    
    var content: () -> Content
    
    init(@CustomViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        VStack {
            self.content()
        }
    }
}
