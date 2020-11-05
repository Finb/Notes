//
//  RxSwiftOperator.swift
//  Notes
//
//  Created by huangfeng on 2020/11/4.
//

import UIKit
import RxSwift

extension RxSwiftOperator {
    class func currentQueueName() -> String {
        let label = __dispatch_queue_get_label(.none)
        return String(cString: label)
    }
}

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
    
    class func from(){
        let a = Observable.from([1,2,3])
        _ = a.subscribe { print($0) }
    }
    
    class func groupBy(){
        let a = Observable.from([1,2,3,4,5,6])
        _ = a.groupBy { (item)  in
            return item % 2
        }
        .subscribe { (event) in
            print("groupBy: \( event )")
            switch event {
            case let  .next(group):
                _ = group.subscribe { (event) in
                    print("event: \( event )")
                }
            default: print(event)
            }
        }
        
        /*
         groupBy 1
         1
         groupBy 0
         2
         3 4
         4 6
         
         */
        
    }
    
    class func ignoreElements(){
        /*
         忽略掉所有的元素，只发出 error 或 completed 事件
         */
        let a = Observable.from([1,2,3,4,5,6])
        _ = a.ignoreElements().subscribe { (event) in
            print(event)
        }
        
        /*
         completed
         */
    }
    
    class func interval(){
        /*
         创建一个 Observable 每隔一段时间，发出一个索引数
         */
        let a = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
        _ = a.subscribe { (event) in
            print(event)
        }
        /*
         1
         2
         3
         ...
         */
    }
    
    class func just(){
        /*
         创建 Observable 发出唯一的一个元素
         */
        let a  = Observable.just(0)
        _ = a.subscribe { (event) in
            print(event)
        }
        /*
         0
         completed
         */
    }
    
    class func map(){
        /*
         通过一个转换函数，将 Observable 的每个元素转换一遍
         map 操作符将源 Observable 的每个元素应用你提供的转换方法，然后返回含有转换结果的 Observable。
         */
        
        _ = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .map { (item) in
                return item * 100
            }
            .subscribe { (event) in
                print(event)
            }
        /*
         0
         100
         200
         300
         ...
         */
        
    }
    
    class func merge(){
        /*
         将多个 Observables 合并成一个
         通过使用 merge 操作符你可以将多个 Observables 合并成一个，当某一个 Observable 发出一个元素时，他就将这个元素发出。
         
         如果，某一个 Observable 发出一个 onError 事件，那么被合并的 Observable 也会将它发出，并且立即终止序列。
         */
        let a = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
        let b = Observable<Int>.interval(.seconds(2), scheduler: MainScheduler.instance)
        
        _ = Observable.merge([a,b]).subscribe { (event) in
            print(event)
        }
        
        /*
         0
         
         1 0
         
         2
         
         3 1
         
         ...
         */
    }
    
    class func materialize(){
        /*
         将序列产生的事件，转换成元素
         */
        _ = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .take(2)
            .materialize()
            .subscribe(onNext: {(e) in
                print(e)
            })
        
        /*
         next(0)
         next(1)
         completed
         */
    }
    
    class func never(){
        _ = Observable<Int>.never()
            .subscribe { (event) in
                //永远不会执行，不会发送事件
                print(event)
            }
    }
    
    class func observeOn(){
        let a = Observable<Int>.create { (observer) -> Disposable in
            
            for i in 0 ..< 1 {
                sleep(1)
                print("create at \(currentQueueName() )")
                observer.onNext(i)
            }
            
            return Disposables.create()
        }
        
        _ = a
            .map({ (item) -> Int in
                print("map at \(currentQueueName() )")
                return 100 + item
            })
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            
            .map({ (item) -> Int in
                print("map2 at \(currentQueueName() )")
                return 1000 + item
            })
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            
            .subscribe { (event) in
                print("subscribe at \(currentQueueName() )   \(event)")
            }
        
        /*
         subscribeOn 影响 create 和 map(或其他操作) 和 subscribe
         observeOn 影响 subscribe 和 map(或其他操作)
         
         单独使用时
         subscribeOn，影响 上下 所有的 三种事件
         observeOn 只影响 在他之下的 map 和 subscribe，它上面的 create 和 map 不影响
         
         组合使用时
         observeOn 影响它 下面的 map 和 subscribe，
         subscribeOn 影响 除 observeOn 之外的
         
         
         create at userInitiated
         map at userInitiated
         map2 at background
         subscribe at background
         
         
         */
    }
    
    class func subscribeOn(){
        observeOn()
    }
    
    class func publish(){
        /*
         将 Observable 转换为可被连接的 Observable
         publish 会将 Observable 转换为可被连接的 Observable。可被连接的 Observable 和普通的 Observable 十分相似，不过在被订阅后不会发出元素，直到 connect 操作符被应用为止。这样一来你可以控制 Observable 在什么时候开始发出元素。
         */
        
        let a = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).publish()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            _ = a.connect()
            _ = a.subscribe { (event) in
                print(event)
            }
            /*
             0
             1
             2
             ...
             */
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            _ = a.subscribe { (event) in
                print(event)
                /*
                 1
                 2
                 3
                 4
                 ...
                 */
            }
        }
        
    }
    
    class func reduce(){
        _ = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .take(5)
            .reduce(0, accumulator: { (a, b) -> Int in
                return a + b
            })
            .subscribe({ (event) in
                print(event)
            })
        
        /*
         next(10)
         completed
         */
    }
    
    class func refCount(){
        /*
         将可被连接的 Observable 转换为普通 Observable
         */
        
        // 这是 可被链接 Observable， 需要手动 connect ，订阅者才会收到事件
        let a = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).publish()
        
        //立即不会执行 ，等refCount启动 connect 后一起执行
        _ = a.subscribe { (event) in
            print("event1 \(event)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let dispose = a
                .refCount() // 转换成普通 Observable 自动connect， 发送事件
                .subscribe { (event) in
                    print("event2 \(event)")
                }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                //最后一个 refCount 停止，停止事件发布
                dispose.dispose()
            }
        }
    }
    
    class func repeatElement(){
        /*
         创建 Observable 重复的发出某个元素
         */
        let a = Observable.repeatElement(0)
        _ = a.subscribe { (event) in
            print(event)
        }
        /*
         next(0)
         next(0)
         ...
         */
    }
    
    class func replay(){
        /*
         确保观察者接收到同样的序列，即使是在 Observable 发出元素后才订阅
         
         replay 操作符将 Observable 转换为可被连接的 Observable，并且这个可被连接的 Observable 将缓存最新的 n 个元素。当有新的观察者对它进行订阅时，它就把这些被缓存的元素发送给观察者。
         */
        let a = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .replay(2)  // replay(0) 和 publish 效果一样
        _ = a.connect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            _ = a.subscribe { (event) in
                print(event)
            }
            /*
             2
             3  // 缓存的将快速发出来
             
             4 // 之后正常接收 1秒一个
             5
             ...
             */
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            _ = a.subscribe { (event) in
                print(event)
            }
            /*
             4
             5
             
             6
             7
             ...
             */
        }
        
    }
    
    class func retry(){
        /*
         如果源 Observable 产生一个错误事件，重新对它进行订阅，希望它不会再次产生错误
         
         retry 操作符不会将 error 事件，传递给观察者，然而，它会从新订阅源 Observable，给这个 Observable 一个重试的机会，让它有机会不产生 error 事件。retry 总是对观察者发出 next 事件，即便源序列产生了一个 error 事件，所以这样可能会产生重复的元素（如上图所示）。
         */
        
        let disposeBag = DisposeBag()
        var count = 1
        
        let sequenceThatErrors = Observable<String>.create { observer in
            observer.onNext("🍎")
            observer.onNext("🍐")
            observer.onNext("🍊")
            
            if count == 1 {
                observer.onError(TestError.error)
                print("Error encountered")
                count += 1
            }
            
            observer.onNext("🐶")
            observer.onNext("🐱")
            observer.onNext("🐭")
            observer.onCompleted()
            
            return Disposables.create()
        }
        
        sequenceThatErrors
            .retry()
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
        /*
         🍎
         🍐
         🍊
         Error encountered
         🍎
         🍐
         🍊
         🐶
         🐱
         🐭
         */
    }
    
    class func sample(){
        /*
         不定期的对 Observable 取样
         sample 操作符将不定期的对源 Observable 进行取样操作。通过第二个 Observable 来控制取样时机。一旦第二个 Observable 发出一个元素，就从源 Observable 中取出最后产生的元素。
         */
        
        let a = Observable<Int>.interval(.seconds(3), scheduler: MainScheduler.instance)
        let b = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
        
        
        // b 每产生一个事件，去就A中取最新的事件 发出来
        _ = a.sample(b).subscribe { (event) in
            print(event)
        }
        /*
         每隔3秒
         0
         1
         2
         3
         */
        
    }
    
    class func scan(){
        
        // 和 reduce 很像 ，但 reduce 是 处理所有事件完毕后 再 发出事件
        // scan 是每处理一次，都发一次事件
        let a = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).take(5)
        
        _ = a.scan(1) { (a, b) -> Int in
            return a + b
        }
        .subscribe { (event) in
            print(event)
        }
        
        /*
         next(1)
         next(2)
         next(4)
         next(7)
         next(11)
         completed
         */
    }
    
    
    class func shareReplay(){
        /*
         shareReplay 操作符将使得观察者共享源 Observable，并且缓存最新的 n 个元素，将这些元素直接发送给新的观察者。
         */
        let a = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .map { (item) -> Int in
                return item * 10
            }
            .share(replay: 2, scope: .forever)
        
        _ = a.subscribe { (event) in
            print("event 1 \(event)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            _ = a.subscribe { (event) in
                print("event 2 \(event)")
            }
        }
        
    }
    
    class func single(){
        /*
         single 操作符将限制 Observable 只产生一个元素。如果 Observable 只有一个元素，它将镜像这个 Observable 。如果 Observable 没有元素或者元素数量大于一，它将产生一个 error 事件。
         */
        let a = Single<Int>.create { (observer) -> Disposable in
            observer(.success(1))
            return Disposables.create()
        }
        
        _ = a.subscribe { (event) in
            print(event)
        }
        
    }
    class func skip() {
        /* 跳过 Observable 中头 n 个元素 */
        _ = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .skip(3)
            .take(5)
            .subscribe { (event) in
                print(event)
            }
        
        /*
         3
         4
         5
         6
         7
         */
    }
    
    class func skipUntil() {
        /* 跳过 Observable 中头几个元素，直到另一个 Observable 发出一个元素 */
        let a = Observable<Int>.just(0).publish()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            _ = a.connect()
        }
        
        _ = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .skipUntil(a)
            .take(5)
            .subscribe { (event) in
                print(event)
            }
        
        /*
         3
         4
         5
         6
         7
         */
    }
    
    class func skipWhile(){
        /*
         跳过 Observable 中头几个元素，直到元素的判定为否
         */
        _ = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .skipWhile({ (item) -> Bool in
                return item < 3
            })
            .take(5)
            .subscribe { (event) in
                print(event)
            }
        /*
         3
         4
         5
         6
         7
         */
    }
    
    class func startWith(){
        _ = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .startWith(-3,-2)
            .take(5)
            .subscribe { (event) in
                print(event)
            }
        /*
         -3
         -2
         0
         1
         2
         */
    }
    
    class func take(){
        /*
         仅仅从 Observable 中发出头 n 个元素
         */
        _ = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .take(5)
            .subscribe { (event) in
                print(event)
            }
        /*
         0
         1
         2
         3
         4
         */
    }
    
    class func takeLast(){
        _ = Observable<Int>.from([1,2,3,4,5])
            .takeLast(2)
            .subscribe { (event) in
                print(event)
            }
        /*
         4
         5
         */
    }
    
    class func takeUntil(){
        /*
         忽略掉在第二个 Observable 产生事件后发出的那部分元素
         与 SkipUntil 相反
         */
        let a = Observable<Int>.just(0).publish()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            _ = a.connect()
        }
        
        _ = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .takeUntil(a)
            .subscribe { (event) in
                print(event)
            }
        /*
         0
         1
         2
         */
    }
    
    class func takeWhile(){
        /*
         镜像一个 Observable 直到某个元素的判定为 false
         */
        _ = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .takeWhile({ (item) -> Bool in
                return item < 5
            })
            .subscribe { (event) in
                print(event)
            }
        /*
         0
         1
         2
         3
         4
         */
    }
    
    class func timeout(){
        _ = Observable<Int>.interval(.seconds(2), scheduler: MainScheduler.instance)
            .timeout(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe { (event) in
                print(event)
            }
        /*
         err
         */
    }
    
    class func timer(){
        _ = Observable<Int>.timer(.seconds(3), scheduler: MainScheduler.instance)
            .subscribe { (event) in
                print(event)
                /*
                 0
                 completed
                 */
            }
        
        _ = Observable<Int>.timer(.seconds(3), period: .seconds(1), scheduler: MainScheduler.instance)
            .subscribe { (event) in
                print(event)
                /*
                 // 3秒后
                 0  // 每1秒间隔执行
                 1
                 2
                 3
                 ...
                 */
            }
        
    }
    
    class func using(){
        /*
         创建一个可被清除的资源(即遵守Disposable协议)，它和 Observable 具有相同的寿命
         
         通过使用 using 操作符创建 Observable 时，同时创建一个可被清除的资源，一旦 Observable 终止了，那么这个资源就会被清除掉了(即调用了该资源的dispose()方法)。
         */
        class DisposableResource: Disposable {
            var values: [Int] = []
            var isDisposed: Bool = false
            
            func dispose() {
                self.values = []
                self.isDisposed = true
                print("!!!DisposableResource is Disposed!!!")
            }
            init(with values: [Int]) {
                self.values = values
            }
        }
        
        let observable = Observable<Int>.using({ () -> DisposableResource in
            return DisposableResource.init(with: [1, 2, 3, 4])
        }, observableFactory: { (resource) -> Observable<Int> in
            if resource.isDisposed {
                return Observable<Int>.from([])
            } else {
                return Observable<Int>.from(resource.values)
            }
        })
        
        let d = observable.subscribe { (event) in
            print(event)
        }
        d.dispose()
    }
    
    class func window(){
        let a = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
        
        print("\(Date())")
        _  = a
            .window(timeSpan: .seconds(3), count: 2, scheduler: MainScheduler.instance)
            .subscribe { (event) in
                print("\(Date()) window event \(event)")
                _ = event.element?.subscribe({ (event) in
                    print("\(Date()) element event \(event)")
                })
            }
        
        /*
         window event next(RxSwift.AddRef<Swift.Int>)
         element event next(0)
         element event next(1)
         element event completed
         window event next(RxSwift.AddRef<Swift.Int>)
         element event next(2)
         element event next(3)
         element event completed
         window event next(RxSwift.AddRef<Swift.Int>)
         element event next(4)
         element event next(5)
         element event completed
         */
    }
    
    class func withLatestFrom(){
        /*
         将两个 Observables 最新的元素通过一个函数组合起来，当第一个 Observable 发出一个元素，就将组合后的元素发送出来
         当第一个 Observable 发出一个元素时，就立即取出第二个 Observable 中最新的元素
         */
        
        let a = Observable<Int>.interval(.seconds(2), scheduler: MainScheduler.instance)
        let b = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
        _ = a.withLatestFrom(b) { (valA, valB) -> Int in
            //假如这里 将 a 最新的值抛弃, 只使用 b的值
            return valB
        }
        .subscribe({ (event) in
            print(event)
        })
        
        
        // a 每隔两秒 取出 b 最新的元素
        /*
         1
         3
         5
         7
         */
    }
    
    class func zip(){
        /*
         通过一个函数将多个 Observables 的元素组合起来，然后将每一个组合的结果发出来
         它会严格的按照序列的索引数进行组合。
         */
        let a = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
        let b = Observable<Int>.interval(.seconds(2), scheduler: MainScheduler.instance)
        
        _ = Observable<Int>.zip([a,b]) { (val) -> Int in
            return val.reduce(0, +)
        }.subscribe { (event) in
            print(event)
        }
        
        /*
         0
         1  0
         2
         3  1
         4
         5  2
         ...
         */
        
        /*  每隔两秒执行
         0
         2
         4
         ...
         */
    }
    
    class func test(){
        zip()
    }
}

