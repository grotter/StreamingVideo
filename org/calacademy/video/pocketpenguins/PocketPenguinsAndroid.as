package org.calacademy.video.pocketpenguins {
	import flash.events.Event;
	import flash.display.StageDisplayState;

	import org.calacademy.video.pocketpenguins.PocketPenguins;
	
	public class PocketPenguinsAndroid extends PocketPenguins {
		public function PocketPenguinsAndroid () {
			super();
		}

		override protected function _initStage ():void {
			super._initStage();

			if (_stage.allowsFullScreenInteractive) {
				_stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			} else {
				_stage.displayState = StageDisplayState.FULL_SCREEN;
			}

			_stage.addEventListener(Event.RESIZE, _onResize);
			_setStageDimensions();
		}

		private function _onResize (e:Event):void {
			_setStageDimensions();	
		}
	}
}
