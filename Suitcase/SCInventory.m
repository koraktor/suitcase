//
//  SCInventory.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <QuartzCore/QuartzCore.h>

#import "SCInventory.h"
#import "SCItem.h"
#import "UIImageView+ASIHTTPRequest.h"

@interface SCInventory () {
    NSArray *_itemTypes;
    NSArray *_items;
}
@end

@implementation SCInventory

@synthesize itemSections = _itemSections;
@synthesize schema = _schema;

- (id)initWithItems:(NSArray *)itemsData andSchema:(SCSchema *)schema {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:[itemsData count]];
    [itemsData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [items addObject:[[SCItem alloc] initWithDictionary:obj andSchema:schema]];
    }];
    _items = items;
    _schema = schema;

    return self;
}

- (void)sortItems {
    NSString *sortOption = [[NSUserDefaults standardUserDefaults] valueForKey:@"sorting"];

    if (sortOption == nil || [sortOption isEqual:@"position"]) {
        _itemSections = [NSArray arrayWithObject:[_items sortedArrayUsingComparator:^NSComparisonResult(SCItem *item1, SCItem *item2) {
            return [item1.position compare:item2.position];
        }]];
    } else if ([sortOption isEqual:@"origin"]) {
        _itemSections = [NSMutableArray arrayWithCapacity:_schema.origins.count];
        for (NSUInteger i = 0; i < _schema.origins.count; i ++) {
            [(NSMutableArray *)_itemSections addObject:[NSMutableArray array]];
        }
        [_items enumerateObjectsUsingBlock:^(SCItem *item, NSUInteger idx, BOOL *stop) {
            NSUInteger originIndex = [[item.dictionary objectForKey:@"origin"] unsignedIntegerValue];
            [[_itemSections objectAtIndex:originIndex] addObject:item];
        }];
    } else if ([sortOption isEqual:@"quality"]) {
        _itemSections = [NSMutableArray arrayWithCapacity:_schema.qualities.count];
        for (NSUInteger i = 0; i < _schema.qualities.count; i ++) {
            [(NSMutableArray *)_itemSections addObject:[NSMutableArray array]];
        }
        [_items enumerateObjectsUsingBlock:^(SCItem *item, NSUInteger idx, BOOL *stop) {
            NSUInteger qualityIndex = [[item.dictionary objectForKey:@"quality"] unsignedIntegerValue];
            [[_itemSections objectAtIndex:qualityIndex] addObject:item];
        }];
    } else if ([sortOption isEqual:@"type"]) {
        if (_itemTypes == nil) {
            _itemTypes = [NSMutableArray array];
            [_items enumerateObjectsUsingBlock:^(SCItem *item, NSUInteger idx, BOOL *stop) {
                if (![_itemTypes containsObject:item.itemType]) {
                    [(NSMutableArray *)_itemTypes addObject:item.itemType];
                }
            }];
            _itemTypes = [_itemTypes sortedArrayUsingSelector:@selector(compare:)];
        }

        _itemSections = [NSMutableArray arrayWithCapacity:_itemTypes.count];
        for (NSUInteger i = 0; i < _itemTypes.count; i ++) {
            [(NSMutableArray *)_itemSections addObject:[NSMutableArray array]];
        }
        [_items enumerateObjectsUsingBlock:^(SCItem *item, NSUInteger idx, BOOL *stop) {
            NSUInteger typeIndex = [_itemTypes indexOfObject:item.itemType];
            [[_itemSections objectAtIndex:typeIndex] addObject:item];
        }];
    }

    _itemSections = [_itemSections copy];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _itemSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [(NSArray *)[_itemSections objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemCell"];

    SCItem *item = [[_itemSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

    [cell.imageView setImageWithURL:[item iconUrl]
                andPlaceholderImage:[UIImage imageNamed:@"item_placeholder.png"]
                    completionBlock:^(UIImage *image) {
                        CGSize size = CGSizeMake(44.0 * [[UIScreen mainScreen] scale], 44.0 * [[UIScreen mainScreen] scale]);
                        UIGraphicsBeginImageContext(size);
                        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
                        UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();

                        cell.imageView.image = scaledImage;
                    }];
    cell.imageView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    cell.imageView.layer.shadowOpacity = 1.0;
    cell.imageView.layer.shadowRadius = 5.0;

    cell.textLabel.text = item.name;

    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"show_colors"] boolValue]) {
        NSInteger itemQuality = [[[item dictionary] objectForKey:@"quality"] integerValue];
        if (itemQuality == 3) {
            cell.imageView.layer.shadowColor = [[UIColor colorWithRed:0.11 green:0.39 blue:0.82 alpha:1.0] CGColor];
        } else if (itemQuality == 5) {
            cell.imageView.layer.shadowColor = [[UIColor colorWithRed:0.53 green:0.33 blue:0.82 alpha:1.0] CGColor];
        } else if (itemQuality == 7) {
            cell.imageView.layer.shadowColor = [[UIColor colorWithRed:0.11 green:0.52 blue:0.17 alpha:1.0] CGColor];
        } else if (itemQuality == 11) {
            cell.imageView.layer.shadowColor = [[UIColor colorWithRed:0.76 green:0.52 blue:0.17 alpha:1.0] CGColor];
        } else {
            cell.imageView.layer.shadowColor = [[UIColor colorWithWhite:0.2 alpha:1.0] CGColor];
        }
    } else {
        cell.imageView.layer.shadowColor = [[UIColor colorWithWhite:0.2 alpha:1.0] CGColor];
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[_itemSections objectAtIndex:section] count] == 0) {
        return nil;
    }

    NSString *sortOption = [[NSUserDefaults standardUserDefaults] valueForKey:@"sorting"];

    if ([sortOption isEqual:@"origin"]) {
        return NSLocalizedString([_schema originNameForIndex:section], @"Origin name");
    } else if ([sortOption isEqual:@"quality"]) {
        return [_schema qualityNameForIndex:section];
    } else if ([sortOption isEqual:@"type"]) {
        return [_itemTypes objectAtIndex:section];
    } else {
        return nil;
    }
}

@end
