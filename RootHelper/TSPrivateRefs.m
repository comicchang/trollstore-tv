#import "TSPrivateRefs.h"

#if TARGET_OS_TV
#include <dlfcn.h>

void TSBksTerminate(NSString* bundleId, int reason, bool report, NSString* desc)
{
	typedef void (*bks_terminate_fn)(NSString*, int, bool, NSString*);
	static bks_terminate_fn fn;
	static dispatch_once_t once;
	dispatch_once(&once, ^
	{
		void* h = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_LAZY | RTLD_GLOBAL);
		if (h) fn = (bks_terminate_fn)dlsym(h, "BKSTerminateApplicationForReasonAndReportWithDescription");
	});
	if (fn) fn(bundleId, reason, report, desc);
}
#else
extern void BKSTerminateApplicationForReasonAndReportWithDescription(NSString* bundleID, int reasonID, bool report, NSString* description);

void TSBksTerminate(NSString* bundleId, int reason, bool report, NSString* desc)
{
	BKSTerminateApplicationForReasonAndReportWithDescription(bundleId, reason, report, desc);
}
#endif
