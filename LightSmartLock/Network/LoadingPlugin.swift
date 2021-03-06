//
//  LoadingPlugin.swift
//  LightSmartLock
//
//  Created by mugua on 2019/11/20.
//  Copyright © 2019 mugua. All rights reserved.
//

import Foundation
import Moya
import PKHUD
import Lottie

final class LoadingPlugin: PluginType {
    
    init() {}
    
    private lazy var animationView: AnimationView = {
        let animation = Animation.named("loading", bundle: Bundle.main, animationCache: LRUAnimationCache.sharedCache)!
        let animationView = AnimationView(animation: animation)
        animationView.frame.size = CGSize(width: 50, height: 50)
        animationView.animation = animation
        animationView.loopMode = .loop
        return animationView
    }()
    
    private lazy var view: UIView = {
        let view = UIView()
        view.frame.size = CGSize(width: 50, height: 50)
        animationView.center = view.center
        view.addSubview(animationView)
        view.backgroundColor = ColorClassification.hudColor.value
        return view
        
    }()
    
    func willSend(_ request: RequestType, target: TargetType) {
        
        DispatchQueue.main.async {
            if !HUD.isVisible {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self.animationView.play()
                HUD.show(.customView(view: self.view))
            }
        }
    }
    
    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            HUD.hide()
        }
        
    }
}
