/*================================================================================
	
	----------------------
	-*- [ZP] Knockback -*-
	----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <xs>

// Knockback Power values for weapons
// Note: negative values will disable knockback power for the weapon
new Float:kb_weapon_power[] = 
{
	-1.0,	// ---
	2.4,	// P228
	-1.0,	// ---
	6.5,	// SCOUT
	-1.0,	// ---
	8.0,	// XM1014
	-1.0,	// ---
	2.3,	// MAC10
	5.0,	// AUG
	-1.0,	// ---
	2.4,	// ELITE
	2.0,	// FIVESEVEN
	2.4,	// UMP45
	5.3,	// SG550
	5.5,	// GALIL
	5.5,	// FAMAS
	2.2,	// USP
	2.0,	// GLOCK18
	10.0,	// AWP
	2.5,	// MP5NAVY
	5.2,	// M249
	8.0,	// M3
	5.0,	// M4A1
	2.4,	// TMP
	6.5,	// G3SG1
	-1.0,	// ---
	5.3,	// DEAGLE
	5.0,	// SG552
	6.0,	// AK47
	-1.0,	// ---
	2.0		// P90
}

new cvar_knockback_damage, cvar_knockback_power
new cvar_knockback_zvel, cvar_knockback_ducking, cvar_knockback_distance

public plugin_init()
{
	register_plugin("[ZP] Knockback", "91905891.0", "ZP Dev Team")
	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Post", 1)
	
	cvar_knockback_damage = register_cvar("zp_knockback_damage", "1")
	cvar_knockback_power = register_cvar("zp_knockback_power", "1")
	cvar_knockback_zvel = register_cvar("zp_knockback_zvel", "0")
	cvar_knockback_ducking = register_cvar("zp_knockback_ducking", "0.25")
	cvar_knockback_distance = register_cvar("zp_knockback_distance", "500")
}

// Ham Trace Attack Post Forward
public fw_TraceAttack_Post(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return;
	
	// Victim isn't zombie or attacker isn't human
	if (cs_get_user_team(victim) != 2 || cs_get_user_team(attacker) == 2)
		return;
	
	// Not bullet damage
	if (!(damage_type & DMG_BULLET))
		return;
	
	// Knockback only if damage is done to victim
	if (damage <= 0.0 || GetHamReturnStatus() == HAM_SUPERCEDE || get_tr2(tracehandle, TR_pHit) != victim)
		return;
	
	// Get whether the victim is in a crouch state
	new ducking = pev(victim, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)
	
	// Zombie knockback when ducking disabled
	if (ducking && get_pcvar_float(cvar_knockback_ducking) == 0.0)
		return;
	
	// Get distance between players
	static origin1[3], origin2[3]
	get_user_origin(victim, origin1)
	get_user_origin(attacker, origin2)
	
	// Max distance exceeded
	if (get_distance(origin1, origin2) > get_pcvar_num(cvar_knockback_distance))
		return ;
	
	// Get victim's velocity
	static Float:velocity[3]
	pev(victim, pev_velocity, velocity)
	
	// Use damage on knockback calculation
	if (get_pcvar_num(cvar_knockback_damage))
		xs_vec_mul_scalar(direction, damage, direction)
	
	// Get attacker's weapon id
	new attacker_weapon = get_user_weapon(attacker)
	
	// Use weapon power on knockback calculation
	if (get_pcvar_num(cvar_knockback_power) && kb_weapon_power[attacker_weapon] > 0.0)
		xs_vec_mul_scalar(direction, kb_weapon_power[attacker_weapon], direction)
	
	// Apply ducking knockback multiplier
	if (ducking)
		xs_vec_mul_scalar(direction, get_pcvar_float(cvar_knockback_ducking), direction)
	
	// Add up the new vector
	xs_vec_add(velocity, direction, direction)
	
	// Should knockback also affect vertical velocity?
	if (!get_pcvar_num(cvar_knockback_zvel))
		direction[2] = velocity[2]
	
	// Set the knockback'd victim's velocity
	set_pev(victim, pev_velocity, direction)
}