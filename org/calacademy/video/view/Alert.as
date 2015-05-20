package org.calacademy.video.view {
	import flash.display.Stage;
	import flash.text.*;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import com.greensock.TweenLite;
	import com.greensock.easing.*;
	
	import org.casalib.display.CasaSprite;
	import org.casalib.display.CasaMovieClip;
	import org.casalib.display.CasaTextField;
	import org.casalib.util.StageReference;
	
	import org.calacademy.video.Config;
	
	public class Alert extends CasaSprite {
		protected var _padding:Number;
		protected var _onStage:Boolean = false;
		protected var _stage:Stage;
		protected var _buttons:CasaSprite;
		protected var _msgContainer:CasaSprite;
		protected var _activeButton:AlertButton;
		protected var _isMedium:Boolean;
		protected var _screen:AlertScreen;
		protected var _contentOffset:Number = 0;
		
		public function Alert (isMedium:Boolean = false) {
			super();
			_isMedium = isMedium;
			_padding = _isMedium ? 11 : 8;
			this.alpha = 0;
			
			this.addEventListener(Event.ADDED_TO_STAGE, _onAdded); 
			this.addEventListener(Event.REMOVED_FROM_STAGE, _onRemoved);
		}
		
		public function initScreen ():void {
			_screen = new AlertScreen();
			_sizeScreen();
			this.addChild(_screen);
		}
		
		protected function _sizeScreen ():void {
			if (_screen == null) return;
			_screen.width = Config.stageWidth / this.scaleX;
			_screen.height = Config.stageHeight / this.scaleY;
		}
		
		protected function _placeMsgContainer ():void {
			if (_msgContainer == null) return;
			_msgContainer.x = Math.round((Config.stageWidth / this.scaleX) / 2);
			_msgContainer.y = Math.round((Config.stageHeight / this.scaleY) / 2);
		}
		
		public function resize ():void {
			_sizeScreen();
			if (this.onStage) _placeMsgContainer();
		}
		
		protected function _getTextField (color:Number, multiline:Boolean = true):CasaTextField {
			var myFormat:TextFormat = new TextFormat();
			myFormat.font = "_sans";
			myFormat.size = _isMedium ? 23 : 16;
			myFormat.leading = _isMedium ? 4 : 3;
			myFormat.align = TextFormatAlign.CENTER;
			
			var txt:CasaTextField = new CasaTextField();
			txt.defaultTextFormat = myFormat;
			txt.textColor = color;
			txt.selectable = false;
			txt.wordWrap = multiline;
			txt.multiline = multiline;
			txt.autoSize = TextFieldAutoSize.LEFT;
			txt.antiAliasType = AntiAliasType.ADVANCED;
			
			return txt;
		}
		
		protected function _getText (txt:String, width:* = null, multiline:Boolean = true):CasaSprite {
			var container:CasaSprite = new CasaSprite();
			var bg:CasaTextField = _getTextField(0x000000, multiline);
			var fg:CasaTextField = _getTextField(0xffffff, multiline);
			
			bg.htmlText = fg.htmlText = txt;
			if (width != null) bg.width = fg.width = width;
			
			bg.y -= 1;
			// bg.alpha = .8;
			
			container.addChild(bg);
			container.addChild(fg);
			
			return container;
		}
		
		protected function _getButton (btnInfo:Object, width:Number = 150):CasaSprite {
			// setup graphics
			var btn:AlertButton = new AlertButton();
			var bg:CasaMovieClip = _isMedium ? new AlertButtonBackgroundMedium() : new AlertButtonBackground();
			var txt:CasaSprite = _getText("<b>" + btnInfo.title + "</b>", null, false);
			
			bg.width = width;
			txt.x = Math.round((bg.width - txt.width) / 2);
			txt.y = Math.round((bg.height - txt.height) / 2) + 1;
			
			btn.bg = bg;
			btn.callback = btnInfo.callback;
			btn.addChild(bg);
			btn.addChild(txt);
			
			// add interactivity
			btn.addEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown);
			
			return btn;
		}
		
		protected function _onMouseDown (e:MouseEvent):void {
			try {
				_activeButton = e.currentTarget;
				_activeButton.bg.gotoAndStop(2);
			} catch (e:Error) {
				trace(e);
			}
			
			_stage.addEventListener(MouseEvent.MOUSE_UP, _onMouseUp);
		}
		
		protected function _onMouseUp (e:MouseEvent):void {
			_stage.removeEventListener(MouseEvent.MOUSE_UP, _onMouseUp);
			
			try {
				_activeButton.bg.gotoAndStop(1);
				_activeButton.callback();
			} catch (e:Error) {
				trace(e);
			}
		}
		
		protected function _getButtonWidth ():int {
			return _isMedium ? 420 : 300;
		}
		
		public function setButtons (btn1Info:Object, btn2Info:Object = null):void {
			if (_buttons != null) _buttons.removeChildrenAndDestroy(true, true);
			_buttons = new CasaSprite();
			
			var width:Number = _getButtonWidth();
			if (btn2Info != null) width = Math.round(width / 2);
			
			var btn1:CasaSprite = _getButton(btn1Info, width);
			btn1.x = _isMedium ? 15 : 10;
			_buttons.addChild(btn1);
			
			if (btn2Info != null) {
				var btn2:CasaSprite = _getButton(btn2Info, width);
				btn2.x = btn1.x + btn1.width;
				_buttons.addChild(btn2);
			}
		}
		
		public function setText (title:String = "", body:String = ""):void {
			// set up containers
			if (_msgContainer != null) _msgContainer.removeChildrenAndDestroy(true, true);
			_msgContainer = new CasaSprite();
			
			var bg:CasaSprite = _isMedium ? new AlertBackgroundMedium() : new AlertBackground();
			var nestedContainer:CasaSprite = new CasaSprite();
			nestedContainer.addChild(bg);			
			nestedContainer.addChild(_buttons);
			
			// text
			var txtContainer:CasaSprite = new CasaSprite();
			var title_txt:CasaSprite;
			var body_txt:CasaSprite;
			
			// add title
			if (title != null && title != "") {
				title_txt = _getText("<b>" + title + "</b>", _getTextWidth());
				txtContainer.addChild(title_txt);
			}
			
			// add body
			if (body != null && body != "") {
				body_txt = _getText(body, _getTextWidth());
				
				if (title_txt != null) {
					body_txt.y += title_txt.height + Math.round(_padding / 2);
				}
				
				txtContainer.addChild(body_txt);
			}
			
			_addExtraContent(txtContainer);
			
			// place text
			txtContainer.x = txtContainer.y = Math.round(_padding * 2);
			nestedContainer.addChild(txtContainer);
			
			_placeButtons(txtContainer);
			_adjustDimensions(bg, txtContainer);
			
			// center containers
			nestedContainer.x = -Math.round(nestedContainer.width / 2);
			nestedContainer.y = -Math.round(nestedContainer.height / 2);
			_placeMsgContainer();
			
			// offset
			txtContainer.x += _contentOffset;
			_buttons.x += _contentOffset;
			
			_msgContainer.addChild(nestedContainer);
			this.addChild(_msgContainer);
		}
		
		protected function _getTextWidth ():Number {
			var buttonOffset:Number = _isMedium ? 15 : 11;
			return _buttons.width - buttonOffset;
		}
		
		protected function _placeButtons (container:CasaSprite = null):void {
			// place buttons
			_buttons.y = Math.round(container.y + container.height);
			_buttons.y += _isMedium ? 17 : 12;
		}
		
		protected function _addExtraContent (container:CasaSprite):void {
			// override
		}
		
		protected function _adjustDimensions (bg:CasaSprite, container:CasaSprite):void {
			if (_isMedium) {
				bg.width = Math.round(container.width + 45);
				bg.height = Math.round(container.height + _buttons.height + 60);
			} else {
				bg.width = Math.round(container.width + 31);
				bg.height = Math.round(container.height + _buttons.height + 44);
			}
		}
		
		public function get onStage ():Boolean {
			return this._onStage;
		}
		
		protected function _onAdded (e:Event):void {
			_stage = StageReference.getStage();
			
			TweenLite.killTweensOf(this);
			TweenLite.killTweensOf(_msgContainer);
			
			// _msgContainer.scaleX = _msgContainer.scaleY = .85;
			this.alpha = 0;
			
			TweenLite.to(this, .8, {
				alpha: 1,
				ease: Expo.easeOut
			});
			
			/*
			TweenLite.to(_msgContainer, .8, {
				scaleX: 1,
				scaleY: 1,
				ease: Elastic.easeOut
			});
			*/
			
			this._onStage = true;
		}
		
		protected function _onRemoved (e:Event):void {
			this._onStage = false;
		}
	}
}
