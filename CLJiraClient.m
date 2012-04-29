//
//  CLJiraClient.m
//  Jira client
//
//  Created by Chris Lundie on 09/Apr/2012.
//  Copyright (c) 2012 Chris Lundie. All rights reserved.
//


#import "CLJiraClient.h"
#import "GTMHTTPFetcher.h"
#import "NSData+Base64.h"


NSString * const CLJiraClientErrorDomain = @"ca.lundie.CLJiraClient";
const NSInteger kCLJiraClientInvalidServerResponseError = 1;


@interface CLJiraClient ()
{
@private
    NSString *_password;
}

- (void)signRequest:(NSMutableURLRequest *)request;

@property (copy, readwrite) NSURL *baseURL;

@end


@implementation CLJiraClient

@synthesize username = _username;
@synthesize baseURL = _baseURL;

- (id)initWithBaseURL:(NSURL *)baseURL
{
    if (baseURL == nil) {
        [NSException raise:NSInvalidArgumentException format:@"baseURL cannot be nil"];
    }
    self = [super init];
    if (self != nil) {
        _baseURL = [baseURL copy];
    }
    return self;
}

- (void)setPassword:(NSString *)password
{
    _password = [password copy];
}

- (GTMHTTPFetcher *)searchJQL:(NSString *)JQL startAt:(NSNumber *)startAt maxResults:(NSNumber *)maxResults fields:(NSArray *)fields expand:(NSArray *)expand completionHandler:(void(^)(NSError *error, NSDictionary *result))completionHandler
{
	GTMHTTPFetcher *fetcher = nil;
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	if (JQL != nil) {
		[params setObject:JQL forKey:@"jql"];
	}
	if (startAt != nil) {
		[params setObject:startAt forKey:@"startAt"];
	}
	if (maxResults != nil) {
		[params setObject:maxResults forKey:@"maxResults"];
	}
	if ([fields count] > 0) {
		[params setObject:[fields componentsJoinedByString:@","] forKey:@"fields"];
	}
	if ([expand count] > 0) {
		[params setObject:[expand componentsJoinedByString:@","] forKey:@"expand"];
	}
	NSData *postBody = [NSJSONSerialization dataWithJSONObject:params options:0 error:NULL];
	NSURL *URL = [[NSURL alloc] initWithString:@"rest/api/2/search" relativeToURL:self.baseURL];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:postBody];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [self signRequest:request];
	fetcher = [[GTMHTTPFetcher alloc] initWithRequest:request];
	BOOL fetchStarted = [fetcher beginFetchWithCompletionHandler:^(NSData *fetchedData, NSError *fetchError) {
		if (fetchError != nil) {
			if (completionHandler != nil) {
				completionHandler(fetchError, nil);
			}
			return;
		}
		if (completionHandler != nil) {
			NSDictionary *result = [NSJSONSerialization JSONObjectWithData:fetchedData options:0 error:NULL];
			if (![result isKindOfClass:[NSDictionary class]]) {
				result = nil;
			}
			completionHandler(nil, result);
		}
	}];
	if (!fetchStarted) {
		fetcher = nil;
	}
	return fetcher;
}

- (GTMHTTPFetcher *)fetchIssueWithIDOrKey:(NSString *)issueIDOrKey completionHandler:(void(^)(NSError *error, NSDictionary *issue))completionHandler
{
	GTMHTTPFetcher *fetcher = nil;
	NSURL *URL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"rest/api/2/issue/%@", [issueIDOrKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] relativeToURL:self.baseURL];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
    [self signRequest:request];
	fetcher = [[GTMHTTPFetcher alloc] initWithRequest:request];
	BOOL fetchStarted = [fetcher beginFetchWithCompletionHandler:^(NSData *fetchedData, NSError *fetchError) {
		if (fetchError != nil) {
			if (completionHandler != nil) {
				completionHandler(fetchError, nil);
			}
			return;
		}
		if (completionHandler != nil) {
			id issue = [NSJSONSerialization JSONObjectWithData:fetchedData options:0 error:NULL];
            if (![issue isKindOfClass:[NSDictionary class]]) {
                issue = nil;
            }
			completionHandler(nil, issue);
		}
	}];
	if (!fetchStarted) {
		fetcher = nil;
	}
	return fetcher;
}

- (GTMHTTPFetcher *)createNewIssueWithPayload:(NSObject *)payload completionHandler:(void(^)(NSError *error, NSString *issueID, NSString *issueKey))completionHandler
{
    GTMHTTPFetcher *fetcher = nil;
    NSData *body = nil;
    if ([NSJSONSerialization isValidJSONObject:payload]) {
        body = [NSJSONSerialization dataWithJSONObject:payload options:0 error:NULL];
    }
    if (body != nil) {
        NSURL *URL = [[NSURL alloc] initWithString:@"rest/api/2/issue/" relativeToURL:self.baseURL];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:body];
        [self signRequest:request];
        fetcher = [[GTMHTTPFetcher alloc] initWithRequest:request];
        BOOL fetchStarted = [fetcher beginFetchWithCompletionHandler:^(NSData *fetchedData, NSError *fetchError) {
            if (fetchError != nil) {
                if (completionHandler != nil) {
                    completionHandler(fetchError, nil, nil);
                }
                return;
            }
            NSDictionary *responseDict = nil;
            responseDict = [NSJSONSerialization JSONObjectWithData:fetchedData options:0 error:NULL];
            if ((responseDict != nil) && ![responseDict isKindOfClass:[NSDictionary class]]) {
                responseDict = nil;
            }
            NSString *issueID = [responseDict objectForKey:@"id"];
            NSString *issueKey = [responseDict objectForKey:@"key"];
            if (![issueID isKindOfClass:[NSString class]] || ![issueKey isKindOfClass:[NSString class]]) {
                if (completionHandler != nil) {
                    NSError *error = [NSError errorWithDomain:CLJiraClientErrorDomain code:kCLJiraClientInvalidServerResponseError userInfo:[NSDictionary dictionary]];
                    completionHandler(error, nil, nil);
                }
            } else {
                if (completionHandler != nil) {
                    completionHandler(nil, issueID, issueKey);
                }
            }
        }];
        if (!fetchStarted) {
            fetcher = nil;
        }
    }
    return fetcher;
}

- (void)signRequest:(NSMutableURLRequest *)request
{
	if ((self.username != nil) && (_password != nil)) {
        NSString *auth = [[[NSString stringWithFormat:@"%@:%@", self.username, _password] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedString];
        [request setValue:[NSString stringWithFormat:@"Basic %@", auth] forHTTPHeaderField:@"Authorization"];
	}
}

@end
