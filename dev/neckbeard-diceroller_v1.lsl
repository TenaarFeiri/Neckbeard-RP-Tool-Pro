// New script for rolling dice.


default
{
	state_entry()
	{
		llSay(0, "Hello, Avatar!");
	}
	touch_start(integer total_number)
	{
		llSay(0, "Touched: "+(string)total_number);
	}
}