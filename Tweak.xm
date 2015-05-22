@interface SBUIController : NSObject 
	+(id)sharedInstance;
	-(BOOL)isOnAC;
@end

@interface BluetoothManager
    +(id)sharedInstance;
    - (_Bool)connected;
    - (id)connectedDevices;
@end

@interface SBMediaController
	+(id)sharedInstance;
	- (_Bool)isPlaying;
@end

@interface SBWiFiManager
	-(id)sharedInstance;
@end

//Create the amIAnAlarm variable which will hold whether or not an alarm is being fired.
static BOOL amIAnAlarm = NO;

//iOS8
%hook SBClockDataProvider

	- (_Bool)_isAlarmNotification:(id)arg1 {
		//Set the amIAnAlarm variable based on whether or not an alarm is being fired.
		amIAnAlarm = %orig;
		//Return the original value.
		return %orig;
	}

%end

//iOS7
/*%hook SBAlertItem

	- (id)initWithLocalNotification:(id)arg1 forApplication:(id)arg2 {
		NSLog(@"ARGUMENT: %d", arg1);
		%orig;
	}
	
%end*/

%hook SBAlertItemsController

	- (void)activateAlertItem:(id)arg1 {
	
		//Erm, fill the pool? :-S
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		//Load the settings
		NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.richardlindsay.alarmrestrict7.plist"];
		
		//Create and set some variables
		BOOL disabled = YES;
		BOOL powerConnected = NO;
		BOOL powerDisconnected = NO;
		BOOL bluetoothConnected = NO;
		BOOL mediaPlaying = NO;
		BOOL wifiConnected = NO;

		//If all switches are set to off, then
		if ([[settings objectForKey:@"powerIsConnected"] boolValue] == NO && [[settings objectForKey:@"powerIsDisconnected"] boolValue] == NO && [[settings objectForKey:@"bluetoothIsConnected"] boolValue] == NO && [[settings objectForKey:@"mediaIsPlaying"] boolValue] == NO && [[settings objectForKey:@"connectedToWiFi"] boolValue] == NO) {
			//set the disabled variable to YES.
			disabled = YES;
		}
		else {
			//else set the disabled variable to NO.
			disabled = NO;
		}

		//If the "Power is connected" switch is enabled, then
		if ([[settings objectForKey:@"powerIsConnected"] boolValue] == YES) {
			
			//create the isPowerConnected variable and set the value to whether or not external power is connected or not.
			SBUIController *isPowerConnected = [objc_getClass("SBUIController") sharedInstance];
			
			//If power is connected, then
			if([isPowerConnected isOnAC]) {
				//set the powerConnected variable to YES
				powerConnected = YES;
			}
			else {
				//else, set powerConnected variable to NO.
				powerConnected = NO;
			}
		}

		//If the "Power is disconnected" switch is enabled, then
		if ([[settings objectForKey:@"powerIsDisconnected"] boolValue] == YES) {
			
			//create the isPowerDisconnected variable and set the value to whether or not external power is connected or not.
			SBUIController *isPowerDisconnected = [objc_getClass("SBUIController") sharedInstance];
			
			//If power is disconnected, then
			if(![isPowerDisconnected isOnAC]) {
				//set the powerDisconnected variable to YES
				powerDisconnected = YES;
			}
			else {
				//else, set powerDisconnected variable to NO.
				powerDisconnected = NO;
			}
		}
		
		//If the "Bluetooth is connected" switch is enabled, then
		if ([[settings objectForKey:@"bluetoothIsConnected"] boolValue] == YES) {

			//Create the connectedToDevice variable and set the value to the device text field in settings.
			NSString *connectedToDevice = [settings valueForKey:@"deviceName"];
			//Create the bm variable and set it to an instance of BluetoothManager
			BluetoothManager *bm = [objc_getClass("BluetoothManager") sharedInstance];

			//If the connectedToDevice variable contains a value
			if ([connectedToDevice length] != 0) {
				//loop through the connectedDevices array and look for an instance of the value stored in settings.
				for(id device in [bm connectedDevices]) {
					//If an instance of the value in settings exists in the array
					if([[device name] rangeOfString:connectedToDevice].location != NSNotFound) {
						//set the bluetoothConnected variable to YES
						bluetoothConnected = YES;
						NSString *connectedToBluetooth = [[bm connectedDevices] description];
						NSLog(@"Connected to device: %@", connectedToBluetooth);
					}
					else {
						//else, set the bluetoothConnected variable to NO.
						bluetoothConnected = NO;
					}
				}
			}
			else {
				if ([bm connected]) {
					//If it is connected to an external device, set the bluetoothConnected variable to YES
					bluetoothConnected = YES;
				}
				else {
					//else, set the bluetoothConnected variable to NO.
					bluetoothConnected = NO;
				}
			}
		}

		//If the "Media is playing" switch is enabled, then
		if ([[settings objectForKey:@"mediaIsPlaying"] boolValue] == YES) {
			
			//create the sbmc variable and set the value to whether or not media is playing.
			SBMediaController *sbmc = [%c(SBMediaController) sharedInstance];
			
			//If media is playing, then
			if ([sbmc isPlaying]) {
				//set the mediaPlaying variable to YES
				mediaPlaying = YES;
			}
			else {
				//else, set the mediaPlaying variable to NO.
				mediaPlaying = NO;
			}
		}

		//If the "Connected to Wi-Fi" switch is enabled, then
		if ([[settings objectForKey:@"connectedToWiFi"] boolValue] == YES) {

			//Create the connectedToSSID variable and set the value to SSID text field in settings.
			NSString *connectedToSSID = [settings valueForKey:@"ssidName"];
			//Create the sbwm variable and set it to an instance of SBWiFIManager
			SBWiFiManager *sbwm = [%c(SBWiFiManager) sharedInstance];
			
			//If the connectedToSSID variable contains a value
			if ([connectedToSSID length] != 0) {
				//create the connectedToNetwork variable and set it to the value of the currently connected to SSID.
				NSString *connectedToNetwork = [sbwm currentNetworkName];
				NSLog(@"Connected to network: %@", connectedToNetwork);

				//check to see if the entered SSID in settings matches the currently connected to SSID.
				if ([connectedToSSID isEqualToString:connectedToNetwork]) {
					//If it is, set the wifiConnected variable to YES
					wifiConnected = YES;
				}
				else {
					//else, set the wifiConnected variable to NO.
					wifiConnected = NO;
				}
			}
			else {
				if ([sbwm isAssociated]) {
					wifiConnected = YES;
				}
				else {
					//else, set the wifiConnected variable to NO.
					wifiConnected = NO;
				}	
			}
		}

		//If the disabled variable is equal to YES, then
		if (disabled == YES) {
			//fire the default method.
			%orig;
		}
		//If the powerConnected, powerDisconnected, bluetoothConnected, mediaPlaying and wifiConnected variables equal NO, then
		else if (powerConnected == NO && powerDisconnected == NO && bluetoothConnected == NO && mediaPlaying == NO && wifiConnected == NO) {
			//fire the default method.
			%orig;
		}
		//If either the powerConnected, powerDisconnected, bluetoothConnected, mediaPlaying or wifiConnected variables equal YES, then
		else {
			if (amIAnAlarm == NO) {
				%orig;
			}
			else {
				//Do nothing
			}
		}

		//Release the settings and
		[settings release];
		//drain the pool :-S
		[pool drain];
	}

%end
