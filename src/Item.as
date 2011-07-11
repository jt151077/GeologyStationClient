package
{
	[Bindable]
	public class Item {
		
		private var _xml:XML;
		private var _name:String;
		private var _type:String;
		private var _question:String;
		private var _sound:String;
		private var _picture:String;
		private var _rfidArray:Array;
		
		public function Item(xml:XML) {
			if(xml != null) {
				_xml = xml;
				this._name = new String(xml.name);
				this._type = new String(xml.type);
				this._question = new String(xml.question);
				this._sound = new String(xml.sound);
				this._picture = new String(xml.picture);
				
				_rfidArray = new Array();
				var rfidXML:XMLList = xml.rfid;
				for each (var tag:XML in rfidXML.*) {
					_rfidArray.push(new String(tag));
				}
			}
		}
		
		public function get videoName():String {
			return _name;
		}
		
		public function get question():String {
			return _question;
		}
		
		public function get picture():String {
			return _picture;
		}
		
		public function get sound():String {
			return _sound;
		}
		
		public function get type():String {
			return _type;
		}
		
		public function get rfids():Array {
			return _rfidArray;
		}
	}
}