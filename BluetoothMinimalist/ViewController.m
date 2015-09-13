//
//  ViewController.m
//  BluetoothMinimalist
//
//  Created by Myles Caley on 9/11/15.
//  Copyright (c) 2015 FirstBuild. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, retain) CBCentralManager* cm;
@property (nonatomic, retain) CBPeripheral* p;
@property (strong,nonatomic) NSMutableDictionary* characteristics;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _cm = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - <CBCentralManagerDelegate>

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"central state changed, nothing to do %ld", (long)central.state);
    }
    else if (central.state == CBCentralManagerStatePoweredOn) {
        NSLog(@"central powered on");
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"a495ff10-c5b1-4b44-b512-1370f02d74de"];
        [_cm scanForPeripheralsWithServices:[NSArray arrayWithObject:uuid] options:nil];

    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if ([[peripheral.identifier UUIDString] isEqualToString:@"DAE19E5A-A7E9-BADA-5538-A356660EF734"])
    {
        _p = peripheral;
        _p.delegate = self;
        [_cm connectPeripheral:_p options:nil];
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"peripheral connected... %@", [peripheral.identifier UUIDString]);
    _p = peripheral;
    _p.delegate = self;
    [_p discoverServices:nil];
}

#pragma mark - <CBPeripheralDelegate>

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    _p = peripheral;
    _p.delegate = self;
    NSArray * services;
    services = [_p services];
    for (CBService *service in services)
    {
        [_p discoverCharacteristics:nil forService:service];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
    NSLog(@"=======================================================================");
    NSLog(@"SERVICE %@", [service.UUID UUIDString]);
    
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        [self.characteristics setObject:characteristic forKey:[characteristic.UUID UUIDString]];
        NSLog(@"    CHARACTERISTIC %@", [characteristic.UUID UUIDString]);
        
        if (characteristic.properties & CBCharacteristicPropertyWrite)
        {
            NSLog(@"        CAN WRITE");
        }
        
        if (characteristic.properties & CBCharacteristicPropertyNotify)
        {
            if  (
                 [[[characteristic UUID] UUIDString] isEqualToString: @"A495FF11-C5B1-4B44-B512-1370F02D74DE"]
                 )
            {
                [_p readValueForCharacteristic:characteristic];
                [_p setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            NSLog(@"        CAN NOTIFY");
        }
        
        if (characteristic.properties & CBCharacteristicPropertyRead)
        {
            NSLog(@"        CAN READ");
        }
        
        if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse)
        {
            NSLog(@"        CAN WRITE WITHOUT RESPONSE");
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"characteristic %@ notification failed %@", characteristic.UUID, error);
        return;
    }
    
    NSLog(@"characteristic %@ , notifying: %s", characteristic.UUID, characteristic.isNotifying ? "true" : "false");
    
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"got data %@", characteristic.value);
}


@end
