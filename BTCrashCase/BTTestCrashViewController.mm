//
//  BTTestCrashViewController.m
//
//  Created by blacktea on 2020/12/8.
//

#import "BTTestCrashViewController.h"
#import <MessageUI/MessageUI.h>
#import <objc/runtime.h>
#include <exception>
#include <string>
#import <Masonry/Masonry.h>
//#import "TestNonArc.h"

typedef struct class_ro_t {
    uint32_t flags;
    uint32_t instanceStart;
    uint32_t instanceSize;
#ifdef __LP64__
    uint32_t reserved;
#endif
    
    const uint8_t * ivarLayout;
    
    char * name;
    void * baseMethodList;
    void * baseProtocols;
    const void * ivars;
    
    const uint8_t * weakIvarLayout;
    void *baseProperties;
} class_ro_t;

typedef struct class_rw {
    uint32_t flags;
    uint32_t version;
    
    const class_ro_t *ro;
    
    void * methods;
    void * properties;
    void * protocols;
    
    Class firstSubclass;
    Class nextSiblingClass;
    
    char *demangledName;
} class_rw_t;

#if !__LP64__
#define FAST_DATA_MASK          0xfffffffcUL
#else
#define FAST_DATA_MASK          0x00007ffffffffff8UL
#endif

// text_exception uses a dynamically-allocated internal c-string for what():
using namespace std;
class text_exception : public std::exception {
private:
    char* text_;
public:
    text_exception(const char* text) {
        text_ = new char[std::strlen(text) + 1];
        std::strcpy(text_, text);
    }
    text_exception(const text_exception& e) {
        text_ = new char[std::strlen(e.text_) + 1];
        std::strcpy(text_, e.text_);
    }
    const char* what() const _NOEXCEPT override {
        return (const char *)text_;
    }
};

@interface BTTestCrashViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray   *data;
@property (strong, nonatomic) NSOperationQueue *queue;

@end

@implementation BTTestCrashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.queue = [[NSOperationQueue alloc] init];
    [self setupViews];
    [self setupData];
}

- (void)setupViews {
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc]init];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.tableFooterView = [UIView new];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    }
    return _tableView;
}

- (void)testOverflow __attribute__ ((optnone))
{
    char a[200];
    [self testOverflow];
    a[1] = 'b';
}

- (void)testOverflow2 __attribute__ ((optnone))
{
    
    NSOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"op1 begin");
        sleep(1);
        NSLog(@"op1 end");
    }];
    
    NSOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"op2 begin");
        sleep(1);
        NSLog(@"op2 end");
    }];
    
    NSOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"op3 begin");
        sleep(1);
        NSLog(@"op3 end");
    }];
    
    [self.queue addOperation:op1];
    [op1 addDependency:op2];
    [op2 addDependency:op1];
//    [op2 addDependency:op3];
//    [op3 addDependency:op1];
//    [self.queue addOperations:@[op2, op3] waitUntilFinished:NO];
    
}

- (void)test_NSException_array_beyound {
    id str = @[@"1"];
    [str objectAtIndex:1];
}

- (void)test_NSException_unrecognized_sel {
    id str = @"hehe";
    [str objectAtIndex:0];
}

- (void)test_NSException_dic {
    id source = nil;
    __used NSDictionary *dic = @{
                                 @"file": source,
                                 @"line": @"12",
                                 @"column":@"co"
                          };
}

- (void)test_CPPException_string {
    throw "This is a cpp exception string!";
}

- (void)test_CPPException_except {
    throw text_exception("This is a cpp exception");
}

- (void)test_CPPException_muti {
    
    for (int i = 0; i < 10; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            throw text_exception("This is a cpp exception");
        });
    }
    
}

- (void)test_SIGBUS_BUS_ADRALN  __attribute__ ((optnone)) {
    void (*func)(void) = (void(*)(void))(void *)((uintptr_t)(void *)NSLog + 1);
    func();
}

- (void)test_SIGBUS_00 __attribute__ ((optnone)) {
    void (*func)(void) = (void(*)(void))(void *)0x0;
    func();
}

- (void)test_SIGSEGV_00 __attribute__ ((optnone)) {
    char *ptr = (char *)(void *)0x0;
    *ptr = 'a';
}

- (void)test_SIGSEGV_wildPointer __attribute__ ((optnone)) {
    __unsafe_unretained NSMutableDictionary * hehe = nil;
    {
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        hehe = dic;
        [hehe setObject:@"1" forKey:@"1"];
    }
    [hehe setObject:@"2" forKey:@"1"];
}

- (void)test_SIGSEGV_wildPointer_bg __attribute__ ((optnone)) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __unsafe_unretained NSMutableDictionary * hehe = nil;
        {
            NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
            hehe = dic;
            [hehe setObject:@"1" forKey:@"1"];
        }
        [hehe setObject:@"2" forKey:@"1"];
    });
}

- (void)test_SIGTRAP __attribute__ ((optnone)) {
    __builtin_trap();
}

- (void)test_abort __attribute__ ((optnone)) {
    abort();
}

- (void)test_MainCPUFull __attribute__ ((optnone)) {
    
    while (true) {
        void *a = calloc(1, 10 * 1024 * 1024);
        free(a);
    }
}

- (void)test_OOM __attribute__ ((optnone)) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (true) {
            void *a = calloc(1, 1 * 1024 * 1024);
            sleep(0.2);
        }
    });
    
}

- (void)test_exit {
    exit(-1);
}

- (void)test_exit_bg {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        exit(-1);
    });
}

- (void)testDoubleRelease {
//    [TestNonArc doubleRelease];
}

- (void)test_objc_fatal __attribute__ ((optnone)) {
    Class aCls = [self class];
    class_rw_t *aCls_rw = *(class_rw_t **)((uintptr_t)aCls + 4 * sizeof(uintptr_t));
    ((class_rw_t *)((uintptr_t)aCls_rw & FAST_DATA_MASK))->nextSiblingClass = aCls;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    _objc_flush_caches(nil);
#pragma clang diagnostic pop
}

- (void)test_SIGILL {
    dispatch_block_t block = [[self.data objectAtIndex:5] objectAtIndex:1];
    if (block) {
        block();
    }
}


static void test1() __attribute__ ((optnone)) {
    __builtin_trap();

}

- (void)test_Backtrace __attribute__ ((optnone)) {
    test1();
    
    
}

- (void)crashWhenBlockRelease {
    int a = 2;
    
    dispatch_block_t block = ^{
        printf("a:%d", a);
    };
    
    id obj = [block copy];
    
    __unsafe_unretained dispatch_block_t nextBlock = obj;
    
    block = nil;
    obj = nil;
    
    NSArray *arr = @[nextBlock];
    
    NSLog(@"obj: %@", obj);
}

- (void)testBlock:(dispatch_block_t)block {
    block();
    __builtin_trap();
}

- (void)crashWhenBlockRelease2 {
    int a = 2;
    
    [self testBlock:^{
        printf("a:%d", a);
    }];
}

void test(void) {
    test1();//. <- lr
    // crash
    // backtrace is wrong,
}

- (void)testValueForUndefineKeyFromNSString {
    //     "[<__NSCFConstantString 0x1028c0900> valueForUndefinedKey:]: this class is not key value coding-compliant for the key name."
    NSDictionary *dict = @{@"action": @"1",@"traceInfo":@"2"};
    if (dict[@"action"] || dict[@"traceInfo"]) {
        NSString *name = [[dict valueForKeyPath:@"traceInfo.name"] description];
        NSDictionary *param = [dict[@"traceInfo"] objectForKey:@"param"];
        NSLog(@"name = %@,param =%@",name,param);
    }
}

- (void)setupData
{
    
    // Do any additional setup after loading the view.
    self.data =
    @[
      @[@"test (backtrace)",
        @"test_Backtrace"],
      
      @[@"NSException (数组越界)",
        @"test_NSException_array_beyound"],
      
      @[@"NSException (unrecognized selector)",
        @"test_NSException_unrecognized_sel"],
      
      @[@"NSException (dic nil)",
        @"test_NSException_dic"],
      
      @[@"CPP Exception (string)",
        @"test_CPPException_string"],
      
      @[@"CPP Exception (std::exception)",
        @"test_CPPException_except"],
      
      @[@"CPP Exception (并发多个)",
        @"test_CPPException_muti"],
      
      @[@"SIGBUS (BUS_ADRALN)",
        @"test_SIGBUS_BUS_ADRALN"],
      
      @[@"SIGBUS (0x0)",
        @"test_SIGBUS_00"],
      
      @[@"SIGSEGV (0x0)",
        @"test_SIGSEGV_00"],
      
      @[@"SIGSEGV (野指针)",
        @"test_SIGSEGV_wildPointer"],
      
      @[@"SIGSEGV (野指针子线程)",
        @"test_SIGSEGV_wildPointer_bg"],
      
      @[@"SIGTRAP",
        @"test_SIGTRAP"],
      
      @[@"SIGBART (abort)",
        @"test_abort"],
      
      @[@"SIGILL",
        @"test_SIGILL"],
      
      @[@"Stack overflow",
        @"testOverflow"],
      
      @[@"Stack overflow2",
        @"testOverflow2"],
      
      @[@"Crash _objc_Fatal",
        @"test_objc_fatal"],
      
      @[@"abort (内存打爆)",
        @"test_OOM"],
      
      @[@"abort (主线程卡死)",
        @"test_MainCPUFull"],
      
      @[@"exit",
        @"test_exit"],
      
      @[@"exit_bg",
        @"test_exit_bg"],
      
      @[@"testDoubleRelease",
        @"testDoubleRelease"],
      
    @[@"crashWhenBlockRelease",
    @"crashWhenBlockRelease"],
    
    @[@"crashWhenBlockRelease2",
    @"crashWhenBlockRelease2"],
      @[@"testValueForUndefineKeyFromNSString",
        @"testValueForUndefineKeyFromNSString"]
      
      ];
    
    
    
    [self.tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell) {
        cell.textLabel.text = [[self.data objectAtIndex:indexPath.row] objectAtIndex:0];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *sel = [[self.data objectAtIndex:indexPath.row] objectAtIndex:1];
    if ([self respondsToSelector:NSSelectorFromString(sel)]) {
        [self performSelector:NSSelectorFromString(sel)];
    }
}

@end
