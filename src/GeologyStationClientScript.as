import air.net.URLMonitor;
import air.update.ApplicationUpdaterUI;
import air.update.events.UpdateEvent;

import com.phidgets.PhidgetRFID;
import com.phidgets.events.PhidgetDataEvent;

import flash.desktop.NativeApplication;
import flash.display.NativeMenu;
import flash.display.NativeMenuItem;
import flash.display.NativeWindow;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.StatusEvent;
import flash.filesystem.File;
import flash.net.URLRequest;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.core.FlexGlobals;
import mx.events.FlexEvent;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;

import spark.events.IndexChangeEvent;

private var fileRef:File;
private var vidsArray:Array = new Array();
private var pathManager:PathManager;

[Bindable] private var availableStations:ArrayCollection;
[Bindable] private var stationListSelectedIndex:Number;

[Bindable] private var enableReloadConfigButton:Boolean = true;

private var monitor:URLMonitor;
private var appUpdater:ApplicationUpdaterUI;

protected function windowedapplication1_applicationCompleteHandler(event:FlexEvent):void {
	systemManager.stage.displayState=flash.display.StageDisplayState.FULL_SCREEN;
	
	//building some application menus
	if(NativeWindow.supportsMenu) {
		stage.nativeWindow.menu = createRootMenu();
	}
	if (NativeApplication.supportsMenu) {
		NativeApplication.nativeApplication.menu = createRootMenu();
	}
	
	//fetch application version from XML description file and set it in the application footer
	var appXml:XML = NativeApplication.nativeApplication.applicationDescriptor;
	var ns:Namespace = appXml.namespace(); 
	FlexGlobals.topLevelApplication.status = "Intermedia (UiO) 2011 - Version "+(appXml.ns::versionNumber).toString();
	
	//instantiate the path manager
	pathManager = new PathManager();
	if(pathManager.isInitialized()) {
		//check if we have a connection to the server
		//monitor = new URLMonitor(new URLRequest("http://xxx"));
		monitor = new URLMonitor(new URLRequest(pathManager.getPathToWebServerStations()));
		monitor.addEventListener(StatusEvent.STATUS, handleMonitorStatus);
		monitor.start();
	}
	else {
		//something weird happened with the pathManager class, maybe let the user know
	}
}

private function handleMonitorStatus(evt:StatusEvent):void {
	if(monitor.available) {
		//we're connected to the server
		//check if there's an update available
		connectStatus.text = "online";
		appUpdater = new ApplicationUpdaterUI();
		appUpdater.delay = 1;
		appUpdater.updateURL = "http://10.0.2.1/client/update.xml";
		appUpdater.isCheckForUpdateVisible = false;
		appUpdater.isDownloadUpdateVisible = true;
		appUpdater.isDownloadProgressVisible = true;
		appUpdater.isInstallUpdateVisible = true;
		appUpdater.addEventListener(ErrorEvent.ERROR, onAppUpdateError);
		appUpdater.addEventListener(UpdateEvent.INITIALIZED, initAppUdpateFinished);
		appUpdater.initialize();
	}
	else {
		//we're offline
		connectStatus.text = "offline";
		//enableReloadConfigButton = false;
		parseLocalConfiguration();
	}
}

private function initAppUdpateFinished(evt:UpdateEvent):void {
	appUpdater.checkNow();
	
	//let's retrieve all available stations from the server
	fetchConfigs.url = pathManager.getPathToWebServerStations();
	fetchConfigs.send();
}

private function onAppUpdateError(event:ErrorEvent):void {
	Alert.show(event.toString());
}

//create root menu
private function createRootMenu():NativeMenu {
	var menu:NativeMenu = new NativeMenu();
	menu.addItem(fileMenu());
	return menu;
}

//create sub menus + menu selection listeners
private function fileMenu():NativeMenuItem {
	var fileMenu:NativeMenuItem = new NativeMenuItem ("File");
	fileMenu.submenu = new NativeMenu();
	
	var confItem:NativeMenuItem = new NativeMenuItem ("Configure...");
	confItem.addEventListener(Event.SELECT, onSelectItem);
	confItem.keyEquivalent = "t";
	fileMenu.submenu.addItem(confItem);
	
	var exitItem:NativeMenuItem = new NativeMenuItem ("Exit");
	exitItem.addEventListener(Event.SELECT, onSelectItem);
	exitItem.keyEquivalent = "q";
	fileMenu.submenu.addItem(exitItem);
	
	return fileMenu;
}

//menu selection handler
private function onSelectItem(e:Event):void {
	var item:NativeMenuItem = e.target as NativeMenuItem
		
	switch(item.label) {
		case "Preferences...":
			//we need to display or update the display here
//						vidPath.text = pathManager.getPathToVids();
//						filePath.text = pathManager.getPathToWebServer();
//						configPanel.visible = true;
			break;
		case "Configure...":
			//look for a previously selected station
			geologisequencer.vidPlayer.source = null;
			retrieveLastChosenStation();
			this.currentState = "configuration";
			break;
		case "Exit":
			//bye-bye
			FlexGlobals.topLevelApplication.close();
			break;
	}			
}

//try to check if the station name saved locally can be found in the loaded allstations array.
private function retrieveLastChosenStation():void {
	var prevSelectedObject:Object;
	
	prevSelectedObject = pathManager.getSelectedStation();
	
	if(availableStations != null && availableStations.length > 0) {
		for (var j:int = 0; j < availableStations.length; j++) {
			if((availableStations[j]).name == prevSelectedObject.name) {
				stationListSelectedIndex = j;
			}
		}
	}
}

//something wrong happened when retrieving the allstations URL. If available, automatically revert and reload previous path
protected function fetchConfigs_faultHandler(event:FaultEvent):void {
	iWaiter.visible = false;
	
	Alert.show("Error while retrieving the configurations", "FetchConfigs service error");
	
	if(pathManager.getPathToWebServerStations() != fetchConfigs.url) {
		fetchConfigs.url = pathManager.getPathToWebServerStations();
		fetchConfigs.send();
	}
}

//allstations URL handler
protected function fetchConfigs_resultHandler(event:ResultEvent):void {
	//that worked, let's save it
	if(pathManager.getPathToWebServerStations() != fetchConfigs.url) {
		pathManager.updatePaths(fetchConfigs.url);
	}
	
	//iterate through the stations in that file
	var xml:XML = event.result as XML;
	availableStations = new ArrayCollection();
	for each (var object:XML in xml.*) {
		availableStations.addItem(object);
	}	
	
	//try update with latest from server
	if(pathManager.getStationFilename() != null) {
		//we try to update the config
		trace("let's update: "+pathManager.getStationFilename());
		loadConfiguration();
	}
	else {
		//no config has been chosen, maybe switch to config panel
	}
}

//load config locally, either after an update or directly because offline
private function parseLocalConfiguration():void {
	monitor.stop();
	monitor.removeEventListener(StatusEvent.STATUS, handleMonitorStatus);
	iWaiter.visible = false;
	
	//retieve local XML
	if(pathManager.getLocalConfig() != null) {
		//we have a local config available
		var xml:XML = pathManager.getLocalConfig();
		
		var item:Item;
		var sequenceArray:ArrayCollection = new ArrayCollection();
		for each (var object:XML in xml.sequence.*) {
			item = new Item(object);
			sequenceArray.addItem(item);
		}
		
		geologisequencer.initSequencer(sequenceArray);
	}
	else {
		//not local config available and no connection, we can't do anything
	}
}

//reloading the allstations
protected function button1_clickHandler(event:MouseEvent):void {
	fetchConfigs.url = urlWS.text;
	fetchConfigs.send();
}

//validating station selection
protected function button2_clickHandler(event:MouseEvent):void {
	if(stationList.selectedIndex > -1) {
		if(pathManager.updateSelectedStation(stationList.selectedItem)) {
			Alert.show("Station changed successfully", "Change station");
			connectStatus.text = "online";
			//reloading stationconfiguration
			loadConfiguration();
		}
		else {
			Alert.show("A problem occurred when saving the station", "Change station");
		}
		
		this.currentState = "presentation";
	}
}

protected function button3_clickHandler(event:MouseEvent):void {
	loadConfiguration();
	this.currentState = "presentation";
}


protected function windowedapplication1_closingHandler(event:Event):void {
	geologisequencer.rfid.close();
}


//re-/load configuration from server 
private function loadConfiguration():void {
	loadChosenConfig.url = new String(pathManager.getPathToWebServerStations()).replace("allstations.xml", pathManager.getStationFilename());
	//loadChosenConfig.url = "http://10.0.2.1/"+pathManager.getStationFilename();
	loadChosenConfig.send();
}

//button status handler if selection is made
protected function stationList_changeHandler(event:IndexChangeEvent):void {
	if(stationList.selectedIndex > -1) {
		okChangeConfigButton.enabled = true;
	}
	else {
		okChangeConfigButton.enabled = false;
	}
}

//result handler for loading a station configuration
protected function loadChosenConfig_resultHandler(event:ResultEvent):void {
	var xml:XML = event.result as XML;
	
	//write the xml first locally
	if(pathManager.writeConfigToLocal(xml)) {
		//if successful parse it
		parseLocalConfiguration();
	}
}

//error handler for station configuration loader
protected function loadChosenConfig_faultHandler(event:FaultEvent):void {
	Alert.show("Error while loading your chosen configuration", "Load configuration service error");
}

//display state handler
protected function group1_clickHandler(event:MouseEvent):void {
	if(systemManager.stage.displayState == flash.display.StageDisplayState.FULL_SCREEN) {
		nativeWindow.maximize();
	}
	else {
		systemManager.stage.displayState = flash.display.StageDisplayState.FULL_SCREEN;
	}
	
}
