package org.calacademy.video.farallones.view {
	import flash.display.StageDisplayState;
	import flash.display.Stage;
	import org.casalib.util.StageReference;
	import org.calacademy.video.farallones.view.SecondaryButton;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	
	public class PanoramaButton extends SecondaryButton {
		public function PanoramaButton () {
			super();
		}
		
		public function showPano ():void {
			if (ExternalInterface.available) {
				// if fullscreen, pano switch is buggy
				var myStage:Stage = StageReference.getStage();
				myStage.displayState = StageDisplayState.NORMAL;
				
				ExternalInterface.call("switch_flash", "live", "krpano");
			}
		}
		
		override protected function _onClick (e:MouseEvent):void {
        	this.showPano();
		}
	}
}
