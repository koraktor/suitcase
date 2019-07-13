//
//  SCDetailViewController.h
//  Suitcase
//
//  Copyright (c) 2012-2016, Sebastian Staudt
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"

#import "SCClassImageView.h"
#import "SCItem.h"
#import "SCItemImageCell.h"
#import "SCSharingController.h"

@interface SCItemViewController : UICollectionViewController <SCSharingController, UIActionSheetDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISplitViewControllerDelegate, TTTAttributedLabelDelegate>

@property (strong, nonatomic) id <SCItem> item;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *wikiButton;

- (IBAction)showWikiPage:(id)sender;

@end
