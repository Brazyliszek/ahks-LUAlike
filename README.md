# ahks-LUAlike

parser that allow you to get acces to int. script functions and variables by simple txt scripts interpreted line by line


### Function:		
execute()
 
### Description:		
load script from txt
 
### Return value:		
boolean, true if script was exectued successfully

### Author:		
Brazyliszek/Brazolek123 [M.Trz]
 
### Credits:		
ExprEval() by Uberi, Eval() by Pulover [Rodolfo U. Batista]


## Bscis of lua-like syntax:
* script must start with expression "start" and end with "end"
* script is executed line by line 
* functions and variable assignments must be ended with ";" sign
* available expressions: start, if ( statement ), then, else, endif, goto, label, end
* if's statement must be within brackets and allow you to use all ahk operators (>, < =<, functions, etc and so on...)
* goto goes to line with predefined label
* label must be ended with ":" sign



 DO NOT USE SHORT VARIABLE NAMES like "i", "a", "num" etc...
 
 DOESN'T SUPPORT MULTI IF STATEMENTS, below example is not allowed:
```
if (a>b)
	then
	if (b>c)
		then...
	endif
endif
```
