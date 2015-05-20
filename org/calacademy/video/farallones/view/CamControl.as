package org.calacademy.video.farallones.view {
	import flash.events.MouseEvent;
	import com.greensock.easing.Expo;
	import com.greensock.TweenLite;
	import org.casalib.time.Interval;
	import org.casalib.display.CasaSprite;
	import org.casalib.util.StringUtil;
	
	import org.calacademy.video.Config;
	import org.calacademy.video.StreamingVideoController;
	import org.calacademy.video.events.ContentEvent;
	import org.calacademy.video.farallones.view.ChangeViewsDropDown;
	import org.calacademy.video.farallones.view.QueuePosition;
	import org.calacademy.video.farallones.view.TimeLeft;
	import org.calacademy.video.farallones.data.LiveStreamData;

	public class CamControl extends CasaSprite {
		private var _dropDown:ChangeViewsDropDown = new ChangeViewsDropDown();
		private var _changeViews:ChangeViews = new ChangeViews();
		private var _requestControl:RequestControl = new RequestControl();
		private var _dropDownDataReceived:Boolean = false;
		private var _data:LiveStreamData = LiveStreamData.getInstance();
		private var _enabled:Boolean = true;
		private var _controlling:Boolean = false;
		private var _queuePosition:QueuePosition = new QueuePosition();
		private var _timeLeft:TimeLeft = new TimeLeft();
		private var _bg:CasaSprite = new CasaSprite();
		private var _fullScreen:Boolean;
		private var _streamingVideoController:StreamingVideoController;
		private var _camResponseInterval:Interval;
		private var _adminDisabled:Boolean = false;
		
		public function CamControl (streamingVideoController:StreamingVideoController) {
			super();
			_streamingVideoController = streamingVideoController;
            _data.addEventListener(ContentEvent.CAMERA_API_RESPONSE, _onCamResponse);

			// some hardcoded coordinates
			this._timeLeft.y = 13;
			this._timeLeft.x = -3;
			this._queuePosition.x = 6;
			this._requestControl.x = 65;
			this._changeViews.y = this._requestControl.y = 9;

			this._changeViews.x = this._requestControl.x + this._requestControl.width + 3;
			this._dropDown.addEventListener(ContentEvent.SELECT, _onDropDownSelect);
			this._dropDown.addEventListener(ContentEvent.COLLAPSED, _onDropDownCollapsed);
            
			this.enable(false);
            
			this._changeViews.addChild(_dropDown);
			this.addChild(_bg);
			this.addChild(_queuePosition);
			this.addChild(_requestControl);
			this.addChild(_changeViews);
			
			_bg.alpha = .5;
			_bg.graphics.beginFill(0x000000);
			_bg.graphics.drawRoundRect(-10, -10, this.width + 30, 72, 10, 10);
			this.fullscreen = false;
		}
		
		public function get bg ():CasaSprite {
			return _bg;
		}
		
		public function set fullscreen (boo:Boolean):void {
			_bg.visible = boo;
			_fullScreen = boo;
		} 
		
		public function get fullscreen ():Boolean {
			return _fullScreen;
		}
		
		public function enable (boo:Boolean = true):void {
			this._enabled = boo;
			
			if (this._enabled) {
				if (this._controlling) {
					_enableControlButton(true);
				} else if (!_data.inQueue) {
					_enableRequestButton(true);
				}
			} else {
				_enableControlButton(false);
				_enableRequestButton(false);
			}
		}
		
		private function _enableRequestButton (boo:Boolean = true):void {
			this._requestControl.enabled = boo;
			
			if (boo) {
				this._requestControl.addEventListener(MouseEvent.MOUSE_UP, _onRequestControl);
			} else {
				this._requestControl.removeEventListener(MouseEvent.MOUSE_UP, _onRequestControl);
			}
		}
		
		private function _enableControlButton (boo:Boolean = true):void {
			this._changeViews.enabled = boo;
			this._timeLeft.enabled = boo;
			
			if (boo) {
				// add count down
				this.addChild(this._timeLeft);
				
				// remove queue position
				if (this._queuePosition.onStage) {
					this.removeChild(this._queuePosition);
				}
			} else {
				// add queue position
				this.addChild(this._queuePosition);
				
				// remove count down
				if (this._timeLeft.onStage) {
					this.removeChild(this._timeLeft);
				}
				
				// collapse the dropdown
				this._dropDown.collapse(true);
			}
		}
		
		private function _onRequestControl (e:MouseEvent):void {
			// add queue position
			this._queuePosition.enabled = true;
			this.addChild(this._queuePosition);
			
			// remove count down
			if (this._timeLeft.onStage) {
				this.removeChild(this._timeLeft);
			}
			
			_enableRequestButton(false);
			_data.joinQueue();
			_data.load();
		}
		
		private function _onCamResponse (e:ContentEvent):void {
			trace("CamControl._onCamResponse: " + e.data);
			
			// camera api request success / fail
			if (e.data) {
				// timeout buffer removal
				if (_camResponseInterval) _camResponseInterval.destroy();
				
				var delay:int = (Config.bufferTime * 1000) + 500;
				_camResponseInterval = Interval.setTimeout(_streamingVideoController.buffer, delay, false);
				_camResponseInterval.start();
			} else {
				// remove the progress / buffer indicator
				_streamingVideoController.buffer(false);
				
				// reset dropdown 
				this._dropDown.collapse(true);
				
				// broadcast error to controller
				this.dispatchEvent(new ContentEvent(ContentEvent.PTZ_ERROR));
			}
		}
		
		private function _onDropDownSelect (e:ContentEvent):void {
			if (_camResponseInterval) _camResponseInterval.destroy();
			
			// start buffering
			_streamingVideoController.buffer(true, true);
			
			// send camera api request
			_data.gotoHotspot(e.data);
		}
		
		private function _onDropDownCollapsed (e:ContentEvent):void {
			_changeViews.addEventListener(MouseEvent.MOUSE_UP, _onChangeMouseUp);
		}
		
		private function _onChangeMouseUp (e:MouseEvent):void {
			if (!_dropDownDataReceived || !_enabled || !_controlling) return;
			
			// only the bg button press should expand
			if (e.target.toString() == "[object DropDownText]") return;
			
			_changeViews.removeEventListener(MouseEvent.MOUSE_UP, _onChangeMouseUp);
			_dropDown.expand();
		}
		
		public function update (data:Object):void {
			if (data.hotspots == null) return;
			// trace("CamControl.update: " + data.camcontrol);
			trace("queue position: " + this._queuePosition.position);
			
			_dropDown.onCamData(data);

			// populate dropdown data once
			if (!_dropDownDataReceived) {
				// bogus, do nothing
				if (_data.isControlling()) return;
                
				// in queue browser refresh
				if (_data.getQueuePosition() > 0) {
					_data.joinQueue();
				}
				
				this.enable();
				_dropDownDataReceived = true;
			}
			
			if (_adminDisabled) {
				// previously admin disabled, reactivate
				if (!_data.isAdminDisabled()) {
					_adminDisabled = false;					
					this.enable(true);
					
					// rejoin the queue
					if (this._controlling) {
						_data.joinQueue();
						return;
					}
				}
			} else {
				// currently enabled and suddenly admin disabled
				if (_data.isAdminDisabled()) {
					_adminDisabled = true;
					this.enable(false);

					// display appropriate message
					if (this._controlling) {
						// currently controlling
						Config.msgKillControlling.body = StringUtil.replace(Config.msgKillControlling.body, "%%time_reactivation%%", data.camcontrol.time_reactivation);
						this.dispatchEvent(new ContentEvent(ContentEvent.KILL_MESSAGE, Config.msgKillControlling));
						
						// manually override position reset
						this._queuePosition.setPosition(1);
					} else {
						if (this._queuePosition.position == 0) {
							// not in the queue
							Config.msgKillNotInQueue.body = StringUtil.replace(Config.msgKillNotInQueue.body, "%%time_reactivation%%", data.camcontrol.time_reactivation);
							this.dispatchEvent(new ContentEvent(ContentEvent.KILL_MESSAGE, Config.msgKillNotInQueue));
						} else {
							// in the queue
							Config.msgKillInQueue.body = StringUtil.replace(Config.msgKillInQueue.body, "%%time_reactivation%%", data.camcontrol.time_reactivation);
							this.dispatchEvent(new ContentEvent(ContentEvent.KILL_MESSAGE, Config.msgKillInQueue));
						}
					}
					
					return;
				}
			}
			
			// main UI is disabled, do nothing
			if (!_enabled) {
				if (this._controlling) _data.joinQueue(false);
				return;
			}
			
			// update the indicators
			this._queuePosition.update(data);
			this._timeLeft.update(data);
			 
			this._controlling = _data.isControlling();

			// switch on _changeViews if diff
			if (this._controlling != this._changeViews.enabled) {
				_enableControlButton(this._controlling);
				
				// if we just lost control...
				if (!this._controlling) {
					// dim the queue position
					this._queuePosition.enabled = false;
					
					// reenable the request button
					_enableRequestButton(true);
				}
			}
			
			// if we're now controlling, stop requesting to join
			if (this._controlling) _data.joinQueue(false);
		}
	}
}
