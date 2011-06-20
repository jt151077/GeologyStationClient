import air.net.URLMonitor;
import air.update.ApplicationUpdaterUI;
import air.update.events.UpdateEvent;

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
	
	if(NativeWindow.supportsMenu) {
		stage.nativeWindow.menu = createRootMenu();
	}
	if (NativeApplication.supportsMenu) {
		NativeApplication.nativeApplication.menu = createRootMenu();
	}
	
	var appXml:XML = NativeApplication.nativeApplication.applicationDescriptor;
	var ns:Namespace = appXml.namespace(); 
	FlexGlobals.topLevelApplication.status = "Intermedia (UiO) 2011 - Version "+(appXml.ns::versionNumber).toString();
	
	monitor = new URLMonitor(new URLRequest("http://10.0.2.1/allstations.xml"));
	monitor.addEventListener(StatusEvent.STATUS, handleMonitorStatus);
	monitor.start();
}

private function handleMonitorStatus(evt:StatusEvent):void {
	if(monitor.available) {
		//we're connected
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
		enableReloadConfigButton = false;
		loadLocalConfig();
	}
}

private function loadLocalConfig():void {
	
	monitor.stop();
	monitor.removeEventListener(StatusEvent.STATUS, handleMonitorStatus);
	
	iWaiter.visible = false;
}

private function initAppUdpateFinished(evt:UpdateEvent):void {
	appUpdater.checkNow();
	
	pathManager = new PathManager();
	
	if(pathManager.isInitialized()) {
		fetchConfigs.url = pathManager.getPathToWebServer();
		fetchConfigs.send();
	}
}

private function onAppUpdateError(event:ErrorEvent):void {
	Alert.show(event.toString());
}

private function createRootMenu():NativeMenu {
	var menu:NativeMenu = new NativeMenu();
	menu.addItem(fileMenu());
	return menu;
}

private function fileMenu():NativeMenuItem {
	var fileMenu:NativeMenuItem = new NativeMenuItem ("File");
	fileMenu.submenu = new NativeMenu();
	
	var confItem:NativeMenuItem = new NativeMenuItem ("Configure...");
	confItem.addEventListener(Event.SELECT, onSelectItem);
	confItem.keyEquivalent = "t";
	fileMenu.submenu.addItem(confItem);
	
	var prefsItem:NativeMenuItem = new NativeMenuItem ("Preferences...");
	prefsItem.addEventListener(Event.SELECT, onSelectItem);
	prefsItem.keyEquivalent = "p";
	fileMenu.submenu.addItem(prefsItem);
	
	var exitItem:NativeMenuItem = new NativeMenuItem ("Exit");
	exitItem.addEventListener(Event.SELECT, onSelectItem);
	exitItem.keyEquivalent = "q";
	fileMenu.submenu.addItem(exitItem);
	
	return fileMenu;
}

private function onSelectItem(e:Event):void {
	var item:NativeMenuItem = e.target as NativeMenuItem
		
	switch(item.label) {
		case "Configure...":
			retrieveLastChosenStation();
			
			this.currentState = "configuration";
			break;
		case "Preferences...":
//						vidPath.text = pathManager.getPathToVids();
//						filePath.text = pathManager.getPathToWebServer();
//						configPanel.visible = true;
			break;
		case "Exit":
			FlexGlobals.topLevelApplication.close();
			break;
	}			
}

private function retrieveLastChosenStation():void {
	var prevSelectedObject:Object;
	
	prevSelectedObject = pathManager.getSelectedStation();
	
	for (var j:int = 0; j < availableStations.length; j++) {
		if((availableStations[j]).name == prevSelectedObject.name) {
			stationListSelectedIndex = j;
		}
	}
}

protected function fetchConfigs_faultHandler(event:FaultEvent):void {
	iWaiter.visible = false;
	
	Alert.show("Error while retrieving the configurations", "FetchConfigs service error");
	
	if(pathManager.getPathToWebServer() != fetchConfigs.url) {
		fetchConfigs.url = pathManager.getPathToWebServer();
		fetchConfigs.send();
	}
}

protected function fetchConfigs_resultHandler(event:ResultEvent):void {
	if(pathManager.getPathToWebServer() != fetchConfigs.url) {
		pathManager.updatePaths(fetchConfigs.url);
	}
	
	var xml:XML = event.result as XML;
	availableStations = new ArrayCollection();
	for each (var object:XML in xml.*) {
		availableStations.addItem(object);
	}	
	
	monitor.stop();
	monitor.removeEventListener(StatusEvent.STATUS, handleMonitorStatus);
	iWaiter.visible = false;
}

protected function button1_clickHandler(event:MouseEvent):void {
	fetchConfigs.url = urlWS.text;
	fetchConfigs.send();
}

protected function button2_clickHandler(event:MouseEvent):void {
	if(stationList.selectedIndex > -1) {
		if(pathManager.updateSelectedStation(stationList.selectedItem)) {
			Alert.show("Station changed successfully", "Change station");
		}
		else {
			Alert.show("A problem occurred when saving the station", "Change station");
		}
		
		this.currentState = "presentation";
	}
}

protected function stationList_changeHandler(event:IndexChangeEvent):void {
	if(stationList.selectedIndex > -1) {
		okChangeConfigButton.enabled = true;
	}
	else {
		okChangeConfigButton.enabled = false;
	}
}

protected function loadChosenConfig_resultHandler(event:ResultEvent):void {
	var xml:XML = event.result as XML;
}

protected function loadChosenConfig_faultHandler(event:FaultEvent):void {
	Alert.show("Error while loading your chosen configuration", "Load configuration service error");
}

protected function group1_clickHandler(event:MouseEvent):void {
	if(systemManager.stage.displayState == flash.display.StageDisplayState.FULL_SCREEN) {
		nativeWindow.maximize();
	}
	else {
		systemManager.stage.displayState = flash.display.StageDisplayState.FULL_SCREEN;
	}
	
}
