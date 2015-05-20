package org.calacademy.video.view {
	import flash.text.*;
	import flash.display.Bitmap;
	import flash.filters.DropShadowFilter;
	import flash.filters.BevelFilter; 
	import flash.filters.BitmapFilterQuality; 
	import flash.filters.BitmapFilterType;
	import org.casalib.display.CasaSprite;
	import org.calacademy.video.view.Alert;
	import org.calacademy.display.DefaultTextField;
	
	public class ScreenGrabForm extends Alert {
		private var _name_txt:DefaultTextField;
		private var _location_txt:DefaultTextField;
		private var _still:Bitmap;
		
		public function ScreenGrabForm (isMedium:Boolean = false) {
			super(isMedium);
			_contentOffset = _padding * 2;
		}
		
		public function getFields ():* {
			if (_name_txt == null || _location_txt == null) return false;
			
			return {
				name: _name_txt,
				location: _location_txt
			};
		}
		
		public function set still (myStill:Bitmap):void {
			_still = myStill;
            _still.smoothing = true;
            
			var targetWidth:Number = 150;
			var per:Number = targetWidth / _still.width;
			_still.width = Math.round(targetWidth);
			_still.height = Math.round(per * _still.height);
			
			// drop shadow
			var dropShadow:DropShadowFilter = new DropShadowFilter();
			dropShadow.angle = 0;
			dropShadow.alpha = .4;
			dropShadow.distance = 3;
			dropShadow.blurX = 20;
			dropShadow.blurY = 20;

			_still.filters = new Array(dropShadow);
		}
		
		override protected function _getButtonWidth ():int {
			return _isMedium ? 350 : 250;
		}
		
		override protected function _placeButtons (txtContainer:CasaSprite = null):void {
			// place buttons
			_buttons.x = _still.width + _still.x + _padding;
			_buttons.y = _location_txt.y + _location_txt.height + _padding;
			_buttons.y += _isMedium ? 20 : 15;
		}
		
		override protected function _addExtraContent (container:CasaSprite):void {
			_name_txt = new DefaultTextField();
			_location_txt = new DefaultTextField(); 
			_styleField(_name_txt);
			_styleField(_location_txt);
			
			_name_txt.defaultText = "Your Name";
			_name_txt.errorText = "Required";
			_location_txt.defaultText = "Your Location (optional)";
			
			_name_txt.x = _location_txt.x = _still.x + _still.width + _padding;
			_still.y = _name_txt.y = container.height + _padding;
			_location_txt.y = _name_txt.y + _name_txt.height + _padding;
            
			container.addChild(_still);
			container.addChild(_name_txt);
			container.addChild(_location_txt);
			
			container.x = 30;
		}
		
		override protected function _getTextWidth ():Number {
			return super._getTextWidth() + _still.width;
		}
		
		override protected function _adjustDimensions (bg:CasaSprite, container:CasaSprite):void {
			var extraPadding = _isMedium ? 45 : 31;
			bg.width = Math.round(_still.width + (_padding * 4) + _buttons.width + extraPadding);
			bg.height = Math.round(container.height + _buttons.height + 20);
		}
		
		protected function _styleField (txt:DefaultTextField):void {
			var myFormat:TextFormat = new TextFormat();
			myFormat.font = "_sans";
			myFormat.size = _isMedium ? 23 : 16;
			
			// Create the bevel filter and set filter properties. 
			var bevel:BevelFilter = new BevelFilter(); 

			bevel.distance = 1; 
			bevel.angle = 45; 
			bevel.highlightColor = 0x333333; 
			bevel.shadowColor = 0xffffff;  
			bevel.blurX = 2; 
			bevel.blurY = 2; 
			bevel.strength = 1;
			bevel.quality = BitmapFilterQuality.HIGH;  
			bevel.type = BitmapFilterType.INNER;
			
			txt.filters = [bevel];
			txt.defaultTextFormat = myFormat;
			txt.width = 238;
			txt.maxChars = 100;
			txt.height = txt.textHeight + 5;
			txt.background = true;
			txt.backgroundColor = 0xffffff;
		}
	}
}
