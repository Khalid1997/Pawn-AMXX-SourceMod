#define SQLON 0 // 1 = Use SQL | 0 = Use file


#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <zombieplague>

//new HELPPAGE[] = "http://home.netcom.com/~everco_ice/bankhelp17.html"
new gHELPPAGE[125]

new bool:canuse[33] = false
new interest[33] = 0
new bankfees = 0
new rounds = 0
new sayspecial[33] = 0
new withdrawals[33]

#define MAX_MONEY 50000

enum BANK_UPGRADES{
	BANK_LOADED,		//if someone has their bank stats loaded
	BANK_LIMIT,			//max money someone can have in their bank
	BANK_INTTIME,		//rounds until interest
	BANK_INTEREST		//interest ammount
}

new play_bank[33][BANK_UPGRADES];

#define MAX_LIMITS 1
new Limit[MAX_LIMITS] = { 10000000000 }
new CostLimit[MAX_LIMITS-1] = { 0 };
 
#define MAX_INTTIME 5
new IntTime[MAX_INTTIME] = { 25, 20, 15, 10, 5 }
new CostIntTime[MAX_INTTIME-1] = { 1000, 1500, 3000, 5000 };
 
#define MAX_INTERESTS 5
new Float:Interest[MAX_INTERESTS] = { 0.01, 0.03, 0.05, 0.07, 0.1 }
new CostInterest[MAX_INTERESTS-1] = { 100, 500, 1000, 2000 };
 
#define AUTO_DEP 50     //with the first level, they will deposit if they go over this much


#if SQLON
	#include <dbi>
#else
	#include <vault>
#endif

#if SQLON
	new Sql:dbc
	new Result:result
#else
	new allowfilepath[251]
#endif

new bank_default_opening, bank_state, bank_min_players, bank_restrict, bank_fees_base, bank_fees_increase
new bank_offrounds, bank_msg_interval, bank_msg, bank_use_ip

public plugin_init()
{
	register_plugin("AMX Bank","3.0","twistedeuphoria/Emp")
	register_concmd("bank_create","bank_create",ADMIN_USER,"Create a new bank account.")
	register_concmd("bank_close","bank_close",ADMIN_CVAR,"Close the AMX Bank.")
	register_concmd("bank_open","bank_open",ADMIN_CVAR,"Open the AMX Bank for business.")
	register_concmd("bank_amount","bank_amount",ADMIN_USER,"Display the amount of money you have in the bank.")
	register_concmd("bank_deposit","bank_deposit",ADMIN_USER,"<amount> :Deposit money into your bank account.")
	register_concmd("bank_withdraw","bank_withdrawl",ADMIN_USER,"<amount> :Withdraw money from your bank account.")
	register_concmd("bank_help","bank_help",ADMIN_USER,"Open up the help for the bank.")
	register_concmd("bank_transfer","bank_transfer",ADMIN_USER,"<user> <amount> : Transfer money to another player.")
	register_concmd("bank_givemoney","bank_givemoney",ADMIN_CVAR,"<user> <amount> : Give a user money.")
	register_concmd("bank_status","bank_status",ADMIN_CVAR,"<user> : Shows user bank stats in console.")
	register_concmd("bank_menu","bank_menu",ADMIN_USER,"Open the bank menu.")
	//register_concmd("bank_upgrade","bank_upgrade",ADMIN_USER,"Upgrades for your bank.")
	register_concmd("maxdep","deposit_maximum",ADMIN_USER,"Deposit all your money.")
	register_concmd("maxwit","withdrawl_maximum",ADMIN_USER,"Withdrawl until you have 50 ammo packs or your bank account is empty.")
	register_clcmd("say","say_cheese")
	register_clcmd("say_team","say_cheese")

	bank_default_opening = register_cvar("bank_default_opening","0")
	bank_state = register_cvar("bank_state","1")
	bank_min_players = register_cvar("bank_min_players","1")
	bank_restrict = register_cvar("bank_restrict","0") // 0 = All user can use the bank 1 = Only users defined in file or SQL
	bank_fees_base = register_cvar("bank_fees_base","0")  //Base bank fee in $
	bank_fees_increase = register_cvar("bank_fees_increase","0") //Added to the base fee for each transaction in a round
	bank_offrounds = register_cvar("bank_offrounds","0") //How many rounds from the start of the map will bank be off for
	bank_msg_interval = register_cvar("bank_msg_interval","60")
	bank_msg = register_cvar("bank_msg","Type bank_help in console to find out how to use the ammo packs bank.")
	bank_use_ip = register_cvar("bank_use_ip","0")

	register_menucmd(register_menuid("Bank Menu:"),1023,"bank_menu_cmd")
	register_menucmd(register_menuid("Bank Upgrades:"),1023,"bank_upgrade_cmd")

	//register_logevent("giveinterest",2,"0=World triggered","1=Round_Start")
        set_task(60.0,"giveinterest",_,_,_,"b");

	#if SQLON
		set_task(5.0,"sqlinit")
	#else
		new directory[201]
		get_configsdir(directory,200)
		if(get_pcvar_num(bank_restrict) == 2)
		{
			formatex(allowfilepath,250,"%s/bankusers.ini",directory)
			if(!file_exists(allowfilepath))
			{
				new writestr[101]
				formatex(writestr,100,";Put all users who can use the bank in here.")
				write_file(allowfilepath,writestr)
			}			
		}
	#endif
	set_task(get_pcvar_float(bank_msg_interval),"bank_spam")

	get_configsdir(gHELPPAGE, 124)
	format(gHELPPAGE, 123, "%s/bank_help.html", gHELPPAGE)
}

public check_use(id,pos)
{
	//client_print(id, print_chat, "Called!!!");
	if(id)
	{
		if( canuse[id] == false)
		{
			if(pos)
			{
				client_print(id,print_chat,"You are not allowed to use the bank.")
			}
			else
			{
				client_print(id,print_chat,"You are not allowed to use the bank.")
			}
			return 0
		}
	}
	new cvarrounds = get_pcvar_num(bank_offrounds)
	if(cvarrounds && rounds <= cvarrounds)
	{
		if(pos)
		{
			client_print(id,print_chat,"Sorry, the bank is disabled for the first %d rounds of the map.",cvarrounds)
		}
		else
		{
			client_print(id,print_chat,"Sorry, the bank is disabled for the first %d rounds of the map.",cvarrounds)
		}
		return 0
	}
	if(!get_pcvar_num(bank_state))
	{
		if(pos)
		{
			client_print(id,print_chat,"Sorry, the bank is closed and no transactions are being processed.")
		}
		else
		{
			client_print(id,print_chat,"Sorry, the bank is closed and no transactions are being processed.")
		}
		return 0
	}
	new players = get_playersnum()
	new minplayers = get_pcvar_num(bank_min_players)
	if(players < minplayers)
	{
		if(pos)
		{
			client_print(id,print_chat,"There must be at least %d players connected to use the bank.",minplayers)
		}
		else
		{
			client_print(id,print_chat,"There must be at least %d players connected to use the bank.",minplayers)
		}
		return 0
	}
	
	//client_print(id, print_chat, "Returned ONE!!!!");
	return 1
}

public get_balance(id)
{
	new sid[35]
	new balance = -1
	if(get_pcvar_num(bank_use_ip))
		get_user_ip(id,sid,34)
	else
		get_user_authid(id,sid,34)
	#if SQLON
		result = dbi_query(dbc,"SELECT * FROM bank WHERE sid = '%s'",sid)
		if(result == RESULT_NONE)
			dbi_free_result(result)
		else
		{
			dbi_nextrow(result)
			balance = dbi_result(result,"amount")
			dbi_free_result(result)
		}
	#else
		new key[51]
		formatex(key,50,"%s_account",sid)
		if(vaultdata_exists(key))
		{
			new total_data[121];
			new balancestr[21], limitstr[21], inttimestr[21], intereststr[21];
			get_vaultdata(key,total_data,120)
			if( !play_bank[id][BANK_LOADED] ){
				parse(total_data, balancestr, 20, limitstr, 20, inttimestr, 20, intereststr, 20);
				play_bank[id][BANK_LOADED] = 1;
				balance = str_to_num(balancestr);
				play_bank[id][BANK_LIMIT] = clamp(str_to_num(limitstr), 0, MAX_LIMITS-1);
				play_bank[id][BANK_INTTIME] = clamp(str_to_num(inttimestr), 0, MAX_INTTIME-1);
				play_bank[id][BANK_INTEREST] = clamp(str_to_num(intereststr), 0, MAX_INTERESTS-1);
			}
			else
				balance = str_to_num(total_data);
		}
	#endif
	return balance
}

public set_balance(id,balance)
{
	new sid[35]
	if(get_pcvar_num(bank_use_ip))
		get_user_ip(id,sid,34)
	else
		get_user_authid(id,sid,34)
	#if SQLON
		result = dbi_query(dbc,"UPDATE bank SET amount = '%d' WHERE sid = '%s'",balance,sid)
		if(result == RESULT_NONE)
		{
			dbi_free_result(result)
			return -1
		}
		else
			return 1
	#else
		new key[51]
		formatex(key,50,"%s_account",sid)
		if(vaultdata_exists(key))
		{
			new totaldata[121];
			formatex(totaldata, 120, "%d %d %d %d", balance, play_bank[id][BANK_LIMIT], play_bank[id][BANK_INTTIME], play_bank[id][BANK_INTEREST] );
			set_vaultdata(key,totaldata)
			return 1
		}
		else
		{
			return -1
		}
	#endif	
}

public bank_menu(id)
{
	new client = 0
	if(read_argc() > 1)
		client = 1
	if(!check_use(id,client)) return PLUGIN_HANDLED
	new menubody[276], keys = 0,len
	new bool:hasacc = true
	len = format(menubody,275,"\r[UaE-Gaming] \wBank Menu:\w^n")
	if(get_balance(id) == -1)
	{
		hasacc = false
		len += format(menubody[len],275-len,"1. Open a Bank Account^n\d")
		keys |= (1<<0|1<<9)		
	}
	else
		len += format(menubody[len],275-len,"\d1. Open a Bank Account^n\w")
	//len += format(menubody[len],275-len,"2. Check your Balance^n3. Deposit Money^n4. Deposit All^n5. Withdraw Money^n6. Withdraw Maximum^n7. Bank Help^n8. Transfer Money^n9. \yBank Upgrades^n^n")
	len += format(menubody[len],275-len,
		"\r2. \yCheck your Balance^n\
		\r3. \yDeposit Money^n\
		\r4. \yDeposit All^n\
		\r5. \yWithdraw Money^n\
		\r6. \yWithdraw All^n\
		\r7. \yBank Help^n\
		\r8. \yTransfer Money^n^n")
	if(hasacc)
	{
		len += format(menubody[len],275-len,"0. Exit")
		//keys |= (1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
		keys |= (1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
	}
	else
		len += format(menubody[len],275-len,"\w0. Exit")
	show_menu(id,keys,menubody,-1,"Bank Menu:")
	return PLUGIN_HANDLED
}

public bank_menu_cmd(id,key)
{
	switch(key)
	{
		case 0: client_cmd(id,"bank_create 1")
		case 1: client_cmd(id,"bank_amount 1")
		case 2:
		{
			sayspecial[id] = 1
			client_print(id,print_chat,"Please enter the amount you want to deposit in chat:")
		}			
		case 3: client_cmd(id,"maxdep")
		case 4:
		{	
			sayspecial[id] = 2
			client_print(id,print_chat,"Please enter the amount you want to withdraw in chat:")
		}
		case 5: client_cmd(id,"maxwit")
		case 6:	client_cmd(id,"bank_help")
		case 7:
		{
			sayspecial[id] = 3
			client_print(id,print_chat,"Please enter the person you want to transfer to and the amount you want to transfer in chat:")
		}
		
		/*
		case 8:	client_cmd(id,"bank_upgrade")
		*/
	}
	return PLUGIN_HANDLED
}

public bank_upgrade(id)
{
	new client = 0
	if(read_argc() > 1)
		client = 1
	if(!check_use(id,client)) return PLUGIN_HANDLED

	if( get_balance(id) <= 0 ){
		client_print( id, print_chat, "You have no money in the bank.");
		return PLUGIN_HANDLED;
	}

	new menubody[512], keys = 0,len

	len = format(menubody,511,"\rBank Upgrades:\w^n^n")
	new currentstat;

	currentstat = play_bank[id][BANK_LIMIT]
	if( currentstat < MAX_LIMITS-1 ){
		len += format(menubody[len],511-len,"1. Bank Limit from %d to \r%d (\y$%d)^n", Limit[currentstat], Limit[currentstat+1], CostLimit[currentstat])
		keys |= (1<<0)
	}
	else
		len += format(menubody[len],511-len,"\d1. Bank Limit is %d^n", Limit[currentstat])

	currentstat = play_bank[id][BANK_INTTIME]
        if( currentstat < MAX_INTTIME-1 ){
                len += format(menubody[len],511-len,"2. Interest Time from %d to \r%d Minutes (\y$%d)^n", IntTime[currentstat], IntTime[currentstat+1], CostIntTime[currentstat])
	}
	else
		len += format(menubody[len],511-len,"\d2. Interest Time is %d Minutes^n", IntTime[currentstat])

	currentstat = play_bank[id][BANK_INTEREST]
        if( currentstat < MAX_INTERESTS-1 ){
                len += format(menubody[len],511-len,"3. Interest Rate from %0.1f%% to \r%0.1f%% (\y$%d)^n", 100.0*Interest[currentstat], 100.0*Interest[currentstat+1], CostInterest[currentstat])
        }
        else
                len += format(menubody[len],511-len,"\d3. Interest Rate is %0.1f%%^n", 100.0*Interest[currentstat])

	len += format(menubody[len],511-len,"0. Exit")
	keys |= (1<<9)

	show_menu(id,keys,menubody,-1,"Bank Upgrades:")
	return PLUGIN_HANDLED
}

public bank_upgrade_cmd(id,key)
{
	new balance = get_balance(id);
	switch(key)
	{
		case 0:{
			new currentstat = play_bank[id][BANK_LIMIT]
			new cost = CostLimit[currentstat]
			if( balance < cost ){
				client_print(id, print_chat, "You need $%d more to upgrade this.", balance-cost );
			}
			else{
				play_bank[id][BANK_LIMIT]++;
				set_balance(id, balance-cost);	//save the new upgrade
				client_print(id, print_chat, "You have upgraded your Bank Limit." );
			}
			bank_upgrade(id);
		}
		case 1:{
			new currentstat = play_bank[id][BANK_INTTIME]
			new cost = CostIntTime[currentstat]
			if( balance < cost ){
				client_print(id, print_chat, "You need $%d more to upgrade this.", balance-cost );
			}
			else{
				play_bank[id][BANK_INTTIME]++;
				set_balance(id, balance-cost);	//save the new upgrade
				client_print(id, print_chat, "You have upgraded your Interest Time." );
			}
			bank_upgrade(id);
		}
		case 2:{
			new currentstat = play_bank[id][BANK_INTEREST]
			new cost = CostInterest[currentstat]
			if( balance < cost ){
				client_print(id, print_chat, "You need $%d more to upgrade this.", balance-cost );
			}
			else{
				play_bank[id][BANK_INTEREST]++;
				set_balance(id, balance-cost);	//save the new upgrade
				client_print(id, print_chat, "You have upgraded your Interest Rate." );
			}
			bank_upgrade(id);
		}
		case 9:	bank_menu(id);
	}
	return PLUGIN_HANDLED
}

public bank_givemoney(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED
	new target[32], tid
	read_argv(1,target,31)
	tid = cmd_target(id,target,2)
	if(!tid)
		return PLUGIN_HANDLED
	new amountstr[10], amount
	read_argv(2,amountstr,9)
	amount = str_to_num(amountstr)
	new totam = amount
	new curmoney = zp_get_user_ammo_packs(tid)
	new newtotal = curmoney + amount
	if(newtotal > MAX_MONEY)
	{		
		zp_set_user_ammo_packs(tid,MAX_MONEY)
		amount = newtotal - MAX_MONEY
	}
	else
	{
		zp_set_user_ammo_packs(tid,newtotal)
		amount = 0
	}
	if(amount > 0)
	{	
		new balance = get_balance(tid)
		if(balance != -1)
			set_balance(id,balance + amount)
	}
	new name[32], tname[32]
	get_user_name(id,name,31)
	get_user_name(tid,tname,31)
	if(read_argc() == 4)
		client_print(id,print_chat,"You gave %s %d ammo packs.",tname,totam)
	else
		console_print(id,"You gave %s %d ammo packs.",tname,totam)
	client_print(tid,print_chat,"%s gave you %d ammo packs, %d ammo packs of which went into your bank account.",name,totam,amount)
	return PLUGIN_HANDLED
}	
public bank_status(id,level,cid)
{
        if(!cmd_access(id,level,cid,2))
                return PLUGIN_HANDLED
        new target[32], tid
        read_argv(1,target,31)
        tid = cmd_target(id,target,2)
        if(!tid)
                return PLUGIN_HANDLED
 
        new tname[32]
        get_user_name(tid,tname,31)
 
        client_print(id,print_chat,"%s has %d ammo packs, %d in bank, %d bank limit, %d interest time, %0.1f interest.",tname,zp_get_user_ammo_packs(tid),get_balance(tid),Limit[play_bank[tid][BANK_LIMIT]],IntTime[play_bank[tid][BANK_INTTIME]],Interest[play_bank[tid][BANK_INTEREST]])
        console_print(id,"%s has %d ammo packs, %d in bank, %d bank limit, %d interest time, %0.1f interest.",tname,zp_get_user_ammo_packs(tid),get_balance(tid),Limit[play_bank[tid][BANK_LIMIT]],IntTime[play_bank[tid][BANK_INTTIME]],Interest[play_bank[tid][BANK_INTEREST]])
 
        return PLUGIN_HANDLED
}

public bank_transfer(id)
{
	new client = 0
	if(read_argc() > 3)
		client = 1
	if(!check_use(id,client)) return PLUGIN_HANDLED
	new target[32]
	read_argv(1,target,31)
	new tgt = cmd_target(id,target,8)
	if(!tgt)
		return PLUGIN_HANDLED
	if(id == tgt)
	{
		if(client)
			client_print(id,print_chat,"You may not transfer money to yourself.")
		else
			console_print(id,"You may not transfer money to yourself.")
		return PLUGIN_HANDLED
	}		
	new tamounts[9],tamount
	read_argv(2,tamounts,8)
	tamount = str_to_num(tamounts)
	if(tamount <= 0) return PLUGIN_HANDLED
	new balance = get_balance(id)
	if(balance == -1)
	{
		if(client)
			client_print(id,print_chat,"You do not have a bank account to transfer money from.")
		else
			console_print(id,"You do not have a bank account to transfer money from.")
		return PLUGIN_HANDLED
	}
	new tbalance = get_balance(tgt)
	new name[32], tname[32]
	get_user_name(tgt,tname,31)
	get_user_name(id,name,31)	
	if(tbalance == -1)
	{
		if(client)
			client_print(id,print_chat,"%s does not have a bank account to transfer money to.",tname)
		else
			console_print(id,"%s does not have a bank account to transfer money to.",tname)
		client_print(tgt,print_chat,"%s tried to transfer money to your account but you don't have a bank account!",name)
		return PLUGIN_HANDLED
	}	
	balance -= tamount
	balance -= bankfees
	if(balance < 0)
	{
		if(client)
			client_print(id,print_chat,"You do not have enough money in your bank account.")
		else
			console_print(id,"You do not have enough money in your bank account.")
		return PLUGIN_HANDLED
	}
	tbalance += tamount
	if(bankfees > 0)
	{
		if(client)
			client_print(id,print_chat,"You paid %d ammo packs in bank fees.",bankfees)
		else
			console_print(id,"You paid %d ammo packs in bank fees.",bankfees)
	}		
	set_balance(id,balance)
	set_balance(tgt,tbalance)
	if(client)
		client_print(id,print_chat,"You have transferred %d ammo packs to %s's bank account. You now have %d ammo packs in your account.",tamount,tname,balance)
	else
		console_print(id,"You have transferred %d ammo packs to %s's bank account. You now have %d ammo packs in your account.",tamount,tname,balance)
	client_print(tgt,print_chat,"%s has transferred %d ammo packs to your bank account. You now have %d ammo packs in your account.",name,tamount,tbalance)
	return PLUGIN_HANDLED
}


public zp_user_infected_post(victim, id)
{
	if(!get_pcvar_num(bank_state))
		return PLUGIN_CONTINUE
	new curmoney = zp_get_user_ammo_packs(id)
	if(curmoney < MAX_MONEY)
		return PLUGIN_CONTINUE
	if(canuse[id] == false)
		return PLUGIN_CONTINUE
	new cvarrounds = get_pcvar_num(bank_offrounds)
	if(rounds <= cvarrounds)
		return PLUGIN_CONTINUE
	if(get_playersnum() >= get_pcvar_num(bank_min_players))
	{
		new balance = get_balance(id)
		if(balance == -1)
			return PLUGIN_CONTINUE
		balance += AUTO_DEP
		set_balance(id,balance)
		zp_set_user_ammo_packs(id,curmoney-AUTO_DEP)
		client_print(id,print_chat,"%d ammo packs have been automatically deposited in your bank account. You now have %d ammo packs in your account.",AUTO_DEP,balance)
	}
	return PLUGIN_CONTINUE
}

public bank_spam()
{
	new cvarval = get_pcvar_num(bank_state)
	if(cvarval)
	{
		new message[256]
		get_pcvar_string(bank_msg,message,255)
		client_print(0,print_chat,message)
	}
	set_task(get_pcvar_float(bank_msg_interval),"bank_spam")
}

public bank_help(id)
{
	show_motd(id,gHELPPAGE,"AMX Bank Help")
}

public say_cheese(id)
{
	new said[191]
	read_args(said,190)
	remove_quotes(said)
	if(sayspecial[id])
	{
		switch(sayspecial[id])
		{
			case 1: client_cmd(id,"bank_deposit %s 1",said)
			case 2: client_cmd(id,"bank_withdraw %s 1",said)
			case 3: client_cmd(id,"bank_transfer %s 1",said)
		}
		sayspecial[id] = 0
		return PLUGIN_HANDLED
	}				
	if(equali(said,"/bank"))
	{
		client_cmd(id,"bank_menu")
		return PLUGIN_HANDLED
	}
	if(said[0] == 'm')
	{
		if(equali(said,"maxwit"))
		{
			withdrawl_maximum(id)
			return PLUGIN_HANDLED
		}
		if(equali(said,"maxdep"))
		{
			deposit_maximum(id)
			return PLUGIN_HANDLED
		}
	}
	else if(said[0] == 'b')
	{
		if(containi(said,"bank_") != -1)
		{
			if(equali(said,"bank_amount"))
			{
				client_cmd(id,"bank_amount 1")
				return PLUGIN_HANDLED
			}
			if(containi(said,"bank_withdraw") != -1)
			{
				replace(said,190,"bank_withdraw","")
				client_cmd(id,"bank_withdraw %s 1",said)
				return PLUGIN_HANDLED
			}
			if(containi(said,"bank_deposit") != -1)
			{
				replace(said,190,"bank_deposit","")
				client_cmd(id,"bank_deposit %s 1",said)
				return PLUGIN_HANDLED
			}
			if(containi(said,"bank_transfer") != -1)
			{
				replace(said,190,"bank_transfer","")
				new target[51],amountstr[51]
				parse(said,target,50,amountstr,50)
				client_cmd(id,"bank_transfer %s %s 1",target,amountstr)
				return PLUGIN_HANDLED
			}
			if(containi(said,"bank_givemoney") != -1)
			{
				replace(said,190,"bank_givemoney","")
				new target[51],amountstr[51]
				parse(said,target,50,amountstr,50)
				client_cmd(id,"bank_givemoney %s %s 1",target,amountstr)
				return PLUGIN_HANDLED
			}
			if(equali(said,"bank_create"))
			{
				client_cmd(id,"bank_create 1")
				return PLUGIN_HANDLED
			}			
			if(equali(said,"bank_help"))
			{
				bank_help(id)
				return PLUGIN_HANDLED
			}
			if(equali(said,"bank_open"))
			{
				client_cmd(id,"bank_open 1")
				return PLUGIN_HANDLED
			}
			if(equali(said,"bank_close"))
			{
				client_cmd(id,"bank_close 1")
				return PLUGIN_HANDLED
			}
			if(equali(said,"bank_upgrade"))
			{
				client_cmd(id,"bank_upgrade 1")
				return PLUGIN_HANDLED
			}
			if(equali(said,"bank_menu") || equali(said,"bank"))
			{
				client_cmd(id,"bank_menu")
				return PLUGIN_HANDLED
			}
		}
	}
	return PLUGIN_CONTINUE
}

public giveinterest()
{
	rounds++
	if(!check_use(0,1)) return PLUGIN_CONTINUE
	bankfees = get_pcvar_num(bank_fees_base)
	if(!get_pcvar_num(bank_state))
		return PLUGIN_CONTINUE
	for(new i = 1;i<=32;i++)
	{
		if(is_user_connected(i))
		{
			new balance = get_balance(i)
			if(canuse[i] && balance > 0)
			{
				interest[i]++
				if(interest[i] >= IntTime[play_bank[i][BANK_INTTIME]])
				{
					interest[i] = 0

					new Float:give = floatmul(Interest[play_bank[i][BANK_INTEREST]],float(balance))
					new givint = floatround(give)
					if(givint > 0)
					{
						new allowed = MAX_MONEY - zp_get_user_ammo_packs(i)
						if(givint <= allowed)
						{
							zp_set_user_ammo_packs(i,zp_get_user_ammo_packs(i)+givint)
							client_print(i,print_chat,"You were given %d ammo packs in interest.",givint)
						}
						else
						{
							new dep = givint - allowed
							client_print(i,print_chat,"You were given %d ammo packs in interest %d ammo packs of which went into your account.",givint,dep)
							zp_set_user_ammo_packs(i,MAX_MONEY)
							balance += dep
							if( balance > Limit[play_bank[i][BANK_LIMIT]] )
							{
								client_print(i,print_chat,"Your bank is at its limit of %d ammo packs.",Limit[play_bank[i][BANK_LIMIT]])
								balance = Limit[play_bank[i][BANK_LIMIT]];
							}
							set_balance(i,balance)
						}
					}
				}
			}
		}
	}
	return PLUGIN_CONTINUE
}

public client_authorized(id)
{
	interest[id] = 0
	withdrawals[id] = 0
	canuse[id] = false

	for( new BANK_UPGRADES:i; i<BANK_UPGRADES; i++ )
		play_bank[id][i] = 0;

	switch(get_pcvar_num(bank_restrict))
	{
		case 0:
		{
			canuse[id] = true
		}
		case 1:
		{
			if(access(id,ADMIN_CHAT))
				canuse[id] = true
			else
				canuse[id] = false
		}
		case 2:
		{
			canuse[id] = false
			new sid[35]
			if(get_pcvar_num(bank_use_ip))
				get_user_ip(id,sid,34,1)
			else
				get_user_authid(id,sid,34)
			#if SQLON	
				result = dbi_query(dbc,"SELECT * FROM bankusers WHERE sid = '%s'",sid)
				if(result == RESULT_NONE)
					canuse[id] = false
				else
					canuse[id] = true
				dbi_free_result(result)
			#else
				new retstr[35],a,i
				while(read_file(allowfilepath,i,retstr,34,a))
				{
					if(equali(sid,retstr))
						canuse[id] = true
					i++
				}
			#endif
		}
	}
}	

public client_disconnect(id)
{
	deposit_maximum(id);
	canuse[id] = false
	interest[id] = 0
}

public deposit_maximum(id)	
{
	if(!check_use(id,1)) return PLUGIN_HANDLED	
	new curmoney = zp_get_user_ammo_packs(id)
	new balance = get_balance(id)
	if(balance == -1)
	{
		client_print(id,print_chat,"You do not have a bank account.")
		return PLUGIN_HANDLED	
	}
	balance += curmoney
	if( balance > Limit[play_bank[id][BANK_LIMIT]] )
	{
		client_print(id,print_chat,"The max amount to have in bank is %d.",Limit[play_bank[id][BANK_LIMIT]])
		return PLUGIN_HANDLED
	}
	set_balance(id,balance)
	zp_set_user_ammo_packs(id,0)
	client_print(id,print_chat,"You have deposited %d ammo packs in your bank account. You now have %d ammo packs in your account.",curmoney,balance)
	return PLUGIN_HANDLED
}

public withdrawl_maximum(id)
{
	if(!check_use(id,1)) return PLUGIN_HANDLED
	new balance = get_balance(id)
	if(balance == -1)
	{
		client_print(id,print_chat,"You do not have a bank account.")
		return PLUGIN_HANDLED
	}
	new curmoney = zp_get_user_ammo_packs(id)
	new maxmoney = MAX_MONEY - zp_get_user_ammo_packs(id)
	if(maxmoney > balance)
		maxmoney = balance
	balance -= maxmoney
	zp_set_user_ammo_packs(id,curmoney + maxmoney)
	if((balance - bankfees) > 0)
		balance -= bankfees
	else
		zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) - bankfees)
	if(bankfees > 0)
		client_print(id,print_chat,"You paid %d ammo packs in bank fees.",bankfees)
	bankfees += get_pcvar_num(bank_fees_increase)		
	set_balance(id,balance)
	client_print(id,print_chat,"You have withdrawn %d ammo packs from your bank account. You now have %d ammo packs in your account.",maxmoney,balance)
	return PLUGIN_HANDLED
}
	
public bank_amount(id)
{
	new client = 0
	if(read_argc() > 1)
		client = 1
	if(!check_use(id,client)) return PLUGIN_HANDLED
	new balance = get_balance(id)
	if(balance == -1)
	{
		if(client)
			client_print(id,print_chat,"You do not have a bank account.")
		else
			console_print(id,"You do not have a bank account.")
		return PLUGIN_HANDLED		
	}
	else
	{
		if(client)
			client_print(id,print_chat,"You have %d ammo packs in your bank account.",balance)
		else
			console_print(id,"You have %d ammo packs in your bank account.",balance)
	}
	return PLUGIN_HANDLED
}

public bank_open(id,level,cid)
{
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	new client = 0
	if(read_argc() > 1)
		client = 1
	if(get_pcvar_num(bank_state))
	{
		if(client)
			client_print(id,print_chat,"The AMX bank is already open.")
		else
			console_print(id,"The AMX bank is already open.")
	}
	else
	{
		console_cmd(id,"amx_cvar bank_state 1")
		if(get_pcvar_num(bank_state))
		{
			if(client)
				client_print(id,print_chat,"The bank is now open.")
			else
				console_print(id,"The bank is now open.")
			client_print(0,print_chat,"The bank is now open for business.")
		}		
		else
		{
			if(client)
				client_print(id,print_chat,"You may not open the bank.")
			else
				console_print(id,"You may not open the bank.")
		}	
	}
	return PLUGIN_HANDLED
}

public bank_close(id,level,cid)
{	
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	new client = 0 
	if(read_argc() > 1)
		client = 1
	if(!get_pcvar_num(bank_state))
	{
		if(client)
			client_print(id,print_chat,"The AMX bank is already closed.")
		else
			console_print(id,"The AMX bank is already closed.")
	}
	else
	{
		console_cmd(id,"amx_cvar bank_state 0")
		if(!get_pcvar_num(bank_state))
		{
			if(client)
				client_print(id,print_chat,"The bank is now closed.")
			else
				console_print(id,"The bank is now closed.")
			client_print(0,print_chat,"The bank is now closed.")
		}		
		else
		{
			if(client)
				client_print(id,print_chat,"You may not close the bank.")
			else
				console_print(id,"You may not close the bank.")
		}	
	}
	return PLUGIN_HANDLED
}

public sqlinit()
{
	#if SQLON
		new error[32],sqlhostname[35],sqluser[35],sqlpass[35],sqldbname[35]
		get_cvar_string("amx_sql_host",sqlhostname,34)
		get_cvar_string("amx_sql_user",sqluser,34)
		get_cvar_string("amx_sql_pass",sqlpass,34)
		get_cvar_string("amx_sql_db",sqldbname,34)
		dbc = dbi_connect(sqlhostname,sqluser,sqlpass,sqldbname,error,31)
		if(dbc == SQL_FAILED)
		{
			server_print("Could not connect.")
			return PLUGIN_HANDLED
		}
		result = dbi_query(dbc,"CREATE TABLE IF NOT EXISTS `bank` (`sid` VARCHAR(35), `amount` BIGINT(20))")
		dbi_free_result(result)
		result = dbi_query(dbc,"CREATE TABLE IF NOT EXISTS `bankusers` (`sid` VARCHAR(35), `comments` VARCHAR(100))")
		dbi_free_result(result)
	#endif
	return 1
}

public bank_create(id)
{
	new client = 0
	if(read_argc() > 1)
		client = 1
	if(!check_use(id,client)) return PLUGIN_HANDLED
	new curmoney,neededmoney, amount
	neededmoney = get_pcvar_num(bank_default_opening)
	curmoney = zp_get_user_ammo_packs(id)
	if(curmoney >= neededmoney)
	{
		amount = neededmoney
		curmoney -= neededmoney
	}
	else
	{
		amount = curmoney
		curmoney = 0
	}
	#if SQLON
		new sid[35]
		if(get_pcvar_num(bank_use_ip))
			get_user_ip(id,sid,34,1)
		else
			get_user_authid(id,sid,34)
		result = dbi_query(dbc,"SELECT * FROM bank WHERE sid = '%s'",sid)
		if(result != RESULT_NONE)
		{
			if(client)
				client_print(id,print_chat,"You already have a bank account!")
			else
				console_print(id,"You already have a bank account!")
			return PLUGIN_HANDLED
		}
		dbi_free_result(result)
		result = dbi_query(dbc,"INSERT INTO bank VALUES ( '%s' , '%d')",sid,amount)
		dbi_free_result(result)
	#else
		new sid[35],key[51]
		if(get_pcvar_num(bank_use_ip))
			get_user_ip(id,sid,34,1)
		else
			get_user_authid(id,sid,34)
		format(key,50,"%s_account",sid)
		if(vaultdata_exists(key))
		{
			if(client)
				client_print(id,print_chat,"You already have a bank account!")
			else
				console_print(id,"You already have a bank account!")
			return PLUGIN_HANDLED
		}
		new saveamstr[21]
		num_to_str(amount,saveamstr,20)
		set_vaultdata(key,saveamstr)
	#endif			
	zp_set_user_ammo_packs(id,curmoney)
	if(client)
		client_print(id,print_chat,"Bank account created successfully. Your account has %d ammo packs in it.",amount)
	else
		console_print(id,"Bank account created successfully. Your account has %d ammo packs in it.",amount)

	bank_menu(id);
	return PLUGIN_HANDLED
}

public bank_withdrawl(id)
{
	new client = 0
	if(read_argc() > 2)
		client = 1
	if(!check_use(id,client)) return PLUGIN_HANDLED
	new balance = get_balance(id)
	if(balance == -1)
	{
		if(client)
			client_print(id,print_chat,"You do not have a bank account.")
		else
			console_print(id,"You do not have a bank account.")
		return PLUGIN_HANDLED		
	}
	new ams[9],amn,maxam	
	read_args(ams,8)
	amn = str_to_num(ams)
	if(amn <= 0) return PLUGIN_HANDLED

	if( withdrawals[id] >= MAX_MONEY ){
		client_print(id,print_chat,"You have already withdrawn %d ammo packs from your bank, try again next map.", withdrawals[id] )
		return PLUGIN_HANDLED;
	}

	maxam = MAX_MONEY - zp_get_user_ammo_packs(id)
	if(amn > maxam)
		amn = maxam
	if(amn > balance)
	{
		if(client)
			client_print(id,print_chat,"There is not enough ammo packs in your bank account.")
		else
			console_print(id,"There is not enough ammo packs in your bank account.")
		return PLUGIN_HANDLED
	}
	balance -= amn
	zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) + amn)
	if(balance >= bankfees)
		balance -= bankfees
	else
		zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) - bankfees)	
	set_balance(id,balance)
	if(bankfees > 0)
	{
		if(client)
			client_print(id,print_chat,"You paid %d ammo packs in bank fees.",bankfees)
		else
			console_print(id,"You paid %d ammo packs in bank fees.",bankfees)
	}
	withdrawals[id] += amn;
	bankfees += get_pcvar_num(bank_fees_increase)
	if(client)
		client_print(id,print_chat,"You have withdrawn %d ammo packs from your bank account. You now have %d ammo packs in your account.",amn,balance)
	else
		console_print(id,"You have withdrawn %d ammo packs from your bank account. You now have %d ammo packs in your account.",amn,balance)
	return PLUGIN_HANDLED
}

public bank_deposit(id)
{
	new client = 0
	if(read_argc() > 2)
		client = 1
	if(!check_use(id,client)) return PLUGIN_HANDLED
	new damounts[9],damount,curmoney
	read_args(damounts,8)
	damount = str_to_num(damounts)
	if(damount <= 0) return PLUGIN_HANDLED
	curmoney = zp_get_user_ammo_packs(id)
	if(damount > curmoney)
	{
		if(client)
			client_print(id,print_chat,"You don't have that much ammo packs.")
		else
			console_print(id,"You don't have that much ammo packs.")
		return PLUGIN_HANDLED
	}
	new balance = get_balance(id)
	if(balance == -1)
	{
		if(client)
			client_print(id,print_chat,"You do not have a bank account.")
		else
			console_print(id,"You do not have a bank account.")
		return PLUGIN_HANDLED
	}
	balance += damount
	if( balance > Limit[play_bank[id][BANK_LIMIT]] )
	{
		if(client)
			client_print(id,print_chat,"The max amount to have in bank is %d.",Limit[play_bank[id][BANK_LIMIT]])
		else
			console_print(id,"The max amount to have in bank is %d.",Limit[play_bank[id][BANK_LIMIT]])
		return PLUGIN_HANDLED
	}
	set_balance(id,balance)
	zp_set_user_ammo_packs(id,curmoney - damount)
	if(client)
		client_print(id,print_chat,"You have deposited %d ammo packs in your bank account. You now have %d ammo packs in your account.",damount,balance)
	else
		console_print(id,"You have deposited %d ammo packs in your bank account. You now have %d ammo packs in your account.",damount,balance)
	return PLUGIN_HANDLED
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
