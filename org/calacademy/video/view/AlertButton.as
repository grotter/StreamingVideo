package org.calacademy.video.view {
	import flash.display.DisplayObject;
	import org.casalib.display.CasaSprite;
	import org.casalib.util.StageReference;
	
	public class AlertButton extends CasaSprite {
		public var bg:DisplayObject;
		public var callback:Function;
		
		public function AlertButton () {
			super();
		}
	}
}
