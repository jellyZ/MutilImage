//  MutilImage
//
//  Created by dong on 14/12/1.
//  Copyright (c) 2014年 dong. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void(^DImageLoadCompletedBlock)(UIImage *image);

@interface UIImageView (MutilImage)


/**
 *  仿微信群头像图片合成
 *
 *  @param array       头像数组
 *  @param placeholder 默认头像
 *  @param complete    合成图片后回调
 */
-(void)setImageGroup:(NSArray*)array placeholderImage:(UIImage *)placeholder  complete:(DImageLoadCompletedBlock)complete;


@end
