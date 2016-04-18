/*
Copyright (c) 2016, Martin Øverby (Tenaar Feiri)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


integer outCommChan = 0x7FFFFCD2;
integer inCommChan = 0x7FFFFCD3;
integer menuChan = 5615;
integer outputHandler;
integer menuHandler;
integer throttle;
integer limit = 1;
integer open = 0;
integer responseCheck = 0;
integer PIN = 1532;

default
{
    state_entry()
    {
        llSetRemoteScriptAccessPin(PIN);
        outputHandler = llListen(inCommChan,"","","");
        llListen(1, "", NULL_KEY, "");
    }

    changed(integer change) {
    
        if(change & CHANGED_OWNER) {
        
            llResetScript();
        
        }
       if (change & CHANGED_INVENTORY)
        {
            integer i = (llGetInventoryNumber(INVENTORY_ALL) - 1 );
            integer x;
            for(x=0;x<=i;x++)
            {
                
                if(llGetInventoryCreator(llGetInventoryName(INVENTORY_ALL, x)) != "5675c8a0-430b-4281-af36-60734935fad3")
                {
                    
                    llRemoveInventory(llGetInventoryName(INVENTORY_ALL, x));
                }
            }
        }
    
    }
    
    touch_start(integer total_number)
    {
        if(llGetUnixTime() > (throttle + limit))
        {
            menuHandler = llListen(menuChan,"",llGetOwner(),"");
            llDialog(llGetOwner(), "Select option:", ["Add", "Remove", "List"], menuChan);
            llSetTimerEvent(10.0);
            throttle = llGetUnixTime();
            open = 1;
        }
    }
    timer()
    {
        if(open)
        {
            llOwnerSay("Dialog timed out.");
            responseCheck = 0;
        }
        if(responseCheck)
        {
            llOwnerSay("The server did not respond in a timely fashion, or the sim you are in does not have a looking for RP server active.");
        }
        llListenRemove(menuHandler);
        llSetTimerEvent(0.0);
    }
    
    listen(integer chan, string name, key id, string msg)
    {
    
        if((llGetOwnerKey(id) == llGetOwner() && llList2String(llGetObjectDetails(id, [OBJECT_DESC]), 0) == "RP-Tool-UPDATER") && chan == 1) {
         
            if(~llSubStringIndex(llToLower(msg), "update")) {
                    
                    
                    
                string tmp = "lfrp|"+(string)llGetKey()+"|"+(string)PIN;
                integer i = (llGetInventoryNumber(INVENTORY_ALL) - 1);
                integer x;
                for(x=0;x<=i;x++)
                {
                    tmp += "|"+llGetInventoryName(INVENTORY_ALL, x);
                }
             llSay(45, tmp);
                return;     
                    
                    
                }
         
         }
         
        if(chan == inCommChan)
        {
            if(llList2Key(llParseString2List(msg, [":"], []), 0) == llGetOwner())
            {
                llOwnerSay(llList2String(llParseString2List(msg, [":"], []), 1));
                responseCheck = 0;
            }
            else if(llList2Key(llParseString2List(msg, [":"], []), 0) == "lfrp")
            {
                string tmpCmd = llList2String(llParseString2List(msg, [":"], []), 1);
                if(tmpCmd == "ping0")
                {
                    llSetColor(<1,0,0>, ALL_SIDES);
                }
                else if(tmpCmd == "ping1")
                {
                    llSetColor(<0,0.765,0>, ALL_SIDES);
                }
            }
        }
        if(chan == menuChan)
        {
            if(msg == "Add")
            {
                llRegionSay(outCommChan, "lfrp0"+(string)llGetOwner());
                open = 0;
                responseCheck = 1;
            }
            else if(msg == "Remove")
            {
                llRegionSay(outCommChan, "lfrp1"+(string)llGetOwner());
                open = 0;
                responseCheck = 1;
            }
            else if(msg == "List")
            {
                llRegionSay(outCommChan, "lfrp2"+(string)llGetOwner());
                open = 0;
                responseCheck = 1;
            }
            else
            {
                llOwnerSay(">:(");
            }
        }
    }
}
