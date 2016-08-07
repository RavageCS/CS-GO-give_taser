# [CSGO] give_taser
Gives an admin or any user a taser when they type !taser or /taser in chat, or sm_taser in console. This is useful if you dont want to spawn with a taser, since taser is in the same slot as knife and csgo always takes the taser out first. Command can be public, any admin, or a specific admin flag required.   
Works best when bound to a key ex:  **bind v sm_taser**

---
### Cvars:  
* sm_gt_enabled: Plugin enabled or disabled (def: 1)
* sm_gt_max_round: Amount of tasers player can recive each round (def: 1)
* sm_gt_max_life: Amount of tasers player can recive each life (def: -1)
* sm_gt_admin_flag: Admin flag required to receive a taser none for no flag needed any allows any admin flag (def: any)
Valid flags: any, none, a,b,c,d,e,f,g,h,i,j,k,m,n,z,o,p

---
### Note:
This plugin only tracks tasers given by this plugin. If a player buys or is given a taser from another plugin, they will still be able to receive tasers using sm_taser.  
[Allied Modders Thread](https://forums.alliedmods.net/showthread.php?t=286092 "Allied Modders Thread")