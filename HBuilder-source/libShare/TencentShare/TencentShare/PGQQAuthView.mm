/*
 *------------------------------------------------------------------
 *  pandora/feature/PGShare
 *  Description:
 *    上传插件实现定义
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-03-22 创建文件
 *------------------------------------------------------------------
 */
#import "PGQQAuthView.h"

@implementation PGQQAuthorizeView

@synthesize authImp = _AuthViewImp;

@synthesize authorizeViewDeleagte;
@synthesize appKey, appSecret, redirectURI;
- (id)initWithFrame:(CGRect)frame {
    if ( self = [super initWithFrame:frame] ) {
        _AuthViewImp = [[TCWBAuthorizeView alloc] initWithFrame:frame];
        _AuthViewImp.authorizeDeleagete = self;
        _AuthViewImp.onlyFirstPage = TRUE;
        [self addSubview:_AuthViewImp];
    }
    return self;
}

+ (NSString *)serializeURL:(NSString *)baseURL params:(NSDictionary *)params httpMethod:(NSString *)httpMethod{
    if (![httpMethod isEqualToString:@"GET"]){
        return baseURL;
    }
    NSURL *parsedURL = [NSURL URLWithString:baseURL];
	NSString *queryPrefix = parsedURL.query ? @"&" : @"?";
	NSString *query = [PGQQAuthorizeView stringFromDictionary:params];
	
	return [NSString stringWithFormat:@"%@%@%@", baseURL, queryPrefix, query];
}

+ (NSString *)stringFromDictionary:(NSDictionary *)dict{
    NSMutableArray *pairs = [NSMutableArray array];
	for (NSString *key in [dict keyEnumerator]){
		if (!([[dict valueForKey:key] isKindOfClass:[NSString class]])){
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, [dict objectForKey:key]]];
		}
        else{
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, [[dict objectForKey:key] URLEncodedStringEx]]];
        }
	}
	
	return [pairs componentsJoinedByString:@"&"];
}

- (NSString*)getAuthorizeURL {
    if ([redirectURI length] <= 0) {
        self.redirectURI = REDIRECTURI;
    }
    NSDictionary *params = [[NSDictionary alloc]initWithObjectsAndKeys:appKey,CLIENT_ID,
                            TOKEN, RESPONSE_TYPE,
                            redirectURI,REDIRECT_URI,
                            @"ios",@"appfrom",
                            [NSNumber numberWithInt:1],@"htmlVersion",
                            nil];
    NSString *urlString = [PGQQAuthorizeView serializeURL:kWBAuthorizeURL
                                             params:params
                                         httpMethod:@"GET"];
    return urlString;
}

- (void)layoutSubviews {
    _AuthViewImp.frame = self.bounds;
}

- (void)setAuthorizeView:(TCWBAuthorizeView*)authView {
    
}

- (void)loadAuthPage {
    [_AuthViewImp loadAuthPage];
}

- (void)authorizeViewDidStartLoad:(TCWBAuthorizeView *)webView {
}

- (void)authorizeViewDidFinishLoad:(TCWBAuthorizeView *)webView {
    if ( [self.authViewDeleagte respondsToSelector:@selector(onloaded)] ) {
        [self.authViewDeleagte performSelector:@selector(onloaded)];
    }
}

- (void)authorizeView:(TCWBAuthorizeView *)webView didSucceedWithAccessToken:(NSString *)token {
    if ( [authorizeViewDeleagte respondsToSelector:@selector(authorizeView:didSucceedWithAccessToken:)] ) {
        [authorizeViewDeleagte performSelector:@selector(authorizeView:didSucceedWithAccessToken:)
                                    withObject:self
                                    withObject:token];
    }
    if ( [self.authViewDeleagte respondsToSelector:@selector(onauthenticated)] ) {
        [self.authViewDeleagte performSelector:@selector(onauthenticated)];
    }
}

- (void)authorizeView:(TCWBAuthorizeView *)authorize didFailuredWithError:(NSError *)error {
    if ( [authorizeViewDeleagte respondsToSelector:@selector(authorizeView:didFailuredWithError:)] ) {
        [authorizeViewDeleagte performSelector:@selector(authorizeView:didFailuredWithError:)
                                    withObject:self
                                    withObject:error];
    }
    if ( [self.authViewDeleagte respondsToSelector:@selector(onerror:)] ) {
        [self.authViewDeleagte performSelector:@selector(onerror:) withObject:error];
    }
}

- (void)dealloc {
    _AuthViewImp.authorizeDeleagete = nil;
    [_AuthViewImp removeFromSuperview];
    [_AuthViewImp release];
    [super dealloc];
}

@end
