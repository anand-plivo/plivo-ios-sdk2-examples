//
//  ContactsViewController.m
//  ObjCVoiceCallingApp
//
//  Created by Siva  on 12/04/17.
//  Copyright © 2017 Plivo. All rights reserved.
//

#import "ContactsViewController.h"
#import "PlivoCallController.h"
#import "APContact.h"
#import "APAddressBook.h"
#import "UtilityClass.h"
#import "Constants.h"
#import "LoginViewController.h"
#import "AppDelegate.h"
#import "CallKitInstance.h"
#import "UIView+Toast.h"
#import <Google/SignIn.h>

@interface ContactsViewController ()<PlivoEndpointDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating>

@property (nonatomic, strong) APAddressBook *addressBook;
@property (nonatomic, strong) NSArray *phoneContacts;
@property (nonatomic, strong) NSArray *sipEndPoints;
@property (nonatomic, strong) NSArray *sipEmailIds;

@property (weak, nonatomic) IBOutlet UITableView* contactsTableView;
@property (weak, nonatomic) IBOutlet UILabel* noContactsLabel;

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *phoneSearchResults;
@property (nonatomic, strong) NSMutableArray *sipSearchResults;
@property (nonatomic, strong) UISegmentedControl *contactsSegmentControl;

// for state restoration
@property BOOL searchControllerWasActive;
@property BOOL searchControllerSearchFieldWasFirstResponder;
@property BOOL isSearchControllerActive;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;

@property (nonatomic, strong) NSArray *sipDetailsArray;

- (IBAction)logoutButtonTapped:(id)sender;

@end

@implementation ContactsViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.addressBook = [[APAddressBook alloc] init];
        __weak typeof(self) weakSelf = self;
        [self.addressBook startObserveChangesWithCallback:^
         {
             [weakSelf loadContacts];
         }];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self loadContacts];
    
    self.sipEndPoints = [[NSUserDefaults standardUserDefaults] objectForKey:kSIPENDPOINTS];
    self.sipEmailIds = [[NSUserDefaults standardUserDefaults] objectForKey:kSIPEMAILIDS];

    self.sipDetailsArray = [[NSUserDefaults standardUserDefaults] objectForKey:kSIPDETAILS];
    
    if(self.sipEndPoints.count > 0)
    {
        NSArray *itemArray = [NSArray arrayWithObjects: @"Phone", @"SIP", nil];
        
        // Create UISegmentedControl object to add control UISegment.
        self.contactsSegmentControl = [[UISegmentedControl alloc] initWithItems:itemArray];
        
        // Set frame for objSegment Control (formate: (x, y, width, height)). where, y = (height of view - height of control).
        [self.contactsSegmentControl setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width * 0.28125, 27, [UIScreen mainScreen].bounds.size.width * 0.4375, 29)];
        
        // handle UISegmentedControl action.
        [self.contactsSegmentControl addTarget:self action:@selector(handleSegmentControl:) forControlEvents: UIControlEventValueChanged];
        
        self.contactsSegmentControl.selectedSegmentIndex = 0;
        
        [self.view addSubview:self.contactsSegmentControl];
            
    }
    else
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width * 0.28125, 27, [UIScreen mainScreen].bounds.size.width * 0.4375, 29)];
        label.text = @"Contacts";
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:17];
        [self.view addSubview:label];
    }
    
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    [self.searchController.searchBar sizeToFit];
    self.contactsTableView.tableHeaderView = self.searchController.searchBar;
    
    // We want ourselves to be the delegate for this filtered table so didSelectRowAtIndexPath is called for both tables.
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO; // default is YES
    self.searchController.searchBar.delegate = self; // so we can monitor text changes + others
    
    // Search is now just presenting a view controller. As such, normal view controller
    // presentation semantics apply. Namely that presentation will walk up the view controller
    // hierarchy until it finds the root view controller or one that defines a presentation context.
    //
    self.definesPresentationContext = YES;  // know where you want UISearchController to be displayed


}

- (void)handleSegmentControl:(UISegmentedControl *)segment
{
    [self.contactsTableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    [[Phone sharedInstance] setDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // restore the searchController's active state
    if (self.searchControllerWasActive) {
        self.searchController.active = self.searchControllerWasActive;
        _searchControllerWasActive = NO;
        
        if (self.searchControllerSearchFieldWasFirstResponder) {
            [self.searchController.searchBar becomeFirstResponder];
            _searchControllerSearchFieldWasFirstResponder = NO;
        }
    }
}


#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}


#pragma mark - UISearchControllerDelegate

// Called after the search controller's search bar has agreed to begin editing or when
// 'active' is set to YES.
// If you choose not to present the controller yourself or do not implement this method,
// a default presentation is performed on your behalf.
//
// Implement this method if the default presentation is not adequate for your purposes.
//
- (void)presentSearchController:(UISearchController *)searchController {
    
}

- (void)willPresentSearchController:(UISearchController *)searchController {
    // do something before the search controller is presented
    self.isSearchControllerActive = YES;
    
}

- (void)didPresentSearchController:(UISearchController *)searchController {
    // do something after the search controller is presented
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    // do something before the search controller is dismissed
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    // do something after the search controller is dismissed
    
    self.isSearchControllerActive = NO;

}

#pragma mark - PlivoEndPoint Delegates
    /**
     * onLogin delegate implementation.
     */
- (void)onLogin
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.view makeToast:kLOGINSUCCESS];
        
    });
    NSLog(@"Ready to make a call");
        
}
    
    /**
     * onLoginFailed delegate implementation.
     */
- (void)onLoginFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{
            
        [self.view makeToast:kLOGINFAILMSG];

        [UtilityClass setUserAuthenticationStatus:NO];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUSERNAME];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPASSWORD];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[GIDSignIn sharedInstance] signOut];

        UIStoryboard *_mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        LoginViewController* loginVC = [_mainStoryboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [[Phone sharedInstance] setDelegate:loginVC];
        
        AppDelegate *_appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        _appDelegate.window.rootViewController = loginVC;

        
    });
    
}


#pragma mark - private

- (void)loadContacts
{
    self.phoneContacts = nil;
    __weak __typeof(self) weakSelf = self;
    self.addressBook.fieldsMask = APContactFieldAll;
    self.addressBook.sortDescriptors = @[
                                         [NSSortDescriptor sortDescriptorWithKey:@"name.firstName" ascending:YES],
                                         [NSSortDescriptor sortDescriptorWithKey:@"name.lastName" ascending:YES]];
    self.addressBook.filterBlock = ^BOOL(APContact *contact)
    {
        return contact.phones.count > 0;
    };
    [self.addressBook loadContacts:^(NSArray<APContact *> *contacts, NSError *error) {
        if (contacts)
        {
            weakSelf.phoneContacts = contacts;
            
            if(weakSelf.phoneContacts > 0)
            {
                self.noContactsLabel.hidden = YES;
                [self.view bringSubviewToFront:self.contactsTableView];
                [weakSelf.contactsTableView reloadData];

            }else{
             
                self.noContactsLabel.hidden = NO;
                [self.view bringSubviewToFront:self.noContactsLabel];
            }
            
        }
        else if (error)
        {
            NSLog(@"No contacts");
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.f;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.isSearchControllerActive)
    {
        if(self.contactsSegmentControl.selectedSegmentIndex == 0)
        {
            return self.phoneSearchResults.count;
        }
        else
        {
            return self.sipSearchResults.count;
        }
    }else
    {
        if(self.contactsSegmentControl)
        {
            if(self.contactsSegmentControl.selectedSegmentIndex == 0)
            {
                return self.phoneContacts.count;
                
            }
            else
            {
                return self.sipDetailsArray.count;
                
            }
        }
        else
        {
            return self.phoneContacts.count;
        }
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(self.isSearchControllerActive)
    {
        if(self.contactsSegmentControl.selectedSegmentIndex == 0)
        {
            
            static NSString *editprofileIdentifier = @"CallHistory";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:editprofileIdentifier];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:editprofileIdentifier];
                
            }
            
            APContact* contact = self.phoneSearchResults[(NSUInteger)indexPath.row];

            cell.textLabel.text = [self contactName:contact];
            cell.detailTextLabel.text = [self contactPhones:contact];
            cell.imageView.image = [UIImage imageNamed:@"TabbarIcon1"];

            return cell;

        }
        else
        {
            static NSString *editprofileIdentifier = @"CallHistory";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:editprofileIdentifier];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:editprofileIdentifier];
                
            }
            
            NSDictionary* sipDict = self.sipSearchResults[indexPath.row];
            
            cell.textLabel.text  = [sipDict[@"eMail"] capitalizedString];
            cell.detailTextLabel.text = sipDict[@"endPoint"];;
            cell.imageView.image = [UIImage imageNamed:@"TabbarIcon1"];
            
            return cell;
        }
    }
    else
    {
        if(self.contactsSegmentControl)
        {
            if(self.contactsSegmentControl.selectedSegmentIndex == 0)
            {

                static NSString *editprofileIdentifier = @"CallHistory";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:editprofileIdentifier];
                if (cell == nil)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:editprofileIdentifier];
                    
                }
                
                APContact* contact = self.phoneContacts[(NSUInteger)indexPath.row];
                
                cell.textLabel.text = [self contactName:contact];
                cell.detailTextLabel.text = [self contactPhones:contact];
                cell.imageView.image = [UIImage imageNamed:@"TabbarIcon1"];
                
                return cell;

            }
            else
            {
                static NSString *editprofileIdentifier = @"CallHistory";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:editprofileIdentifier];
                if (cell == nil)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:editprofileIdentifier];
                    
                }
                
                NSDictionary* sipDict = self.sipDetailsArray[indexPath.row];
                
                cell.textLabel.text  = [sipDict[@"eMail"] capitalizedString];
                cell.detailTextLabel.text = sipDict[@"endPoint"];;
                cell.imageView.image = [UIImage imageNamed:@"TabbarIcon1"];
                
                return cell;
            }
        }
        else
        {
            static NSString *editprofileIdentifier = @"CallHistory";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:editprofileIdentifier];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:editprofileIdentifier];
                
            }
            
            APContact* contact = self.phoneContacts[(NSUInteger)indexPath.row];
            
            cell.textLabel.text = [self contactName:contact];
            cell.detailTextLabel.text = [self contactPhones:contact];
            cell.imageView.image = [UIImage imageNamed:@"TabbarIcon1"];
            
            return cell;
            
        }
    }
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(self.isSearchControllerActive)
    {
        if(self.contactsSegmentControl.selectedSegmentIndex == 0)
        {
            
            APContact* contactDetails = self.phoneSearchResults[(NSUInteger)indexPath.row];
            APPhone* apPhoneObj = contactDetails.phones[0];
            NSString *phoneNumber = [apPhoneObj.number stringByReplacingOccurrencesOfString:@"\\s"
                                                                                 withString:@""
                                                                                    options:NSRegularExpressionSearch
                                                                                      range:NSMakeRange(0, apPhoneObj.number.length)];
            
            PlivoCallController* plivoVC = [self.tabBarController.viewControllers objectAtIndex:2];
            [[Phone sharedInstance] setDelegate:plivoVC];
            [CallKitInstance sharedInstance].callUUID = [NSUUID UUID];
            [plivoVC performStartCallActionWithUUID:[CallKitInstance sharedInstance].callUUID handle:phoneNumber];
            self.tabBarController.selectedViewController = [self.tabBarController.viewControllers objectAtIndex:2];

        }
        else
        {
            NSDictionary* sipDict = self.sipSearchResults[indexPath.row];
            
            PlivoCallController* plivoVC = [self.tabBarController.viewControllers objectAtIndex:2];
            [[Phone sharedInstance] setDelegate:plivoVC];
            [CallKitInstance sharedInstance].callUUID = [NSUUID UUID];
            [plivoVC performStartCallActionWithUUID:[CallKitInstance sharedInstance].callUUID handle:sipDict[@"endPoint"]];
            self.tabBarController.selectedViewController = [self.tabBarController.viewControllers objectAtIndex:2];        }
    }else
    {
        if(self.contactsSegmentControl)
        {
            if(self.contactsSegmentControl.selectedSegmentIndex == 0)
            {

                APContact* contactDetails = self.phoneContacts[(NSUInteger)indexPath.row];
                APPhone* apPhoneObj = contactDetails.phones[0];
                NSString *phoneNumber = [apPhoneObj.number stringByReplacingOccurrencesOfString:@"\\s"
                                                                                     withString:@""
                                                                                        options:NSRegularExpressionSearch
                                                                                          range:NSMakeRange(0, apPhoneObj.number.length)];
                
                PlivoCallController* plivoVC = [self.tabBarController.viewControllers objectAtIndex:2];
                [[Phone sharedInstance] setDelegate:plivoVC];
                [CallKitInstance sharedInstance].callUUID = [NSUUID UUID];
                [plivoVC performStartCallActionWithUUID:[CallKitInstance sharedInstance].callUUID handle:phoneNumber];
                self.tabBarController.selectedViewController = [self.tabBarController.viewControllers objectAtIndex:2];
            }
            else
            {
                NSDictionary* sipDict = self.sipDetailsArray[indexPath.row];
    
                PlivoCallController* plivoVC = [self.tabBarController.viewControllers objectAtIndex:2];
                [[Phone sharedInstance] setDelegate:plivoVC];
                [CallKitInstance sharedInstance].callUUID = [NSUUID UUID];
                [plivoVC performStartCallActionWithUUID:[CallKitInstance sharedInstance].callUUID handle:sipDict[@"endPoint"]];
                self.tabBarController.selectedViewController = [self.tabBarController.viewControllers objectAtIndex:2];
                
            }
        }
        else
        {
            APContact* contactDetails = self.phoneContacts[(NSUInteger)indexPath.row];
            APPhone* apPhoneObj = contactDetails.phones[0];
            NSString *phoneNumber = [apPhoneObj.number stringByReplacingOccurrencesOfString:@"\\s"
                                                                                 withString:@""
                                                                                    options:NSRegularExpressionSearch
                                                                                      range:NSMakeRange(0, apPhoneObj.number.length)];
            
            PlivoCallController* plivoVC = [self.tabBarController.viewControllers objectAtIndex:2];
            [[Phone sharedInstance] setDelegate:plivoVC];
            [CallKitInstance sharedInstance].callUUID = [NSUUID UUID];
            [plivoVC performStartCallActionWithUUID:[CallKitInstance sharedInstance].callUUID handle:phoneNumber];
            self.tabBarController.selectedViewController = [self.tabBarController.viewControllers objectAtIndex:2];        }
    }
    
    
    
}

- (IBAction)logoutButtonTapped:(id)sender
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Logout"
                                 message:@"Are you sure you want to logout?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Yes"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle your yes please button action here
                                    
                                    PlivoCallController* plivoVC = [self.tabBarController.viewControllers objectAtIndex:2];
                                    [[Phone sharedInstance] setDelegate:plivoVC];
                                    [plivoVC unRegisterSIPEndpoit];
                                    self.tabBarController.selectedViewController = [self.tabBarController.viewControllers objectAtIndex:2];
                                    
                                }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"No"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle no, thanks button
                               }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // update the filtered array based on the search text
    NSString *searchText = searchController.searchBar.text;
    
    if(self.contactsSegmentControl.selectedSegmentIndex == 0)
    {
        self.phoneSearchResults = [self.phoneContacts mutableCopy];

        // strip out all the leading and trailing spaces
        NSString *strippedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // break up the search terms (separated by spaces)
        NSArray *searchItems = nil;
        if (strippedString.length > 0)
        {
            searchItems = [strippedString componentsSeparatedByString:@" "];
        }
        
        // build all the "AND" expressions for each value in the searchString
        //
        NSMutableArray *andMatchPredicates = [NSMutableArray array];
        
        for (NSString *searchString in searchItems) {
            // each searchString creates an OR predicate for: name, yearIntroduced, introPrice
            //
            // example if searchItems contains "iphone 599 2007":
            //      name CONTAINS[c] "iphone"
            //      name CONTAINS[c] "599", yearIntroduced ==[c] 599, introPrice ==[c] 599
            //      name CONTAINS[c] "2007", yearIntroduced ==[c] 2007, introPrice ==[c] 2007
            //
            NSMutableArray *searchItemsPredicate = [NSMutableArray array];
            
            // Below we use NSExpression represent expressions in our predicates.
            // NSPredicate is made up of smaller, atomic parts: two NSExpressions (a left-hand value and a right-hand value)
            
            // name field matching
            NSExpression *lhs = [NSExpression expressionForKeyPath:@"name.compositeName"];
            NSExpression *rhs = [NSExpression expressionForConstantValue:searchString];
            NSPredicate *finalPredicate = [NSComparisonPredicate
                                           predicateWithLeftExpression:lhs
                                           rightExpression:rhs
                                           modifier:NSDirectPredicateModifier
                                           type:NSContainsPredicateOperatorType
                                           options:NSCaseInsensitivePredicateOption];
            [searchItemsPredicate addObject:finalPredicate];
            
            // yearIntroduced field matching
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            numberFormatter.numberStyle = NSNumberFormatterNoStyle;
            NSNumber *targetNumber = [numberFormatter numberFromString:searchString];
            if (targetNumber != nil) {   // searchString may not convert to a number
                lhs = [NSExpression expressionForKeyPath:@"phones"];
                rhs = [NSExpression expressionForConstantValue:targetNumber];
                finalPredicate = [NSComparisonPredicate
                                  predicateWithLeftExpression:lhs
                                  rightExpression:rhs
                                  modifier:NSDirectPredicateModifier
                                  type:NSEqualToPredicateOperatorType
                                  options:NSCaseInsensitivePredicateOption];
                [searchItemsPredicate addObject:finalPredicate];
                
            }
            
            // at this OR predicate to our master AND predicate
            NSCompoundPredicate *orMatchPredicates = [NSCompoundPredicate orPredicateWithSubpredicates:searchItemsPredicate];
            [andMatchPredicates addObject:orMatchPredicates];
        }
        
        // match up the fields of the Product object
        NSCompoundPredicate *finalCompoundPredicate =
        [NSCompoundPredicate andPredicateWithSubpredicates:andMatchPredicates];
        self.phoneSearchResults = [[self.phoneSearchResults filteredArrayUsingPredicate:finalCompoundPredicate] mutableCopy];
    }
    else
    {
        self.sipSearchResults = [self.sipDetailsArray mutableCopy];

        // strip out all the leading and trailing spaces
        NSString *strippedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // break up the search terms (separated by spaces)
        NSArray *searchItems = nil;
        if (strippedString.length > 0) {
            searchItems = [strippedString componentsSeparatedByString:@" "];
        }
        
        // build all the "AND" expressions for each value in the searchString
        //
        NSMutableArray *andMatchPredicates = [NSMutableArray array];
        
        for (NSString *searchString in searchItems) {
            // each searchString creates an OR predicate for: name, yearIntroduced, introPrice
            //
            // example if searchItems contains "iphone 599 2007":
            //      name CONTAINS[c] "iphone"
            //      name CONTAINS[c] "599", yearIntroduced ==[c] 599, introPrice ==[c] 599
            //      name CONTAINS[c] "2007", yearIntroduced ==[c] 2007, introPrice ==[c] 2007
            //
            NSMutableArray *searchItemsPredicate = [NSMutableArray array];
            
            // Below we use NSExpression represent expressions in our predicates.
            // NSPredicate is made up of smaller, atomic parts: two NSExpressions (a left-hand value and a right-hand value)
            
            // name field matching
            NSExpression *lhs = [NSExpression expressionForKeyPath:@"eMail"];
            NSExpression *rhs = [NSExpression expressionForConstantValue:searchString];
            NSPredicate *finalPredicate = [NSComparisonPredicate
                                           predicateWithLeftExpression:lhs
                                           rightExpression:rhs
                                           modifier:NSDirectPredicateModifier
                                           type:NSContainsPredicateOperatorType
                                           options:NSCaseInsensitivePredicateOption];
            [searchItemsPredicate addObject:finalPredicate];
            
            // yearIntroduced field matching
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            numberFormatter.numberStyle = NSNumberFormatterNoStyle;
            NSNumber *targetNumber = [numberFormatter numberFromString:searchString];
            if (targetNumber != nil) {   // searchString may not convert to a number
                lhs = [NSExpression expressionForKeyPath:@"endPoint"];
                rhs = [NSExpression expressionForConstantValue:targetNumber];
                finalPredicate = [NSComparisonPredicate
                                  predicateWithLeftExpression:lhs
                                  rightExpression:rhs
                                  modifier:NSDirectPredicateModifier
                                  type:NSEqualToPredicateOperatorType
                                  options:NSCaseInsensitivePredicateOption];
                [searchItemsPredicate addObject:finalPredicate];
                
            }
            
            // at this OR predicate to our master AND predicate
            NSCompoundPredicate *orMatchPredicates = [NSCompoundPredicate orPredicateWithSubpredicates:searchItemsPredicate];
            [andMatchPredicates addObject:orMatchPredicates];
        }
        
        // match up the fields of the Product object
        NSCompoundPredicate *finalCompoundPredicate =
        [NSCompoundPredicate andPredicateWithSubpredicates:andMatchPredicates];
        self.sipSearchResults = [[self.sipSearchResults filteredArrayUsingPredicate:finalCompoundPredicate] mutableCopy];
    }
    
    [self.contactsTableView reloadData];
}


#pragma mark - UIStateRestoration

// we restore several items for state restoration:
//  1) Search controller's active state,
//  2) search text,
//  3) first responder

NSString *const ViewControllerTitleKey = @"ViewControllerTitleKey";
NSString *const SearchControllerIsActiveKey = @"SearchControllerIsActiveKey";
NSString *const SearchBarTextKey = @"SearchBarTextKey";
NSString *const SearchBarIsFirstResponderKey = @"SearchBarIsFirstResponderKey";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    // encode the view state so it can be restored later
    
    // encode the title
    [coder encodeObject:self.title forKey:ViewControllerTitleKey];
    
    UISearchController *searchController = self.searchController;
    
    // encode the search controller's active state
    BOOL searchDisplayControllerIsActive = searchController.isActive;
    [coder encodeBool:searchDisplayControllerIsActive forKey:SearchControllerIsActiveKey];
    
    // encode the first responser status
    if (searchDisplayControllerIsActive) {
        [coder encodeBool:[searchController.searchBar isFirstResponder] forKey:SearchBarIsFirstResponderKey];
    }
    
    // encode the search bar text
    [coder encodeObject:searchController.searchBar.text forKey:SearchBarTextKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    // restore the title
    self.title = [coder decodeObjectForKey:ViewControllerTitleKey];
    
    // restore the active state:
    // we can't make the searchController active here since it's not part of the view
    // hierarchy yet, instead we do it in viewWillAppear
    //
    _searchControllerWasActive = [coder decodeBoolForKey:SearchControllerIsActiveKey];
    
    // restore the first responder status:
    // we can't make the searchController first responder here since it's not part of the view
    // hierarchy yet, instead we do it in viewWillAppear
    //
    _searchControllerSearchFieldWasFirstResponder = [coder decodeBoolForKey:SearchBarIsFirstResponderKey];
    
    // restore the text in the search field
    self.searchController.searchBar.text = [coder decodeObjectForKey:SearchBarTextKey];
}

- (NSString *)contactName:(APContact *)contact
{
    if (contact.name.compositeName)
    {
        return contact.name.compositeName;
    }
    else if (contact.name.firstName && contact.name.lastName)
    {
        return [NSString stringWithFormat:@"%@ %@", contact.name.firstName, contact.name.lastName];
    }
    else if (contact.name.firstName || contact.name.lastName)
    {
        return contact.name.firstName ?: contact.name.lastName;
    }
    else
    {
        return @"Untitled contact";
    }
}

- (NSString *)contactPhones:(APContact *)contact
{
    if (contact.phones.count > 0)
    {
        APPhone* phoneNum = contact.phones[0];
        return phoneNum.number;
    }
    else
    {
        return @"(No phones)";
    }
}

- (NSString *)contactEmails:(APContact *)contact
{
    if (contact.emails.count > 1)
    {
        NSMutableString *result = [[NSMutableString alloc] init];
        for (APEmail *email in contact.emails)
        {
            [result appendFormat:@"%@, ", email.address];
        }
        return result;
    }
    else
    {
        return contact.emails.count == 1 ? contact.emails[0].address : @"(No emails)";
    }
}

@end


//                NSString *identifier = NSStringFromClass(ContactTableViewCell.class);
//                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier
//                                                                        forIndexPath:indexPath];
//                if ([cell isKindOfClass:ContactTableViewCell.class])
//                {
//                    NSDictionary* sipDict = self.sipDetailsArray[indexPath.row];
//
//                    ContactTableViewCell *contactCell = (ContactTableViewCell *)cell;
//
//                    contactCell.nameLabel.text = [sipDict[@"eMail"] capitalizedString];
//                    contactCell.phonesLabel.text = sipDict[@"endPoint"];
//
//
//                }

//            NSString *identifier = NSStringFromClass(ContactTableViewCell.class);
//            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier
//                                                                    forIndexPath:indexPath];
//            if ([cell isKindOfClass:ContactTableViewCell.class])
//            {
//                NSDictionary* sipDict = self.sipSearchResults[indexPath.row];
//
//                ContactTableViewCell *contactCell = (ContactTableViewCell *)cell;
//
//                contactCell.nameLabel.text = [sipDict[@"eMail"] capitalizedString];
//                contactCell.phonesLabel.text = sipDict[@"endPoint"];
//
//            }

//        NSMutableString *result = [[NSMutableString alloc] init];
//        for (APPhone *phone in contact.phones)
//        {
//            NSString *string = phone.localizedLabel.length == 0 ? phone.number :
//                               [NSString stringWithFormat:@"%@ (%@)", phone.number,
//                                                          phone.localizedLabel];
//            [result appendFormat:@"%@, ", string];
//        }
//        return result;

//            NSString *identifier = NSStringFromClass(ContactTableViewCell.class);
//            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier
//                                                                    forIndexPath:indexPath];
//            if ([cell isKindOfClass:ContactTableViewCell.class])
//            {
//                ContactTableViewCell *contactCell = (ContactTableViewCell *)cell;
//                [contactCell updateWithContact:self.phoneSearchResults[(NSUInteger)indexPath.row]];
//            }
//            return cell;
//                NSString *identifier = NSStringFromClass(ContactTableViewCell.class);
//                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier
//                                                                        forIndexPath:indexPath];
//                if ([cell isKindOfClass:ContactTableViewCell.class])
//                {
//                    ContactTableViewCell *contactCell = (ContactTableViewCell *)cell;
//                    [contactCell updateWithContact:self.phoneContacts[(NSUInteger)indexPath.row]];
//                }
//                return cell;
//            NSString *identifier = NSStringFromClass(ContactTableViewCell.class);
//            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier
//                                                                    forIndexPath:indexPath];
//            if ([cell isKindOfClass:ContactTableViewCell.class])
//            {
//                ContactTableViewCell *contactCell = (ContactTableViewCell *)cell;
//                [contactCell updateWithContact:self.phoneContacts[(NSUInteger)indexPath.row]];
//            }
//            return cell;
