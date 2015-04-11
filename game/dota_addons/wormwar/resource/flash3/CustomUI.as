package {
	import flash.display.MovieClip;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.Timer; 

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
		var cinematicStart:Boolean = false;
		var currentHighscore:int = 0;
		var segmentsToWinLabel:TextField = null;

		var firstPartLifespan:Number = 9;
		var framesPerSec:Number = 60;

		var currentPitch:Number = 50;
		var startPitch:Number = 50;
		var endPitch:Number = 10;
		var pitchInterval:Number = (endPitch-startPitch)/(firstPartLifespan*framesPerSec)

		var currentYaw:Number = 90;
		var startYaw:Number = 90;
		var endYaw:Number = 270;
		var yawInterval:Number = (endYaw-startYaw)/(firstPartLifespan*framesPerSec)

		var currentDist:Number = 1400;
		var startingDist:Number = 1400;
		var endingDist:Number = 800;
		var distInterval:Number = (endingDist-startingDist)/(firstPartLifespan*framesPerSec)  // total of lifeSpan*60 frames in denominator.

		var r_farz:Number = 5000;
		var firstPartTimer:Object = null;
		var firstPartOver:Boolean = false
		var secondPartTimer:Object = null;
		var secondPartOver:Boolean = false

		//constructor, you usually will use onLoaded() instead
		public function CustomUI() : void {
	
		}

		//this function is called when the UI is loaded
		public function onLoaded() : void {		
			//make this UI visible
			visible = true;
			trace("[CustomUI] OnLoaded");
			
			this.gameAPI.SubscribeToGameEvent("show_main_ability", showMainAbility);
			this.gameAPI.SubscribeToGameEvent("turn_off_waitforplayers", turnOffWaitForPlayers);
			this.gameAPI.SubscribeToGameEvent("start_ending_cinematic", startEndingCinematic);
			this.gameAPI.SubscribeToGameEvent("change_segments_to_win", change_segments_to_win);
			// highscore stuff
			this.gameAPI.SubscribeToGameEvent("retrieve_highscore", this.retrieveHighscore);
			this.gameAPI.SubscribeToGameEvent("update_highscore", this.updateHighscore);

			this.gameAPI.SubscribeToGameEvent("enter_hero_selection", this.enter_hero_selection);
			this.gameAPI.SubscribeToGameEvent("display_custom_end_screen", this.display_custom_end_screen);

			this.addChild(holder);
			segmentsToWinLabel = segmentsToWin.segmentsToWinLabel
			segmentsToWinLabel.visible = false

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

			//pass the gameAPI on to the modules
			this.scoreBoard.setup(this.gameAPI, this.globals);
			this.waitForPlayers.setup(this.gameAPI, this.globals);
			this.waitForPlayers2.setup(this.gameAPI, this.globals);
			this.feedback.setup(this.gameAPI, this.globals);
			this.playAgain.setup(this.gameAPI, this.globals);
			this.customEndScreen.setup(this.gameAPI, this.globals);
			//this.waitForPlayersBottom.setup(this.gameAPI, this.globals);

			addEventListener(Event.ENTER_FRAME, myEnterFrame);

			trace("[CustomUI] OnLoaded finished!");
		}

		public function display_custom_end_screen(args:Object) : void {
			holder.visible = false
			customEndScreen.visible = true
		}

		public function enter_hero_selection(args:Object) : void {
			globals.Loader_shared_heroselectorandloadout.movieClip.heroDock.repickButton.enabled = false
			globals.Loader_shared_heroselectorandloadout.movieClip.heroDock.playGameButton.enabled = false
		}

		// highscore stuff
		public function retrieveHighscore(args:Object) : void {
			//trace("##retrieveHighscore");
			//Get the Highscore for the player
			globals.Loader_StatsCollectionHighscores.movieClip.GetPersonalLeaderboard('XXXXXXXXXXXXXXXXXXX', PersonalCallback);
			//trace("##FINISHED SHOWING HIGHSCORES");
		}

		public function updateHighscore(args:Object) : void {
			
			//trace("##Fired Game event, Checking if Highscore should be updated");
			if (globals.Players.GetLocalPlayer() == args.player_ID)
			{
				currentHighscore = args.score;
				globals.Loader_StatsCollectionHighscores.movieClip.GetPersonalLeaderboard('XXXXXXXXXXXXXXXXXXX', PersonalCallback);
			}
			//trace("##Finished updateHighscore");
		}

		public function PersonalCallback(jsonInfo:Object) {
			//trace("###HighscorePanel PersonalCallback");
			var i:int = 0;
			for (var highscoreID in jsonInfo) {
				//trace("##Tracing Highscore number "+i);
				i++;
				//trace(highscoreID);
				var leaderboard:Array = jsonInfo[highscoreID];
				for each (var entry:Object in leaderboard) {
					//trace(entry.highscoreValue);
					//trace(entry.date);
						
					// Check to update highscore
					if (entry.highscoreValue < currentHighscore)
					{
						globals.Loader_StatsCollectionHighscores.movieClip.SaveHighScore('XXXXXXXXXXXXXXXXXXX', 2, currentHighscore);
						//this.setHighScore(currentHighscore);
						trace("## HIGH SCORE SUCCESFULLY UPDATED TO "+currentHighscore);
						this.gameAPI.SendServerCommand("HighscoreAchieved "+currentHighscore);
					}
					else
					{
						//trace("## Another higher score was found: ",entry.highscoreValue);
						currentHighscore = entry.highscoreValue;
						//this.setHighScore(currentHighscore);
					}
				}
			}
			if (i == 0) { 
				//trace("## NO HIGHSCORES, DEFAULTING TO 0"); 
				globals.Loader_StatsCollectionHighscores.movieClip.SaveHighScore('XXXXXXXXXXXXXXXXXXX', 2, 1);//Save 1 highscore because 0 is dumbo
				currentHighscore = 0;
				//this.setHighScore(currentHighscore);
				//this.gameAPI.SendServerCommand("ShowFirstTime");
			}
			else
			{
				//Welcome back! your highscore is...
			}
			this.gameAPI.SendServerCommand("HighscoreRetrieved " + currentHighscore);
		}
		// end of highscore stuff

		public function change_segments_to_win(args:Object) : void {
			var tf:TextFormat = segmentsToWinLabel.getTextFormat()
			segmentsToWinLabel.text = Globals.instance.GameInterface.Translate("#SegmentsToWinLabel") + " " + args.amount
			segmentsToWinLabel.setTextFormat(tf)
			segmentsToWinLabel.visible = true
		}

		public function showMainAbility(args:Object) : void {
			if (globals.Players.GetLocalPlayer() == args.pID)
			{
				globals.Loader_actionpanel.movieClip.visible = false
				Globals.instance.GameInterface.SetConvar("dota_render_crop_height", "0")
				Globals.instance.GameInterface.SetConvar("dota_draw_portrait", "0")
				showAbilityButton();
			}
		}

		private function myEnterFrame(e:Event) : void {
			//trace("new frame.")
			if (cinematicStart) {
				if (firstPartTimer == null) {
					firstPartTimer = new Timer(1000, firstPartLifespan)
					firstPartTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onFirstPartTimerComplete);
					Globals.instance.GameInterface.SetConvar("r_farz", r_farz.toString());
					Globals.instance.GameInterface.SetConvar("dota_camera_edgemove", "0");
					Globals.instance.GameInterface.SetConvar("dota_camera_disable_zoom", "1");
					trace("distInterval: " + distInterval)
					trace("yawInterval: " + yawInterval)
					trace("pitchInterval: " + pitchInterval)
					trace("starting first part.")
					firstPartTimer.start()
				}

				if (!firstPartOver) {
					if (currentDist > endingDist) {
						currentDist += distInterval;
						//trace("currentDist: " + currentDist)
						Globals.instance.GameInterface.SetConvar("dota_camera_distance", currentDist.toString());
					}
					if (currentYaw < endYaw) {
						currentYaw += yawInterval
						//trace("currentYaw: " + currentYaw)
						Globals.instance.GameInterface.SetConvar("dota_camera_yaw", currentYaw.toString());
					}
					if (currentPitch > endPitch) {
						currentPitch += pitchInterval
						//trace("currentPitch " + currentPitch)
						Globals.instance.GameInterface.SetConvar("dota_camera_pitch_max", currentPitch.toString());
					}
				}
				if (firstPartOver && !secondPartOver) {
					//trace("starting second part.")
				}
			}

		}

        public function onFirstPartTimerComplete(event:TimerEvent):void 
        {
        	trace("ending first part.")
            // prep for second part
			Globals.instance.GameInterface.SetConvar("dota_camera_edgemove", "1");
			Globals.instance.GameInterface.SetConvar("dota_camera_disable_zoom", "0");
			Globals.instance.GameInterface.SetConvar("dota_camera_distance", startingDist.toString())
			Globals.instance.GameInterface.SetConvar("dota_camera_yaw", startYaw.toString());
			Globals.instance.GameInterface.SetConvar("dota_camera_pitch_max", startPitch.toString());

            firstPartOver = true;
        } 

		public function startEndingCinematic(args:Object) : void {
			//Globals.instance.GameInterface.SetConvar
			cinematicStart = true

		}

		public function turnOffWaitForPlayers(args:Object) : void {
			this.waitForPlayers.visible = false
			this.waitForPlayers2.visible = false
		}

		public function showAbilityButton(): void {
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
					
			segmentsToWin.width = segmentsToWin.width*scaleRatioY
			segmentsToWin.height = segmentsToWin.height*scaleRatioY

			segmentsToWin.x = ScreenWidth-segmentsToWin.width
			segmentsToWin.y = 3

			//pass the resize event to our module, we pass the width and height of the screen, as well as the INVERSE of the stage scaling ratios.
			this.scoreBoard.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			this.waitForPlayers.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			this.waitForPlayers2.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			this.feedback.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			this.playAgain.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			this.customEndScreen.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			//this.waitForPlayersBottom.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
		}
	}
}