package org.calacademy.video.view {
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import org.casalib.display.CasaMovieClip;
	import com.greensock.TweenLite;
	import com.greensock.easing.Expo;
	import org.casalib.util.StageReference;
	
	public class SecondaryButton extends CasaMovieClip {
		private var _clickable:Boolean = true;
		private var _stage:Stage = StageReference.getStage();
		
		public function SecondaryButton () {
			super();
			this.clickable = true;
		}
		
		public function get clickable ():Boolean {
			return _clickable;
		}
		
		public function set clickable (boo:Boolean):void {
			this.buttonMode = boo;
			this.useHandCursor = boo;
			
			if (boo) {
				this.addEventListener(MouseEvent.MOUSE_UP, _onClick);
				this.addEventListener(MouseEvent.MOUSE_OVER, _onOver);
				this.addEventListener(MouseEvent.MOUSE_OUT, _onOut);
			} else {
				this.removeEventListener(MouseEvent.MOUSE_UP, _onClick); 
				this.removeEventListener(MouseEvent.MOUSE_OVER, _onOver);
				this.removeEventListener(MouseEvent.MOUSE_OUT, _onOut);
			}
			
			var myAlpha:Number = boo ? 1 : .5;
			TweenLite.killTweensOf(this);
			
			TweenLite.to(this, 1, {
				alpha: myAlpha,
				ease: Expo.easeOut
			});
			
			_clickable = boo;
			_onOut(null);
		}
		
		private function _onOver (e:MouseEvent):void {
			this.gotoAndStop(2);
		}
		
		private function _onOut (e:MouseEvent):void {
			this.gotoAndStop(1);
		}
		
		protected function _onClick (e:MouseEvent):void {
			// override
		}
	}
}
