// Neckbeard Chatter
// Handles chats.
//
// Last edit: March 30th, 2016 - Tenaar Feiri
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
    Changes:
    
                ::0.8::
                    - Speculative fix for issue where last letter of a first name was sometimes omitted after loading a character with togglename on.
*/

string version = "r20001_01";

string curName;

integer togglename;
integer whisper;

integer chan = 1;

string funcName() // Outputs processed name.
{
    string name = curName;
    if(togglename)
    {
        name = llStringTrim(llList2String(llParseString2List(name, [" "], []), 0), STRING_TRIM);
    }
    
   return name;
}

// Function for speaking.
funcDoSpeak(string post)
{
    string savedName = llGetObjectName();
    //llOwnerSay((string)llGetUsedMemory()+" bytes used.");
    // Check to see if a channel has been typed in double by accident.
    if(llGetSubString(post, 0, 0) == "/" && (string)((integer)llGetSubString(post, 1, 1)) == llGetSubString(post, 1, 1))
    {
        post = llDeleteSubString(post, 0, 1);
        post = llStringTrim(post, STRING_TRIM);
    }
    // First handle OOC chat. With double brackets, we're indicating OOC!
    if(llGetSubString(post, 0, 1) == "((" && llGetSubString(post, (-1 -1), -1) == "))")
    {
        post = llDeleteSubString(post, 0, 1); // Delete first double brackets.
        post = llDeleteSubString(post, (-1 - 1), -1); // Delete second double brackets.
        post = llStringTrim(post, STRING_TRIM); // Trim leading and trailing spaces.
        llSetObjectName(curName+" ("+llKey2Name(llGetOwner())+") OOC");
        llSay(0, post);
    }
    else if(llGetSubString(post, 0, 0) == "#") // If we begin with a hashtag, we're whispering!
    {
        llSetObjectName(funcName());
        post = llDeleteSubString(post, 0, 0);
        post = llStringTrim(post, STRING_TRIM);
        llWhisper(0, "/me whispers, \""+post+"\"");
    }
    else if(llGetSubString(post, 0, 0) == "!") // Shout if we have an exclamation mark.
    {
        llSetObjectName(funcName());
        post = llDeleteSubString(post, 0, 0);
        post = llStringTrim(post, STRING_TRIM);
        llShout(0, "/me "+post);
    }
    else if(llGetSubString(post, 0, 0) == ":") // Talk if we have a colon.
    {
        llSetObjectName(funcName());
         post = llDeleteSubString(post, 0, 0);
        post = llStringTrim(post, STRING_TRIM);
        if(!whisper)
        {
            llSay(0, "/me says, \""+post+"\"");
        }
        else
        {
            llWhisper(0,"/me says, \""+post+"\"");
        }
    }
    else if(llGetSubString(post, 0, 0) == "'")
    {
        string charName = funcName();
		if(llGetSubString(llToLower(post), 0, 1) == "'s" || llGetSubString(llToLower(post), 0, 0) == "'")
		{
			if(llToLower(llGetSubString(charName, -1, -1)) == "s")
			{
				llSetObjectName(charName+"'");
				if(llGetSubString(post, 1, 1) == " " || llGetSubString(post, 1, 1) == "")
				{
					post = llStringTrim(llDeleteSubString(post, 0, 0), STRING_TRIM);
				}
				else
				{
					post = llStringTrim(llDeleteSubString(post, 0, 1), STRING_TRIM);
				}

			}
			else
			{
				llSetObjectName(charName+"'s");
				post = llStringTrim(llDeleteSubString(post, 0, 1), STRING_TRIM);

			}
		}
		else
		{
			llSetObjectName(charName);
		}
		if(post == " " || post == "")
		{
			jump failed;
		}
        if(!whisper)
        {
			
			llSay(0, "/me "+post);
			
        }
        else
        {
			
			llWhisper(0,"/me "+ post);
			
        }

    }
    else if(llGetSubString(post, 0, 0) == ",")
    {
        llSetObjectName(funcName()+",");
        post = llDeleteSubString(post, 0, 0);
        post = llStringTrim(post, STRING_TRIM);
		if(post == " " || post == "")
		{
			jump failed;
		}
        if(!whisper)
        {
            llSay(0, "/me "+post);
        }
        else
        {
            llWhisper(0,"/me "+ post);
        }
    }
    else // If none of the above are true, chat normally!
    {
        llSetObjectName(funcName());
        if(!whisper)
        {
            llSay(0, "/me "+post);
        }
        else
        {
            llWhisper(0,"/me "+ post);
        }
    }
    llMessageLinked(LINK_THIS, 1331, "regen", NULL_KEY);
	@failed;
    llSetObjectName(savedName); // At the end of the chat, set object name back to default.

}

integer cHan;
default
{
    state_entry()
    {
        llListen(4, "", llGetOwner(), "");
        llListen(3, "", llGetOwner(), "");
        llListen(22, "", llGetOwner(), "");
        cHan = llListen(chan, "", NULL_KEY, "");
    }

    // Link message event for receiving currently loaded character names.
    // Responds to number 1337.
    link_message(integer sender, integer num, string m, key id)
    {
        if(num == 1337)
        {
            string tmp = m;
            curName = tmp; // Set the current name.
            //llOwnerSay(tmp + " -> " + curName);
        }
        else if(num == 1330)
        {
            // Handle which channel we operate on.
            llListenRemove(cHan);
            chan = (integer)m;
            cHan = llListen(chan, "", NULL_KEY, "");
        }
        
    }
    
    // Obvious. This event is for when something has changed.
    changed(integer change)
    {
        // If the object has changed owners, we'll want to reset the script.
        if(change & CHANGED_OWNER)
        {
            // Obvious.
            llResetScript();
            
            // This is done to prevent the script from failing to recognize its new owner when attempting to
            // use the new chatter.
        }
    }
    
    
    listen(integer c, string n, key id, string m)
    {
        // If id isn't the owner, exit.
        if(llGetOwner() == id || (llGetOwnerKey(id) == llGetOwner() && llList2String(llGetObjectDetails(id, [OBJECT_DESC]), 0) == "RP-Tool-HUD"))
        {

            if(c == 4)
            {
                if(m != "" && m != " ")
                {
                    funcDoSpeak(m); // Post if c == 4.
                }
            }
            // If we use OOC chat...
            else if(c == 22)
            {
                
                if(m == "" && m == " ") {
                    return;
                }
                // Talk OOC!
                string tmp = llGetObjectName();
                llSetObjectName(curName+" ("+llKey2Name(llGetOwner())+") OOC");
                llSay(0, m);
                llSetObjectName(tmp); // At the end of the chat, set object name back to default.
            }
            else if(c == 3) // NPC/Nameless speak!
            {
                if(m == "" && m == " ") {
                    return;
                }
                string tmp = llGetObjectName();
                // Check to see if a channel has been typed in double by accident.
                if(llGetSubString(m, 0, 0) == "/" && (string)((integer)llGetSubString(m, 1, 1)) == llGetSubString(m, 1, 1))
                {
                    m = llDeleteSubString(m, 0, 1);
                    m = llStringTrim(m, STRING_TRIM);
                }
                llSetObjectName("");
    
                if(llGetSubString(m, 0, 0) == "#") // If we begin with a hashtag, we're whispering!
                {
    
                    m = llDeleteSubString(m, 0, 0);
                    m = llStringTrim(m, STRING_TRIM);
                    llWhisper(0, "/me "+m);
                }
                else if(llGetSubString(m, 0, 0) == "!") // Shout if we have an exclamation mark.
                {
                    llSetObjectName("(player event)");
                    m = llDeleteSubString(m, 0, 0);
                    m = llStringTrim(m, STRING_TRIM);
                    llShout(0, m);
                }
    
                else // If none of the above are true, chat normally!
                {
                    if(!whisper)
                    {
                        llSay(0, "/me "+m);
                    }
                    else
                    {
                        llWhisper(0, "/me "+m);
                    }
                }
                llSetObjectName(tmp);
                llMessageLinked(LINK_THIS, 1331, "regen", NULL_KEY);
            }
            else if(c == chan)
            {
                if(llToLower(m) == "togglename") // Handles toggling of name display.
                {
                    if(togglename)
                    {
                        togglename = FALSE;
                        llOwnerSay("Chatter now uses your characters' full names.");
                    }
                    else
                    {
                        togglename = TRUE;
                        llOwnerSay("Chatter is now using only your characters' first names.");
                    }
                }
                else if(llToLower(m) == "togglewhisper")
                {
                    if(!whisper)
                    {
                        whisper = TRUE;
                        llOwnerSay("/4 & /3 chatrange reduced to 10 meters.");
                    }
                    else
                    {
                        whisper = FALSE;
                        llOwnerSay("/4 & /3 chatrange increased to 20 meters.");
                    }
    
                }
            }
        }
        
    }

}