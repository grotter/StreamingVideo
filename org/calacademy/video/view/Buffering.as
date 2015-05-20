package org.calacademy.video.view {
	import org.casalib.display.CasaSprite;
	import org.casalib.display.CasaMovieClip;
	import org.casalib.display.CasaTextField;
	import flash.text.*;
	import flash.events.Event;
	import flash.display.DisplayObject;
	import com.greensock.TweenLite;
	import com.greensock.easing.*;
	import org.calacademy.video.events.ContentEvent;
	import org.calacademy.video.view.Buffering;
	import org.calacademy.video.Config;
	
	public class Buffering extends CasaSprite {		
		private var _text:CasaTextField;
		private var _onStage:Boolean = false;
		private var _stream:Object;
		private var _isMedium:Boolean;
		private var _indicator:CasaMovieClip;
		private var _lastBufferPercent:Number;
		private var _lastBufferLength:Number;
		private var _message:String;
		private var _isStatic:Boolean;
		
		public function Buffering (isMedium:Boolean = false) {
			super();
			this.alpha = 0;
			isStatic = false;
			_isMedium = isMedium;
			_init();
			
			this.addEventListener(Event.ADDED_TO_STAGE, _onAdded); 
			this.addEventListener(Event.REMOVED_FROM_STAGE, _onRemoved);
		}
		
		public function set isStatic (boo:Boolean):void {
			_isStatic = boo;
			
			if (_isStatic) {
				_message = Config.staticLoadingMessage;
				reset();
			} else {
				_message = Config.loadingMessage;
			}
		}
		
		protected function _init ():void {
			var shadow:BufferingShadow = new BufferingShadow();
			if (_isMedium) shadow.scaleX = shadow.scaleY = 1.4;
			super.addChild(shadow);
			
			_indicator = _isMedium ? new BufferingIndicatorMedium() : new BufferingIndicator();
			_indicator.stop();
			super.addChild(_indicator);
			
			var myFormat:TextFormat = new TextFormat();
			myFormat.font = (new WhitneySemibold()).fontName;
			myFormat.size = _isMedium ? 23 : 16;
			myFormat.align = TextFormatAlign.CENTER;
			
			this._text = new CasaTextField();
			this._text.defaultTextFormat = myFormat;
			this._text.width = Config.stageWidth;
			this._text.embedFonts = true;
			this._text.textColor = 0xffffff;
			this._text.selectable = false;
			this._text.x -= Config.stageWidth / 2;
			this._text.y += _isMedium ? 37 : 26;
			this._text.antiAliasType = AntiAliasType.ADVANCED;
		 
			this.reset();
			super.addChild(this._text);
		}
		
		public function reset ():void {
			_lastBufferPercent = 0;
			_lastBufferLength = 0;
			this.setText(_message);
		}
		
		public function setStream (stream:Object):void {
			this._stream = stream;
		}
		
		public function get onStage ():Boolean {
			return this._onStage;
		}
		
		override public function addChild (obj:DisplayObject):DisplayObject {
			var obj:DisplayObject = super.addChild(obj);
			super.addChild(this._text); // make sure text is on top
			return obj;
		}
		
		public function setText (str:String):void {
			this._text.text = str;
		}
		
		private function _onAdded (e:Event):void {
			TweenLite.killTweensOf(this);
			
			var inst:Buffering = this;
			this._lastBufferPercent = 0;
			this._lastBufferLength = 0;
			this.alpha = 0;
			
			TweenLite.to(this, 1, {
				alpha: 1,
				ease: Expo.easeOut,
				delay: .8,
				onInit: function () {
					inst.addEventListener(Event.ENTER_FRAME, inst._onEnterFrame);
				}
			});
			
			this.x = Config.stageWidth / 2;
			this.y = Config.stageHeight / 2;
			this.y -= _isMedium ? 25 : 17;
			
			this._onStage = true;
			_indicator.play();
		}
		
		private function _onRemoved (e:Event):void {
			this._onStage = false;
			this.removeEventListener(Event.ENTER_FRAME, _onEnterFrame);
			this.setText(_message);
			_indicator.stop();
		}
		
		private function _onEnterFrame (e:Event):void {
			if (_isStatic) return;
			
			// check if we have a valid stream
			if (_stream) {
				// @note
				// progress dispatches should really be firing regardless of whether or not
				// the graphic is on the stage. however, the timeout timer is
				// stopped before displaying alerts. @see PocketPenguins._displayAlert 
				
				// if buffer length has changed, dispatch progress event
				if (typeof(_stream.getBufferLength) == "function") {
					var len:Number = _stream.getBufferLength();
					
					if (_lastBufferLength != len && len > 0.01) {
						this.dispatchEvent(new ContentEvent(ContentEvent.PROGRESS));
					}
					
					_lastBufferLength = len;
				}
				
				// buffered more than 0%, update textfield
				if (typeof(_stream.getPercentBuffered) == "function") {
                	var per:Number = _stream.getPercentBuffered();
                    
					// greater than zero and last value
					if (per > 0) {
						if (per > _lastBufferPercent) {
							_lastBufferPercent = per;
	 						this.setText("Buffering " + per + "%");
						}
					}
				}
			}
		}
	}
}
