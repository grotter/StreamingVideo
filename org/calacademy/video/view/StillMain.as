package org.calacademy.video.view {
	import org.casalib.display.CasaSprite;
	import org.casalib.util.RatioUtil;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import org.calacademy.video.Config;
	
	public class StillMain extends CasaSprite {		
		private var _originalDimensions:Object;
		
		public function StillMain () {
			super();
			
			_originalDimensions = {
				w: this.width,
				h: this.height
			};
			
			this.visible = false;
			
			this.addEventListener(Event.ADDED_TO_STAGE, _onAdded); 
		}
		
		private function _onAdded (e:Event):void {
			resize();
			this.visible = true;
		}
        
		public function resize ():void {
			// fill stage
			var mySize:Rectangle = new Rectangle(0, 0, _originalDimensions.w, _originalDimensions.h);
			var bounds:Rectangle = new Rectangle(0, 0, Config.stageWidth, Config.stageHeight);
			var result:Rectangle = RatioUtil.scaleToFill(mySize, bounds);
			
			this.width = result.width;
			this.height = result.height;
			
			this.x = Math.round((Config.stageWidth - this.width) / 2);
			this.y = Math.round((Config.stageHeight - this.height) / 2);
		}
	}
}
