/*
Copyright (c) 2016, Martin Øverby (Tenaar Feiri), Erika Fluffy
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/*
Changelog for 1.0.0 - Erika Fluffy
- Codebase for new HUD
- Added llTextBox Functionality for Titles
- Added llTextBox Functionality for Resource Pool
- Codebase written to use single-prim hud based on x,y coordinates
- All initial functions added and preliminary testing done.
- Fixed newline being stripped properly from title update strings.
- Fixed newline being stripped properly from resource update strings.
- Added changed/changeowner state reset to prevent issues.

Changelog for 1.0.1 - Erika Fluffy
- Added length constraint for constants due to llDialogs() button length limit.

Changelog for 1.0.2 - Erika Fluffy
- Raised timeout values for things and stuff.

Changelog for 1.0.3 - Tenaar Feiri
- Added communication with the streamlined updater.

Changelog for 02/06/13 - Tenaar Feiri
- Changed the resource handler to use title8 instead of energy.

Changelog for 07/21/14 - Tenaar Feiri
    - Completely redid the HUD functionality, now 90% original code.
    - Updated HUD for multi-page support.
    
Changelog for 08/23/14 - Tenaar Feiri
    - Started updating HUD for mod support.
    - Optimized HUD button selection.
    
Changelog for 08/24/14 - Tenaar Feiri
    - Started adding variables for mod support.

*/

list buttons = 
[
/*0*/     "silentroll|postregen",   0.00000, 1.00000, 0.00000, 0.18927, //1,2,3,4
/*5*/     "changetitle|togglename",       0.00000, 1.00000, 0.18927, 0.32331, //6,7,8,9
/*10*/    "changeconstant|togglewhisper",     0.00000, 1.00000, 0.32331, 0.45329, //11,12,13,14
/*15*/    "afk|update",          0.00000, 0.48401, 0.45329, 0.58733, //16,17,18,19
/*20*/    "roll|showcap",         0.48401, 1.00000, 0.45329, 0.58733, //21,22,23,24
/*25*/    "ooc|restore",          0.00000, 0.48401, 0.58733, 0.71342, //26,27,28,29
/*30*/    "load|percent off",         0.48401, 1.00000, 0.58733, 0.71342, //31,32,33,34
/*35*/    "ic|backup",           0.00000, 0.48401, 0.71342, 0.83916, //36,37,38,39
/*40*/    "save|percent on",         0.48401, 1.00000, 0.71342, 0.83916, //41,42,43,44
/*45*/    "help|help|help",         0.80771, 1.00000, 0.83916, 1.00000  //46,47,48,49
];

list custButtons; // For custom button positions.

integer custom; // Keeps track of whether we're using custom buttons and pages.

list pages = [
                    1, "eb12bc0f-ca54-6a8a-7144-a109d164dff8",
                    2, "b2f75e86-76d5-d599-eab1-1648e85d0f28"
            ];
            
list custPages; // What kind of custom pages we've got.

integer page = 1;

integer done;

integer whichButton (float x, float y)
{
    integer xminx = 1;
    integer xmaxx = 2;
    integer yminy = 3;
    integer ymaxy = 4;
    integer i = 0;
    for(; i < 10; i++)
    {
        float xmin = llList2Float(buttons, xminx);
        float xmax = llList2Float(buttons, xmaxx);
        float ymin = llList2Float(buttons, yminy);
        float ymax = llList2Float(buttons, ymaxy);
        if(x >= xmin && x <= xmax && y >= ymin && y <= ymax)
        {
            return (xminx - 1);
        }
        xminx += 5;
        xmaxx += 5;
        yminy += 5;
        ymaxy += 5;
    }
    return -1;
}

integer commsChan = 1;
integer commsChanH;

integer regChan;
integer regChanH;
string regStr;

integer Key2AppChan(key ID, integer App) { // Generates a unique channel per key, with additional app modifier.
    return 0x80000000 | ((integer)("0x"+(string)ID) ^ App);
}

string hudDesc;

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llResetScript();
        }
    }
    state_entry()
{   
    llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_DESC, "RP-Tool-HUD"]);
    commsChanH = llListen(commsChan, "", llGetOwner(), "");
    llOwnerSay("HUD ready.");
    llAllowInventoryDrop(FALSE);
    page = 1;
    string tex = llList2String(pages, (llListFindList(pages, [page]) + 1));
    llSetLinkTexture(LINK_THIS, tex, ALL_SIDES);
    regChan = Key2AppChan(llGetOwner(), 697001);
    regChanH = llListen(regChan, "", llGetOwner(), "");
    }
    
    // Handles messages sent from the pages row.
    link_message(integer sender, integer num, string str, key id)
    {
        if(num != 0)
        {
            integer found = llListFindList(pages, [num]);
            if(found == -1 || str != "nbapage")
            {
                return;
            }
            page = num;
            
            string tex = llList2String(pages, (llListFindList(pages, [page]) + 1));
            llSetLinkTexture(LINK_THIS, tex, ALL_SIDES);
            
        }
    }
    
    on_rez(integer startparam) { llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_DESC, "RP-Tool-HUD"]); }
    
    listen(integer c, string n, key id, string m)
    {
        if(llGetOwnerKey(id) != llGetOwner() && id != llGetOwner())
        {
            return;
        }
        if(c == commsChan)
        {
            
            if(llGetSubString(llToLower(m), 0, 12) == "changechannel")
            {
                m = llDeleteSubString(m, 0, 12);
                m = llStringTrim(m, STRING_TRIM);
                if((string)((integer)m) == m) // If valid integer...
                {
                    if(m != "4" && m != "3" && m != "22")
                    {
                        llListenRemove(commsChanH); // Remove this listen.
                        commsChan = (integer)m; // Update the titleChan value.
                        commsChanH = llListen(commsChan, "", NULL_KEY, ""); // Set a new listen.
                        //llOwnerSay("Successfully changed operating channel to: "+(string)titleChan+"\nRemember to update this in your HUD to reflect this change if you use it."); // And announce!
                        //llMessageLinked(LINK_THIS, 1330, "5", NULL_KEY);
                    }
                    else
                    {
                        //llOwnerSay("You cannot use chatter channels as titler channels.");
                    }
                }
                else
                {
                    //llOwnerSay("Couldn't change RP tool option channel - invalid integer. Your command: "+command);
                }
            }
        }
        else if(c == regChan)
        {
            list tmp;
            if(regStr == "postregen")
            {
                tmp = llParseString2List(m, [" "], []);
                if(llGetListLength(tmp) != 2)
                {
                    llOwnerSay("You must have both a regen and a max value to set a postregen. It should look like this:\nmin max");
                    return;
                }
                llSay(commsChan, regStr + " " + llDumpList2String(tmp, " "));
            }
            else if(regStr == "regen")
            {
                tmp = llParseString2List(m, [" "], []);
                if(llGetListLength(tmp) != 3)
                {
                    llOwnerSay("You must have a regen & a max value, and a time limit to set a regen. It should look like this:\nmin max time");
                    return;
                }
                llSay(commsChan, regStr + " " + llDumpList2String(tmp, " "));
            }
            regStr = "";
        }
        
    }
    
    
    
    touch_end(integer total_number)
    {
        
        if(llDetectedKey(0) != llGetOwner())
        {
            llOwnerSay(llKey2Name(llDetectedKey(0)) + " just attempted to touch me without permission.");
            return;
        }
        
        if(llDetectedLinkNumber(0) != llGetLinkNumber())
        {
            return;
        }
        
        vector point = llDetectedTouchST(0);
        integer which = whichButton(point.x, point.y);
        
        if(which != -1)
        {
            list tmp;
            if(!custom)
            {
                tmp = llParseString2List(llList2String(buttons, which), ["|"], []);
            }
            else
            {
                tmp = llParseString2List(llList2String(custButtons, which), ["|"], []);
            }
            string result;
            if(llGetListLength(tmp) >= page)
            {
                result = llList2String(tmp, (page - 1));
            }
            else
            {
                llOwnerSay("ERROR: No parameter defined for button on page "+(string)page+": "+llDumpList2String(tmp, "|"));
                return;
            }
            if(llToLower(result) == "backup" || llToLower(result) == "restore")
            {
                llSay(44, result);
            }
            else if(llToLower(result) == "postregen")
            {
                regStr = "postregen";
                llTextBox(llGetOwner(), "Type in: regen max\nRemember space between regen & max.", regChan);
            }
            else
            {
                llSay(commsChan, result);
            }
           
        }
        
    }
    

    
}