//
//  ViewController.m
//  BTCrashCase
//
//  Created by blacktea on 2022/2/25.
//

#import "ViewController.h"

// 通用的参数列表提取方案
#define s_generate_messageStr \
NSString *contentStr = nil;\
va_list ap;\
va_start(ap,content);\
contentStr = [[NSString alloc] initWithFormat:content arguments: ap];\
va_end(ap);\
if( contentStr == nil ){return;}

FOUNDATION_EXTERN void BTTest1(BOOL isDo, NSDictionary* params, NSString* content, ... );

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    BTTest1(YES,nil,[NSString stringWithFormat:@"打开新页面,uri =%@%@",@"ASCHybridViewController",@"https://air.alibaba.com/apps/rax-app/rfq-buyer/post.html?wh_weex=true&wx_ignore_downgrade=true&wx_navbar_transparent=true&quantity=500.00&pr"]);
}

void BTTest1( BOOL isAcceptUri, NSDictionary* params, NSString* content, ... )
{
    s_generate_messageStr
}

@end
