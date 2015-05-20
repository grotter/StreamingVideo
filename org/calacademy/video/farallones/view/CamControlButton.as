package org.calacademy.video.farallones.view {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import org.casalib.display.CasaSprite;
	import com.greensock.TweenLite;
	import com.greensock.easing.Expo;
	
	public class CamControlButton extends CasaSprite {
		public var bg_mc:MovieClip;
		private var _enabled:Boolean = true;
		
		public function CamControlButton () {
			super();
			this.enabled = true;
		}
		
		public function get enabled ():Boolean {
			return _enabled;
		}
		
		public function set enabled (boo:Boolean):void {
			this.buttonMode = boo;
			this.useHandCursor = boo;
			
			if (boo) {
				this.addEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown); 
				this.addEventListener(MouseEvent.MOUSE_UP, _onMouseUp);
			} else {
				this.removeEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown); 
				this.removeEventListener(MouseEvent.MOUSE_UP, _onMouseUp);
			}
			
			var myAlpha:Number = boo ? 1 : .5;
			TweenLite.killTweensOf(this);
			
			TweenLite.to(this, 1, {
				alpha: myAlpha,
				ease: Expo.easeOut
			});
			
			_enabled = boo;
		}
		
		private function _onMouseDown (e:MouseEvent):void {
			this.bg_mc.gotoAndStop(2);
		}
		
		private function _onMouseUp (e:MouseEvent):void {
			this.bg_mc.gotoAndStop(1);
		}
	}
}
