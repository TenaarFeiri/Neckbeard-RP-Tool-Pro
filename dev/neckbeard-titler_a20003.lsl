//    Neckbeard RP Tool Pro, by Tenaar Feiri.
//    Using functions from: Erika Fluffy, 
//    Started work: April 2nd, 2014
//    Last Updated: April 9th, 2016
//
/*
Copyright (c) 2016, Martin Øverby (Tenaar Feiri)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Global variables listed by category. //

// ### Misc. Info Vars. ### //

string version = "a20003"; // Our titler version.

integer DEBUG = FALSE;

string name = "Neckbeard RP Tool - "; // Titler's name.

// ### Functions for online connectivity ### //

key verID;

// ### Channel variables ### //

integer Key2AppChan(key ID, integer App) { // Generates a unique channel per key, with additional app modifier.
    return 0x80000000 | ((integer)("0x"+(string)ID) ^ App);
}
integer saveLoadHandle;
integer saveload;
integer saveorload = 1; // 1 = save, 2 = load
integer titleChan = 1; // The channel through which we give the titler commands. Can be changed!
integer titleChanHandler; // Handles the titleChan!
integer changeTitle; // To keep track of the channel we use for changing titles.
integer changeTitleHandler; // Handler for the changeTitle channel.
integer changeIt; // FALSE when selecting title/constant, TRUE when changing it.
string selected; // Set when choosing a title/constant to change.
//integer isComma = 0; // 0 = line separation; 1 = comma separation; 2 = merge line 1 & 2 without comma.)

// ### Titler data ### //

//vector color = <1,1,1>; // Colour for the titler text. Default is white.
float alpha = 1.0; // Titler visibility.
list constants = ["Name:","Species:","Mood:","Status:","Body:","Scent:","Currently:","Energy:"]; // List for our constants.
list titles = ["My name","My species","My mood","My status","My body","my scent","my current action","100","on", "0", "100", "255,255,255", "0"]; // List for our titles!

/*

    List of Title nums & their functions
    
        0-7 -> title1-title8
        
        8 -> Percentage on/off
        
        9 -> Post regen
        
        10 -> Maximum energy (used w/ postregen)
        
        11 -> Text colour,
        
        12 -> Comma
        

*/

string ooc = ""; // What msg to show if we're OOC.
string afk = ""; // What msg to show if we're AFK.
integer out = 0; // 0 = IC, 1 = OOC, 2 = AFK.
integer postRegenLast; // Last time we had a post regen.
integer postRegenThrottle = 120; // How long we have to wait between each post for it to trigger post regen.
integer showCap = TRUE; // Show the post regen cap.


list colors = [
                "blue", "0,0,255",
                "red", "255,0,0",
                "green", "0,255,0",
                "white", "255,255,255",
                "black", "0,0,0",
                "yellow", "255,255,0",
                "purple", "128,0,128",
                "aqua", "0,255,255",
                "teal", "128,255,255"
                ];


// ### Functions for handling titler data ### //


changeOutTit(integer cOt, integer title, string data)
{
    string tmpN = llList2String(constants, title);
    string tmpD = llList2String(titles, title);
    
    // If cOt == 1, then we're changing a constant.
    if(cOt == 1)
    {
        constants = llListReplaceList(constants, [(string)data], title, title);
        llOwnerSay("Constant \""+tmpN+"\" (title"+(string)(title+1)+") changed to\" "+llList2String(constants, title)+"\"");
    }
    // If cOt == 2, then we're changing a title.
    else if(cOt == 2)
    {
        titles = llListReplaceList(titles, [(string)data], title, title);
        llOwnerSay("Title \""+tmpN+"\" (title"+(string)(title+1)+") changed from \""+tmpD+"\" to\" "+llList2String(titles, title)+"\"");
    }
}


// Function to show the dialog options for title & constant changing.
showDialog(integer num)
{
    changeIt = FALSE; // Resets changeIt.
    list tmp; // Temporary list.
    string desc; // Description.
    integer i = (llGetListLength(constants) - 1); // How many constants we have. Important note: # of constants == # of parsing titles.
    integer x;
    if(num == 1) // If num == 1, then we're selecting titles.
    {
        for(x=0;x<=i;x++)
        {
            tmp += ["title"+(string)(x+1)]; // Add the title to the list.
            desc += "Title "+(string)(x+1)+": ("+llList2String(constants, x)+") "+llList2String(titles, x); // Add constant values & 
            if(x != i)
            {
                desc += "\n"; // Append linebreak if not last entry.
            }
        }
        // When we're done, double check that the list lengths match.
        if(llGetListLength(tmp) != (i+1))
        {
            llOwnerSay("Cannot show dialog menu; titles not matched.");
            return;
        }
        tmp = paginateList(0, tmp);
        // But if they are equally long, let's roll!
        changeTitle = Key2AppChan(llGetOwner(), 4321); // Define the channel.
        changeTitleHandler = llListen(changeTitle, "", llGetOwner(), ""); // Initiate the listen.
        // Then trigger the dialog.
        llDialog(llGetOwner(), desc, tmp, changeTitle);
    }
    else if(num == 2) // If num == 2, we're changing the constants.
    {
        for(x=0;x<=i;x++)
        {
            tmp += ["const"+(string)(x+1)]; // Add the title to the list.
            desc += "Title "+(string)(x+1)+": ("+llList2String(constants, x)+") "+llList2String(titles, x); // Add constant values & 
            if(x != i)
            {
                desc += "\n"; // Append linebreak if not last entry.
            }
        }
        // When we're done, double check that the list lengths match.
        if(llGetListLength(tmp) != (i+1))
        {
            llOwnerSay("Cannot show dialog menu; titles not matched.");
            return;
        }
        tmp = paginateList(0, tmp);
        // But if they are equally long, let's roll!
        changeTitle = Key2AppChan(llGetOwner(), 4322); // Define the channel.
        changeTitleHandler = llListen(changeTitle, "", llGetOwner(), ""); // Initiate the listen.
        // Then trigger the dialog.
        llDialog(llGetOwner(), desc, tmp, changeTitle);
    }
}


// Function for handling dice rolls.
integer diceRoll(integer faces)
{
    // This function will use the time of day & sim uptime as a randomized seed.
    // Then it will calculate a dice roll and output the result.
    integer seed = FALSE;
    if(faces < 2) {
        return seed;
    }
    
    string timestamp = llGetTimestamp() + (string)llGetTime();
    
    integer length = (llStringLength(timestamp) - 1);
    integer x;
    for(x = 0; x<=length; x++) {
        if(!IsInteger(llGetSubString(timestamp, x, x))) {
            timestamp = llDeleteSubString(timestamp, x, x);
        }
    }
    
    list tmp;
    
    length = (llStringLength(timestamp) - 1);
    for(x = 0; x<=length; x++) {
        tmp += [llGetSubString(timestamp, x, x)];
    }
     
    
    length = (llGetListLength(tmp) - 1);
    for(x=0;x<=length;x++) {
        tmp = llListRandomize(tmp, 0);
    }
    seed = 1;
    for(x=0;x<=length;x++) {
        if(x < 0) {
            if((integer)llList2String(tmp, x) != 0) {
                seed += (integer)llList2String(tmp, x);
            }
        }
        else if((integer)llList2String(tmp, x) != 0) {
            seed += llList2Integer(tmp, x);
        }
    }
    seed = 1 + (seed % faces);
    
    if(seed > faces) {
        seed = faces;
    }
    else if(seed < 1) {
        seed = 1;
    }
   
    //llOwnerSay((string)seed);
    
    return seed;
}


funcUpdTitle(integer const, integer loc, string data) // Update either constant or title.
{
    if(const) // If we're updating a constant...
    {
        if(out)
        {
            changeOutTit(1, loc, data);
        }
        else
        {
            constants = llListReplaceList(constants, [(string)data], loc, loc); // Update the relevant constant value.
        }
    }
    else // If we're updating a title...
    {
        if(out)
        {
            changeOutTit(2, loc, data);
        }
        else
        {
            titles = llListReplaceList(titles, [(string)data], loc, loc);
        }
    }
    funcParseTitle();
    // Then if we've updated the name & not the constant...
    if(loc == 0 && !const)
    {
         if (llGetSubString(llList2String(titles, 0), -1, -1) == llUnescapeURL("%0A") )
        {
            llListReplaceList(titles,[(string)llGetSubString(llList2String(titles, 0), 0, -2)], 0, 0);
        }
        // Inform chatter.
        llMessageLinked(LINK_THIS, 1337, llList2String(titles, 0), ""); // Informs chatter of name change.

    }
}

string funcFindTag(string data)
{
    list tmp;
    if(~llSubStringIndex(data, "$p"))
    {
        tmp = llParseString2List(data, ["$p"], []);
        data = llDumpList2String(tmp, "\n");
    }
    else if(~llSubStringIndex(data, "$n"))
    {
        // Filter out $n from the name so it doesn't show in the titler.
        tmp = llParseString2List(data, ["$n"], []);
        data = llDumpList2String(tmp, "");
    }
    
    return data;
}

funcParseTitle() // Parse the title.
{
    string tmp; // Temporary string.
    string nameVal = funcFindTag(llList2String(titles, 0));
    if(nameVal == "nil")
    {
        nameVal = "";
    }
    if(out == 1) // If ooc...
    {
        tmp = "[OOC]\n"+nameVal+"\n"+ooc+""; // Put the OOC message in the string.
    }
    else if(out == 2) // If afk...
    {
        tmp = "[AFK]\n"+nameVal+"\n"+afk+""; // Put the AFK message in the string.
    }
    else // If IC...
    {
        
        integer i = 7; // How many titles we'll be parsing through.
        integer x; // Counter integer.
        string isComma = llList2String(titles, 12);
        for(x=0;x<=i;x++) // Begin loop!
        {
            string constVal = funcFindTag(llList2String(constants, x));
            string titleVal = funcFindTag(llList2String(titles, x));
            if(constVal == "nil" && titleVal == "nil")
            {
                jump break;
            }
            else if(constVal == "nil")
            {
                constVal = "";
            }
            else if(titleVal == "nil")
            {
                titleVal = "";
            }
            tmp = tmp + constVal + " " + titleVal; // Add the title to the temporary string.
            if(x != i) // If x is not the last entry in the list...
            {
                if(x == 0 && IsInteger(isComma) && (integer)isComma == 1) // Check to see if x is exactly 0 and that comma is true.
                {
                    tmp = tmp + ", "; // If comma is true, separate the two top titles by a comma instead of a linebreak.
                }
                else if(x == 0 && IsInteger(isComma) && (integer)isComma == 2)
                {
                        tmp = tmp + " ";
                }
                else // If this is not the case...
                {
                    tmp = tmp + "\n"; // Then we separate by way of linebreak.
                }
            }
            @break;
        }
        // Then when the loop is over, add the percentage...if it exists.
        if(llList2String(titles, 7) != "nil") // If energy is hidden, or is not integer, do not add %.
        {
            if(IsInteger(llList2String(titles, 7)))
            {
                if(llList2String(titles, 8) == "on")
                {
                    tmp = tmp + "%"; // Add % if exists & energy is shown.
                }
                else if(llList2String(titles, 8) != "on" && showCap && llList2Integer(titles, 9) > 0)
                {
                    tmp = tmp + " / " + llList2String(titles, 10);
                }
            }
        }
    }
    if(DEBUG) { llOwnerSay(tmp); }
    // Then when all this is done, display title.
    string tempcol = "<"+llList2String(titles, 11)+">";
    llSetText(tmp, rgb2sl((vector)tempcol), alpha);
}

integer IsInteger(string var)
{
    integer i;
    for (i=0;i<llStringLength(var);++i)
    {
        if(!~llListFindList(["1","2","3","4","5","6","7","8","9","0"],[llGetSubString(var,i,i)]))
        {
            return FALSE;
        }
    }
    return TRUE;
}

vector rgb2sl( vector rgb )
{
    return rgb / 255;        
}

integer strIsVector(string str)
{
    str = llStringTrim(str, STRING_TRIM);

    if(llGetSubString(str, 0, 0) != "<" || llGetSubString(str, -1, -1) != ">")
        return FALSE;

    integer commaIndex = llSubStringIndex(str, ",");

    if(commaIndex == -1 || commaIndex == 1)
        return FALSE;

    if( !strIsDecimal(llGetSubString(str, 1, commaIndex - 1)) || llGetSubString(str, commaIndex - 1, commaIndex - 1) == " " )
        return FALSE;

    str = llDeleteSubString(str, 1, commaIndex);

    commaIndex = llSubStringIndex(str, ",");

    if(commaIndex == -1 || commaIndex == 1 || commaIndex == llStringLength(str) - 2 ||
        
        !strIsDecimal(llGetSubString(str, 1, commaIndex - 1)) || llGetSubString(str, commaIndex - 1, commaIndex - 1) == " " ||
        
        !strIsDecimal(llGetSubString(str, commaIndex + 1, -2)) ||  llGetSubString(str, -2, -2) == " ")
            
            return FALSE;

    return TRUE;
}

// Returns TRUE if the string is a decimal
integer strIsDecimal(string str)
{
    str = llStringTrim(str, STRING_TRIM);

    integer strLen = llStringLength(str);
    if(!strLen){return FALSE;}

    integer i;
    if(llGetSubString(str,0,0) == "-" && strLen > 1)
        i = 1;
    else
        i = 0;

    integer decimalPointFlag = FALSE;

    for(; i < strLen; i++)
    {
        string currentChar = llGetSubString(str, i, i);

        if(currentChar == ".")
            if(decimalPointFlag)
                return FALSE;
        else
            decimalPointFlag = TRUE;
        else if(currentChar != "3" && currentChar != "6" && currentChar != "9" &&
            currentChar != "2" && currentChar != "5" && currentChar != "8" && // the order dosen't matter
                currentChar != "1" && currentChar != "4" && currentChar != "7" && currentChar != "0")
                    return FALSE;
    }

    return TRUE;
}

// Function for handling post regens!
funcPostRegen()
{
    if(llList2String(titles, 7) == "nil" || !IsInteger(llList2String(titles, 7)) || llList2Integer(titles, 9) == 0) // Do not update the energy if it's hidden, or is not an integer, or if regen is disabled.
    {
        return;
    }

    // If it's appropriate to update energy, and we actually are using postregen...
    if(llGetUnixTime() > (postRegenLast + postRegenThrottle))
    {

        
        
        // Do the regen!
        integer regeneration = (llList2Integer(titles, 7) + llList2Integer(titles, 9)); // Calculate next regen value!

        // If regeneration result is bigger than the max limit...
        if(regeneration > llList2Integer(titles, 10))
        {
            // Set regeneration to the max limit.
            regeneration = llList2Integer(titles, 10);
        }
        // Then update the energy value.
        titles = llListReplaceList(titles, [(string)regeneration], 7, 7);

        // Then make a note of when this completed.
        postRegenLast = llGetUnixTime();
        
        // Then reparse titles.
        funcParseTitle();
    }
}


// ### Variables and/or functions dealing with save files! ### //

// Separator for constants: c~c
// Separator for titles: t~t
// Separator between the constants and titles: @|@
// Separator for option params: |**|

// This funciton handles the saving and loading.
funcSaveLoadChar(string data)
{
    // Since we don't save the character data in this script, we need to format it properly.
    if(llGetSubString(data, 0, 4) == "save:")
    {
        // Now, if we're saving then we only have two variables to worry about: "save:" and "slot#".
        // Let's put them in a temporary list for now. Since data looks like "save:slot#", this is easy.
        list tmp = llParseStringKeepNulls(data, [":"], []);

        // Now that we have those two variables in our list, we can use the data string without having to define a new one.
        // This could be done by way of loop, but luckily LL has provided us with much better ways to dump lists!
        // So we'll just do this fast.
        data = llDumpList2String(constants, "c~c")+"@|@"+llDumpList2String(titles, "t~t");
        // Then let's add our options to the string.
        // First we add in "save" and at the end we've got the slot it will save to.
        data = llList2String(tmp, 0) + "|**|" + data + "|**|" + llList2String(tmp, 1);

        // With this done, we can now send a linked message with our data to the character save script!
        // The 2nd option in the function below, the integer after LINK_THIS, identifies what we're doing.
        // 1 means we're saving. 2 would mean we're loading.
        llMessageLinked(LINK_THIS, 1, data, "");

        // And that's it. Now the character handler will take care of the rest.
    }
    // If we're loading then we've got our data in place already!
    else if(llGetSubString(data, 0, 4) == "load:")
    {
        data = llDeleteSubString(data, 0, 4);
        list tmp = llParseStringKeepNulls(data, ["@|@"], []);

        // We can do this the easy way.
        // Just replace the list with the data. We already got our separators, and we can do this in one fell swoop!
        list tmpD =  llParseStringKeepNulls(llList2String(tmp, 0),
            ["c~c"],
            []
                );
        constants = llListReplaceList(constants,
            tmpD,
            0, (llGetListLength(tmpD) - 1));

        // Constants should be up to date now. Rinse and repeat with titles.
        
        tmpD = llParseStringKeepNulls(llList2String(tmp, 1),
            ["t~t"],
            []
                );
        titles = llListReplaceList(titles,
            tmpD,
            0, (llGetListLength(tmpD) - 1));

        // Then with that done, all we need to do is re-parse the titles!
        funcParseTitle();
        llOwnerSay("Character "+llList2String(titles, 0)+" has been successfully loaded.");
        llMessageLinked(LINK_THIS, 1337, llList2String(titles, 0), ""); // Informs chatter of name change.
        // This will also remember post regen rates.
    }
}

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

//////////////////////////////
// Execute code. //
default
{
    state_entry()
    {
        // ### SETUP ### //
        llSetObjectName(name+version);
        saveload = Key2AppChan(llGetOwner(), 112);
        titleChanHandler = llListen(titleChan, "", "", "");
        // ############# //
        funcParseTitle();
        llOwnerSay((string)llGetUsedMemory()+" bytes used.");
        llMessageLinked(LINK_THIS, 1337, llList2String(titles, 0), ""); // Informs chatter of name.
        llOwnerSay("If you haven't already, please consider joining our group here as this is where you'll receive updates and support from: secondlife:///app/group/fbd3b4cb-8dca-6f36-679c-a3d0b44662a9/about \nGitHub link: https://github.com/TenaarFeiri/Neckbeard-RP-Tool-Pro");
    }

    // Handles incoming link messages.
    link_message(integer sender, integer num, string data, key id)
    {

        // If num == 2, then we're loading a character.
        if(num == 2)
        {
            //llOwnerSay(data);
            // Run the function to load the data.
            funcSaveLoadChar(data);
        }
        else if(num == 5)
        {
            if(llToLower(data) == "save" || llToLower(data) == "load")
            {
            }
            else
            {
                funcSaveLoadChar(data);
            }
        }
        else if(num == 4)
        {
            saveLoadHandle = llListen(saveload, "", llGetOwner(), "");
            //llSetTimerEvent(120);
            list tmp = llParseString2List(data, ["@@@"], []);
            llDialog(llGetOwner(), "Please select your slot:\n"+llList2String(tmp, 0), llParseString2List(llList2String(tmp, 1), [","], []) , saveload);
        }
        else if(num == 1331)
        {
            // If 1331, we're getting a regen message.
            if(data == "regen")
            {
                funcPostRegen(); // Execute regen.
                if(changeTitleHandler) // If changeTitleHandler is set when we get a regen message...
                { // Reset those stats.
                    changeIt = FALSE;
                    llListenRemove(changeTitleHandler);
                    changeTitleHandler = FALSE;
                    changeTitle = FALSE;
                    selected = "";
                }
            }
        }

    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llResetScript();
        }
    }

    on_rez(integer start_param)
    {
        llListenRemove(saveLoadHandle);
        llMessageLinked(LINK_THIS, 1337, llList2String(titles, 0), ""); // Informs chatter of name.
    }

    listen(integer c, string n, key id, string m) // Listen to commands!
    {
        //llOwnerSay("Heard you on chan " + (string)c + ", msg: "+m);
        // Check to see if we are actually hearing the commands of our owner & their HUD!
        if(llGetOwner() == id || (llGetOwnerKey(id) == llGetOwner() && llList2String(llGetObjectDetails(id, [OBJECT_DESC]), 0) == "RP-Tool-HUD"))
        {
                // If all is well, let's start checking to see what happens.
        
                if(c == saveload)
                {
                    // If we're saving, just do function.
                    if(saveorload == 1)
                    {
                        m = "save:slot"+m;
                        funcSaveLoadChar(m);
                    }
                    // If not, perform loading operation!
                    else if(saveorload == 2)
                    {
                        m = "load|**|"+m;
                        llMessageLinked(LINK_THIS, 1, m, "");
                    }
                }
                else if(c == titleChan) // If the communicating channel is channe titleChan, then we're receiving a command!
                {
                    integer tmp; // We're probably gonna need this!
                    string command = "/"+(string)titleChan+" "+m; // Just in case we experience an error.
                    // If m has "title" in it and the number following it is a number...
                    if(llGetSubString(llToLower(m), 0, 4) == "title" && (string)((integer)llGetSubString(llToLower(m), 5, 5)) == llGetSubString(llToLower(m), 5, 5))
                    {
                        // Then we're going to update a title. So let's update!
                        tmp = ((integer)llGetSubString(m, 5, 5) - 1); // Add the title number to the temporary integer. Reduce by 1 for zero-indexed list.
                        if(tmp > 7) // If tmp is bigger than 7...
                        {
                            llOwnerSay("Could not update title. Title number not valid. Your command: "+command);
                            return;
                        }
        
                        m = llDeleteSubString(m, 0, 5); // Then delete "title#" from the string.
                        m = llStringTrim(m, STRING_TRIM); // Trim the string for leading and trailing spaces.
                        if(llToLower(m) == "hide" || llToLower(m) == "none")
                        {
                            m = "nil";
                        }
                        
        
                        funcUpdTitle(FALSE, tmp, m); // Then update the title!
                    } // End title.
                    // If not title, we're updating the constant. Same thing applies!
                    else if(llGetSubString(llToLower(m), 0, 4) == "const" && (string)((integer)llGetSubString(llToLower(m), 5, 5)) == llGetSubString(llToLower(m), 5, 5))
                    {
                        // Then we're going to update a constant. So let's update!
                        tmp = ((integer)llGetSubString(m, 5, 5) - 1); // Add the const number to the temporary integer. Reduce by 1 for zero-indexed list.
                        if(tmp > 7) // If tmp is bigger than 7...
                        {
                            llOwnerSay("Could not update constant. Constant number not valid. Your command: "+command);
                            return;
                        }
                        m = llDeleteSubString(m, 0, 5); // Then delete "const" from the string.
                        m = llStringTrim(m, STRING_TRIM); // Trim the string for leading and trailing spaces.
                        if(llToLower(m) == "hide" || llToLower(m) == "none")
                        {
                            m = "nil";
                        }
                        funcUpdTitle(TRUE, tmp, m); // Then update the constant!
                    } // End update.
        
                    // Are we updating the percent perhaps?
                    else if(llGetSubString(llToLower(m), 0, 6) == "percent")
                    {
                        m = llDeleteSubString(m, 0, 6);
                        m = llStringTrim(llToLower(m), STRING_TRIM);
                        if(m == "on") // If we're adding the percent onto the thing...
                        {
                            titles = llListReplaceList(titles, ["on"], 8, 8); // Add it to the list.
                        }
                        else if(m == "off") // Or if we're removing it...
                        {
                            titles = llListReplaceList(titles, ["off"], 8, 8); // Take it away!
                        }
                        funcParseTitle(); // Then parse the new title.
                    }
                    // We could be updating colours as well! Colour presets no longer exist to save memory.
                    else if(llGetSubString(llToLower(m), 0, 4) == "color")
                    {
                        m = llDeleteSubString(m, 0, 4);
                        m = llStringTrim(m, STRING_TRIM);
                        string mTemp = m;
                        mTemp = llDumpList2String(llParseStringKeepNulls(mTemp, [" "], []), ",");
                        if(strIsVector("<"+mTemp+">")) // If the colour value is indeed a vector...
                        {
                            titles = llListReplaceList(titles, [mTemp], 11, 11); // Set the value.
                            funcParseTitle(); // Reparse the title.
                        }
                        else if(~llListFindList(colors, [m]))
                        {
                            titles = llListReplaceList(titles, [llList2String(colors, (llListFindList(colors, [m])+1))], 11, 11); // Set the value.
                            funcParseTitle(); // Reparse the title.
                        }
                        else if(llToLower(m) == "random")
                        {
                            titles = llListReplaceList(titles, [(string)llFrand(255.0)+","+(string)llFrand(255.0)+","+(string)llFrand(255.0)], 11, 11); // Set the value.
                            funcParseTitle(); // Reparse the title.
                        }
                        else
                        {
                            llOwnerSay("Colour changing failed. Invalid vector, or colour preset doesn't exist. Your command: "+command);
                        }
                    }
                    // Let's do regens.
                    else if(llGetSubString(llToLower(m), 0, 8) == "postregen") // If we're using a postregen command...
                    {
                        list temp; // Prepare temporary list.
                        m = llDeleteSubString(m, 0, 8); // Clean the string.
                        m = llStringTrim(m, STRING_TRIM_HEAD); // Trim leading and trailing spaces.
                        temp = llParseStringKeepNulls(m, [" "], []); // Parse the postregen values to a list.
                        if(llGetListLength(temp) < 2 || llGetListLength(temp) > 2) // If the list length is smaller or higher than 2, something went wrong.
                        {
                            llOwnerSay("Failed to set the post regen. Too many or too few values in command. Your command: "+command);
                            return;
                        }
                        titles = llListReplaceList(titles, [llList2String(temp, 0),llList2String(temp, 1)], 9, 10); // Update the titles list with the correct values.
        
                        if(showCap && llList2String(titles, 8) == "off")
                        {
                            funcParseTitle(); // Reparse the title if showCal is on and percent is off.
                        }
                    }
                    // What version are we on?
                    else if(llToLower(m) == "version")
                    {
                        llOwnerSay(name+version);
                    }
                    // For changing which channel we listen to!
                    else if(llGetSubString(llToLower(m), 0, 12) == "changechannel")
                    {
                        m = llDeleteSubString(m, 0, 12);
                        m = llStringTrim(m, STRING_TRIM);
                        if(IsInteger(m)) // If valid integer...
                        {
                            if(m != "4" && m != "3" && m != "22" && m != "44")
                            {
                                llListenRemove(titleChanHandler); // Remove this listen.
                                titleChanHandler = FALSE;
                                
                                titleChan = (integer)m; // Update the titleChan value.
                                
                                
                                titleChanHandler = llListen(titleChan, "", "", ""); // Set a new listen.
                                llOwnerSay("Successfully changed operating channel to: "+(string)titleChan+"\nRemember to update this in your HUD to reflect this change if you use it."); // And announce!
                                llMessageLinked(LINK_THIS, 1330, (string)titleChan, "");
                            }
                            else
                            {
                                llOwnerSay("You cannot use chatter channels as titler channels.");
                            }
                        }
                        else
                        {
                            llOwnerSay("Couldn't change RP tool option channel - invalid integer. Your command: "+command);
                        }
                    }
                    // Toggle comma parsing!
                    else if(llToLower(m) == "comma")
                    {
                        string isComma = llList2String(titles, 12);
                        
                        if(IsInteger(isComma))
                        {
                            if(isComma == "0")
                            {
                                isComma = "1";
                            }
                            else if(isComma == "1")
                            {
                                isComma = "2";
                            }
                            else if((integer)isComma >= 2)
                            {
                                isComma = "0";
                            }
                            
                            titles = llListReplaceList(titles, [(string)isComma], 12, 12);                            
                            funcParseTitle();
                        }
                    }
                    else if(llGetSubString(llToLower(m), 0, 2) == "ooc")
                    {
                        out = 1;
                        m = llDeleteSubString(m, 0, 2);
                        m = llStringTrim(m, STRING_TRIM);
                        if(llToLower(m) == "none" || llToLower(m) == "hide")
                        {
                            ooc = "";
                        }
                        else if(m != "")
                        {
                            ooc = "["+m+"]";
                        }
                        funcParseTitle();
                    }
                    else if(llGetSubString(llToLower(m), 0, 2) == "afk")
                    {
                        out = 2;
                        m = llDeleteSubString(m, 0, 2);
                        m = llStringTrim(m, STRING_TRIM);
                        if(llToLower(m) == "none" || llToLower(m) == "hide")
                        {
                            afk = "";
                        }
                        else if(m != "")
                        {
                            afk = "["+m+"]";
                        }
                        funcParseTitle();
                    }
                    else if(llGetSubString(llToLower(m), 0, 3) == "back" || llGetSubString(llToLower(m), 0, 1) == "ic")
                    {
                        out = 0;
                        funcParseTitle();
                    }
        
                    else if(llToLower(m) == "save")
                    {
                        saveorload = 1;
                        llMessageLinked(LINK_THIS, 3, m, "");
                    }
                    else if(llToLower(m) == "load")
                    {
                        saveorload = 2;
                        llMessageLinked(LINK_THIS, 3, m, "");
                    }
                    // Rolling commands!
                    else if(llGetSubString(llToLower(m), 0, 3) == "roll")
                    {
                        integer faces = 20;
                        m = llDeleteSubString(m, 0, 3);
                        m = llStringTrim(m, STRING_TRIM);
                        list tmp = llParseStringKeepNulls(m, [" "], []);
                        if(IsInteger(llList2String(tmp, 0)) && (integer)llList2String(tmp, 0) > 1)
                        {
                            faces = (integer)llList2String(tmp, 0);
                        }
                        llSetObjectName(llList2String(titles, 0)+"'s Dice Roll (D"+(string)faces+")");
                        integer result = diceRoll(faces);
                        if(result > 0)
                        {
                            llSay(0, (string)result);
                        }
                        else
                        {
                            llOwnerSay("You need to specify at least 2 sides!");
                        }
                        llSetObjectName(name+version);
                    }
                    else if(llGetSubString(llToLower(m), 0, 9) == "silentroll")
                    {
                        integer faces = 20;
                        m = llDeleteSubString(m, 0, 9);
                        m = llStringTrim(m, STRING_TRIM);
                        list tmp = llParseStringKeepNulls(m, [" "], []);
                        if(IsInteger(llList2String(tmp, 0)) && (integer)llList2String(tmp, 0) > 1)
                        {
                            faces = (integer)llList2String(tmp, 0);
                        }
                        llSetObjectName(llList2String(titles, 0)+"'s Private Dice Roll (D"+(string)faces+")");
                        integer result = diceRoll(faces);
                        if(result > 0)
                        {
                            llOwnerSay((string)result);
                        }
                        else
                        {
                            llOwnerSay("You need to specify at least 2 sides!");
                        }
                        llSetObjectName(name+version);
                    }
                    // To give the help notecard.
                    else if(llToLower(m) == "help")
                    {
                        llGiveInventory(llGetOwner(), "Neckbeard RP Tool Help");    
                    }
                    else if(llToLower(m) == "changetitle")
                    {
                        showDialog(1);
                    }
                    else if(llToLower(m) == "changeconstant")
                    {
                        showDialog(2);
                    }
                    else if(llToLower(m) == "showcap")
                    {
                        if(showCap)
                        {
                            showCap = FALSE;
                        }
                        else
                        {
                            showCap = TRUE;
                        }
                        funcParseTitle();
                    }
                    else if(llToLower(llGetSubString(m, 0, 4)) == "alpha")
                    {
                        list tmp = llParseString2List(llToLower(m), [" "], []); // Parses the lowercased string into a list separated by whitespace.
                        if(llList2String(tmp, 1) == "hide") // Obvious.
                        {
                            alpha = -1.0;
                        }
                        else if(llList2String(tmp, 1) == "show") // Obvious.
                        {
                            alpha = 1.0;
                        }
                        else if((integer)((string)((integer)llList2String(tmp, 1)))) // If the value is an integer, apply it.
                        {
                            alpha = (float)llList2Integer(tmp, 1)/100;
                        }
                        else // If none of the above are true, error and exit.
                        {
                            llOwnerSay("Sorry, couldn't recognize float value. Your input: "+ command);
                            return;
                        }
                        funcParseTitle(); // And parse the title.
                    }
                    else // If none of the above match then we're probably updating titles...
                    {
                        // First let's just parse the entire string to a list, and then take the first value of that from it...
                        list msg = llList2List(llParseString2List(m, [" "], []), 0, 0); // What's our value here...
                        integer i = (llGetListLength(constants) - 1); // Get the length of our constants list.
                        integer x; // Our counting integer!
                        integer location = -1; // Where in the list we are...
                        string cnst; // Temporary string for constants.
                        if(~llSubStringIndex(llList2String(msg, 0), "_"))
                        {
                            // If there is underscore, treat as whitewspace.
                            msg = llListReplaceList(msg, [llDumpList2String(llParseString2List(llList2String(msg, 0), ["_"], []), " ")], 0, 0);
                        }
                        for(x=0;x<=i;x++) // Begin the loop...
                        {
                            // Now we're going to find which location our title's at...
                            cnst = llToLower(llList2String(constants, x)); // Parse to string.
                            if(llGetSubString(cnst, -1, -1) == ":" && llGetSubString(llList2String(msg, 0), -1, -1) != ":") // If there's a colon there and it's not present in the command, we'll remove it.
                            {
                                cnst = llDeleteSubString(cnst, -1, -1);
                            }
                            if(cnst == llToLower(llList2String(msg, 0))) // If the constants match up exactly, we have our title!
                            {
                                location = x;
                                jump break;
                            }
                        }
                        @break;
                        if(location < 0) // If after the loop is done, we have no location...
                        {
                            //llOwnerSay("Couldn't find your title. Your command: "+command); // Error away!
                            return; // And exit.
                        }
                        // But if all went as planned...
                        // Then we're going to update a title. So let's update!
        
                        if(location > 7) // If tmp is bigger than 7...
                        {
                            llOwnerSay("Could not update title. Title number not valid. Your command: "+command);
                            return;
                        }
        
                        m = llDeleteSubString(m, 0, (llStringLength(llList2String(msg, 0))-1)); // Then delete "title#" from the string.
                        m = llStringTrim(m, STRING_TRIM); // Trim the string for leading and trailing spaces.
                        if(location == 7 && (string)((integer)m) != m) // If we're updating our energy, and M is not an integer...
                        {
                            if(llToLower(m) == "hide" || llToLower(m) == "none")
                            {
                                m = "";
                            }
                            else
                            {
        
                                //llOwnerSay("Couldn't update title: "+llList2String(constants, location)+". Your value is not an integer! Your command: "+command);
                                //return;
                            }
                        }
                        else if(llToLower(m) == "hide" || llToLower(m) == "none")
                        {
                            m = "";
                        }
                        funcUpdTitle(FALSE, location, m); // Then update the title!
                    }
        
                } // End c == 1
                else if(c == Key2AppChan(llGetOwner(), 4321)) // Let's select titles.
                {
                    if(!changeIt)
                    {
                        selected = m;
                        integer i = ((integer)llGetSubString(selected, -1, -1) - 1); // Get the number.
                        llTextBox(llGetOwner(), "Title "+(string)(i+1)+": ("+llList2String(constants, i)+") "+llList2String(titles, i), changeTitle);
                        changeIt = TRUE;
                    }
                    else
                    {
                        integer i = ((integer)llGetSubString(selected, -1, -1) - 1); // Get the number.
                        if(llToLower(m) == "none" || llToLower(m) == "hide")
                        {
                            m = "";
                        }
                        //titles = llListReplaceList(titles, [m], i, i);
                        funcUpdTitle(FALSE, i, m); // Then update the title!
                        changeIt = FALSE;
                        llListenRemove(changeTitleHandler);
                        changeTitleHandler = FALSE;
                        changeTitle = FALSE;
                        selected = "";
                        //funcParseTitle();
                    }
                } // End
                else if(c == Key2AppChan(llGetOwner(), 4322)) // Let's select constants.
                {
                    if(!changeIt)
                    {
                        selected = m;
                        integer i = ((integer)llGetSubString(selected, -1, -1) - 1); // Get the number.
                        llTextBox(llGetOwner(), "Title "+(string)(i+1)+": ("+llList2String(constants, i)+") "+llList2String(titles, i), changeTitle);
                        changeIt = TRUE;
                    }
                    else
                    {
                        integer i = ((integer)llGetSubString(selected, -1, -1) - 1); // Get the number.
                        if(llToLower(m) == "none" || llToLower(m) == "hide")
                        {
                            m = "";
                        }
                        //constants = llListReplaceList(constants, [m], i, i);
                        funcUpdTitle(TRUE, i, m); // Then update the title!
                        changeIt = FALSE;
                        llListenRemove(changeTitleHandler);
                        changeTitleHandler = FALSE;
                        changeTitle = FALSE;
                        selected = "";
                        //funcParseTitle();
                    }
               }
            }
    }
}