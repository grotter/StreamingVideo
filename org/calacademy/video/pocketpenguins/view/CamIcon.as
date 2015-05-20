package org.calacademy.video.pocketpenguins.view {
	import org.casalib.display.CasaMovieClip;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.display.Stage;
	import org.casalib.util.StageReference;
	import org.calacademy.video.events.ContentEvent;
	import org.calacademy.video.Config;
	
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	public class CamIcon extends CasaMovieClip {		
		private var _hitWidth:int = Math.round(Config.stageWidth / 2);
		private var _stage:Stage;
		private var _keyEnabled:Boolean = true;
		
		public function CamIcon () {
			super();
			_stage = StageReference.getStage();
			this.cacheAsBitmap = true;
			this.active = false;
			this.x = Config.stageWidth;
			this.enable(true);
			
			this.addEventListener(Event.ADDED_TO_STAGE, _onAdded);
		}
		
		public function set keyEnabled (boo:Boolean):void {
			_keyEnabled = boo;
			if (!boo) this.active = false;
		}
		
		private function _onAdded (e:Event):void {
			this.graphics.beginFill(0, 0);
			this.graphics.drawRect(-_hitWidth / this.scaleX, 0, _hitWidth / this.scaleX, Config.stageHeight);
			this.graphics.endFill();
		}
		
		private function _onKey (e:KeyboardEvent):void {
			if (!_keyEnabled) return;
			
			// for devices with listenable hardware keys
			switch (e.keyCode) {
				case Keyboard.MENU:
					e.preventDefault();
					e.stopImmediatePropagation();
					
					if (e.type == "keyUp") {
						_onUp(e, true);
					} else if (e.type == "keyDown") {
						_onDown(e, true);
					}
                    
					break;
			}
		}
		
		public function set active (boo:Boolean):void {
			var frame:int = boo ? 2 : 1;
			this.gotoAndStop(frame);
		}
		
		/**
		 *	Using a MOUSE_UP handler on the stage instead of the button itself
		 *  since we need to capture the equivalent of "onReleaseOutside"
		 */
		public function enable (boo:Boolean):void {
			if (boo) {
				this.addEventListener(MouseEvent.MOUSE_DOWN, _onDown);
				_stage.addEventListener(KeyboardEvent.KEY_DOWN, _onKey);
			} else {
				this.removeEventListener(MouseEvent.MOUSE_DOWN, _onDown);
				_stage.removeEventListener(MouseEvent.MOUSE_UP, _onUp);
				_stage.removeEventListener(KeyboardEvent.KEY_DOWN, _onKey);
				_stage.removeEventListener(KeyboardEvent.KEY_UP, _onKey);
			}
		}
		
		private function _onDown (e:*, isKey:Boolean = false):void {
			this.active = true;
			
			if (isKey) {
				_stage.addEventListener(KeyboardEvent.KEY_UP, _onKey);
			} else {
				_stage.addEventListener(MouseEvent.MOUSE_UP, _onUp);
			}
		}
		
		private function _onUp (e:*, isKey:Boolean = false):void {
			if (isKey) {
				_stage.removeEventListener(KeyboardEvent.KEY_UP, _onKey);
			} else {
				_stage.removeEventListener(MouseEvent.MOUSE_UP, _onUp);
			}

			this.active = false;
			this.dispatchEvent(new ContentEvent(ContentEvent.SELECT));
		}
	}
}
