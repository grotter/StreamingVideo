package org.calacademy.video.pocketpenguins.view {
	import flash.events.Event;
	import flash.display.MovieClip;
	import org.casalib.display.CasaMovieClip;
	import org.casalib.util.ArrayUtil;
	import com.greensock.TweenLite;
	import com.greensock.easing.*;
	import org.calacademy.video.Config;
	
	public class MoneyButton extends CasaMovieClip {		
		private var _defaultFrameLabel:String = "buy-tickets";
		private var _validFrameLabels:Array = ["sms", "buy-tickets", "donate-online"];
		public var label:String = "";
		public var wiggle_mc:MovieClip;
		
		public function MoneyButton () {
			super();
			this.y = Config.stageHeight;
			this.cacheAsBitmap = true;
			
			this.addEventListener(Event.ADDED_TO_STAGE, _onAdded);
		}
		
		override public function play ():void {
			this.wiggle_mc.gotoAndPlay(2);
		}
		
		private function _onAdded (e:Event):void {
			this.play();
		}
		
		public function setGraphic (frameLabel:String):void {
			if (ArrayUtil.contains(_validFrameLabels, frameLabel) == 0) {
				// invalid
				this.label = _defaultFrameLabel;
			} else {
				this.label = frameLabel;
			}
			
			this.gotoAndStop(this.label);
		}
	}
}
