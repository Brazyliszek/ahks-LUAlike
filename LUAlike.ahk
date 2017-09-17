;=======================================================================================
;
; Function:			execute()
; Description:		load script from txt
; Return value:		boolean, true if script was exectued successfully
;
; Author:			Brazyliszek/Brazolek123 [M.Trz]
; Credits:			ExprEval() by Uberi, Eval() by Pulover [Rodolfo U. Batista]
;
;=======================================================================================
;
;	bascis of lua-like syntax:
;	script must start with expression "start" and end with "end"
; 	script is executed line by line 
; 	functions and variable assignments must be ended with ";" sign
;	available expressions: start, if ( statement ), then, else, endif, goto, label, end
; 	if's statement must be within brackets and allow you to use all ahk operators (>, < =<, functions, etc and so on...)
;	goto goes to line with predefined label
;	label must be ended with ":" sign
; 	DO NOT USE SHORT VARIABLE NAMES like "i", "a", "num" etc...
; 	DOESN'T SUPPORT MULTI IF STATEMENTS, below example is not allowed:
;	if (a>b)
;		then
;			if (b>c)
;				then...
;			endif
;	endif
;
;======================================================================================


#include eval.ahk

execute(script){
   if (script = ""){
      Console("Script might not exist, it is broken or file directory is wrong.")
      return 0
   }
   
	;removes all tabs from code
	read_text:=RegExReplace(script, A_tab)
	
	;removes all blank lines from code
	Loop {
		StringReplace, read_text, read_text, `r`n`r`n, `r`n, UseErrorLevel
		if ErrorLevel = 0
			break
	}
    
	;shows code before parsing
	;msgbox, %read_text%

	global line:=[]
	lineType:=[]
	thenPos:=[]
	elsePos:=[]
	ifPos:=[]
	endifPos:=[]
	labelList:=[]
	thenAllowed:=0
	elseAllowed:=0
	global maxIndex
	
	;First level of script parsing
	;	1) assigning each code line to its type
	;	2) pre-check syntax 

	startCount:=0
	endCount:=0
	ifCount:=0
	endifCount:=0
	elseCount:=0
	thenCount:=0
	i:=1
	j:=
	
	;first loop without debugging
	Loop, parse, read_text, `n, `r 
	{
		line[i]  := A_LoopField
		maxIndex := i
		i++
	}
	
	i:=1
	;start debugging
	Loop, parse, read_text, `n, `r  
	{
		line[i]  := A_LoopField

		;check if it is label
		if (lineEndsWith(line[i], ":")){
			if (InStr(line[i], A_SPACE)){
				Console("Script error at line: " . i . ".`nLabel must not contain any spaces...`n`n`nSpecifically: `n" . print3Lines(i) )
				return 0
			}
			lineType[i] := "label"
			labelList[i]:= trim(line[i],":")
		}
		
		;check if it is goto
		else if ((lineEndsWith(line[i], ";")) and !(lineEndsWith(line[i], ":")) and (InStr(SubStr(line[i], 1 , 4),"goto")))
			lineType[i] := "goto-expression"
		;check if its comment
		else if (InStr(SubStr(line[i], 1 , 4),"//"))
			lineType[i] := "comment"
		
		; check rest expressions
		else if (line[i]="start"){
			lineType[i] := "start-expression"
			startCount++
		}
		else if (line[i]="end"){
			lineType[i] := "end-expression"
			endcount++
		}
		else if (line[i]="then"){
			lineType[i] := "then-expression"
			thenPos[thenCount]:=i
			thenCount++
		}
		else if (line[i]="else"){
			lineType[i] := "else-expression"
			elsePos[elseCount]:=i
			elseCount++
		}
		else if (line[i]="endif"){
			lineType[i] := "endif-expression"
			endifPos[endifCount]:=i
			endifCount++
		}
		
		;check if it is var
		else if (lineEndsWith(line[i], ";") and InStr(line[i], ":=")){
			lineType[i] := "var"
		}
		
		;check if it is function
		else if ((lineEndsWith(line[i], ";")) and !(lineEndsWith(line[i], ":")) and !(InStr(line[i], ":="))){
			StringReplace, tempOut,A_LoopField,`(,`(,UseErrorLevel
			countLeftsided := ErrorLevel
			StringReplace, tempOut,A_LoopField,`),`),UseErrorLevel
			countRightsided := ErrorLevel
			if (countLeftsided > 0 and (countLeftsided=countRightsided)){
				StringReplace, tempStr, A_LoopField, %A_SPACE%,, All
				if isFunc(SubStr(tempStr, 1, InStr(tempStr, "(") - 1)){
					lineType[i] := "func"
				}
				else{
					Console("Script error at line: " . i . ".`nNot recgonized function " .  SubStr(tempStr, 1, InStr(tempStr, "(") - 1)  . ".`n`n`nSpecifically: `n" . print3Lines(i) )
					return 0
				}
			}
		}
		
		;check if its "if-expression"
		else if (!(lineEndsWith(line[i], ";")) and !(lineEndsWith(line[i], ":")) and (InStr(SubStr(line[i], 1 , 2),"if"))){
			lineType[i] := "if-expression"
			ifPos[ifCount]:=i
			ifCount++
		}
			
		;if non of above statements were true parser should return failure
		else{
				Console("Script error at line: " . i . ".`nCould not read statement.`n`n`nSpecifically: `n" . print3Lines(i) )
				return 0
			}
		maxIndex:=i
		i++
	}

	; second level of syntax check
	if (startCount > 1){
		Console("Script syntax error.`nToo many 'start' expressions.")
		return 0
	}
	if (startCount = 0){
		Console("Script syntax error.`nFunction must begin with 'start' expression.")
		return 0
	}
	if (endCount > 1){
		Console("Script syntax error. `nToo many 'end' expressions.")
		return 0
	}
	if (endCount = 0){
		Console("Script syntax error.`nFunction must be closed with 'end' expression.")
		return 0
	}
	if (ifCount > endifCount){
		Console("Script syntax error.`n'If' expression not ended with 'endif'.")
		return 0
	}
	if (ifCount < endifCount){
		Console("Script syntax error.`n'Endif' with no matching 'if' expression.")
		return 0
	}
	if (thenCount > ifCount){
		Console("Script syntax error.`n'Then' with no matching 'if' expression.")
		return 0
	}
	if (thenCount < ifCount){
		Console("Script syntax error.`n'If' with no matching 'then' expression.")
		return 0
	}
	if (elseCount > thenCount){
		Console("Script syntax error.`n'Else' with no matching 'then' expression.")
		return 0
	}

	;third level of syntax chceck
	i:=0
	k_longVar:=0
	loop %ifCount% {
		A_longVar:=ifPos[i]
		B_longVar:=endifPos[i]
		C_longVar:=thenPos[i]
		D_longVar:=elsePos[k_longVar]
		;msgbox % "ifpos: " . A_longVar . "`nthenpos: " . c_longVar . "`nelsepos: " . d_longVar . "`nendifpos: " . b_longVar 
		if (C_longVar-A_longVar>1){
			Console("Script error at line: " . c_longVar . "`n'Then' expression should be placed in the very next line of 'if-statement'.`n`n`nSpecifically here:`n" . print3Lines(c_longVar))
			return 0
		}
		if (D_longVar!=""){
			if (D_longVar>B_longVar){     ;gdy else jest poza endifem
				k_longVar--
			}
			else if (D_longVar<C_longVar){
				Console("Script error at line: " . d_longVar . "`n'Else' expression should be placed after 'then'.`n`n`nSpecifically here:`n" . print3Lines(d_longVar))
				return 0
			}
		}
		i++
		k_longVar++
	}


	;upon success execute it
	i:=1
	while (lineType[i] != "end-expression"){
		if (lineType[i] = "start-expression"){
			i++
		}
		else if (lineType[i] = "func"){
			eval(line[i])
			i++
		}
		else if (lineType[i] = "var"){
			exp:=RTrim(line[i], ";")
			eval(exp)
			i++
		}
		else if (lineType[i] = "comment"){
			i++
		}
		else if (lineType[i] = "if-expression"){
			StringGetPos, startNawias, % line[i], `(, L
			StringGetPos, endNawias, % line[i], `), R
			exp := SubStr(line[i], startNawias+1, endNawias - startNawias + 1)
			if StrJoin(eval(exp), ""){										;goto label then
				i++
				thenAllowed:=1
				elseAllowed:=0
			}
			else{											;goto label else if exist else go to label endif
				i++
				thenAllowed:=0
				elseAllowed:=1
			}
		}
		else if (lineType[i] = "then-expression"){
			if (thenAllowed){
				thenAllowed:=0
				elseAllowed:=0
				i++
			}
			else{
				while (lineType[i] != "else-expression") and (lineType[i] != "endif-expression"){
					i++
				}
			}
		}
		else if (lineType[i] = "else-expression"){
			if (elseAllowed){
				thenAllowed:=0
				elseAllowed:=0
				i++
			}
			else{
				while (lineType[i] != "endif-expression"){
				i++
				}
			}
		}
		else if (lineType[i] = "endif-expression"){
			thenAllowed:=0
			elseAllowed:=0
			i++
		}
		else if (lineType[i] = "goto-expression"){
			labelName:=trim(line[i], "goto ")
			labelName:=trim(labelName, ";")
			For key, value in labelList
				if (value = labelName){
					i:=key
					break
				}
		}
		else if (lineType[i] = "label"){
			i++
		}
		else if (lineType[i] = "end"){
			return 1
		}
		else{
			Console("Script unexpected error at line: " . i . ".`n`n`nSpecifically: `n" . print3Lines(i))
			return 0
		}
	}
return 1
}


print3Lines(i){
	global maxIndex
	global line
	if (i=1)
		return i . " >   " . line[i] . "`n" . i + 1 . "       " .  line[i+1] . "`n" . i + 2 . "       " .  line[i+2]
	else if (i=maxIndex)
		return i - 2 . "       " . line[i-2] . "`n" . i -1 . "       " . line[i-1] . "`n" . i . " >   " .  line[i]
	else if (i <= 8)
		return i - 1 . "       " . line[i-1] . "`n" . i . " >   " . line[i] . "`n" . i + 1 . "       " .  line[i+1]
	else if (i = 9)
		return i - 1 . "       " . line[i-1] . "`n" . i . " >   " . line[i] . "`n" . i + 1 . "     " .  line[i+1]
	else if (i = 10)
		return i - 1 . "         " . line[i-1] . "`n" . i . " >   " . line[i] . "`n" . i + 1 . "       " .  line[i+1]
	else if (i >= 11)
		return i - 1 . "       " . line[i-1] . "`n" . i . " >   " . line[i] . "`n" . i + 1 . "       " .  line[i+1]
	else if (i>maxIndex)
		return "ERROR"
	else
		return "ERROR"
}

lineEndsWith(content, Delimiter){
	if SubStr(content, StrLen(content) , 1) = Delimiter
		return 1
	else
		return 0
}

Console(text){
	msgbox, % text
}