//
//  FSConfiguration.h
//  FashionShop
//
//  Created by gong yi on 11/13/12.
//  Copyright (c) 2012 Fashion. All rights reserved.
//

#include "FSConfiguration+Fonts.h"
#import "FSAppDelegate.h"

#ifndef FashionShop_FSConfiguration_h
#define FashionShop_FSConfiguration_h




#define REST_API_APP_SECRET_KEY @"yintai123456"
#define REST_API_CLIENT_VERSION @"1.0"
#define REST_API_URL   @"http://itoo.yintai.com/api" //@"http://10.32.11.65:9550/api" ////
#define SINA_WEIBO_APP_KEY @"1594791248"
#define SINA_WEIBO_APP_SECRET_KEY @"7ef3ddef06d52a937a0fcc3fc44d19f4"
#define SINA_WEIBO_APP_REDIRECT_URI @"http://www.intime.com.cn"


#define QQ_WEIBO_APP_KEY @"801298995"
#define QQ_WEIBO_APP_SECRET_KEY @"dbab88f4d3e0b27c00b15f52d1a5fc61"
#define QQ_WEIBO_APP_REDIRECT_URI @"http://www.intime.com.cn"
#define WEIXIN_API_APP_KEY @"wx730465bd3f0845af"

#define FLURRY_APP_KEY @"BVP8QWHDDXKCBPZRPFT4"

#define BAIDU_MAP_KEY @"D768745A12D429DEC85D896036A25C50A52313E6"

//notification
#define LN_USER_UPDATED @"LN_USER_UPDATED"
#define LN_FAVOR_UPDATED @"LN_USER_FAVOR_UPDATED"
#define LN_ITEM_UPDATED @"LN_USER_ITEM_UPDATED"
#define COMMON_PAGE_SIZE 10

//HeQingshan
#define NAV_HIGH        44
#define FIL_HIGH        45
#define TAB_HIGH        46
#define APP_HIGH        [[UIScreen mainScreen] applicationFrame].size.height
#define APP_WIDTH       [[UIScreen mainScreen] applicationFrame].size.width
#define SCREEN_HIGH     [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH    [[UIScreen mainScreen] bounds].size.width
#define MAIN_HIGH       APP_HIGH - NAV_HIGH
#define BODY_HIGH       APP_HIGH - NAV_HIGH - TAB_HIGH
#define theApp          ((FSAppDelegate *) [[UIApplication sharedApplication] delegate])
#define STATUSBAR_HIGH  ([UIApplication sharedApplication].statusBarHidden?0:20)
//当前设备是否支持高清
#define isRetina ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
//是否高清，放大系数
#define RetinaFactor (isRetina?2:1)
// 是否iPad
#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define RGBACOLOR(r,g,b,a)       [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define RGBCOLOR(r,g,b)          [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define XRGBCOLOR(r,g,b)         [UIColor colorWithRed:(0x##r)/255.0 green:(0x##g)/255.0 blue:(0x##b)/255.0 alpha:1]

#define FONT(a)             [UIFont systemFontOfSize:a]
#define BFONT(a)            [UIFont boldSystemFontOfSize:a]

#endif
