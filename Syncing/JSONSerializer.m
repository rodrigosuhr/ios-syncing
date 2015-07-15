//
//  JSONSerializer.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "JSONSerializer.h"
#import "DateSerializer.h"
#import <objc/runtime.h>
#include "SerializationUtil.h"

@interface JSONSerializer ()

@property (strong, nonatomic) Class modelClass;
@property (strong, nonatomic) Annotations *annotations;
@property (strong, nonatomic) NSManagedObjectContext *context;

@end

@implementation JSONSerializer

- (instancetype)initWithModelClass:(Class)modelClass withAnnotations:(Annotations *)annotations withContext:(NSManagedObjectContext *)context
{
    self = [super init];
    
    if (self)
    {
        _modelClass = modelClass;
        _annotations = annotations;
        _context = context;
    }
    
    return self;
}

- (NSArray *)toJSON:(NSManagedObject *)object withJSON:(NSDictionary *)jsonObject
{
    Class superClass = _modelClass;
    NSMutableArray *unusedAttributes = [[NSMutableArray alloc] init];
    
    while (superClass != nil)
    {
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList([superClass class], &outCount);
        
        for (i = 0; i < outCount; i++)
        {
            objc_property_t property = properties[i];
            NSString *attributeName = [NSString stringWithFormat:@"%s", property_getName(property)];
            Class type = [SerializationUtil propertyTypeFor:property];
            
            FieldSerializer *fieldSerializer = [self getFieldSerializer:attributeName
                                                      withAttributeType:type
                                                             withObject:object
                                                               withJSON:jsonObject];
            
            if (fieldSerializer == nil || ![fieldSerializer updateJSON])
            {
                [unusedAttributes addObject:attributeName];
            }
        }
        
        superClass = class_getSuperclass(superClass);
        if (superClass == [NSManagedObject class])
        {
            break;
        }
    }
    
    return unusedAttributes;
}

- (NSArray *)updateFromJSON:(NSDictionary *)jsonObject withObject:(NSManagedObject *)object
{
    Class superClass = _modelClass;
    NSMutableArray *unusedAttributes = [[NSMutableArray alloc] init];
    
    while (superClass != nil)
    {
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList([superClass class], &outCount);
        
        for (i = 0; i < outCount; i++)
        {
            objc_property_t property = properties[i];
            NSString *attributeName = [NSString stringWithFormat:@"%s", property_getName(property)];
            Class type = [SerializationUtil propertyTypeFor:property];
            
            FieldSerializer *fieldSerializer = [self getFieldSerializer:attributeName
                                                      withAttributeType:type
                                                             withObject:object
                                                               withJSON:jsonObject];
            
            if (fieldSerializer == nil || ![fieldSerializer updateField])
            {
                [unusedAttributes addObject:attributeName];
            }
        }
        
        superClass = class_getSuperclass(superClass);
        if (superClass == [NSManagedObject class])
        {
            break;
        }
    }
    
    return unusedAttributes;
}

- (FieldSerializer *)getFieldSerializer:(NSString *)attribute withAttributeType:(Class)type withObject:(NSManagedObject *)object withJSON:(NSDictionary *)jsonObject
{
    JSON *fieldAnnotation = [_annotations annotationForAttribute:attribute];
    
    if ([type isMemberOfClass:[NSDate class]])
    {
        return [[DateSerializer alloc] initWithAttribute:attribute
                                              withObject:object
                                                withJSON:jsonObject
                                          withAnnotation:fieldAnnotation];
    }
    else
    {
        return [[FieldSerializer alloc] initWithAttribute:attribute
                                               withObject:object
                                                 withJSON:jsonObject
                                           withAnnotation:fieldAnnotation];
    }
}

@end
