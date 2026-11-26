#import <Foundation/Foundation.h>
#import <TSUtil.h>

// 私有类/符号在 tvOS SDK 中无桩，且不能在 main() 前由 dyld 强绑定。
// 统一经运行时查找：类用 NSClassFromString，函数用 dlsym。

static inline Class TSClass(NSString* name)
{
#if TARGET_OS_TV
	ts_loadTVPrivateFrameworks();
#endif
	return NSClassFromString(name);
}

void TSBksTerminate(NSString* bundleId, int reason, bool report, NSString* desc);
