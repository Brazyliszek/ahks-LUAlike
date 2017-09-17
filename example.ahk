SetWorkingDir %A_ScriptDir%
#include lualike.ahk

example_script =
(
start
console("Start");
// comment 
if (A_ScreenWidth > 1000)
	then
		console("Screen width is wider than 1k px.");
	else
		console("Screen width is not wider than 1k px.");
endif
varCount := 0;
loop_label001:
if (varCount <= 5)
	then
		console("Loop count: "  . varCount . ".");
		varCount := varCount + 1;
		goto loop_label001;
endif
console("End");
end
)

execute(example_script)
exitapp
