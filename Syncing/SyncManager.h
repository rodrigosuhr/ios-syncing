//
//  SyncManager.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SyncManager <NSObject>

- (NSString *)getIdentifier;
- (NSString *)getResponseIdentifier;
- (BOOL)shouldSendSingleObject;
- (NSArray *)getModifiedData;
- (BOOL)hasModifiedData;
- (NSArray *)getModifiedFiles;
- (NSArray *)getModifiedFilesForObject:(NSDictionary *)object;
- (NSArray *)saveNewData:(NSArray *)jsonObjects withDeviceId:(NSString *)deviceId;
- (void)processSendResponse:(NSArray *)jsonResponse;
- (NSDictionary *)serializeObject:(NSObject *)object;
- (NSObject *)saveObject:(NSDictionary *)object withDeviceId:(NSString *)deviceId;
- (void)postEvent:(NSArray *)objects;		

@end
