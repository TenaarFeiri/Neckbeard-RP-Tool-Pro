integer cChan = -235798; // Channel for talking to the station.
//integer cChan = -2222; // debug channel
string descKey = "{ahg81332-11er-3221-agt3-8tyo2d004333}"; // For authentication.

string curW; // Store the weather value.
string curT = NULL_KEY;
key default_texture = "71b3d333-5c3b-b71b-3c1a-aa8dbf49a708";

default
{
	state_entry()
	{
		llSetText("", <1,1,1>, 0);
		llSetTexture(default_texture, ALL_SIDES);
		llSetAlpha(0, ALL_SIDES);
		llListen(cChan, "", "", "");
		llRegionSay(cChan, "weather");	
	}
	on_rez(integer s) {
		llRegionSay(cChan, "weather");
	}
	changed(integer change)
	{
		if(change & CHANGED_OWNER || change & CHANGED_REGION)
		{
			llResetScript();
		}
	}
	listen(integer c, string n, key id, string m) {

		if(llList2String(llGetObjectDetails(id, [OBJECT_DESC]), 0) == descKey) {
			list tmp = llParseString2List(m, ["|"], [""]);
			if(m != curW + "|" + curT) {
				if(curW != llList2String(tmp, 0)) {
					curW = llList2String(tmp, 0);
					llOwnerSay(curW);
				}
				if(llList2String(tmp, 1) != curT)
				{
					curT = llList2String(tmp, 1);
					llSetTexture(curT, ALL_SIDES);
					if(llGetTexture(ALL_SIDES) != default_texture)
					{
						llSetAlpha(1, ALL_SIDES);
					}
				}
				}
				if(llGetListLength(tmp) > 2)
				{
					llSetText(curW + llList2String(tmp, 2), <1,1,1>, 1);
				}
				else
				{
					llSetText(curW, <1,1,1>, 1);
				}

			}

		}
}