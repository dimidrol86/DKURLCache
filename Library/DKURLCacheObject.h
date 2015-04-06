

#import <Foundation/Foundation.h>

@interface DKURLCacheObject : NSObject

@property (nonatomic,strong) NSData *data;
@property (nonatomic,strong) NSString *etag;
@property (nonatomic,strong) NSString *lastModified;
@property (nonatomic,strong) NSString *urlString;

@end
