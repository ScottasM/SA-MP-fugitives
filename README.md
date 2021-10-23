# SA-MP-fugitives
A fugitives system written using FCNPC plugin. 

Fugitives will be driving in a vehicle around los santos and some of them will even shoot at you standing on top of the car.
Players goal is to shoot those fugitives down, and to catch them completely - destroy the vehicle. Once they are down players have to handcuff them and transport them back to the station to get a reward.



The whole system works on prerecorded paths. There are 3 scenarios with 3 different paths for each scenario. When one path is completed it chooses one from other 2 and will go like that forever.
All paths end in the same location, so the change of pathes(teleportation) isn't seen.
Bank robbing scenario has 2 bots on top of the vehicle(surfing) that shoots police officers around them
store robbing has 1 surfing bot
hit and run has only the driver.
  
This code was originally written in lithuanian language, so i tried to explain as much as i can. Happy to help if you can't understand something.

Installation : 

Add PDbegliai.amx to your filterscrips folder. (Or compile PDbegliai.pwn with all the changes you need)
Add PDbegliai to filterscripts line in server.cfg 
Add FCNPC and streamer, sscanf (if you don't have) plugins to your server
Done. 

To test the system out use /testfugitive to launch them and /telenpc to teleport.

Here is a video we made to showcase the system. It is in lithuanian, but you can see how it works even without understanding the language
https://www.youtube.com/watch?v=6onQq9nQEDg



