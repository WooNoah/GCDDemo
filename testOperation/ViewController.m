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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];


}

- (IBAction)clickAction:(id)sender {
//    NSLog(@"--------------------------begin-----------------");
    [self testDispatchSemaphore];

//    NSLog(@"--------------------------complete-----------------");
   
}

- (void)dispatchSignalTest {
    NSLog(@"--------------------------begin-----------------");
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(quene, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"--------------------------async begin1-----------------");
        [NSThread sleepForTimeInterval:3];
        dispatch_semaphore_signal(semaphore);
        NSLog(@"--------------------------async complete1-----------------");
    });
    
    dispatch_async(quene, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"--------------------------async begin2-----------------");
        [NSThread sleepForTimeInterval:3];
        dispatch_semaphore_signal(semaphore);
        NSLog(@"--------------------------async complete2-----------------");
    });
    
    NSLog(@"--------------------------complete-----------------");
}

- (void)testDispatchSemaphore {
    NSLog(@"--------------------------begin-----------------");
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_queue_t que = dispatch_get_global_queue(0, 0);
    
    dispatch_async(que, ^{
        
        NSLog(@"--------------------------async begin1-----------------");
        [NSThread sleepForTimeInterval:3];
        dispatch_semaphore_signal(sema);
        NSLog(@"--------------------------async complete1-----------------");
    });
    
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    NSLog(@"--------------------------complete-----------------");
    
}

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


- (void)dispatchGroupTest {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("com.fxeyeQueue.www", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_group_enter(group);
    dispatch_group_enter(group);
    dispatch_group_async(group, queue, ^{
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            
            NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
            [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"--------------------------success1-----------------");
                dispatch_group_leave(group);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"--------------------------fail1-----------------");
                dispatch_group_leave(group);
            }];
            
            [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"--------------------------success2-----------------");
                dispatch_group_leave(group);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"--------------------------fail2-----------------");
                dispatch_group_leave(group);
            }];
        });
        
    });
    
    dispatch_group_notify(group, queue, ^{
        NSLog(@"--------------------------notify-----------------");
    });
    
    NSLog(@"--------------------------complete-----------------");
    
}

- (void)dispatchSemaphoreTest {
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    NSLog(@"--------------------------dispatch begin-----------------");
    dispatch_async(queue, ^{
        NSString *imgUrl = @"https://www.baidu.com/img/bd_logo1.png";
        [[AFHTTPSessionManager manager] GET:imgUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"--------------------------success-----------------");
            dispatch_semaphore_signal(sema);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"--------------------------fail-----------------");
            dispatch_semaphore_signal(sema);
        }];
        
        
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSLog(@"--------------------------dispatch complete-----------------");
    });
    
    NSLog(@"--------------------------dispatch async complete-----------------");
}


@end
