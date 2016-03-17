//
//  CustomTransactionManager.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/25/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "CustomTransactionManager.h"
#import "CustomException.h"
#import <CoreData/CoreData.h>
#import "SyncConfig.h"

@interface CustomTransactionManager()

@property BOOL isSuccessful;

@end

@implementation CustomTransactionManager

/**
 * init
 */
- (id)init
{
    if (self = [super init])
    {
        self.isSuccessful = NO;
    }
    
    return self;
}

/**
 * doInTransaction
 */
- (void)doInTransaction:(void(^)(void))manipulateInTransaction withContext:(NSManagedObjectContext *)context
{
    @try
    {
        manipulateInTransaction();
        [self performSaveWithContext:context];
        self.isSuccessful = YES;
    }
    @catch (InvalidThreadIdException *exception)
    {
        [context reset];
    }
    @catch (NSException *exception)
    {
        [context reset];
        @throw exception;
    }
}

/**
 * wasSuccessful
 */
- (BOOL)wasSuccessful
{
    return self.isSuccessful;
}

- (void)performSaveWithContext:(NSManagedObjectContext *)context
{
    // Saving child managed object context
    NSError *childError = nil;
    [context save:&childError];
    if (childError) {
        NSString *errorString = [NSString stringWithFormat:@"CustomTransactionManager: error on performSaveWithContext for child MOC: %@.", childError];
        NSException *ex = [NSException exceptionWithName:@"CoreDataSaveError" reason:errorString userInfo:nil];
        @throw ex;
    }
    
    // Saving parent managed object context
    NSManagedObjectContext *mainContext = [[SyncConfig getInstance] context];
    [mainContext performBlock:^{
        NSError *parentError = nil;
        [mainContext save:&parentError];
        if (parentError) {
            NSString *errorString = [NSString stringWithFormat:@"CustomTransactionManager: error on performSaveWithContext for parent MOC: %@.", parentError];
            NSException *ex = [NSException exceptionWithName:@"CoreDataSaveError" reason:errorString userInfo:nil];
            @throw ex;
        }
    }];
}

@end
