package {
	import flash.text.Font;
	import flash.text.TextFormat;	
	
	
	public class Fonts {
		[Embed(source="assets/font/ttf/Archer-BoldItalic.otf", fontFamily="Archer", embedAsCFF="false", mimeType="application/x-font")]
		private static var font:Class;
		
		public static function qText():TextFormat {
			var tf:TextFormat = new TextFormat();
			var tf_font:Font = new font();
			tf.font = tf_font.fontName;
			tf.color = 0xffffcc;
			tf.size = 54;
			return tf;
		}
		
		public static function authorName():TextFormat {
			var tf:TextFormat = new TextFormat();
			var tf_font:Font = new font();
			tf.font = tf_font.fontName;
			tf.color = 0xeeeeee;
			tf.size = 20;
			return tf;
		}
	}
}
