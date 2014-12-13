
//  MutilImage
//
//  Created by dong on 14/12/1.
//  Copyright (c) 2014年 dong. All rights reserved.
//

#import "ViewController.h"

#import "UIImageView+MutilImage.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
   NSArray* imageArray =  @[@"http://h.hiphotos.baidu.com/image/w%3D310/sign=5c9f683b58afa40f3cc6c8dc9b65038c/060828381f30e92497f643384e086e061d95f76d.jpg",@"http://c.hiphotos.baidu.com/image/w%3D310/sign=2bcc3cdeab014c08193b2ea43a7a025b/bf096b63f6246b60cedb0303e9f81a4c500fa2f4.jpg",@"http://c.hiphotos.baidu.com/image/w%3D310/sign=2bcc3cdeab014c08193b2ea43a7a025b/bf096b63f6246b60cedb0303e9f81a4c500fa2f4.jpg",@"http://c.hiphotos.baidu.com/image/w%3D310/sign=2bcc3cdeab014c08193b2ea43a7a025b/bf096b63f6246b60cedb0303e9f81a4c500fa2f4.jpg",@"http://c.hiphotos.baidu.com/image/w%3D310/sign=2bcc3cdeab014c08193b2ea43a7a025b/bf096b63f6246b60cedb0303e9f81a4c500fa2f4.jpg",@"http://c.hiphotos.baidu.com/image/w%3D310/sign=2bcc3cdeab014c08193b2ea43a7a025b/bf096b63f6246b60cedb0303e9f81a4c500fa2f4.jpg",@"http://c.hiphotos.baidu.com/image/w%3D310/sign=2bcc3cdeab014c08193b2ea43a7a025b/bf096b63f6246b60cedb0303e9f81a4c500fa2f4.jpg",@"",@"",@"",@""];
    
    UIImageView* mutilImageView =[[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    UIImage* image = [UIImage imageNamed:@"guoguo"];
    [mutilImageView setImageGroup:imageArray placeholderImage:[UIImage imageNamed:@"guoguo"] complete:^(UIImage *image) {
        
    }];
    [self.view addSubview:mutilImageView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
