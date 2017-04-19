//
//  MySpotlightImporter.h
//  FLIFSpotlightImporter
//
//  Created by Sveinbjorn Thordarson on 15/04/2017.
//  Copyright © 2017 Sveinbjorn Thordarson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define YOUR_STORE_TYPE NSXMLStoreType

@interface MySpotlightImporter : NSObject

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (BOOL)importFileAtPath:(NSString *)filePath attributes:(NSMutableDictionary *)attributes error:(NSError **)error;

@end
