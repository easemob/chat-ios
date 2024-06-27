//
//  GCDTimer.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/5.
//

import Foundation


public protocol GCDTimer {
    // 启动
    func resume()
    // 暂停
    func suspend()
    // 取消
    func cancel()
}

public class GCDTimerMaker {
    
    static func exec(_ task: (() -> ())?, interval: Int, repeats: Bool = true, async: Bool = true) -> GCDTimer? {
        
        guard let _ = task else {
            return nil
        }
        
        return TimerMaker(task,
                          deadline: .now(),
                          repeating: repeats ? .seconds(interval):.never,
                          async: async)
        
    }
}

private class TimerMaker: GCDTimer {
    
    /// 当前Timer 运行状态
    enum TimerState {
        case runing
        case stoped
    }
    
    private var state = TimerState.stoped
    
    private var timer: DispatchSourceTimer?
    
    convenience init(_ exce: (() -> ())?, deadline: DispatchTime, repeating interval: DispatchTimeInterval = .never, leeway: DispatchTimeInterval = .seconds(0), async: Bool = true) {
        self.init()

        let queue = async ? DispatchQueue.global():DispatchQueue.main
        
        timer = DispatchSource.makeTimerSource(queue: queue)
        
        timer?.schedule(deadline: deadline,
                        repeating: interval,
                        leeway: leeway)
        
        timer?.setEventHandler(handler: {
            exce?()
        })
    }
    
    
    func resume() {
        guard state != .runing else { return }
        state = .runing
        timer?.resume()
    }
    
    func suspend() {
        guard state != .stoped else { return }
        state = .stoped
        timer?.suspend()
    }
    
    func cancel() {
        state = .stoped
        timer?.cancel()
    }
    
    
}

