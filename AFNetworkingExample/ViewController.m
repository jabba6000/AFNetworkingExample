//
//  ViewController.m
//  AFNetworkingExample
//
//  Created by Uri Fuholichev on 10/15/16.
//  Copyright © 2016 Andrei Karpenia. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking.h>
// добавили строку адреса осн страницы
static NSString * const BaseURLString = @"http://www.raywenderlich.com/demos/weather_sample/";

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UITableView *myTableView;
//__block перед немутабельным объектом делаем его изменяемым
@property (strong, nonatomic) __block NSArray *weather;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)jsonTapped:(UIButton *)sender {
    // Создаем строку для адреса ресурса
    NSString *string = [NSString stringWithFormat:@"%@weather.php?format=json", BaseURLString];
    NSURL *url = [NSURL URLWithString:string];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // теперь подгруженные данные будут хранится в responseObject - это либо словарь, либо массив
    [manager GET:url.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        //выполним проверку на то, словарь пришел или массив
        if ([responseObject isKindOfClass:[NSArray class]]) {
            NSLog(@"It's an Array");
        } else if ([responseObject isKindOfClass:[NSDictionary class]]) {
            //пришел словарь. По ключам доходим до нужного нам массива
            NSDictionary *dictionary = responseObject;
            NSDictionary *data = [dictionary objectForKey:@"data"];
            _weather = [data objectForKey:@"weather"];
            [_myTableView reloadData];
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell" forIndexPath:indexPath];
    cell.textLabel.text = [[_weather objectAtIndex:indexPath.row] objectForKey:@"date"];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_weather count];
}

@end
