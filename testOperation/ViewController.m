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

@property (strong, nonatomic) dispatch_group_t group;
@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) dispatch_semaphore_t sema;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];


}

- (IBAction)clickAction:(id)sender {
    [self asynchronizeWithoutBlockTest];
}





#pragma mark - dispatch_barrier
/**
 * dispatch_barrier
 */
- (void)dispatchBarrierTest {
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        dispatch_barrier_async(queue, ^{
            NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
            [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"--------------------------success-----------------");
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"--------------------------fail-----------------");
                
            }];
        });
        
        NSLog(@"--------------------------barrier complete-----------------");
        
    });
}


#pragma mark - dispatch_group
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

#pragma mark - NSOperationQueue
- (void)operationQueue {
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    queue.maxConcurrentOperationCount = 1;
    NSBlockOperation *block1 = [NSBlockOperation blockOperationWithBlock:^{
        [self afnRequestWithTag:1];
    }];
    NSBlockOperation *block2 = [NSBlockOperation blockOperationWithBlock:^{
        [self afnRequestWithTag:2];
    }];
    NSBlockOperation *block3 = [NSBlockOperation blockOperationWithBlock:^{
        [self afnRequestWithTag:3];
    }];
    NSBlockOperation *block4 = [NSBlockOperation blockOperationWithBlock:^{
        [self afnRequestWithTag:4];
    }];
    
//    [queue addOperations:@[block1,block2,block3,block4] waitUntilFinished:YES];
    [queue addOperation:block1];
    [queue addOperation:block2];
    [queue addOperation:block3];
    [queue addOperation:block4];
    NSLog(@"--------------------------complete-----------------");
}


- (void)afnRequestWithTag:(NSUInteger)tag {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
        [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"%@",[NSString stringWithFormat:@"--------------------------success%zd-----------------",tag]);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"%@",[NSString stringWithFormat:@"--------------------------fail%zd-----------------",tag]);
        }];
    });
}

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
- (void)dispatchSemaphoreTest {
    self.sema = dispatch_semaphore_create(2);
    self.queue = dispatch_queue_create(0, 0);

    NSLog(@"--------------------------dispatch begin-----------------");
    dispatch_async(self.queue, ^{
        dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
            [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"--------------------------success1-----------------");
                dispatch_semaphore_signal(self.sema);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"--------------------------fail1-----------------");
                dispatch_semaphore_signal(self.sema);
            }];
            
        });
        
        NSLog(@"--------------------------dispatch async complete1-----------------");
    });
    
    dispatch_async(self.queue, ^{
        dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
            [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {

            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"--------------------------success2-----------------");
                dispatch_semaphore_signal(self.sema);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"--------------------------fail2-----------------");
                dispatch_semaphore_signal(self.sema);
            }];
        });
        NSLog(@"--------------------------dispatch async complete2-----------------");
    });
    
    dispatch_async(self.queue, ^{
        dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
        NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
        [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {

        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"--------------------------success3-----------------");
            dispatch_semaphore_signal(self.sema);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"--------------------------fail3-----------------");
            dispatch_semaphore_signal(self.sema);
        }];
        NSLog(@"--------------------------dispatch async complete3-----------------");
    });
    
    NSLog(@"--------------------------dispatch complete-----------------");
}

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


@end
