// New script for rolling dice.
// Written by Tenaar Feiri.
// NOTE: I am basically number-blind so I suck at math.
// Still, I have attempted to offer as fairly randomized numbers as overly possible.

integer roll_dice(integer num)
{
	integer result;

	integer x = 1;
	integer y = num;

	result = llFloor(

		x + (integer)(llFrand(y - x + 1))


			);

	return result;
}

string letUsRoll(integer num)
{
	list temp;
	integer x;
	integer y = 50;
	for(;x<=50;x++)
	{
		temp += roll_dice(num);
	}

	string out;
	x = 0;
	for(;x<=50;x++)
	{
		temp = llListRandomize(temp, 1);
	}
	x = 0;
	out = (string)llList2String(temp, llFloor(

		x + (integer)(llFrand((y-1) - x + 1))


			));

	return out;
}

default
{
	state_entry()
	{
		//llSay(0, "Hello, Avatar!");
	}

	changed(integer change)
	{
		if(change & CHANGED_OWNER)
		{
			llResetScript();
		}
	}

	link_message(integer sender, integer number, string message, key id)
	{
		// We receive the diceroll request here. The number will be 9985
		if(number == 9985)
		{
			string objName = llGetObjectName();
			list tmp = llParseString2List(message, [":"], []);
			if(llList2String(tmp, 0) == "silentroll")
			{
				llSetObjectName(llKey2Name(llGetOwner())+"'s private dice roll");
				llOwnerSay(letUsRoll(llList2Integer(tmp, 1)));
			}
			else
			{
				llSetObjectName(llKey2Name(llGetOwner())+"'s dice roll");
				llSay(letUsRoll(llList2Integer(tmp, 1)), 0);
			}

			llSetObjectName(objName);
		}
	}

}