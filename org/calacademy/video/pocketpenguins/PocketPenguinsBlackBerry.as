package org.calacademy.video.pocketpenguins {
	import org.calacademy.video.pocketpenguins.PocketPenguins;
	import org.calacademy.video.pocketpenguins.view.Logo;
	import org.calacademy.video.Config;
	
	public class PocketPenguinsBlackBerry extends PocketPenguins {		
		private var _device:String = "z10";
		
		public function PocketPenguinsBlackBerry () {
			super(); 
		}
		
		override protected function _initStage ():void {
			super._initStage();
			
			if (Config.stageWidth == 720 && Config.stageHeight == 720) {
				_device = "q10";
				_resolution = 2;
			}
			
			if (Config.stageWidth == 1024 && Config.stageHeight == 600) {
				_device = "playbook";
			}
			
			if (_device == "z10") _resolution = 3;
		}
		
		override protected function _initLogo ():void {
			if (_resolution == 2) {
				_logo = (_device == "q10") ? new LogoMediumVertical() : new LogoMedium();
			} else {
				_logo = new Logo();
			}
		}
	}
}
