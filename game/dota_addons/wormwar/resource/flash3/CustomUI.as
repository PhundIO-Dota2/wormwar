package {
	import flash.display.MovieClip;
	import flash.text.*;

	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class CustomUI extends MovieClip {
		
		//these three variables are required by the engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		private var ScreenWidth:int;
		private var ScreenHeight:int;
		public var scaleRatioY:Number;
		
		private var holder:MovieClip = new MovieClip;

		//constructor, you usually will use onLoaded() instead
		public function CustomUI() : void {
	
		}

		//this function is called when the UI is loaded
		public function onLoaded() : void {		
			//make this UI visible
			visible = true;
			trace("[CustomUI] OnLoaded");
			
			this.gameAPI.SubscribeToGameEvent("show_main_ability", showMainAbility);
			this.gameAPI.SubscribeToGameEvent("show_banner", showBanner);
			this.gameAPI.SubscribeToGameEvent("turn_off_waitforplayers", turnOffWaitForPlayers);

			this.addChild(holder);
			
			var oldChatSay:Function = globals.Loader_hud_chat.movieClip.gameAPI.ChatSay;
			globals.Loader_hud_chat.movieClip.gameAPI.ChatSay = function(obj:Object, bool:Boolean){
				var type:int = globals.Loader_hud_chat.movieClip.m_nLastMessageMode
				if (bool)
					type = 4
				
				gameAPI.SendServerCommand( "player_say " + type + " " + obj.toString());
				oldChatSay(obj, bool);
			};

			//let the client rescale the UI
			Globals.instance.resizeManager.AddListener(this);
			globals.Loader_shared_heroselectorandloadout.movieClip.heroDock.repickButton.enabled = false
			globals.Loader_shared_heroselectorandloadout.movieClip.heroDock.playGameButton.enabled = false

			//overrideKillBanners();
			//globals.Loader_hud_chat.movieClip.headerRampage0.symbolTextField.headerTextField	

			//pass the gameAPI on to the modules
			this.scoreBoard.setup(this.gameAPI, this.globals);
			this.waitForPlayers.setup(this.gameAPI, this.globals);
			
			//this is not needed, but it shows you your UI has loaded (needs 'scaleform_spew 1' in console)
			trace("[CustomUI] OnLoaded finished!");
		}
		
		public function showBanner() : void {
			trace("showBanner start")
			var obj = globals.Loader_hud_chat.movieClip.headerRampage0
			Util.PrintTable(obj)
			obj.symbolTextField.headerTextField.visible = true
			obj.symbolTextField.symbolTextField.visible = true
			/*obj.symbolTextField.headerTextField.text = "HELLO%21%21"
			obj.visible = true;
			obj.symbolTextField.visible = true;
			obj.symbolTextField.visible = true;
			var i:int = 0;
			for (i = 0; i<obj.numChildren; i++)
			{
			    trace(obj.getChildAt(i));
			    obj.getChildAt(i).visible = true;
			}*/
			trace("showBanner end")
		}

		public function showMainAbility(args:Object) : void {
			trace("##Event Firing Detected")
			trace("##Data: "+args.pID);
			if (globals.Players.GetLocalPlayer() == args.pID)
			{
				showAbilityButton();
			}
		}

		public function turnOffWaitForPlayers(args:Object) : void {
			this.waitForPlayers.visible = false

		}

		public function showAbilityButton(): void {
			globals.Loader_actionpanel.movieClip.visible = false;
			
			// Special thanks to zed for this
			var abHold = globals.Loader_actionpanel.movieClip.middle.abilities["Ability0"];
			var manaHold = globals.Loader_actionpanel.movieClip.middle.abilities["abilityMana0"];
			var keyHold = globals.Loader_actionpanel.movieClip.middle.abilities["abilityBind0"];
			globals.Loader_actionpanel.movieClip.middle.abilities.removeChild(abHold);
			globals.Loader_actionpanel.movieClip.middle.abilities.removeChild(manaHold);
			globals.Loader_actionpanel.movieClip.middle.abilities.removeChild(keyHold);
								
			holder.addChild(abHold);
			holder.addChild(manaHold);
			holder.addChild(keyHold);
						
			holder.x = ScreenWidth*.5;
			holder.y = ScreenHeight*.85;
									
			//holder.width = 128;
			//holder.height = 100;
			trace(abHold.scaleX,abHold.scaleY);
			abHold.scaleY = 1 * scaleRatioY;
			abHold.scaleX = 1 * scaleRatioY;
			
			trace(manaHold.scaleX,manaHold.scaleY);
			manaHold.scaleY = 1 * scaleRatioY;
			manaHold.scaleX = 1 * scaleRatioY;
			
			trace(keyHold.scaleX,keyHold.scaleY);
			keyHold.scaleY = 1.5 * scaleRatioY;
			keyHold.scaleX = 1.5 * scaleRatioY;
		}

		//this handles the resizes
		public function onResize(re:ResizeManager) : * {
			
			// calculate by what ratio the stage is scaling
			scaleRatioY = re.ScreenHeight/1080;
			
			trace("[CustomUI] ##### RESIZE #########");
					
			ScreenWidth = re.ScreenWidth;
			ScreenHeight = re.ScreenHeight;
					
			//pass the resize event to our module, we pass the width and height of the screen, as well as the INVERSE of the stage scaling ratios.
			this.scoreBoard.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			this.waitForPlayers.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
		}
	}
}