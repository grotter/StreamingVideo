package org.calacademy.video.view {
	import flash.geom.Rectangle;
	import com.greensock.TweenLite;
	import com.greensock.easing.*;
	import org.casalib.display.CasaSprite;	
	import org.calacademy.video.Config;
	import flash.events.Event;
	
	public class SnapShot extends CasaSprite {		
		public function SnapShot () {
			super();
			this.graphics.beginFill(0xffffff);
			this.graphics.drawRect(0, 0, Config.stageWidth, Config.stageHeight);
			
			this.addEventListener(Event.ADDED_TO_STAGE, _onAdded);
			this.addEventListener(Event.REMOVED_FROM_STAGE, _onRemoved);
		}
		
		private function _onAdded (e:Event):void {
			TweenLite.killTweensOf(this);
			this.alpha = 1;
			
			var snd:ShutterClick = new ShutterClick();
			snd.play();
			
			var inst:SnapShot = this;
			
			TweenLite.to(this, 1, {
				alpha: 0,
				delay: .3,
				ease: Expo.easeOut,
				onComplete: function () {
					inst.destroy();
				}
			});
		}
		
		private function _onRemoved (e:Event):void {}
	}
}
