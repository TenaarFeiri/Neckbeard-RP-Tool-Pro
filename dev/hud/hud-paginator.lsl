/*
Copyright (c) 2016, Martin Øverby (Tenaar Feiri), Erika Fluffy
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

list buttons = 
[
/*0*/     "1",   0.009202, 0.316777, 0.058819, 0.965371, //1,2,3,4
/*5*/     "2",   0.337282, 0.660236, 0.058819, 0.965371, //6,7,8,9
/*10*/    "3",   0.675615, 0.993443, 0.058819, 0.965371 //11,12,13,14

];

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

default
{
    state_entry()
    {
        
    }
    
    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llResetScript();
        }
    }

    touch_end(integer total_number)
    {
        if(llDetectedKey(0) != llGetOwner())
        {
            return;
        }
        
        vector point = llDetectedTouchST(0);
        //llOwnerSay("X: " + (string)point.x + "\nY: " + (string)point.y);
        integer which = whichButton(point.x, point.y);
        if(which != -1)
        {
            if(which == 0)
            {
                llMessageLinked(LINK_SET, 1, "nbapage", NULL_KEY);
            }
            else if(which == 5)
            {
                llMessageLinked(LINK_SET, 2, "nbapage", NULL_KEY);
            }
            else if(which == 10)
            {
                llOwnerSay("Page 3 not implemented yet.");
                //llMessageLinked(LINK_SET, 3, "nbapage", NULL_KEY);
            }
        }
    }
}
