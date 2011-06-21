package
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.SharedObject;
	import flash.net.SharedObjectFlushStatus;
	
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	public class PathManager {
		
		public static const PATH_TO_WEB_SERVER:String = "http://localhost/geo/allstations.xml";
		public static const DEFAULT_SELECTION:Object = new Object();
		private var so:SharedObject;
		
		public function PathManager() {
			so = SharedObject.getLocal("geoconfclient");
			//so.clear();
		}
		
		public function isInitialized():Boolean {
			var pweb:String = so.data.pathtoserver;
			var selstation:String = so.data.selstation;
			
			if(pweb == null) {
				so.data.pathtoserver = PATH_TO_WEB_SERVER;
			}
			
			if(selstation == null) {
				so.data.selstation = DEFAULT_SELECTION;
			}
			
			if(so.flush() == SharedObjectFlushStatus.FLUSHED) {
				return true;
			}
			else {
				return false;
			}
		}
		
		public function getPathToWebServerStations():String {
			return new String(so.data.pathtoserver);
		}

		public function getSelectedStation():Object {
			var ob:Object = (so.data.selstation);
			return ob;
		}
		
		public function getStationFilename():String {
			var ob:Object = (so.data.selstation);
			return ob.filename;
		}
		
		public function updatePaths(webpath:String):Boolean {
			so.data.pathtoserver = webpath;
			
			if(so.flush() == SharedObjectFlushStatus.FLUSHED) {
				return true;
			}
			else {
				return false;
			}
		}
		
		public function updateSelectedStation(ob:Object):Boolean {
			so.data.selstation = ob;
				
			if(so.flush() == SharedObjectFlushStatus.FLUSHED) {
				return true;
			}
			else {
				return false;
			}
		}
		
		public function writeConfigToLocal(xml:XML):Boolean {
			so.data.xmlselected = xml;
			
			if(so.flush() == SharedObjectFlushStatus.FLUSHED) {
				return true;
			}
			else {
				return false;
			}
		}
		
		public function getLocalConfig():XML {
			return so.data.xmlselected;
		}
	}
}