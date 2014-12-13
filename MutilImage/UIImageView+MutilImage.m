//
//  UIImage+MutilImage.m
//  MutilImage
//
//  Created by dong on 14/12/1.
//  Copyright (c) 2014年 dong. All rights reserved.
//

#import "UIImageView+MutilImage.h"
#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa.h>
#import <UIImageView+WebCache.h>
#import "objc/runtime.h"
#import <ImageIO/ImageIO.h>
#import "CocoaSecurity.h"


static char operationKey;

static const int  padding = 2;
static const int  leftPadding = 4;
static const int  rightPadding = 4;
static const int  topPadding =  4;
static const int  buttomPadding = 4;

//安全主线程

#define dispatch_main_sync_safe(block)\
if ([NSThread isMainThread]) {\
block();\
}\
else {\
dispatch_sync(dispatch_get_main_queue(), block);\
}

@implementation UIImageView (MutilImage)

-(void)setImageGroup:(NSArray*)array placeholderImage:(UIImage *)placeholder  complete:(DImageLoadCompletedBlock)complete{
    self.image = placeholder;
    
    NSString* lcache = [self cacheKeyForPath:[NSString stringWithFormat:@"%@",array]];
    NSData* lcacheData = [self cacheImageForKey:lcache];
    if (lcacheData) {
        self.image =[UIImage imageWithData:lcacheData];
        return;
    }
    [self cancleLoad];
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    [queue addOperationWithBlock:^{
        @autoreleasepool {
            NSString* cache = [self cacheKeyForPath:[NSString stringWithFormat:@"%@",array]];
            NSData* cacheData = [self cacheImageForKey:cache];
            UIImage* image ;
            if (cacheData) {
                image =[UIImage imageWithData:cacheData];
                if(image){
                    @weakify(self);
                    dispatch_main_sync_safe(^{
                        @strongify(self);
                        self.image = image;
                        if (complete) {
                            complete(image);
                            [self cancleLoad];
                        }
                    });
                }
            }else{
                @weakify(self);
                [[self drawImage:array placeholderImage:placeholder] subscribeNext:^(id x) {
                    [self saveCache:UIImageJPEGRepresentation(x, 1.0) key:cache];
                    dispatch_main_sync_safe(^{
                        @strongify(self);
                        self.image = x;
                        if (complete) {
                            complete(x);
                            [self cancleLoad];
                        }
                    });
                    
                }];
                
            }
            
        }
    }];
    objc_setAssociatedObject(self, &operationKey, queue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}




-(NSString*)cacheKeyForPath:(NSString*)filepath{
    
    NSRange range =   [filepath rangeOfString:@"Documents"];
    if (range.length > 0) {
        filepath = [filepath substringFromIndex:range.location+range.length];
    }
    CocoaSecurityResult *encoder1 = [CocoaSecurity md5:filepath];
    return encoder1.hexLower;
}

-(NSData*)cacheImageForKey:(NSString*)key{
    NSString*filePath =  [self cacheFIlePathForKey:key];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ( [fileManager fileExistsAtPath:filePath]) {
        return [NSData dataWithContentsOfFile:filePath];
    }
    return nil;
}

-(void)saveCache:(NSData*)data key:(NSString*)key{
    NSString*filepath = [self cacheFIlePathForKey:key];
    [data writeToFile:filepath atomically:YES];
}

-(NSString*)cacheFIlePathForKey:(NSString*)key{
    NSArray *paths   = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cache = [paths objectAtIndex:0];
    NSString* filePath= [NSString stringWithFormat:@"%@%@",cache,key];
    return filePath;
}


-(void)dealloc{
    [self cancleLoad];
}

-(void)cancleLoad{
    NSOperationQueue *queue = objc_getAssociatedObject(self, &operationKey);
    if(queue){
        [queue cancelAllOperations];
    }
    objc_setAssociatedObject(self, &operationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}



-(RACSignal*)drawImage:(NSArray*)array placeholderImage:(UIImage*)placeholderImage{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriberValue) {
        NSDictionary* itemLayouts = @{ @(1):@[@(1)],@(2):@[@(2)],@(3):@[@(1),@(2)],@(4):@[@(2),@(2)],@(5):@[@(2),@(3)], @(6):@[@(3),@(3)],@(7):@[@(1),@(3),@(3)],@(8):@[@(2),@(3),@(3)],@(9):@[@(3),@(3),@(3)]};
        int count  = array.count <9 ?array.count:9;
        NSArray* imageLayout = itemLayouts[@(count)];
        CGSize imageItemSize = [self getItemWAH:array layouts:itemLayouts ];
        
        NSMutableArray* task = [NSMutableArray array];
        
        for (int i = 0 ; i< 9 && i < array.count; i++) {
            UIImageView* imageView =[[UIImageView alloc] init];
            NSString*urlString =array[i];
            
            if (![urlString length] > 0) {
                urlString = nil;
            }
            [task addObject:[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                if (urlString) {
                    
                    [imageView sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:placeholderImage completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                        if (image) {
                            [subscriber sendNext:image];
                        }else{
                            [subscriber sendNext:[UIImage imageNamed:@"default_avatar"]];
                        }
                        
                        [subscriber sendCompleted];
                    }];
                }else{
                    [subscriber sendNext:placeholderImage];
                    [subscriber sendCompleted];
                }
                return [RACDisposable disposableWithBlock:^{}];
            }]];
            
            
        }
        //使用信号合成 把图片下载的完成的信号 合成一个信号，等待所有的信号完成之后 才处理一次合成图片
        [[RACSignal combineLatest:task] subscribeNext:^(id x) {
            UIImage* image =  [self drawGroupView:x layout:imageLayout maxCount:count itemSize:imageItemSize];
            [subscriberValue sendNext:image];
            [subscriberValue sendCompleted];
        }];
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }];
}





-(UIImage*)drawGroupView:(NSArray*)images layout:(NSArray*)imageLayout maxCount:(int)count itemSize:(CGSize)size{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 8.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *bgColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1.0];
    CGContextSetStrokeColorWithColor(context, bgColor.CGColor);
    CGContextSetFillColorWithColor(context, bgColor.CGColor);
    CGRect bgRect = self.bounds;
    CGContextAddRect(context, bgRect);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    for (int i = 0 ; i< [images count] ; i++) {
        UIImage* image = images[i];
        if (count ==1) {
            [image drawInRect:CGRectMake(CGRectGetWidth(self.bounds)/4, CGRectGetHeight(self.bounds)/4, CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2)];
        }else{
            [image drawInRect:[self getItemFrame:i layout:imageLayout maxCount:count itemSize:size ] blendMode:kCGBlendModeMultiply alpha:1.0];
        }
    }
    
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return scaledImage;
}



/**
 *  获取每个头像的位置 （PS： 算法不行 有待改善）
 *
 *  @param index         头像的下表
 *  @param imageLayout   头像布局数组
 *  @param count         总头像个数
 *  @param imageItemSize 头像大小
 *
 *  @return 头像的位置
 */
-(CGRect)getItemFrame:(int)index layout:(NSArray*)imageLayout maxCount:(int)count itemSize:(CGSize)imageItemSize{
    CGRect frame;
    
    //根据index 获取 当前是在第几行 第几列
    int layoutSection =  [imageLayout count];
    int section;
    int row;
    int sectionCount;
    for (int i = 0 ; i< layoutSection; i++) {
        int layoutCount;
        NSNumber* num = imageLayout[i];
        layoutCount= [num intValue];
        for (int y = 0 ; y < i; y++) {
            NSNumber* num1 = imageLayout[y];
            layoutCount += [num1 intValue];
        }
        if(layoutCount>index){
            section = i+1;
            row = index - layoutCount +[num intValue];
            sectionCount = [num intValue];
            break;
        }
    }
    
    float y = padding*section+ imageItemSize.width*(section-1) +( CGRectGetHeight(self.frame)-imageItemSize.height*layoutSection -padding*(layoutSection+1))/2 ;
    frame.origin.y = y;
    frame.size.width = imageItemSize.width;
    frame.size.height = imageItemSize.height;
    
    float x = CGRectGetWidth(self.frame)/sectionCount /2 - imageItemSize.width/2 + (row) *CGRectGetWidth(self.frame)/sectionCount-padding*(row == 0&& sectionCount==1 ? 0:(row-1));
    
    if (sectionCount == 2) {
        x = CGRectGetWidth(self.frame) /2 - (padding)*(row==0?1:-1)- imageItemSize.width*(row==0?1:0);
    }
    frame.origin.x = x;
    return frame;
}


/**
 *  获取item的大小
 *
 *  @return item的大小
 */
-(CGSize)getItemWAH:(NSArray*)_icons layouts:(NSDictionary*)itemLayouts{
    int count  = [_icons count] > 9 ? 9 : [_icons count];
    NSArray* imageLayout = itemLayouts[@(count)];
    CGRect viewFrame = self.frame;
    float width = viewFrame.size.width;
    float hight = viewFrame.size.height;
    int maxRowCount = [self loadRowMaxCount:imageLayout];
    int perColumCount = [imageLayout count];
    float itemWidth =(width -  (maxRowCount -1)* padding -leftPadding -rightPadding ) /maxRowCount;
    float itemHigth =(hight -  (perColumCount - 1)* padding - topPadding -buttomPadding)  /perColumCount;
    float itemWAH = itemWidth > itemHigth ?  itemHigth:  itemWidth;
    return CGSizeMake(itemWAH, itemWAH);
}


/**
 *  获取全部最大的列数
 *
 *  @param layout 布局
 *
 *  @return 最大列数
 */
-(NSInteger)loadRowMaxCount:(NSArray*)layout{
    if (layout && [layout count]>0) {
        NSComparator cmptr = ^(id obj1, id obj2){
            if ([obj1 integerValue] > [obj2 integerValue]) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            
            if ([obj1 integerValue] < [obj2 integerValue]) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedSame;
        };
        return  [[[layout sortedArrayUsingComparator:cmptr] lastObject] integerValue];
    }
    return 0;
}


@end
