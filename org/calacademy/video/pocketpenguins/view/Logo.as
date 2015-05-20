package org.calacademy.video.pocketpenguins.view {
	import org.casalib.display.CasaSprite;
	import com.greensock.TweenLite;
	import com.greensock.easing.*;

	public class Logo extends CasaSprite {		
		
		public function Logo () {
			super();
			this.cacheAsBitmap = true;
			
			/*
			this.alpha = 0;
			
			TweenLite.to(this, 1.2, {
				alpha: 1,
				ease: Expo.easeOut,
				delay: 1.8
			});
			*/
		}
	}
}
