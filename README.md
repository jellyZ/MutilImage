### 简介
---
本项目仿微信头像，能够合成多个头像返回一个UIImage。
 

----


### 如何使用？

----

	#import "UIImageView+MutilImage.h"
	
	UIImageView* mutilImageView =[[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    [mutilImageView setImageGroup:imageUrlStrArray placeholderImage:[UIImage imageNamed:@"默认图"] complete:^(UIImage *image) {
        
    }];
	


### 以后更新内容
---

	1.算法优化，现在完全没有算法的概念，是以前项目完成的，觉得可以分享就分享出去
	
	
### 联系方式

QQ：651247149
Email： 651247149@qq.com





