//
//  RxSwiftOperator.swift
//  Notes
//
//  Created by huangfeng on 2020/11/4.
//

import UIKit
import RxSwift

class RxSwiftOperator {
    
    class func amb() {
        // 在多个源 Observables 中， 取第一个发出元素或产生事件的 Observable，然后只发出它的元素
        // 当你传入多个 Observables 到 amb 操作符时，它将取其中一个 Observable：第一个产生事件的那个 Observable
        // 可以是一个 next，error 或者 completed 事件。 amb 将忽略掉其他的 Observables。
        
        let a = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .map { (item) in
                return 100 + item
            }
            .take(5)
        let b = Observable<Int>.interval(.seconds(3), scheduler: MainScheduler.instance)
        let c = Observable<Int>.interval(.seconds(5), scheduler: MainScheduler.instance)
        
        _ = Observable.amb([a,b,c]).subscribe { (event) in
            print(event)
        }
        
        // 只有 a 的事件会执行，因为他最先发出事件
        /*
         100
         101
         102
         103
         104
         completed
         */
        
    }
    
    
    class func buffer(){
        // 缓存元素，然后将缓存的元素集合，周期性的发出来
        // buffer 操作符将缓存 Observable
        // 中发出的新元素，当元素达到某个数量，或者经过了特定的时间，它就会将这个元素集合发送出来。
        
        _ = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .take(5)
            .buffer(timeSpan: .seconds(3), count: 2, scheduler: MainScheduler.instance)
            .subscribe { (event) in
                print(event)
            }
        
        // 每两秒发送一次事件，或者等待3秒发个 []， 或者收到完成事件后立即发送
        /*
         next([0, 1])
         next([2, 3])
         next([4])
         completed
         */
    }
    
    class func catchError(){
        /*
         从一个错误事件中恢复，将错误事件替换成一个备选序列
         catchError 操作符将会拦截一个 error 事件，将它替换成其他的元素或者一组元素，然后传递给观察者。这样可以使得 Observable 正常结束，或者根本都不需要结束。

         这里存在其他版本的 catchError 操作符。
         */
        
        let sequenceThatFails = PublishSubject<String>()
        let recoverySequence = PublishSubject<String>()
        
        _ = sequenceThatFails
            .catchError {
                print("Error:", $0)
                return recoverySequence
            }
            .subscribe { print($0) }
        
        sequenceThatFails.onNext("😬")
        sequenceThatFails.onNext("😨")
        sequenceThatFails.onNext("😡")
        sequenceThatFails.onNext("🔴")
        sequenceThatFails.onError(TestError.error)
        
        //继续订阅恢复序列
        recoverySequence.onNext("😊")
        recoverySequence.onNext("😊")
        recoverySequence.onError(TestError.error)
        
        //不再发送，恢复序列可没有 catchError
        recoverySequence.onNext("😭")
        
    }
    
    class func catchErrorJustReturn(){

        let sequenceThatFails = PublishSubject<String>()

        _ = sequenceThatFails
            .catchErrorJustReturn("😊")
            .subscribe { print($0) }
        
        sequenceThatFails.onNext("😬")
        sequenceThatFails.onNext("😨")
        sequenceThatFails.onNext("😡")
        sequenceThatFails.onNext("🔴")
        sequenceThatFails.onError(TestError.error)
        
        //不再发送
        sequenceThatFails.onNext("🔴")
        sequenceThatFails.onNext("🔴")
        
        /*
         next(😬)
         next(😨)
         next(😡)
         next(🔴)
         next(😊)
         completed
         */

        
    }
    
    class func combineLatest(){
        /*
         当多个 Observables 中任何一个发出一个元素，就发出一个元素。这个元素是由这些 Observables 中最新的元素，通过一个函数组合起来的
         
         combineLatest 操作符将多个 Observables 中最新的元素通过一个函数组合起来，然后将这个组合的结果发出来。这些源 Observables 中任何一个发出一个元素，他都会发出一个元素（前提是，这些 Observables 曾经发出过元素）。
         */
        
        let a = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).take(3)
        let b = Observable<Int>.interval(.seconds(2), scheduler: MainScheduler.instance).take(4)
        
        _ = Observable.combineLatest(a, b) { (l, r) in
            return "\(Date()) \(l) \(r)"
        }.subscribe { (event) in
            print(event)
        }
        
        /*
         
         012
          0 1 2 3
         
         1s:     等待 b 序列发送
         2s: 1 0
         3s: 2 0
         4s: 2 1
         5s:     a序列发完了，b序列还得等1秒，
         6s: 2 2
         7s:
         8s: 2 3
         */
        
    }
    class func concat(){
        /*
         让两个或多个 Observables 按顺序串连起来
         
         concat 操作符将多个 Observables 按顺序串联起来，当前一个 Observable 元素发送完毕后，后一个 Observable 才可以开始发出元素。

         concat 将等待前一个 Observable 产生完成事件后，才对后一个 Observable 进行订阅。如果后一个是“热” Observable ，在它前一个 Observable 产生完成事件前，所产生的元素将不会被发送出来。
         */
        
        let a = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).take(3)
        
        let b = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).take(4)
        
        // 热 Observable 轮到他时，之前发送的事件会被丢弃
        let c = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).take(10).replay(0)
        _ = c.connect()
        _ = c.subscribe { (event) in
            print("hot c \(event)")
        }
        
        _ = Observable.concat([a,b,c])
            .subscribe { (event) in
                print("concat \(event)")
            }
        
        /*
         concat 0   hot 0
         concat 1   hot 1
         concat 2   hot 2
         concat 0   hot 3
         concat 1   hot 4
         concat 2   hot 5
         concat 3   hot 6
         concat 7   hot 7
         concat 8   hot 8
         concat 9   hot 9
         */
        
        
    }
    
    class func concatMap(){
        /*
         将 Observable 的元素转换成其他的 Observable，然后将这些 Observables 串连起来
         
         concatMap 操作符将源 Observable 的每一个元素应用一个转换方法，将他们转换成 Observables。然后让这些 Observables 按顺序的发出元素，当前一个 Observable 元素发送完毕后，后一个 Observable 才可以开始发出元素。等待前一个 Observable 产生完成事件后，才对后一个 Observable 进行订阅。
         */
        
        let a = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).take(3)
        
        let b = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).take(4)
        
        _ = a.concatMap { (item) -> Observable<Int> in
            print("\(Date()) concatMap \(item)")
            return b
        }
        .subscribe { (event) in
            print("\(Date()) event \(event)")
        }
        
        /*
         concatMap 0
         
         concatMap 1
         event 0
         
         concatMap 2
         event 1   // 接下来按顺序执行序列  [0123 0123 0123]
         event 2
         event 3
         
         event 0
         event 1
         event 2
         event 3
         
         event 0
         event 1
         event 2
         event 3
         */
        
    }
    
    class func connect(){
        /*
         通知 ConnectableObservable 可以开始发出元素了
         
         ConnectableObservable 和普通的 Observable 十分相似，不过在被订阅后不会发出元素，直到 connect 操作符被应用为止。这样一来你可以等所有观察者全部订阅完成后，才发出元素。
         
         一旦序列 connect, 后来的订阅者将从下一次发送开始接收，
         之前的发送不会发送到新的订阅者
         */
        let intSequence = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .publish()

        _ = intSequence
            .subscribe(onNext: { print("Subscription 1:, Event: \($0)") })

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            _ = intSequence.connect()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
          _ = intSequence
              .subscribe(onNext: { print("Subscription 2:, Event: \($0)") })
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
          _ = intSequence
              .subscribe(onNext: { print("Subscription 3:, Event: \($0)") })
        }
    }
    
    class func create(){
        /*
         通过一个构建函数完整的创建一个 Observable
         
         create 操作符将创建一个 Observable，你需要提供一个构建函数，在构建函数里面描述事件（next，error，completed）的产生过程。

         通常情况下一个有限的序列，只会调用一次观察者的 onCompleted 或者 onError 方法。并且在调用它们后，不会再去调用观察者的其他方法。
         */
        
        let a = Observable<Int>.create { (observer) -> Disposable in
            DispatchQueue.global(qos: .default).async {
                for i in 0 ..< 5 {
                    sleep(1)
                    DispatchQueue.main.sync {
                        observer.onNext(i)
                    }
                }
                DispatchQueue.main.sync {
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
        
        _ =  a.subscribe { print($0) }
    }
    class func debounce() {
        /*
         过滤掉高频产生的元素
         */
        
        let a = Observable<Int>.create { (observer) -> Disposable in
            DispatchQueue.global(qos: .default).async {
                for i in 0 ..< 5 {
                    sleep(1)
                    DispatchQueue.main.sync {
                        if i == 2 {
                            //模拟高频发送元素
                            observer.onNext(100)
                            observer.onNext(101)
                            observer.onNext(102)
                            observer.onNext(103)
                        }
                        else{
                            observer.onNext(i)
                        }
                    }
                    
                }
                DispatchQueue.main.sync {
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
        
        _  = a.debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe { print($0) }
        
        /*
         0
         1
         103
         3
         4
         completed
         */
    }
    
    class func deferred() {
        /*
         直到订阅发生，才创建 Observable，并且为每位订阅者创建全新的 Observable
         */
        
        let a = Observable.deferred { () -> Observable<Int> in
            let a = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).take(3).replay(0)
            _ = a.connect()
            return a
        }.asObservable()
        print("created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            _ = a.subscribe{print($0)}
        }
        
        /*
         created
         
         
         next(0)
         next(1)
         next(2)
         completed
         */
        
    }
    
    class func delay(){
        _ = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .delay(.seconds(3), scheduler: MainScheduler.instance)
            .subscribe{ print($0) }
        
        /*
         等待3s + 1s
         0
         1
         2
         */
    }
    
    class func delaySubscription(){
        /*
         进行延时订阅
         */
        print("\(Date()) created")
        let a = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .take(5)
            .replay(0)
        _ = a.connect()
        
        _ = a.delaySubscription(.seconds(3), scheduler: MainScheduler.instance)
            .subscribe{ print("\(Date()) \($0)") }
        
        /*
             0 1 2 都发送完了，才开始订阅
         3
         4
         */
    }
    
    class func dematerialize(){
        
    }
    
    class func distinctUntilChanged(){
        /*
         阻止 Observable 发出相同的元素
         
         distinctUntilChanged 操作符将阻止 Observable 发出相同的元素。
         如果后一个元素和前一个元素是相同的，那么这个元素将不会被发出来。
         如果后一个元素和前一个元素不相同，那么这个元素才会被发出来。
         */
        _ = Observable.of("1", "2", "2", "2", "3", "0", "1")
            .distinctUntilChanged()
            .subscribe(onNext: { print($0) })
        
        /*
         1
         2
         3
         0
         1
         */
    }
    class func `do`(){

    }
    class func elementAt(){
        /*
         只发出 Observable 中的第 n 个元素
         */
        let a = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .take(5)
            .elementAt(3)
        
        _ = a.subscribe{ print($0) }
        
        /*
         
         
         
         3  3前后的元素将不会被发送
         
        */
           
    }
    
    class func filter(){
        /*
         仅仅发出 Observable 中通过判定的元素
         */
        let a = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .take(10)
            .filter { (i) -> Bool in
                return i % 2 == 0
            }
        _ = a.subscribe { print($0) }
        
        /*
         0
           // 奇数不发送
         2
         
         4
         
         6
         
         8
         */
    }
    
    class func flatMap(){
        let a = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .take(2)
        
        let b = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .take(3)
        
        _ = a.flatMap { (item) -> Observable<Int> in
            print("flatMap \(item)")
            return b
        }.subscribe { (event) in
            print(event)
        }
        
        /*
         a 中每发送一个元素，都生成一个 b 序列， 将这些生成的序列 组合成一个新的序列
         例如 上面  [0 1 2 ,
                      0 1 2 ]
         打印
         
         flatMap 0  序列[0 1 2]
         
         flatMap 1  序列[0 1 2 ,
                          0 1 2 ]
         0
         
         1  0
         2  1
            2
         
         */
    }
    
    class func flatMapLatest() {
        /*
         将 Observable 的元素转换成其他的 Observable，然后取这些 Observables 中最新的一个
         flatMapLatest 操作符将源 Observable 的每一个元素应用一个转换方法，将他们转换成 Observables。
         一旦转换出一个新的 Observable，就只发出它的元素，旧的 Observables 的元素将被忽略掉。
         */
        let a = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .take(3)
        
        let b = Observable<Int>
            .interval(.seconds(3), scheduler: MainScheduler.instance)
            .take(3)
        
        _ = Observable<Int>
            .interval(.seconds(3), scheduler: MainScheduler.instance)
            .take(2)
            .flatMapLatest { (item) -> Observable<Int> in
            if item == 0 {
                return a
            }
            return b
        }.subscribe{ print($0) }
        
        
        /*
         0
         1
         0   最新序列为b, a已经是老的序列，就不再发送了
         1
         2
         */
        
    }
    
    class func test(){
        flatMapLatest()
    }
}
