//
//  ViewController.m
//  testOperation
//
//  Created by Noah on 2018/10/31.
//  Copyright © 2018 Noah. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking.h>

@interface ViewController ()

//@property (strong, nonatomic) dispatch_group_t group;
//@property (strong, nonatomic) dispatch_queue_t queue;
//@property (strong, nonatomic) dispatch_semaphore_t sema;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];


}

- (IBAction)clickAction:(id)sender {
    [self dispatchBarrierTest];
}





#pragma mark - dispatch_barrier
/**
 * dispatch_barrier,只在并发队列中才有用，而且不能是获取的系统的全局队列，得是通过dispatch_queue_create自己创建的并发队列才可以
 */
- (void)dispatchBarrierFunction {
    dispatch_queue_t queue = dispatch_queue_create("com.fxxxxxx.www", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSLog(@"task1 -%@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"task2 -%@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"task3 -%@",[NSThread currentThread]);
    });
    
    dispatch_barrier_async(queue, ^{
        [NSThread sleepForTimeInterval:5];
        NSLog(@"barrier");
    });
    NSLog(@"asynchronous");
    
    dispatch_async(queue, ^{
        NSLog(@"task4 -%@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"task5 -%@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"task6 -%@",[NSThread currentThread]);
    });
}

/**
 * dispatch_barrier,只在并发队列中才有用，而且不能是获取的系统的全局队列，得是通过dispatch_queue_create自己创建的并发队列才可以
 * 可以看到，带有网络请求异步回调的情况，并不适用，可以使用dispatch_group_enter/dispatch_group_leave或者dispatch_semaphore_wait来实现
 */
- (void)dispatchBarrierTest {
    dispatch_queue_t queue = dispatch_queue_create("com.fxxxxxx.wwww", DISPATCH_QUEUE_CONCURRENT);

    dispatch_async(queue, ^{
        [self afnRequestWithTag:1 delay:2 complete:^{
            
        }];
    });
    
    dispatch_async(queue, ^{
        [self afnRequestWithTag:2 delay:2 complete:^{
            
        }];
    });
    
    dispatch_async(queue, ^{
        [self afnRequestWithTag:3 delay:2 complete:^{
            
        }];
    });
    
    dispatch_barrier_async(queue, ^{
        NSLog(@"barrier");
    });
    
    dispatch_async(queue, ^{
        [self afnRequestWithTag:4 delay:2 complete:^{
            
        }];
    });
    
    dispatch_async(queue, ^{
        [self afnRequestWithTag:5 delay:2 complete:^{
            
        }];
    });
    
    NSLog(@"--------------------------barrier complete-----------------");
}


#pragma mark - dispatch_group
/**
 * dispatch_group_async+dispatch_group_notify方法的结合
 * 异步处理中没有带有延时操作的block之类的，此时可以正常处理
 * 若异步处理中有包含block的延时处理（例如AFN网络请求），此时改写法无法保证正确性
 * 届时要结合dispatch_group_enter()、dispatch_group_leave()方法才能达到效果
 */
- (void)asynchronizeWithoutBlockTest {
    dispatch_queue_t queue = dispatch_queue_create("com.fxxxx.www", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, queue, ^{
        NSLog(@"1111111111111111111");
    });
    
    dispatch_group_async(group, queue, ^{
        NSLog(@"2222222222222222222");
    });
    
    dispatch_group_async(group, queue, ^{
        NSLog(@"3333333333333333333");
    });
    
    dispatch_group_notify(group, queue, ^{
        NSLog(@"complete");
    });
}

/**
 * 多个异步操作，在全部完成之后统一做一步事件
 */
- (void)dispatchGroupTest {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("com.fxeyeQueue.www", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_group_async(group, queue, ^{
        
        NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
        dispatch_group_enter(group);
        [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"--------------------------success1-----------------");
            dispatch_group_leave(group);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"--------------------------fail1-----------------");
            dispatch_group_leave(group);
        }];
    });
    
    dispatch_group_async(group, queue, ^{
        
        NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
        dispatch_group_enter(group);
        [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"--------------------------success2-----------------");
            dispatch_group_leave(group);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"--------------------------fail2-----------------");
            dispatch_group_leave(group);
        }];
    });
    
    dispatch_group_notify(group, queue, ^{
        NSLog(@"--------------------------notify-----------------");
    });
    
    NSLog(@"--------------------------complete-----------------");
    
}

#pragma mark - NSOperationQueue Test
/**
 * 这里明显结论是不对的。
 */
- (void)operationQueueTest {
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    queue.maxConcurrentOperationCount = 1;  //这里设置最大并发数量（无效）
    NSBlockOperation *block1 = [NSBlockOperation blockOperationWithBlock:^{
        [self afnRequestWithTag:1 delay:3 complete:^{
            
        }];
    }];
    NSBlockOperation *block2 = [NSBlockOperation blockOperationWithBlock:^{
        [self afnRequestWithTag:2 delay:3 complete:^{
            
        }];
    }];
    NSBlockOperation *block3 = [NSBlockOperation blockOperationWithBlock:^{
        [self afnRequestWithTag:3 delay:0 complete:^{
            
        }];
    }];
    NSBlockOperation *block4 = [NSBlockOperation blockOperationWithBlock:^{
        [self afnRequestWithTag:4 delay:0 complete:^{
            
        }];
    }];
    
//    [queue addOperations:@[block1,block2,block3,block4] waitUntilFinished:YES];
    [queue addOperation:block1];
    [queue addOperation:block2];
    [queue addOperation:block3];
    [queue addOperation:block4];
    [block4 addDependency:block3];  //这里添加依赖（无效）
    [block3 addDependency:block2];
    [block2 addDependency:block1];
    NSLog(@"--------------------------complete-----------------");
}

#pragma mark - Semaphore Usage
/**
 * 异步操作使用dispatch_semaphore改为同步操作
 */
- (void)testDispatchSemaphore {
    NSLog(@"--------------------------begin-----------------");
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_queue_t que = dispatch_get_global_queue(0, 0);
    
    dispatch_async(que, ^{
        
        NSLog(@"--------------------------async begin1-----------------");
        [NSThread sleepForTimeInterval:3];
        NSLog(@"--------------------------async complete1-----------------");
        dispatch_semaphore_signal(sema);
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    NSLog(@"--------------------------complete-----------------");
    
}

- (void)dispatchSemaphoreZero {
    //Passing zero for the value is useful for when two threads need to reconcile the completion of a particular event. Passing a value greater than zero is useful for managing a finite pool of resources, where the pool size is equal to the value. 苹果官方文档中这么写
    NSLog(@"begin");
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    
    dispatch_async(queue, ^{
        long count = dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSLog(@"1:%ld",count);
        [self afnRequestWithTag:1 delay:4 complete:^{
            dispatch_semaphore_signal(sema);
        }];
    });
    
    dispatch_async(queue, ^{
        long count = dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSLog(@"2:%ld",count);
        [self afnRequestWithTag:2 delay:3 complete:^{
            dispatch_semaphore_signal(sema);
        }];
    });
    
    dispatch_async(queue, ^{
        long count = dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSLog(@"3:%ld",count);
        [self afnRequestWithTag:3 delay:3 complete:^{
            dispatch_semaphore_signal(sema);
        }];
    });
    
    dispatch_async(queue, ^{
        long count = dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSLog(@"4:%ld",count);
        [self afnRequestWithTag:4 delay:2 complete:^{
            dispatch_semaphore_signal(sema);
        }];
    });
    NSLog(@"end");
    
}

/**
 * semaphore设置非0测试，（此处写法与下面dispatchSemaphoreTestWithCrash方法一致，但是并没有引发崩溃）
 */
- (void)dispatchSemaphoreNonZeroTest {
    NSLog(@"begin");
    dispatch_semaphore_t sema = dispatch_semaphore_create(2);
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    
    dispatch_async(queue, ^{
        long count = dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSLog(@"1:%ld",count);
        [self afnRequestWithTag:1 delay:4 complete:^{
            dispatch_semaphore_signal(sema);
        }];
    });
    
    dispatch_async(queue, ^{
        long count = dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSLog(@"2:%ld",count);
        [self afnRequestWithTag:2 delay:3 complete:^{
            dispatch_semaphore_signal(sema);
        }];
    });
    
    dispatch_async(queue, ^{
        long count = dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSLog(@"3:%ld",count);
        [self afnRequestWithTag:3 delay:3 complete:^{
            dispatch_semaphore_signal(sema);
        }];
    });
    
    dispatch_async(queue, ^{
        long count = dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSLog(@"4:%ld",count);
        [self afnRequestWithTag:4 delay:2 complete:^{
            dispatch_semaphore_signal(sema);
        }];
    });
    NSLog(@"end");
}

/**
 * 多个异步操作，限制最大并行两个线程(dispatch_async中不包含AFN等携带有block方法)
 */
- (void)dispatchSignalTest {
    NSLog(@"--------------------------begin-----------------");
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(2);
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(quene, ^{
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        NSLog(@"--------------------------async begin1-----------------");
        [NSThread sleepForTimeInterval:3];
        NSLog(@"--------------------------async complete1-----------------");
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_async(quene, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"--------------------------async begin2-----------------");
        [NSThread sleepForTimeInterval:3];
        NSLog(@"--------------------------async complete2-----------------");
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_async(quene, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"--------------------------async begin4-----------------");
        [NSThread sleepForTimeInterval:2];
        NSLog(@"--------------------------async complete4-----------------");
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_async(quene, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"--------------------------async begin3-----------------");
        [NSThread sleepForTimeInterval:3];
        NSLog(@"--------------------------async complete3-----------------");
        dispatch_semaphore_signal(semaphore);
    });
    
    NSLog(@"--------------------------complete-----------------");
}

/**
 * 常规dispatch_semaphore使用方法（多个网络请求，限制最大并发数量）
 */
//- (void)dispatchSemaphoreTest {
//    self.sema = dispatch_semaphore_create(2);
//    self.queue = dispatch_queue_create(0, 0);
//
//    NSLog(@"--------------------------dispatch begin-----------------");
//    dispatch_async(self.queue, ^{
//        dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
//
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
//            [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
//
//            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//                NSLog(@"--------------------------success1-----------------");
//                dispatch_semaphore_signal(self.sema);
//            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//                NSLog(@"--------------------------fail1-----------------");
//                dispatch_semaphore_signal(self.sema);
//            }];
//
//        });
//
//        NSLog(@"--------------------------dispatch async complete1-----------------");
//    });
//
//    dispatch_async(self.queue, ^{
//        dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
//            [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
//
//            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//                NSLog(@"--------------------------success2-----------------");
//                dispatch_semaphore_signal(self.sema);
//            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//                NSLog(@"--------------------------fail2-----------------");
//                dispatch_semaphore_signal(self.sema);
//            }];
//        });
//        NSLog(@"--------------------------dispatch async complete2-----------------");
//    });
//
//    dispatch_async(self.queue, ^{
//        dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
//        NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
//        [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
//
//        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//            NSLog(@"--------------------------success3-----------------");
//            dispatch_semaphore_signal(self.sema);
//        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//            NSLog(@"--------------------------fail3-----------------");
//            dispatch_semaphore_signal(self.sema);
//        }];
//        NSLog(@"--------------------------dispatch async complete3-----------------");
//    });
//
//    NSLog(@"--------------------------dispatch complete-----------------");
//}

/**
 * 常规dispatch_semaphore使用方法（多个网络请求，限制最大并发数量）
 * 此方法会引发崩溃，因为在程序执行的过程中，dispatch_semaphore_t对象已经被释放了
 */
- (void)dispatchSemaphoreTestWithCrash {
    dispatch_queue_t queue = dispatch_queue_create(0, 0);
    dispatch_semaphore_t sema = dispatch_semaphore_create(2);
    
    NSLog(@"--------------------------dispatch begin-----------------");
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
            [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"--------------------------success1-----------------");
                dispatch_semaphore_signal(sema);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"--------------------------fail1-----------------");
                dispatch_semaphore_signal(sema);
            }];
            
        });
        
        NSLog(@"--------------------------dispatch async complete1-----------------");
    });
    
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
            [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"--------------------------success2-----------------");
                dispatch_semaphore_signal(sema);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"--------------------------fail2-----------------");
                dispatch_semaphore_signal(sema);
            }];
        });
        NSLog(@"--------------------------dispatch async complete2-----------------");
    });
    
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
        [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"--------------------------success3-----------------");
            dispatch_semaphore_signal(sema);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"--------------------------fail3-----------------");
            dispatch_semaphore_signal(sema);
        }];
        NSLog(@"--------------------------dispatch async complete3-----------------");
    });
    
    NSLog(@"--------------------------dispatch complete-----------------");
}


#pragma mark - 用来测试的网络请求
/**
 * 用来测试的网络请求
 */
- (void)afnRequestWithTag:(NSUInteger)tag delay:(int)delay complete:(void(^)(void))handler {
    //[NSThread sleepForTimeInterval:delay];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
        [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"%@",[NSString stringWithFormat:@"--------------------------success%zd-----------------",tag]);
            handler();
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"%@",[NSString stringWithFormat:@"--------------------------fail%zd-----------------",tag]);
            handler();
        }];
    });
}



@end
