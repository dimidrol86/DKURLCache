
#import <Foundation/Foundation.h>
#import "DKURLCacheObject.h"

@interface DKURLCache : NSObject


/**Singleton.
*/
+(DKURLCache*)sharedCache;

/**Save cache to file.
 */
-(void)saveCacheToDisk;

/**Remove cache (with file).
 */
-(void)removeAllCache;


/**Prepare url request. Setting ETag or If-Since-Modified.
 */
-(NSMutableURLRequest*)prepareUrlRequest:(NSMutableURLRequest*)request;

/**Return cached response data or cached response to next time.
 */
-(id)responseData:(id)responseData forResponse:(NSHTTPURLResponse*)response;


@end
