//
//  CLJiraClient.h
//  Jira client
//
//  Created by Chris Lundie on 09/Apr/2012.
//  Copyright (c) 2012 Chris Lundie. All rights reserved.
//


@class GTMHTTPFetcher;


#import <Foundation/Foundation.h>


extern NSString * const CLJiraClientErrorDomain;
extern const NSInteger kCLJiraClientInvalidServerResponseError;


@interface CLJiraClient : NSObject

/**
 Designated initializer.
 
 \param baseURL Base URL of your server. For example, <https://jira.example.com>. Must not be nil.
 */
- (id)initWithBaseURL:(NSURL *)baseURL;

- (void)setPassword:(NSString *)password;

/**
 Create a new issue.
 
 \param payload Payload must be an NSDictionary that can be converted to JSON.
 
 \example A payload might look like this:

 {
   "fields": {
     "components": [
       {
         "name": "iPhone"
       }
     ], 
     "issuetype": {
       "name": "Bug"
     }, 
     "project": {
       "key": "My Project"
     }, 
     "summary": "Test bug"
   }
 }

 */
- (GTMHTTPFetcher *)createNewIssueWithPayload:(NSObject *)payload completionHandler:(void(^)(NSError *error, NSString *issueID, NSString *issueKey))completionHandler;

/**
 Fetch an issue with the given ID or key.
 */
- (GTMHTTPFetcher *)fetchIssueWithIDOrKey:(NSString *)issueIDOrKey completionHandler:(void(^)(NSError *error, NSDictionary *issue))completionHandler;

/**
 Perform a JQL query.
 */
- (GTMHTTPFetcher *)searchJQL:(NSString *)JQL startAt:(NSNumber *)startAt maxResults:(NSNumber *)maxResults fields:(NSArray *)fields expand:(NSArray *)expand completionHandler:(void(^)(NSError *error, NSDictionary *result))completionHandler;

@property (copy) NSString *username;
@property (copy, readonly) NSURL *baseURL;

@end
