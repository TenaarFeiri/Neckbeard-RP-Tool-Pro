// Character Handler by Tenaar Feiri
// Rewritten from scratch.
/*
Copyright (c) 2016, Martin Øverby (Tenaar Feiri)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/*
// ### CHANGELOGS ### \\

    # 0.7
        - Upgraded character server backups to prevent data loss from misplaced %s in the titles.
        - Started fixing notecard backups.
    
    # 0.8
        - Added 3 more character slots to savefile.
    
    #0.9
        - Fixed stack-heap error.
    
    # 0.11
        - Implemented offline backups and restorations.
        - Severed connection to server entirely.
    
*/



// ### Variables ### //

list names = ["empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"]; // Used for recalling char names.
list slots = ["null@|@null","null@|@null","null@|@null","null@|@null","null@|@null","null@|@null","null@|@null","null@|@null","null@|@null","null@|@null","null@|@null","null@|@null"];

integer backup = 0; // 1 = backup, 2 = restore.
integer isBusy = FALSE;

integer notecardHandler; // Handler for notecard parsing.
integer notecardChan; // Channel for notecard parsing.

key nc; // Key for reading notecards.
string cardname = "backup"; // Name of card to read.
string defCardName = "backup";
integer line; // Keep track of where we are in our notecard.
string input; // Input string from backup.
string constSep = "c~c"; // Constants separator.
string titleSep = "t~t"; // Titles separator.
string constTitleSep = "@|@"; // Separates constant list & titles list.
integer dataConstant = FALSE; // FALSE when loading names from notecard, TRUE when loading vals.
integer posInList = 0; // Reset to 0 after loading from notecard.
integer lastPos;
integer pagination;


// ### Functions ### //



// Function to paginate lists properly.

list paginateList( integer vIdxPag, list cards ){ // Handles listing of paginated lists.
    list vLstRtn;
    if ((cards != []) > 12){ //-- we have more than one possible page
        integer vIntTtl = -~((~([] != cards)) / 10);                                 //-- Total possible pages
        integer vIdxBgn = (vIdxPag = (vIntTtl + vIdxPag) % vIntTtl) * 10;              //-- first menu index
        string  vStrPag = llGetSubString( "                     ", 21 - vIdxPag, 21 ); //-- encode page number as spaces
        //-- get ten (or less for the last page) entries from the list and insert back/fwd buttons
        vLstRtn = llListInsertList( llList2List( cards, vIdxBgn, vIdxBgn + 9 ), (list)(" <" + vStrPag), 0xFFFFFFFF ) +(list)(" >" + vStrPag);
    }else{ //-- we only have 1 page
            vLstRtn = cards; //-- just use the list as is
    }
    return //-- fix the order for [L2R,T2B] and send it out
        llList2List( vLstRtn, -3, -1 ) + llList2List( vLstRtn, -6, -4 ) +
        llList2List( vLstRtn, -9, -7 ) + llList2List( vLstRtn, -12, -10 );
}

integer getStringBytes(string msg) {
    //Definitions:
    //msg == unescapable_chars + escapable_chars
    //bytes == unescapable_bytes + escapable_bytes
    //unescapable_bytes == unescapable_chars
 
    //s == unescapable_chars + (escapable_bytes * 3)
    string s = llEscapeURL(msg);//uses 3 characters per byte escaped.
 
    //remove 1 char from each escapable_byte's triplet.
    //t == unescapable_chars + (escapable_bytes * 2)
    string t = (string)llParseString2List(s,["%"],[]);
 
    //return == (unescapable_chars * 2 + escapable_bytes * 4) - (unescapable_chars + (escapable_bytes * 3))
    //return == unescapable_chars + escapable_bytes == unescapable_bytes + escapable_bytes
    //return == bytes
    return llStringLength(t) * 2 - llStringLength(s);
}

// For replacing things in the string.
string strReplace(string source, string pattern, string replace) {
    while (llSubStringIndex(source, pattern) > -1) {
        integer len = llStringLength(pattern);
        integer pos = llSubStringIndex(source, pattern);
        if (llStringLength(source) == len) { source = replace; }
        else if (pos == 0) { source = replace+llGetSubString(source, pos+len, -1); }
        else if (pos == llStringLength(source)-len) { source = llGetSubString(source, 0, pos-1)+replace; }
        else { source = llGetSubString(source, 0, pos-1)+replace+llGetSubString(source, pos+len, -1); }
    }
    return source;
}

// Function to backup or restore data.
funcBackupRestore(string cN)
{
    // If we're backing up...
    if(backup == 1)
    {
        key owner = llGetOwner();
                    
        string data;// = llDumpList2String(names, "\n") + "\n<!>"; //+ llDumpList2String(slots, "\n");
        integer x = 0;
        integer y = (llGetListLength(names) - 1);
		for(;x<=y;x++)
		{
			data += "[name]"+llList2String(names, x)+"\n";
		}
		data += "<!>";
		x = 0;
		y = (llGetListLength(slots) - 1);
        for(;x<=y;x++)
        {
            data += "\n";
            string constants = "[const]" + llList2String(llParseString2List(llList2String(slots, x), ["@|@"], []), 0);
            string vals = "[datas]" + llList2String(llParseString2List(llList2String(slots, x), ["@|@"], []), 1);
            data += constants + "\n" + vals + "@@@";
        }
        /* data = strReplace(data, "%", "[perc]");
        string out = "do=2&uuid="+(string)owner+"&username="+llKey2Name(owner)+"&data="+llEscapeURL(data);
        llOwnerSay((string)getStringBytes(out)+" bytes.");
        connect = llHTTPRequest(server, [HTTP_BODY_MAXLENGTH, 16000, HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded"], out);
        llOwnerSay("Connecting to server..."); */
        
        string out = "Copy everything below this line into your backups notecard (do not include the line)\nYou can safely copy the chat as is, chatter name and all; the tool is configured to only pick relevant data. \n ================= \n";
        
        llOwnerSay(out);
		llOwnerSay("\n" + llList2String(llParseString2List(data, ["<!>"], []), 0) + "<!>");
		list temp = llParseString2List(llList2String(llParseString2List(data, ["<!>"], []), 1), ["@@@"], []);
		x = 0;
		y = (llGetListLength(temp) - 1);
		for(;x<=y;x++)
		{
			llOwnerSay("\n" + llList2String(temp, x));
		}
		
        
    }
    // Otherwise, we're restoring.
    else if(backup == 2)
    {
       /* key owner = llGetOwner();
        string out = "do=3&uuid="+(string)owner;
        connect = llHTTPRequest(server, [HTTP_BODY_MAXLENGTH, 16000, HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded"], out);
        llOwnerSay("Connecting to server...");*/
        if(llGetInventoryType(cardname) == INVENTORY_NONE)
        {
            llOwnerSay("Card \"" + cardname + "\" does not exist in object inventory.");
            cardname = defCardName;
            backup = 0;
            llSetTimerEvent(0);
            return;
        }
        posInList = 0;
        input = "";
        line = 0;
        isBusy = TRUE;
        dataConstant = FALSE;
        llOwnerSay("Beginning loading of template: " + cardname);
        nc = llGetNotecardLine(cardname, line++);
    }

    //backup = 0;
}



// Function to parse the loaded data.
funcParseLoadData(string data)
{
    //llOwnerSay("Notecard output (pre-cut): " + data);
    list tmp = llParseString2List(llList2String(slots, posInList), ["@|@"], []);
    if(dataConstant)
    {
        if(llGetSubString(data, 0, 6) == "[const]")
        {
            data = llStringTrim(llDeleteSubString(data, 0, 6), STRING_TRIM);
            tmp = llListReplaceList(tmp, [(string)data, ""], 0, 1);
            input += llDumpList2String(tmp, constTitleSep);
        }
        else if(llGetSubString(data, 0, 6) == "[datas]")
        {
            data = llStringTrim(llDeleteSubString(data, 0, 6), STRING_TRIM);
            input += data;
            if(posInList <= (llGetListLength(slots) - 1))
            {
                input += data;
                slots = llListReplaceList(slots, [input], posInList, posInList);
                posInList = (posInList + 1); // Advance list position.
                input = "";
            }
        }
    }
    else
    {
        if(posInList <= (llGetListLength(slots) - 1) && llGetSubString(data, 0, 5) == "[name]")
        {
			data = llStringTrim(llDeleteSubString(data, 0, 5), STRING_TRIM);
            names = llListReplaceList(names, [data], posInList, posInList);
            posInList = (posInList + 1); // Advance list position.
        }
    }
    //llOwnerSay("Notecard output (post-cut): " + data);
}

// Loads or saves data.
funcLoadSaveData(string data)
{
    list tmp = llParseStringKeepNulls(data, ["|**|"], []);
    //llOwnerSay(llDumpList2String(tmp, ", ")); return;

    // If we're saving, then that should be the first thing we see in our
    if(llList2String(tmp, 0) == "save")
    {
        // First we parse the slot into
        string slot = llList2String(tmp, 2);

        if(llGetSubString(slot, 0, 3) == "slot")
        {
            // If we have a "slot" there, delete those letter!
            slot = llDeleteSubString(slot, 0, 3);
            slot = llStringTrim(slot, STRING_TRIM);
        }
        else
        {
            // If not, we have failed, so return 0!
            llOwnerSay("Saving character failed!");
            return;
        }

        // Carry on!
        // Verify that we have an integer...
        if((string)((integer)slot) == slot)
        {
            slot = (string)((integer)slot-1);
            // If we have an integer, perfect!
            // First fix the list! We're replacing it with the proper value.
            tmp = llList2List(tmp, 1, 1);
            //llOwnerSay(llDumpList2String(tmp, ", ")); return;

            slots = llListReplaceList(slots, [llDumpList2String(tmp, "@|@")], (integer)slot, (integer)slot);

            // Then replace that list with a separated list so we can find the name easier.
            tmp = llListReplaceList(tmp, llParseStringKeepNulls(llList2String(tmp, 0), ["@|@"], []), 0, -1);
            //llOwnerSay(llDumpList2String(tmp, ", ")); //return;
            // Put the name in a string.
            string name = llList2String(llParseStringKeepNulls(llList2String(tmp, 1), ["t~t"], []), 0);
            // Then let's update the saved data!
            names = llListReplaceList(names, [name], (integer)slot, (integer)slot);
            //llOwnerSay(llList2String(names, (integer)slot)); return;
            // Verify that we have indeed successfully saved the thing...
            if(llList2String(names, (integer)slot) == name && llList2String(slots, (integer)slot) == llDumpList2String(tmp, "@|@"))
            {
                llOwnerSay("Character "+name+" has been saved successfully.");
                return;
            }
            else
            {
                llOwnerSay("Save fail.");
                names = llListReplaceList(names, ["empty"], (integer)slot, (integer)slot);
                slots = llListReplaceList(slots, ["null@|@null"], (integer)slot, (integer)slot);


                return;
            }

        }
        else
        {
            // If not, we have failed, so return 0!
            llOwnerSay("Saving character failed! (faulty integer)");
            return;
        }
    }
    // If we're loading, it's pretty simple.
    else if(llList2String(tmp, 0) == "load")
    {
        string out = llList2String(slots, (llList2Integer(tmp, 1) - 1));
        if(out != "" && llToLower(llList2String(names, (llList2Integer(tmp, 1) - 1))) != "empty")
        {
            string loadme = "load:"+out;
            //llOwnerSay(llDumpList2String(tmp, ", ")); //return;
            //llOwnerSay(loadme); return;
            llMessageLinked(LINK_THIS, 2, loadme, NULL_KEY);
        }
        else
        {
            llOwnerSay("Could not load character; it does not exist.");
        }
    }
}

default
{
    state_entry()
    {
        llListen(44, "", NULL_KEY, "");
    }

    /* http_response(key request, integer status, list meta, string data)
    {
        if(request != connect)
        {
            return;
        }

        if(backup == 1)
        {
            if(data == "1")
            {
                llOwnerSay("Backup completed successfully.");
                backup = 0;
                llSetTimerEvent(0);
            }
            else
            {
                llOwnerSay("Backup failed.");
                backup = 0;
                llSetTimerEvent(0);
            }
        }
        else if(backup == 2)
        {
            llOwnerSay("Character data retrieved. Parsing...");
            funcParseLoadData(data);
            backup = 0;
            llSetTimerEvent(0);
        }
    } */

    listen(integer c, string n, key id, string m)
    {
        if(isBusy)
        {
            return;
        }
        
        /*if(c == pagination)
        {
            if (!llSubStringIndex( m, " " )){ //-- detects (hidden) leading space of page change buttons
                llDialog( id,
                    cardList(),
                    paginateList( llStringLength( m ) + llSubStringIndex( m, "»" ) - 2 ),
                    search );
            }
            else {
                //-- button was not a page button, your code goes here,
                //-- use (llListFindList( gLstMnu, (list)vStrMsg ) / 10) for remenu command if present
                llGiveInventory(id, llList2String(card_Name, ((integer)m - 1)));
        llRemoveInventory(llList2String(card_Name, ((integer)m - 1)));
        
            session = FALSE;
                add_Cards();
                cur_Usr = NULL_KEY;
        llListenRemove(sHandler);
        
            } */

        if(c == 44)
        {
            // Check to see if we are actually hearing the commands of our owner & their HUD!
            if(llGetOwner() == id || (llGetOwnerKey(id) == llGetOwner() && llList2String(llGetObjectDetails(id, [OBJECT_DESC]), 0) == "RP-Tool-HUD"))
            {

                if(llToLower(m) == "backup")
                {
                    if(backup != 1)
                    {
                        llOwnerSay("Please type \"/44 backup\" again (without quotes) to perform the backup. You have 10 seconds.");
                        backup = 1;
                        llSetTimerEvent(10.0);
                    }
                    else
                    {
                        funcBackupRestore("");
                    }
                }
                else if(llToLower(llGetSubString(m, 0, 6)) == "restore")
                {
                    if(backup != 2)
                    {
                        llOwnerSay("Please type \"/44 restore\" again (without quotes) to perform the restore. You have 10 seconds.");
                        if(~llSubStringIndex(m, " "))
                        {
                            cardname = llStringTrim(llDeleteSubString(m, 0, 6), STRING_TRIM);
                            llOwnerSay("You will load card: " + cardname);
                        }
                        backup = 2;
                        llSetTimerEvent(10.0);
                    }
                    else
                    {
                        funcBackupRestore(cardname);
                    }
                }
                else if(llToLower(llGetSubString(m, 0, 7)) == "template")
                {
                    m = llStringTrim(llDeleteSubString(m, 0, 6), STRING_TRIM);
                    defCardName = m;
                    cardname = m;
                    llOwnerSay("Default backups template changed to: " + defCardName);
                }
            }
        }
    }

    timer()
    {
        backup = 0;
        llSetTimerEvent(0);
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llResetScript();
        }
    }
    
    on_rez(integer start)
    {
        if(llGetAttached())
        {
            nc = NULL_KEY;
            line = 0;
            input = "";
            posInList = 0;
            dataConstant = FALSE;
            isBusy = FALSE;
            cardname = defCardName;
        }
    }
    
    dataserver(key r, string d)
    {
        if(nc == r)
        {
            if(d == EOF)
            {
                llOwnerSay("Successfully restored backups.");
                nc = NULL_KEY;
                line = 0;
                input = "";
                dataConstant = FALSE;
                posInList = 0;
                isBusy = FALSE;
                cardname = defCardName;
                //llOwnerSay(llDumpList2String(slots, "\n"));
            }
            else
            {
                if(d == "")
                {
                    jump break;
                }
                if(d == "<!>")
                {
                    dataConstant = TRUE;
                    posInList = 0;
                    input = "";
                    nc = llGetNotecardLine(cardname, line++);
                    return;
                }
                string restoringWhich;
                if(dataConstant)
                {
                    if(lastPos != posInList)
                    {
                        restoringWhich = "Restoring character data: " + (string)(posInList + 1);
                        lastPos = posInList;
                    }
                }
                else
                {
                    restoringWhich = "Restoring name data: " + (string)(posInList + 1);
                    lastPos = posInList;
                }
                //llOwnerSay(restoringWhich);
                funcParseLoadData(d);
                @break;
                nc = llGetNotecardLine(cardname, line++);
            }
        }
    }

    // Link message for communication with the other script.
    link_message(integer sender, integer num, string data, key id)
    {

        // If we're saving then save!
        if(num == 1)
        {
            funcLoadSaveData(data);
        }
        else if(num == 3)
        {
            string output;
            integer i = (llGetListLength(names)-1);
            integer x = 0;
            for(x=0;x<=i;x++)
            {
                output += "Slot "+(string)(x+1)+": " +llList2String(names, x)+"\n";
            }
            x = 0;
            output += "@@@";
            list tmp;
            for(x=0;x<=i;x++)
            {
                tmp += (string)(x+1)+",";
            }
            tmp = paginateList(0, tmp);
            llMessageLinked(LINK_THIS, 4, output+llDumpList2String(tmp, ""), "");
        }
        else if(num == 44) // If num == 44 then we received a request for start parameters.
        {
            // Send the start param to the updater script.
            llMessageLinked(LINK_THIS,45,llGetScriptName()+"|"+(string)llGetStartParameter(),NULL_KEY);
        }

    }

}