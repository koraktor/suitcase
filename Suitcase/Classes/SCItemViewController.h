//
//  SCDetailViewController.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"

#import "SCClassImageView.h"
#import "SCItem.h"
#import "SCItemImageCell.h"

@interface SCItemViewController : UICollectionViewController <UIActionSheetDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISplitViewControllerDelegate, TTTAttributedLabelDelegate>

@property (strong, nonatomic) id <SCItem> item;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *wikiButton;

- (IBAction)showItemSet:(id)sender;
- (IBAction)showWikiPage:(id)sender;

@end
