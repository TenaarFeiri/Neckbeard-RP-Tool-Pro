// New Storage script for character backups.
// Written by Tenaar Feiri.
//
/*
	Copyright (c) 2017, Martin �verby (Tenaar Feiri)
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

	3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


// For backups, we'll be using a list with the following format: charname, chardata
list backups;

// How we communicate.
integer channel_id; // ID for our channel so we can track it and disable it.
integer channel; // Channel number.


// Booleans and integers
integer what_action = 0; // 1 = backup, 2 = restore.
integer debug = TRUE; // debug mode


// Menu lists
string touch_menu_str = "What do you want to do?"
	list touch_menu = ["Backup", "Restore", "Cancel"];

string confirm_action = "Please confirm action: ";
string selected_action = "None";


default
{
	state_entry()
	{
		// Init
		if(debug)
		{
		}
	}
	touch_end(integer total_number)
	{
		// I prefer using touch_end.
		// touch_start is also acceptable.


	}
	listen(integer c, string n, key id, string m)
	{
		if(!channel_id || c != channel || !what_action)
		{
			// We don't want anything here to trigger if we're not expecting it.
			return;
		}



	}
}