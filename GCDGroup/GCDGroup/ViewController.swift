//
//  ViewController.swift
//  GCDGroup
//
//  Created by iOS on 2018/10/28.
//  Copyright © 2018年 weiman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var myQueue: DispatchQueue?
    var myQueueTimer: DispatchQueue?
    var myTimer: DispatchSourceTimer?
    var myGroup: DispatchGroup?
    var mySource: DispatchSource?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //loadData()
        //testGCD()
        loadDataSemaphore2()
    }
}

extension ViewController {
    
    //场景
    /*
     在开发过程中很常见的一个场景是一个页面需要调用两个异步的网络请求，需要等两个请求都返回以后再组合数据并刷新UI.
     解决思路：
     
     dispatch_semaphore_t ：通俗的说我们可以理解成他是一个红绿灯的信号，当它的信号量小于0时(红灯)等待，当信号量为1或大于1时(绿灯)走。
     1. 创建一个默认值为0的信号量，在调用网络请求的异步方法后就之行wait()，因此这个方法会一直等待， 在网络请求的block返回时之行signal()，这时才代表这个方法结束阻塞，可以继续执行了。
     2. 两个网络请求方法都用同样的方式操作信号量，因此只有两个请求都返回结果后方法才会继续执行。
     3. 再用原来的group.notify触发后续执行。
     */
    
    //GCD 信号量控制并发 （dispatch_semaphore）
    /*
     下面我们逐一介绍三个函数：
     
     （1）dispatch_semaphore_create的声明为：
     　　　　dispatch_semaphore_t dispatch_semaphore_create(long value);
     　　　　传入的参数为long，输出一个dispatch_semaphore_t类型且值为value的信号量。值得注意的是，这里的传入的参数value必须大于或等于0，否则dispatch_semaphore_create会返回NULL。
     
     （2）dispatch_semaphore_signal的声明为：
     　　　　long dispatch_semaphore_signal(dispatch_semaphore_t dsema)这个函数会使传入的信号量dsema的值加1；（至于返回值，待会儿再讲）
     (3) dispatch_semaphore_wait的声明为：
     　　　　long dispatch_semaphore_wait(dispatch_semaphore_t dsema, dispatch_time_t timeout)；
     这个函数会使传入的信号量dsema的值减1。这个函数的作用是这样的，如果dsema信号量的值大于0，该函数所处线程就继续执行下面的语句，并且将信号量的值减1；如果desema的值为0，那么这个函数就阻塞当前线程等待timeout（注意timeout的类型为dispatch_time_t，不能直接传入整形或float型数），如果等待的期间desema的值被dispatch_semaphore_signal函数加1了，且该函数（即dispatch_semaphore_wait）所处线程获得了信号量，那么就继续向下执行并将信号量减1。如果等待期间没有获取到信号量或者信号量的值一直为0，那么等到timeout时，其所处线程自动执行其后语句。
     （4）dispatch_semaphore_signal的返回值为long类型，当返回值为0时表示当前并没有线程等待其处理的信号量，其处理的信号量的值加1即可。当返回值不为0时，表示其当前有（一个或多个）线程等待其处理的信号量，并且该函数唤醒了一个等待的线程（当线程有优先级时，唤醒优先级最高的线程；否则随机唤醒）。
     　　　　dispatch_semaphore_wait的返回值也为long型。当其返回0时表示在timeout之前，该函数所处的线程被成功唤醒。当其返回不为0时，表示timeout发生。
     （5）关于信号量，一般可以用停车来比喻。
     　　　　停车场剩余4个车位，那么即使同时来了四辆车也能停的下。如果此时来了五辆车，那么就有一辆需要等待。信号量的值就相当于剩余车位的数目，dispatch_semaphore_wait函数就相当于来了一辆车，dispatch_semaphore_signal就相当于走了一辆车。停车位的剩余数目在初始化的时候就已经指明了（dispatch_semaphore_create（long value）），调用一次dispatch_semaphore_signal，剩余的车位就增加一个；调用一次dispatch_semaphore_wait剩余车位就减少一个；当剩余车位为0时，再来车（即调用dispatch_semaphore_wait）就只能等待。有可能同时有几辆车等待一个停车位。有些车主没有耐心，给自己设定了一段等待时间，这段时间内等不到停车位就走了，如果等到了就开进去停车。而有些车主就像把车停在这，所以就一直等下去。

     */
    func loadDataSemaphore() {
        
        let mySemaphore  = DispatchSemaphore(value: 3)
        for i in 0...10 {
            print("i = \(i)")
            
            let _ = mySemaphore.wait(timeout: DispatchTime.now() + 2.0)
            myQueue = DispatchQueue.init(label: "一条线程")
            myQueue?.async {
                
                for j in 0...4 {
                    print("有限资源 \(j)")
                    sleep(UInt32(3.0))
                }
                
                print("哈啊哈哈哈哈哈哈")
                mySemaphore.signal()
            }
            
        }
    }
    
    func loadDataSemaphore2() {
        
        // 任务队列
        let queue = DispatchQueue(label: "requestHandler")
        // 分组
        let group = DispatchGroup()
        
        
        // 第一个网络请求
        queue.async(group: group) {
            
            let mySemaphore = DispatchSemaphore(value: 0)
            
            Api.request.request(ApiService.firstRequest, callbackQueue: DispatchQueue.main, progress: { (progressR) in
                print("--first----progress----- \(progressR.progress)")
                print("---first---progress.response----\(progressR.response)")
            }) { (result) in
                
                print("--first---result------ \(result)")
                switch result {
                    
                case .success(_):
                    print("first请求成功")
                case .failure(_):
                    print("first请求失败")
                }
                
                mySemaphore.signal()
            }
            mySemaphore.wait()
        }
        
        // 第二个网络请求
        queue.async(group: group) {
            
            let sema = DispatchSemaphore(value: 0)
            Api.request.request(ApiService.secondRequest, callbackQueue: DispatchQueue.main, progress: { (progressR) in
                
                print("--second----progress----- \(progressR.progress)")
                print("---second---progress.response----\(progressR.response)")
                
            }) { (result) in
                
                print("--second---result------ \(result)")
                switch result {
                    
                case .success(_):
                    print("second请求成功")
                case .failure(_):
                    print("second请求失败")
                }
                
                sema.signal()
            }
            
            sema.wait()
        }
        
        
        // 全部调用完成后回到主线程，刷新UI
        group.notify(queue: DispatchQueue.main) {
            
            print("哈哈哈哈哈，请求都回来了，刷新UI吧")
        }
        
    }
}

extension ViewController {
    
    /// 异步并行队列
    func testGCD2() {
        
        print("开始了")
        myQueue = DispatchQueue.global()
        
        myQueue?.async {
            for i in 0...10 {
                print("---1--- i = \(i)")
            }
        }
        
        myQueue?.async {
            for i in 0...20 {
                print("---2--- i = \(i)")
            }
        }
        
        myQueue?.async(group: nil, qos: .default, flags: .barrier, execute: {
            print("执行上面两个在执行这一个")
        })
        
        myQueue?.async {
            print("哈哈哈哈哈哈哈啊哈")
        }
        
        print("结束了")
        
    }
}

extension ViewController {
    
    /// 异步串行队列
    func testGCD() {
        
        print("开始了")
        myQueue = DispatchQueue.init(label: "一条线程")
        
        myQueue?.async {
            for i in 0...10 {
                print("---1--- i = \(i)")
            }
        }
        
        myQueue?.async {
            for i in 0...20 {
                print("---2--- i = \(i)")
            }
        }
        
        myQueue?.async(group: nil, qos: .default, flags: .barrier, execute: {
            print("执行上面两个在执行这一个")
        })
        
        myQueue?.async {
            print("哈哈哈哈哈哈哈啊哈")
        }
        
        print("结束了")
        
    }
    
}

extension ViewController {
    
    /// group
    private func loadData() {
        
        let group = DispatchGroup()
        
        group.enter()
        Api.request.request(ApiService.firstRequest, callbackQueue: DispatchQueue.main, progress: { (progressR) in
            print("--first----progress----- \(progressR.progress)")
            print("---first---progress.response----\(progressR.response)")
        }) { (result) in
            
            print("--first---result------ \(result)")
            switch result {
                
            case .success(_):
                print("first请求成功")
            case .failure(_):
                print("first请求失败")
            }
            
            group.leave()
        }
        
        group.enter()
        Api.request.request(ApiService.secondRequest, callbackQueue: DispatchQueue.main, progress: { (progressR) in
            
            print("--second----progress----- \(progressR.progress)")
            print("---second---progress.response----\(progressR.response)")
            
        }) { (result) in
            
            print("--second---result------ \(result)")
            switch result {
                
            case .success(_):
                print("second请求成功")
            case .failure(_):
                print("second请求失败")
            }
            
            group.leave()
        }
        
        group.enter()
        Api.request.request(ApiService.thirdRequest, callbackQueue: DispatchQueue.main, progress: { (progressR) in
            
            print("--third----progress----- \(progressR.progress)")
            print("---third---progress.response----\(progressR.response)")
            
        }) { (result) in
            
            print("--third---result------ \(result)")
            switch result {
                
            case .success(_):
                print("third请求成功")
            case .failure(_):
                print("third请求失败")
            }
            
            group.leave()
        }
        
        group.notify(queue: .main) {
            
            print("全部请求完成了，开始更新UI了")
            
        }
        
    }
}

