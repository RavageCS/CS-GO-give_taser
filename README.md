# [CSGO] give_taser
Gives an admin or any user a taser and equips the taser when they type !taser or /taser in chat, or sm_taser in console.   
If player already has a taser, using sm_taser will equip it.  
If player has a taser equiped when sm_taser is used the taser will be removed and switch to last weapon used.  
When a taser is removed money and variables are reset.  
This is useful if you dont want to spawn with a taser, since taser is in the same slot as knife and csgo always takes the taser out first.  
Command can be public, any admin, or a specific admin flag required.  
   
Works best when bound to a key ex:  **bind t sm_taser**

---
### Cvars:  
* sm_gt_enabled: Plugin enabled or disabled (def: 1)
* sm_gt_max_round: Amount of tasers player can receive each round (def: 1)
* sm_gt_max_life: Amount of tasers player can receive each life (def: -1)
* sm_gt_track_buys: Should plugin count tasers purchased from buy menu (def: 1)
* sm_gt_track_money: Require player to pay $200 to receive a taser (def: 0)
* sm_gt_cooldown: Number of seconds to wait between giving a taser, 0 to disable, time starts when fired (def: 120)
* sm_gt_admin_flag: Admin flag required to receive a taser none for no flag needed any allows any admin flag (def: any)
Valid flags: any, none, a,b,c,d,e,f,g,h,i,j,k,m,n,z,o,p

---
### Note:
Currently can not remove tasers purchased from buy menu, only tasers given by sm_taser.  
[Allied Modders Thread](https://forums.alliedmods.net/showthread.php?t=286092 "Allied Modders Thread")