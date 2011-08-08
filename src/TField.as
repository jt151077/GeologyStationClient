package  {
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	public class TField extends TextField {
		
		private var tForm:TextFormat;
		
		public function TField(tFormat:TextFormat, w:Number, h:Number = 0, sharp:Number = 20, thick:Number = -20, sel:Boolean = false){
			this.embedFonts = true;
			this.multiline = true;
			this.autoSize = TextFieldAutoSize.CENTER;
			this.selectable = true;
			this.mouseEnabled = true;
			this.antiAliasType = AntiAliasType.ADVANCED;
			this.sharpness = sharp;
			this.thickness = thick;
			
			if(w != 0){
				if(h != 0){
					this.autoSize = TextFieldAutoSize.NONE;
					this.height = h;
				}
				this.wordWrap = true;
				this.width = w;
			}
			
			tForm = tFormat;
		}
		
		public function set content(textContent:String):void {
			this.text = textContent;
			tForm.align = TextFormatAlign.CENTER;
			this.setTextFormat(tForm);
		}
		
		public function get content():String {
			return this.text;
		}
		
		public function set centerSizing(b:Boolean):void {
			this.autoSize = (b) ? TextFieldAutoSize.CENTER : TextFieldAutoSize.LEFT;
			this.setTextFormat(tForm);
		}
		
		public function set tFormat(form:TextFormat):void {
			tForm = form;
			this.setTextFormat(tForm);
		}
	}
}

