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
	
	public class CustomEndScreen extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;

		var _exitBtn:Object;

		public function CustomEndScreen() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			// Font Labels
			var txFormatBold:TextFormat = new TextFormat;
			txFormatBold.font = "$TextFontBold";
			var txFormatTitle:TextFormat = new TextFormat;
			txFormatTitle.font = "$TitleFontBold";

			creditsTitle.text = Globals.instance.GameInterface.Translate("#Credits")
			creditsTitle.setTextFormat(txFormatTitle);

			tellYourFriends.text = Globals.instance.GameInterface.Translate("#TellYourFriends")
			tellYourFriends.setTextFormat(txFormatBold);

			//interestedInMaking
			interestedInMaking.text = Globals.instance.GameInterface.Translate("#InterestedInMaking")
			interestedInMaking.setTextFormat(txFormatBold);

			_exitBtn = replaceWithValveComponent(exitBtn, "ButtonThinPrimary", true);
			_exitBtn.addEventListener(ButtonEvent.CLICK, onExitBtn);
			_exitBtn.label = Globals.instance.GameInterface.Translate("#Exit");

			trace("##Called CustomEndScreen Setup!");
		}
		
        public function onExitBtn(event:ButtonEvent)
        {
        	var i:int = globals.Players.GetLocalPlayer();
        	//this.gameAPI.SendServerCommand("player_wants_to_leave");
        	globals.Loader_gameend.movieClip.gameAPI.OnFinishButtonPress()
			visible = false
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

		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean) {
			trace("Stage Size: ",stageW,stageH);

			this.width = this.width*yScale;
			this.height	 = this.height*yScale;

			// this is always called at the resolution the player is currently at.
			this.x = stageW/2-this.width/2;
			this.y = stageH/2 - this.height/2 + 50*yScale;
			
			trace("#Result Resize: ",this.x,this.y,yScale);
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
		}
	}	
}

