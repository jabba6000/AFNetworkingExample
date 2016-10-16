//
//  ViewController.m
//  AFNetworkingExample
//
//  Created by Uri Fuholichev on 10/15/16.
//  Copyright © 2016 Andrei Karpenia. All rights reserved.
//
/*
http://www.raywenderlich.com/demos/weather_sample/weather.php?format=json
http://www.raywenderlich.com/demos/weather_sample/weather.php?format=xml
http://www.raywenderlich.com/demos/weather_sample/weather.php?format=plist
*/

//это чтобы картинки подгружать асинхронно
#import "UIImageView+AFNetworking.h"

#import "ViewController.h"
#import <AFNetworking.h>
// добавили строку адреса осн страницы
static NSString * const BaseURLString = @"http://www.raywenderlich.com/demos/weather_sample/";

@interface ViewController () <NSXMLParserDelegate>

@property (strong, nonatomic) IBOutlet UITableView *myTableView;
//__block перед немутабельным объектом делаем его изменяемым
@property (strong, nonatomic) __block NSArray *weather;

//Свойства для парсинга XML
@property(nonatomic, strong) NSMutableDictionary *currentDictionary;   // current section being parsed
@property(nonatomic, strong) NSMutableDictionary *xmlWeather;          // completed parsed xml response
@property(nonatomic, strong) NSString *elementName;
@property(nonatomic, strong) NSMutableString *outstring;
//////////
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

//Для JSON данных
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
        NSLog(@"Error JSON: %@", error);
    }];
}

//здесь мы еще добавим лэйзи довнлоад (асинхронный) подгрузку картинок
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell" forIndexPath:indexPath];
    cell.textLabel.text = [[_weather objectAtIndex:indexPath.row] objectForKey:@"date"];
    
    //Этот код отвечает за асинхронную подгрузку картинок
    NSURL *url = [NSURL URLWithString:[[[[_weather objectAtIndex:indexPath.row] objectForKey: @"weatherIconUrl"] objectAtIndex:0] objectForKey: @"value"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    UIImage *placeholderImage = [UIImage imageNamed:@"placeholder"];
    
    __weak UITableViewCell *weakCell = cell;
    
    // здесь success и failure блоки являются опциональными, но если их не объявить, то не будет сразу выравнивания 
    [cell.imageView setImageWithURLRequest:request
                          placeholderImage:placeholderImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       
                                       weakCell.imageView.image = image;
                                       [weakCell setNeedsLayout];
                                       
                                   } failure:nil];
    ///////////

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_weather count];
}

//для plist. plist - это тот же формат XML, только структурированных по логике от Apple
- (IBAction)plistTapped:(UIButton *)sender {
    //создаем строку адреса
    NSString *string = [NSString stringWithFormat:@"%@weather.php?format=plist", BaseURLString];
    NSURL *url = [NSURL URLWithString:string];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

    //ЗДЕСЬ ЕЩЕ НУЖНО ЯВНО УКАЗАТЬ СЕРИЛИЗАТОР
    manager.responseSerializer = [AFPropertyListResponseSerializer serializer];
    
    // теперь подгруженные данные будут хранится в responseObject - это либо словарь, либо массив
    [manager GET:url.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSLog(@"PLIST: %@", responseObject);
        //выполним проверку на то, словарь пришел или массив
        if ([responseObject isKindOfClass:[NSArray class]]) {
            NSLog(@"It's an Array");
        } else if ([responseObject isKindOfClass:[NSDictionary class]]) {
            //пришел словарь. По ключам доходим до нужного нам массива
            NSLog(@"It's a dictionary");
            NSDictionary *dictionary = responseObject;
            NSDictionary *data = [dictionary objectForKey:@"data"];
            _weather = [data objectForKey:@"weather"];
            [_myTableView reloadData];
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error plist: %@", error);
    }];
}

//Теперь для XML
- (IBAction)xmpTapped:(UIButton *)sender {
    NSString *string = [NSString stringWithFormat:@"%@weather.php?format=xml", BaseURLString];
    NSURL *url = [NSURL URLWithString:string];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
    
    [manager GET:url.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        
        //Вместо NSDictionary на этот раз приходит экземпляр NSXMLParser
         NSXMLParser *XMLParser = (NSXMLParser *)responseObject;
        [XMLParser setShouldProcessNamespaces:YES];
         XMLParser.delegate = self;
         [XMLParser parse];
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error XML: %@", error);
    }];
}

#pragma mark - NSXMLParserDelegateMethods

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    self.xmlWeather = [NSMutableDictionary dictionary];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    self.elementName = qName;
    
    if([qName isEqualToString:@"current_condition"] ||
       [qName isEqualToString:@"weather"] ||
       [qName isEqualToString:@"request"]) {
        self.currentDictionary = [NSMutableDictionary dictionary];
    }
    
    self.outstring = [NSMutableString string];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!self.elementName)
        return;
    
    [self.outstring appendFormat:@"%@", string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // 1
    if ([qName isEqualToString:@"current_condition"] ||
        [qName isEqualToString:@"request"]) {
        self.xmlWeather[qName] = @[self.currentDictionary];
        self.currentDictionary = nil;
    }
    // 2
    else if ([qName isEqualToString:@"weather"]) {
        
        // Initialize the list of weather items if it doesn't exist
        NSMutableArray *array = self.xmlWeather[@"weather"] ?: [NSMutableArray array];
        
        // Add the current weather object
        [array addObject:self.currentDictionary];
        
        // Set the new array to the "weather" key on xmlWeather dictionary
        self.xmlWeather[@"weather"] = array;
        
        self.currentDictionary = nil;
    }
    // 3
    else if ([qName isEqualToString:@"value"]) {
        // Ignore value tags, they only appear in the two conditions below
    }
    // 4
    else if ([qName isEqualToString:@"weatherDesc"] ||
             [qName isEqualToString:@"weatherIconUrl"]) {
        NSDictionary *dictionary = @{@"value": self.outstring};
        NSArray *array = @[dictionary];
        self.currentDictionary[qName] = array;
    }
    // 5
    else if (qName) {
        self.currentDictionary[qName] = self.outstring;
    }
    
    self.elementName = nil;
}

- (void) parserDidEndDocument:(NSXMLParser *)parser {
    //первая команда засунет распарсенный словарь xmlWeather внутрь словаря data под ключ "data"
    // это делается, чтобы сохранить изначальную структуру по аналогии с PLIST b JSON
    NSDictionary *data = @{@"data": self.xmlWeather};
    NSDictionary *allData = [data objectForKey:@"data"];
    _weather = [allData objectForKey:@"weather"];
    
    NSLog(@"XML weather array is %lu", (unsigned long)[_weather count]);
    [self.myTableView reloadData];
}

@end
