package org.calacademy.video.farallones.view {
	import flash.events.MouseEvent;
	import org.calacademy.video.farallones.view.SecondaryButton;
	import org.calacademy.video.events.ContentEvent;
	
	public class FullScreenButton extends SecondaryButton {
		public function FullScreenButton () {
			super();
		}
		
		override protected function _onClick (e:MouseEvent):void {
			this.dispatchEvent(new ContentEvent(ContentEvent.FULLSCREEN));
		}
	}
}
