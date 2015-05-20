package org.calacademy.video.view {
	import org.calacademy.video.Config;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.events.MouseEvent;
	import flash.display.MovieClip;
	import org.casalib.util.FlashVarUtil;
	import org.casalib.display.CasaSprite;
	
	public class Logo extends CasaSprite {
		public var hit_mc:MovieClip;
		
		public function Logo () {
			super();
			hit_mc.alpha = 0;
			hit_mc.buttonMode = true;
			hit_mc.addEventListener(MouseEvent.MOUSE_UP, _onMouseUp);   
		}
		
		public function removeMouseListener ():void {
			hit_mc.removeEventListener(MouseEvent.MOUSE_UP, _onMouseUp);
			hit_mc.buttonMode = false;
		}
		
		private function _onMouseUp (e:MouseEvent):void {
			var targ:String = FlashVarUtil.hasKey("windowTarget") ? FlashVarUtil.getValue("windowTarget") : "_top";
			navigateToURL(new URLRequest(Config.logoUrl), targ);
		}
	}
}
