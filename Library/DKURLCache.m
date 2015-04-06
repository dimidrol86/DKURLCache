

#import "DKURLCache.h"

#define FIlE_CACHE_KEY @"dkurlcache"

#define ETAG_KEY @"ETag"
#define LAST_MODIFIED_KEY @"Last-Modified"
#define IF_MODIFIED_SINCE_KEY @"If-Modified-Since"

#define DATA_KEY @"data"

@interface DKURLCache ()

@property (nonatomic, strong) NSMutableDictionary *cache;
@property (nonatomic, strong) NSString *cachePath;

@end


@implementation DKURLCache

@synthesize cache=_cache;
@synthesize cachePath;


#pragma mark - Singleton
+(DKURLCache*)sharedCache
{
    static DKURLCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[self alloc] init];
    });
    return sharedCache;
}

#pragma mark - initialization
-(id)init
{
    self=[super init];
    if (self)
    {
        cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[cachePath stringByAppendingPathComponent:FIlE_CACHE_KEY]])
        {
            [self setCache:[NSMutableDictionary dictionaryWithContentsOfFile:[cachePath stringByAppendingPathComponent:FIlE_CACHE_KEY]]];

        }

        if (!_cache) _cache=[[NSMutableDictionary alloc] init];

    }
    return self;
}

#pragma mark - read/write from cache dictionary


/**Write/Rewrite new cache object.
 */
-(void)setObjectToCache:(id)obj forUrl:(NSString*)key headers:(NSDictionary*)headers
{
    NSMutableDictionary *dict=[NSMutableDictionary new];
    
    if (headers)
    {
        for (NSString*key in [headers allKeys]) {
            
            if ([key isEqual:ETAG_KEY])
                [dict setObject:[headers objectForKey:key] forKey:ETAG_KEY];
            
            if ([key isEqual:LAST_MODIFIED_KEY])
                [dict setObject:[headers objectForKey:key] forKey:LAST_MODIFIED_KEY];
            
        }
    }
    
    [dict setObject:obj forKey:DATA_KEY];
    
    [_cache setObject:dict forKey:key];
}

/**Read cache object.
 */
-(DKURLCacheObject*)objectCacheForUrl:(NSString*)key
{
    return [DKURLCache parseToObjectCache:[_cache objectForKey:key] forUrl:key];
}

/**Parse from dictionary to cache object.
 */
+(DKURLCacheObject*)parseToObjectCache:(NSDictionary*)dict forUrl:(NSString*)key
{
    DKURLCacheObject *cache=[DKURLCacheObject new];
    
    cache.urlString=key;
    
    if (dict)
    {
        id etag=[dict objectForKey:ETAG_KEY];
        if ([etag isKindOfClass:[NSString class]])
            cache.etag=etag;
        
        id lastModified=[dict objectForKey:LAST_MODIFIED_KEY];
        if ([lastModified isKindOfClass:[NSString class]])
            cache.lastModified=lastModified;

        id data=[dict objectForKey:DATA_KEY];
        if ([data isKindOfClass:[NSData class]])
            cache.data=data;
        
    }
    return cache;
}


#pragma mark - Handling url requests and responses

-(NSMutableURLRequest*)prepareUrlRequest:(NSMutableURLRequest*)request
{
    DKURLCacheObject *obj=[self objectCacheForUrl:request.URL.absoluteString];
    
    if (obj.etag)
        [request setValue:obj.etag forHTTPHeaderField:ETAG_KEY];

    if (obj.lastModified)
        [request setValue:obj.lastModified forHTTPHeaderField:IF_MODIFIED_SINCE_KEY];

    return request;
}


-(id)responseData:(id)responseData forResponse:(NSHTTPURLResponse*)response
{
    NSLog(@"RESPONSE CODE: %li",(long)response.statusCode);
    switch (response.statusCode) {
        case 200:
        {
            if (responseData)
                [self setObjectToCache:responseData forUrl:response.URL.absoluteString headers:response.allHeaderFields];
        }
            break;
        case 304:
        {
            DKURLCacheObject *obj=[self objectCacheForUrl:response.URL.absoluteString];
            if (obj.data)
                return obj.data;
        }
            break;
        default:
            break;
    }
    
    return responseData;
}


#pragma mark - save/remove

-(void)saveCacheToDisk
{
    [_cache writeToFile:[cachePath stringByAppendingPathComponent:FIlE_CACHE_KEY] atomically:YES];
}

-(void)removeAllCache
{
    [_cache removeAllObjects];
    
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[cachePath stringByAppendingPathComponent:FIlE_CACHE_KEY]])
        [[NSFileManager defaultManager] removeItemAtPath:[cachePath stringByAppendingPathComponent:FIlE_CACHE_KEY] error:&error];

}


@end
