package  {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import flash.utils.Dictionary;
	import scaleform.clik.events.*;
	import scaleform.clik.data.DataProvider;
	import flash.events.TimerEvent; 
    import flash.utils.Timer; 

	import ValveLib.*;
	import flash.text.TextFormat;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class PlayAgain extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;
		var showPlayAgainForm:Boolean;
		var slot_to_pID:Array = new Array(12);
		var nextEmptySlot:int = 0;
		var pID_to_slot:Array = new Array(12);
		var _yesPlayAgainBtn:Object;
		var _noPlayAgainBtn:Object;
		var _shareFeedbackBtn:Object;
		var timer:Object;

		//var newSubmitBtn:Object;
		//var newScoreSlider:Object;
		//var yesWillPlayAgainBtn:Object;
		//var noWillPlayAgainBtn:Object;


		public function PlayAgain() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			this.gameAPI.SubscribeToGameEvent("game_over_player_data", gameOverPlayerDataReceived);

			// Font Labels
			var txFormatBold:TextFormat = new TextFormat;
			txFormatBold.font = "$TextFontBold";
			var txFormatTitle:TextFormat = new TextFormat;
			txFormatTitle.font = "$TitleFontBold";

			playAgainTitle.text = Globals.instance.GameInterface.Translate("#PlayAgainTitle");
			playAgainTitle.setTextFormat(txFormatTitle);

			newGameWillStartText.text = Globals.instance.GameInterface.Translate("#NewGameWillStart");
			newGameWillStartText.setTextFormat(txFormatBold);

			doYouWantToPlayAgainText.text = Globals.instance.GameInterface.Translate("#DoYouWantToPlayAgain");
			doYouWantToPlayAgainText.setTextFormat(txFormatBold);

			feedbackInfo.text = Globals.instance.GameInterface.Translate("#FeedbackInfo");
			feedbackInfo.setTextFormat(txFormatBold);

			timeTillNextGameStarts.text = Globals.instance.GameInterface.Translate("#TimeTillNextGameStarts");
			timeTillNextGameStarts.setTextFormat(txFormatBold);

			cleanForm();

			_yesPlayAgainBtn = replaceWithValveComponent(yesPlayAgainBtn, "ButtonThinPrimary", true);
			_yesPlayAgainBtn.addEventListener(ButtonEvent.CLICK, onYesPlayAgainBtn);
			_yesPlayAgainBtn.label = Globals.instance.GameInterface.Translate("#Yes");

			_noPlayAgainBtn = replaceWithValveComponent(noPlayAgainBtn, "ButtonThinSecondary", true);
			_noPlayAgainBtn.addEventListener(ButtonEvent.CLICK, onNoPlayAgainBtn);
			_noPlayAgainBtn.label = Globals.instance.GameInterface.Translate("#No");

			//globals.Players.GetPlayerName(globals.Players.GetLocalPlayer());
			//shareFeedbackBtn
			_shareFeedbackBtn = replaceWithValveComponent(shareFeedbackBtn, "ButtonThinPrimary", true);
			_shareFeedbackBtn.addEventListener(ButtonEvent.CLICK, onShareFeedback);
			_shareFeedbackBtn.label = Globals.instance.GameInterface.Translate("#ShareFeedback");

			/*this.q1Title.text = Globals.instance.GameInterface.Translate("#Q1Title");
			this.q1Title.setTextFormat(txFormatBold);

			this.q2Title.text = Globals.instance.GameInterface.Translate("#Q2Title");
			this.q2Title.setTextFormat(txFormatBold);

			this.q3Title.text = Globals.instance.GameInterface.Translate("#Q3Title");*/

			visible = false;
			trace("##Called PlayAgain Setup!");
		}
		
		public function gameOverPlayerDataReceived(args:Object) : void {
			if (visible == false) {
				visible = true;
				timeTillNextGameStarts.text = Globals.instance.GameInterface.Translate("#TimeTillNextGameStarts") + " 60";
				timer = new Timer(1000, 60);
	            // designates listeners for the interval and completion events 
	            timer.addEventListener(TimerEvent.TIMER, onTick); 
	            timer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete); 
	            timer.start()
	            trace("added timer")
			}
			slot_to_pID[nextEmptySlot] = args.pID
			var name:TextField = getChildByName("Name_" + nextEmptySlot) as TextField;
			name.text = args.playerName
			pID_to_slot[args.pID] = nextEmptySlot;
			nextEmptySlot++;

			if (globals.Players.GetLocalPlayer() == args.pID)
			{
				//showAbilityButton();
			}
		}

        public function onTick(event:TimerEvent):void  
        {
            timeTillNextGameStarts.text = Globals.instance.GameInterface.Translate("#TimeTillNextGameStarts") + " " + (60-event.target.currentCount);
        } 
 
        public function onTimerComplete(event:TimerEvent):void 
        {
            //cleanup
            cleanForm()
            visible = false
            
            this.gameAPI.SendServerCommand("start_a_new_game");
        } 

        public function onYesPlayAgainBtn(event:ButtonEvent)
        {
        	var i:int = pID_to_slot[globals.Players.GetLocalPlayer()];

			var noPlay:MovieClip = getChildByName("noPlay_" + i) as MovieClip;
			var yesPlay:MovieClip = getChildByName("yesPlay_" + i) as MovieClip;
			noPlay.visible = false;
			yesPlay.visible = true;
        }

        public function onNoPlayAgainBtn(event:ButtonEvent)
        {
        	var i:int = pID_to_slot[globals.Players.GetLocalPlayer()];

			var noPlay:MovieClip = getChildByName("noPlay_" + i) as MovieClip;
			var yesPlay:MovieClip = getChildByName("yesPlay_" + i) as MovieClip;
			noPlay.visible = true;
			yesPlay.visible = false;
        	// show feedback blah blah
        	this.gameAPI.SendServerCommand("player_wants_to_leave");
        }

        public function onShareFeedback(event:ButtonEvent)
        {
        	var i:int = pID_to_slot[globals.Players.GetLocalPlayer()];

        }

        public function cleanForm() {
			slot_to_pID = new Array(12);
			nextEmptySlot = 0;
			pID_to_slot = new Array(12);

			for (var i:int = 0; i <= 11; i++) {
				var name:TextField = getChildByName("Name_" + i) as TextField;
				var noPlay:MovieClip = getChildByName("noPlay_" + i) as MovieClip;
				var yesPlay:MovieClip = getChildByName("yesPlay_" + i) as MovieClip;

				name.text = "";
				noPlay.visible = false;
				yesPlay.visible = false;
			}
        }

		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean) {
			trace("Stage Size: ",stageW,stageH);

			this.width = this.width*yScale;
			this.height	 = this.height*yScale;

			// this is always called at the resolution the player is currently at.
			this.x = stageW/2;
			this.y = stageH/2 - 50*yScale;
			
			trace("#Result Resize: ",this.x,this.y,yScale);
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
		}
		//Parameters: 
		//	mc - The movieclip to replace
		//	type - The name of the class you want to replace with
		//	keepDimensions - Resize from default dimensions to the dimensions of mc (optional, false by default)
		public function replaceWithValveComponent(mc:MovieClip, type:String, keepDimensions:Boolean = false) : MovieClip {
			var parent = mc.parent;
			var oldx = mc.x;
			var oldy = mc.y;
			var oldwidth = mc.width;
			var oldheight = mc.height;
			
			var newObjectClass = getDefinitionByName(type);
			var newObject = new newObjectClass();
			newObject.x = oldx;
			newObject.y = oldy;
			if (keepDimensions) {
				newObject.width = oldwidth;
				newObject.height = oldheight;
			}
			
			parent.removeChild(mc);
			parent.addChild(newObject);
			
			return newObject;
		}
	}
}

