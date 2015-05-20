package org.calacademy.video.farallones.view {
	import org.casalib.display.CasaSprite;
	import com.greensock.easing.Expo;
	import com.greensock.TweenLite;
	import flash.events.Event;

	public class ControlIndicator extends CasaSprite {
		protected var _enabled:Boolean = false;
		public var onStage:Boolean = false;
		
		public function ControlIndicator () {
			super();
			this.enabled = false;
			this.addEventListener(Event.ADDED_TO_STAGE, _onAdded);
			this.addEventListener(Event.REMOVED_FROM_STAGE, _onRemoved);
		}
		
		protected function _onAdded (e:Event):void {
			this.onStage = true;
			
			TweenLite.killTweensOf(this);
			this.alpha = 0;
			var myAlpha:Number = this.enabled ? 1 : .5;
			
			TweenLite.to(this, 1, {
				alpha: myAlpha,
				delay: .2,
				ease: Expo.easeOut
			});
		}
		
		protected function _onRemoved (e:Event):void {
			this.onStage = false;
			reset();
			
			TweenLite.killTweensOf(this);
			this.alpha = 0;
		}
		
		public function get enabled ():Boolean {
			return _enabled;
		}
		
		public function set enabled (boo:Boolean):void {
			var myAlpha:Number = boo ? 1 : .5;
			TweenLite.killTweensOf(this);
			
			TweenLite.to(this, 1, {
				alpha: myAlpha,
				ease: Expo.easeOut
			});
			
			_enabled = boo;
		}
		
		public function reset ():void {}
		
		public function update (data:Object):void {}
	}
}
