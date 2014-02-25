//
//  RMUBlogViewController.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 2/24/14.
//  Copyright (c) 2014 Blake Ellingham. All rights reserved.
//

#import "RMUBlogViewController.h"

@interface RMUBlogViewController ()

@property (weak, nonatomic) IBOutlet UILabel *blogName;
@property (weak, nonatomic) IBOutlet UILabel *blogURL;
@property (weak, nonatomic) IBOutlet UIWebView *blogWebView;

@end

@implementation RMUBlogViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadBlogURL:self.blogURLString];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadBlogURL:(NSString*)blogURL
{
    NSLog(@"%@ bloggy bloggers", blogURL);
    NSString *fullURL =[NSString stringWithFormat:(@"http://%@"),blogURL];
    NSURL *url = [NSURL URLWithString:fullURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.blogWebView loadRequest:request];
    [self.blogName setText:blogURL];
}


- (IBAction)dismissController:(id)sender
{
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                
                             }];
}

@end
