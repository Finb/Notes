//
//  RxSwiftOperator.swift
//  Notes
//
//  Created by huangfeng on 2020/11/4.
//

import UIKit
import RxSwift

class RxSwiftOperator {
    class func test(){
        amb()
    }
    
    class func amb() {
        // 在多个源 Observables 中， 取第一个发出元素或产生事件的 Observable，然后只发出它的元素
        // 当你传入多个 Observables 到 amb 操作符时，它将取其中一个 Observable：第一个产生事件的那个 Observable
        // 可以是一个 next，error 或者 completed 事件。 amb 将忽略掉其他的 Observables。
        
        let a = Observable<Int>.interval(1, scheduler: MainScheduler.instance)
            .map { (item) in
                return 100 + item
            }
            .take(5)
        let b = Observable<Int>.interval(3, scheduler: MainScheduler.instance)
        let c = Observable<Int>.interval(5, scheduler: MainScheduler.instance)
        
        Observable.amb([a,b,c]).subscribe { (event) in
            print(event)
        }
        
        // 只有 a 的事件会执行，因为他最先发出事件
        
    }
    
    
}
