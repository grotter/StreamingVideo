package org.calacademy.video.farallones.view {
	import flash.display.Stage;
	import flash.text.*;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import org.calacademy.video.events.ContentEvent;
	import org.calacademy.video.farallones.view.DropDownText;
	import org.casalib.display.CasaSprite;
	import org.casalib.time.Interval;
	import org.casalib.util.StageReference;
	import com.greensock.easing.Expo;
	import com.greensock.TweenLite;

	public class ChangeViewsDropDown extends CasaSprite {
		private var _bg:DropDownBackground = new DropDownBackground();
		private var _itemMask:CasaSprite = new CasaSprite();
		private var _itemContainer:CasaSprite = new CasaSprite();
		private var _set:Boolean = false;
		private var _txtColorDefault:Number = 0xffffff;
		private var _txtColorHighlight:Number = 0x8bff06;
		private var _menuItems:Vector.<DropDownText> = new Vector.<DropDownText>();
		private var _inactivity:Interval;
		private var _stage:Stage = StageReference.getStage();
		
		public function ChangeViewsDropDown () {
			super();
			this.addChild(_bg);
			this.visible = false;
			
			// drop shadow
			var dropShadow:DropShadowFilter = new DropShadowFilter();
			dropShadow.angle = 0;
			dropShadow.alpha = .4;
			dropShadow.distance = 3;
			dropShadow.blurX = 20;
			dropShadow.blurY = 20;

			this.filters = new Array(dropShadow);
			
			// if we click outside the dropdown, collapse
			_stage.addEventListener(MouseEvent.MOUSE_DOWN, _onStageDown);
		}
		
		private function _onInactivity ():void {
			collapse();
		}
		
		private function _onStageDown (e:MouseEvent):void {
			if (e.target.toString() == "[object DropDownText]") return;
			collapse();
		}
		
		public function onCamData (data:Object):void {
			if (data.hotspots == null || _set) return;
			
			// add menu items
			var i:int = data.hotspots.length;
			var myFormat:TextFormat = new TextFormat();
			myFormat.font = (new WhitneyMedium()).fontName;
			myFormat.size = 9;
			
			while (i--) {
				var obj:Object = data.hotspots[i];
				
				var title_txt:DropDownText = new DropDownText();
				_menuItems.push(title_txt);
				
				title_txt.defaultTextFormat = myFormat;
				title_txt.embedFonts = true;
				title_txt.width = _bg.width - 4;
				title_txt.height = 15;
				title_txt.multiline = false;
				title_txt.textColor = _txtColorDefault;
				title_txt.selectable = false;
				title_txt.antiAliasType = AntiAliasType.ADVANCED;
				
				title_txt.text = obj.title.toUpperCase();
				title_txt.code = obj.code;
				title_txt.y = i * title_txt.height;
				
				title_txt.addEventListener(MouseEvent.MOUSE_OVER, _onMouseOver);
				title_txt.addEventListener(MouseEvent.MOUSE_OUT, _onMouseOut);
				title_txt.addEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown);
				title_txt.addEventListener(MouseEvent.MOUSE_UP, _onMouseUp);
				
				_itemContainer.addChild(title_txt);
			}
            
			_itemContainer.x = 2;
			_itemContainer.y = 10;
			this.addChild(_itemContainer);
			
			// set mask
			_itemMask.graphics.beginFill(0xFF0000);
			_itemMask.graphics.drawRect(_itemContainer.x, _itemContainer.y, _itemContainer.width, _itemContainer.height);
			_itemContainer.mask = _itemMask;
			this.addChild(_itemMask);
			
			_set = true;
			collapse(false, false);
			this.visible = true;
		}
		
		private function _unselectAll ():void {
			for each (var txt:DropDownText in _menuItems) {
				txt.selected = false
				txt.textColor = _txtColorDefault;
			}
		}
		
		private function _onMouseOver (e:MouseEvent):void {
			if (_inactivity != null) _inactivity.destroy();
			
			if (e.currentTarget.selected) return;
			e.currentTarget.textColor = _txtColorHighlight;
		}
		
		private function _onMouseOut (e:MouseEvent):void {
			_setDelay();
			
			if (e.currentTarget.selected) return;
			e.currentTarget.textColor = _txtColorDefault;
		}
		
		private function _onMouseDown (e:MouseEvent):void {
			if (e.currentTarget.selected) return;
			e.currentTarget.textColor = _txtColorDefault;
		}
		
		private function _onMouseUp (e:MouseEvent):void {
			if (e.currentTarget.selected) return;
			
			_unselectAll();
			
			// select
			e.currentTarget.selected = true;
			e.currentTarget.textColor = _txtColorHighlight;
			this.dispatchEvent(new ContentEvent(ContentEvent.SELECT, e.currentTarget.code));
			
			collapse();
		}
		
		private function _setDelay ():void {
			if (_inactivity != null) _inactivity.destroy();
			_inactivity = Interval.setTimeout(_onInactivity, 3000);
			_inactivity.start();
		}
		
		private function _killTweens ():void {
			TweenLite.killTweensOf(this);
			TweenLite.killTweensOf(_itemMask);
			TweenLite.killTweensOf(_bg);
		}
		
		private function tweenTo (targetHeight:Number, animate:Boolean = true):void {
			_killTweens();
			
			if (animate) {
				var closing:Boolean = (targetHeight == 0);
				var maskD:Number = closing ? 1 : 1.3;
				var bgD:Number = closing ? 1.3 : 1;
				
				if (closing) {
					maskD -= .6;
					bgD -= .6;
				}
				
				TweenLite.to(_itemMask, maskD, {
					height: targetHeight,
					ease: Expo.easeOut
				});

				TweenLite.to(_bg, bgD, {
					height: targetHeight,
					ease: Expo.easeOut
				});
				
				if (closing) {
					TweenLite.to(this, .3, {
						delay: .3,
						alpha: 0,
						ease: Expo.easeOut
					})
				} else {
					this.alpha = 1;
				}
			} else {
				_itemMask.height = _bg.height = targetHeight;
			}
		}
		
		public function collapse (reset:Boolean = false, animate:Boolean = true):void {
			if (_inactivity != null) _inactivity.destroy();
			
			if (!_set) return;
			this.tweenTo(0, animate);
			this.dispatchEvent(new ContentEvent(ContentEvent.COLLAPSED));
			if (reset) _unselectAll();
		}
		
		public function expand ():void {
			if (!_set) return;
			this.tweenTo(_itemContainer.height + 17);
			_setDelay();
		}
		
		override public function destroy ():void {
			_killTweens();
			super.destroy();
		}
	}
}
