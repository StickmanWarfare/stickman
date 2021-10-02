unit Scripts;

interface

uses
  D3DX9,
  SysUtils,
  Windows,
  MMSystem,
  //
  IdHTTP,
  IdMultipartFormData,
  //
  Typestuff,
  Multiplayer,
  Props,
  newsoundunit,
  qjson;

type
  TScriptsHandler = class;

  TScript = record
    name: string;
    instructions: TStringArray;
  end;

  T3dLabel = record
    pos: TD3DXVector3;
    rad: single;
    text: string;
  end;

  TVecVar = record
    pos: TD3DXVector3;
    name: string;
  end;

  TNumVar = record
    num: single;
    name: string;
  end;

  TStrVar = record
    text: string;
    name: string;
  end;

  TBind = record
    key: char;
    script: string;
  end;

  TTimedscript = record
    time: cardinal;
    script: string;
  end;

  TScriptArray = array of TScript;
  TBindArray = array of TBind;
  TTimedscriptArray = array of TTimedscript;
  TVecVarArray = array of TVecVar;
  TNumVarArray = array of TNumVar;
  TStrVarArray = array of TStrVar;

  TCommand = string;
  TCommandHandler = function(args: TStringArray; out handler: TScriptsHandler): boolean;
  TCommandHandlerArray = array of TCommandHandler;

  TArgsParserResult = record
    args: TStringArray;
    handled: boolean;
  end;

  TScriptsHandler = class (TObject)
    private
      _scripts: TScriptArray;
      _timedscripts: TTimedscriptArray;
      _commandHandlers: TCommandHandlerArray;
      //
      _vecVars: TVecVarArray;
      _numVars: TNumVarArray;
      _strVars: TStrVarArray;
      //
      _actualscript: string;
      _actualscriptline: integer;
      _scriptdepth: integer;
      _scriptevaling: array[0..50] of boolean;
    public
      _binds: TBindArray; //TODO: make private (waiting for more unit refacts)
    published
      constructor Create(config: TQJSON);
      procedure handletimedscripts;
      //
      function explodeLine(line: string; args: TStringArray): TStringArray;
      function parseGlobals(args: TStringArray): TArgsParserResult;
      function parseControls(args: TStringArray): TArgsParserResult;
      function parseAssignments(args: TStringArray): TArgsParserResult;
      function parseDeclarations(args: TStringArray): TArgsParserResult;
      function parseCommands(args: TStringArray; line: string): TArgsParserResult;
      //
      function compute(words: TStringArray): TSingleArray;
      function computeVecs(words: TStringArray): TD3DXVector3;
      function computeNums(words: TStringArray): single;
      function getVecVar(name: string): TD3DXVector3;
      function getNumVar(name: string): single;  
      procedure varCompare(args: TStringArray);
      //
      function varToString(input: string): string;
      procedure scripterror(text: string);
      procedure evalScript(name: string);
      procedure evalScriptLine(line: string);
  end;

var
  scriptsHandler: TScriptsHandler;


implementation

function getLangCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward; 
function bindCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function unbindCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function unbindAllCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function triggerEnableCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function triggerDisableCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function fastinfoCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function fastinfoRedCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function printCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function chatmostCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function displayCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function closedisplayCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function scriptCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function timeoutCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function particleStopCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function particleStartCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function particlePositionCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function propHideCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function propShowCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function dynamizateCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function dynamicSpeedCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function propPositionCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function propRotationCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function botWaveCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function botSkirmishCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function botStartBattleCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function botStopBattleCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function explodeCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
//function respawnCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function soundCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
function fegyvskinCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;
//function watercraftCMD(args: TStringArray; out handler: TScriptsHandler): boolean; forward;



constructor TScriptsHandler.Create(config: TQJSON);
var
  n, m, i, j: Integer;
begin
  //init arrays
  setlength(_scripts, 0);
  setlength(_binds, 0);
  setlength(_timedscripts, 0);
  setlength(_vecVars, 0);
  setlength(_numVars, 0);
  setlength(_strVars, 0);
  setlength(_commandHandlers, 0);

  //parse JSON
  n := config.GetNum(['scripts']);
  setlength(_scripts, n);
  for i := 0 to n - 1 do
    with _scripts[i] do
    begin
      m := config.GetNum(['scripts', i]);
      setlength(instructions, m);
      name := config.GetKey(['scripts'], i);

      for j := 0 to m - 1 do
        instructions[j] := config.GetString(['scripts', i, j]);
    end;

  //TODO: niceify
  setlength(_commandHandlers, 30);
  _commandHandlers[0] := getLangCMD;
  _commandHandlers[1] := bindCMD;
  _commandHandlers[2] := unbindCMD;
  _commandHandlers[3] := unbindAllCMD;
  _commandHandlers[4] := triggerEnableCMD;
  _commandHandlers[5] := triggerDisableCMD;
  _commandHandlers[6] := fastinfoCMD;
  _commandHandlers[7] := fastinfoRedCMD;
  _commandHandlers[8] := printCMD;
  _commandHandlers[9] := chatmostCMD;
  _commandHandlers[10] := displayCMD;
  _commandHandlers[11] := closedisplayCMD;
  _commandHandlers[12] := scriptCMD;
  _commandHandlers[13] := timeoutCMD;
  _commandHandlers[14] := particleStopCMD;
  _commandHandlers[15] := particleStartCMD;
  _commandHandlers[16] := particlePositionCMD;
  _commandHandlers[17] := propHideCMD;
  _commandHandlers[18] := propShowCMD;
  _commandHandlers[19] := dynamizateCMD;
  _commandHandlers[20] := dynamicSpeedCMD;
  _commandHandlers[21] := propPositionCMD;
  _commandHandlers[22] := propRotationCMD;
  _commandHandlers[23] := botWaveCMD;
  _commandHandlers[24] := botSkirmishCMD;
  _commandHandlers[25] := botStartBattleCMD;
  _commandHandlers[26] := botStopBattleCMD;
  _commandHandlers[27] := explodeCMD;
  _commandHandlers[28] := soundCMD;
  _commandHandlers[29] := fegyvskinCMD;

  _scriptdepth := 0;
end;

procedure TScriptsHandler.scripterror(text: string);
begin
  writeln(logfile, text, ' in ', _actualscript, ' : ', _actualscriptline);
end;

procedure TScriptsHandler.handletimedscripts;
var
  i, j, n:integer;
  now:cardinal;
begin
  n:=length(_timedscripts);
  now:=GetTickCount;

  for i:=0 to n - 1 do
  begin
    if _timedscripts[i].time < now then
    begin
      evalscript(_timedscripts[i].script);
    end;
  end;

  for i:=0 to length(_timedscripts) - 1 do
  begin
    if _timedscripts[i].time < now then
    begin
      for j:=i to length(_timedscripts) - 2 do
        _timedscripts[j]:=_timedscripts[j + 1];
      SetLength(_timedscripts, length(_timedscripts) - 1);
    end;
  end;
end;

function TScriptsHandler.varToString(input: string): string;
var
  i, n:integer;
  varname:string;
begin
  result:=input;
  if length(input) < 2 then exit;
  if input[1] = '%' then
  begin
    varname:=copy(input, 2, length(input) - 1);
    n:=Length(_numVars);
    for i:=0 to n - 1 do
      if _numVars[i].name = varname then
      begin
        result:=FormatFloat('0.####', _numVars[i].num);
        exit;
      end;
  end
  else
    if input[1] = '!' then
    begin
      varname:=copy(input, 2, length(input) - 1);
      n:=Length(_vecVars);
      for i:=0 to n - 1 do
        if _vecVars[i].name = varname then
        begin
          result:=FloatToStr(_vecVars[i].pos.x) + ', ' + FloatToStr(_vecVars[i].pos.y) + ', ' + FloatToStr(_vecVars[i].pos.z);
          exit;
        end;
    end
    else
      if input[1] = '$' then
      begin
        if input = '$_' then begin result:= ' ';exit; end;
        if input = '$NL' then begin result:=AnsiString(#13#10);exit; end;
        varname:=copy(input, 2, length(input) - 1);
        n:=Length(_strVars);
        for i:=0 to n - 1 do
          if _strVars[i].name = varname then
          begin
            result:=_strVars[i].text;
            exit;
          end;
      end;
end;

function TScriptsHandler.explodeLine(line: string; args: TStringArray): TStringArray;
var
  i, j, len: integer;
begin
  result := args;

  len:=Length(line);
  j:=0;
  SetLength(result, 1);

  for i:=1 to len do begin
    if (line[i] = ' ') then
    begin
      if ((Length(result[j]) > 0)) then
      begin
        inc(j);
        SetLength(result, j + 1);
      end;
    end
    else
    begin
      result[j]:=result[j] + line[i];
    end;
  end;
end;

function TScriptsHandler.parseGlobals(args: TStringArray): TArgsParserResult;
var
  i, j, argnum: integer;
begin
  result.args := args;
  result.handled := false;

  argnum := length(result.args);

  for i:=1 to high(result.args) do
  begin
    if result.args[i] = '!playerpos' then
    begin                                 
      result.handled := true;
      setLength(result.args, Length(result.args) + 2);
      argnum:=argnum + 2;
      for j:=argnum - 1 downto i + 1 do
      begin
        result.args[j]:=result.args[j - 2];
        result.args[i]:=FloatToStr(cpx^);
        result.args[i + 1]:=FloatToStr(cpy^);
        result.args[i + 2]:=FloatToStr(cpz^);
      end;

      continue;
    end;

    if result.args[i] = '$weapon' then
    begin               
      result.handled := true;
      case myfegyv of
        FEGYV_MPG:result.args[i] := 'FEGYV_MPG';
        FEGYV_M82A1:result.args[i] := 'FEGYV_M82A1';
        FEGYV_M4A1:result.args[i] := 'FEGYV_M4A1';
        FEGYV_QUAD:result.args[i] := 'FEGYV_QUAD';
        FEGYV_NOOB:result.args[i] := 'FEGYV_NOOB';
        FEGYV_LAW:result.args[i] := 'FEGYV_LAW';
        FEGYV_X72:result.args[i] := 'FEGYV_X72';
        FEGYV_MP5A3:result.args[i] := 'FEGYV_MP5A3';
        FEGYV_H31_T:result.args[i] := 'FEGYV_H31_T';
        FEGYV_H31_G:result.args[i] := 'FEGYV_H31_G';
        FEGYV_HPL:result.args[i] := 'FEGYV_HPL';
        FEGYV_BM3:result.args[i] := 'FEGYV_BM3';
        FEGYV_BM3_2, FEGYV_BM3_3:;
      end;

      continue;
    end;

    if result.args[i] = '$team' then
    begin      
      result.handled := true;
      case myfegyv of
        FEGYV_MPG, FEGYV_QUAD, FEGYV_NOOB, FEGYV_X72, FEGYV_H31_T, FEGYV_HPL:result.args[i] := 'TECH';
      else
        result.args[i] := 'GUN';
      end;

      continue;
    end;

    if result.args[i] = '%teamn' then
    begin       
      result.handled := true;
      case myfegyv of
        FEGYV_MPG, FEGYV_QUAD, FEGYV_NOOB, FEGYV_X72, FEGYV_H31_T, FEGYV_HPL:result.args[i] := '0';
      else
        result.args[i] := '1';
      end;

      continue;
    end;

  end; //for
end;

function TScriptsHandler.parseControls(args: TStringArray): TArgsParserResult;
begin
  result.args := args;
  result.handled := false;

  if (result.args[0] = 'if') then
  begin                                 
    result.handled := true;
    if not _scriptevaling[_scriptdepth] then
    begin
      inc(_scriptdepth);
      _scriptevaling[_scriptdepth]:=false;
    end
    else
      varCompare(copy(result.args, 1, length(result.args) - 1));

    exit;
  end;

  if (result.args[0] = 'else') then
  begin
    result.handled := true;
    if _scriptdepth > 0 then
      _scriptevaling[_scriptdepth] := not _scriptevaling[_scriptdepth] and _scriptevaling[_scriptdepth - 1]
    else
      scripterror('Unexpected else');

    exit;
  end;

  if (result.args[0] = 'endif') then
  begin
    result.handled := true;
    if _scriptdepth > 0 then
      dec(_scriptdepth)
    else
      scripterror('Unexpected endif');

    exit;
  end;
end;

function TScriptsHandler.parseAssignments(args: TStringArray): TArgsParserResult;
var
  i, j: integer;
  t, tmp: string;
begin
  result.args := args;
  result.handled := false;

  if (length(result.args) <= 1) then exit;

  t:=result.args[0][1];

  if (t = '!') and (result.args[1] = '=') then
  begin
    result.handled := true;
    for i:=0 to length(_vecvars) - 1 do
      if result.args[0] = '!' + _vecvars[i].name then
        _vecvars[i].pos:=computevecs(copy(result.args, 2, length(result.args) - 2));

     exit;
  end;

  if (t = '%') and (result.args[1] = '=') then
  begin
    result.handled := true;
    for i:=0 to length(_numVars) - 1 do
      if result.args[0] = '%' + _numVars[i].name then
        _numVars[i].num:=computenums(copy(result.args, 2, length(result.args) - 2));

    exit;
  end;

  if (t = '$') and (result.args[1] = '=') then
  begin
    result.handled := true;
    for i:=0 to length(_strVars) - 1 do
      if result.args[0] = '$' + _strVars[i].name then
       begin
         tmp:= '';
         for j:=2 to length(result.args) - 1 do
         begin
           tmp:=tmp + varToString(result.args[j]);
           //if j<Length(args)-1 then tmp := tmp + ' ';
         end;
         _strVars[i].text:=tmp;
       end;

     exit;
   end;
   
end;

function TScriptsHandler.parseDeclarations(args: TStringArray): TArgsParserResult;
begin
  result.args := args;
  result.handled := false;

  if (result.args[0] <> 'var') or (length(result.args) <= 1) then exit;

  if (result.args[1][1] = '%') then
  begin
    result.handled := true;
    setlength(_numVars, length(_numVars) + 1);
    _numVars[length(_numVars) - 1].name := copy(result.args[1], 2, length(result.args[1]) - 1);

    exit;
  end;

  if (result.args[1][1] = '!') then
  begin
    result.handled := true;
    setlength(_vecVars, length(_vecVars) + 1);
    _vecVars[length(_vecVars) - 1].name := copy(result.args[1], 2, length(result.args[1]) - 1);

    exit;
  end;

  if (result.args[1][1] = '$') then
  begin
    result.handled := true;
    setlength(_strVars, length(_strVars) + 1);
    _strVars[length(_strVars) - 1].name := copy(result.args[1], 2, length(result.args[1]) - 1);

    exit;
  end;
end;

function TScriptsHandler.parseCommands(args: TStringArray; line: string): TArgsParserResult;
var
  i: integer;
  res: boolean;
begin
  result.args := args;
  result.handled := false;

  for i := 0 to high(_commandHandlers) do
  begin
    res := _commandHandlers[i](result.args, self);
    result.handled := result.handled or res;
  end;
end;

function TScriptsHandler.getVecVar(name: string): TD3DXVector3;
var
  i, n:integer;
begin
  n:=length(_vecVars);
  result:=D3DXVector3Zero;
  for i:=0 to n - 1 do
    if _vecVars[i].name = name then
    begin
      result:=_vecVars[i].pos;
      exit;
    end;

  //why isnt this script error lel debug loife
  multisc.chats[addchatindex].uzenet := 'No such vector variable: ' + name;
  addchatindex:=addchatindex + 1;
end;

function TScriptsHandler.getNumVar(name: string): single;
var
  i, n:integer;
begin
  n:=length(_numVars);
  result:=0;
  for i:=0 to n - 1 do
    if _numVars[i].name = name then
    begin
      result:=_numVars[i].num;
      exit;
    end;

  //why isnt this script error lel debug loife part 2
  multisc.chats[addchatindex].uzenet := 'No such numeric variable: ' + name;
  addchatindex:=addchatindex + 1;
end;

procedure TScriptsHandler.varCompare(args: TStringArray);
var
  argnum, i, j:integer;
  v1, v2:single;
  truth:boolean;
  op:string;
  a, b:TStringArray;
begin
  argnum:=length(args);

  //find the comparator
  for i:=0 to high(args) do
  begin

    if ((args[i] <> '=') or (args[i] <> '>') or (args[i] <> '<') or
        (args[i] <> '!=') or (args[i] <> '>=') or (args[i] <> '<=')) then
    begin
      continue;
    end;

    op := args[i];
    setlength(a, i);
    setlength(b, argnum - i - 1);

    for j:=0 to i - 1 do
      a[j] := args[j];

    for j:=0 to argnum - i - 2 do
      b[j] := args[i + 1 + j];

    v1:=compute(a)[0];
    v2:=compute(b)[0];

    truth := false;

    if (op = '=') and (v1 = v2) then truth := true;
    if (op = '<') and (v1 < v2) then truth := true;
    if (op = '>') and (v1 > v2) then truth := true;
    if (op = '!=') and (v1 <> v2) then truth := true;
    if (op = '<=') and (v1 <= v2) then truth := true;
    if (op = '>=') and (v1 >= v2) then truth := true;

    inc(_scriptdepth);
    _scriptevaling[_scriptdepth] := truth;

    exit;
  end;//for

end;

function TScriptsHandler.computeVecs(words: TStringArray): TD3DXVector3;
var
  tmp:TSingleArray;
  tmp2:TStringArray;
  i, n:integer;
begin
  n:=length(words);
  setLength(tmp2, n);

  for i:=0 to n - 1 do
    tmp2[i]:=words[i];

  tmp:=compute(tmp2);
  result:=D3DXVector3(tmp[0], tmp[1], tmp[2]);
end;

function TScriptsHandler.computeNums(words: TStringArray): single;
var
  tmp:TSingleArray;
  tmp2:TStringArray;
  i, n:integer;
begin
  n:=length(words);
  setLength(tmp2, n);

  for i:=0 to n - 1 do
    tmp2[i]:=words[i];

  tmp:=compute(tmp2);
  result:=tmp[0];
end;

function TScriptsHandler.compute(words: TStringArray): TSingleArray;
var
  i, j, n:integer;
  tmp:TD3DXVector3;
  error:Integer;
  numnum, varnum:integer;
  nums, vars:array[0..2] of single;
  operator:char;
  value:single;
  r:TSingleArray;
begin
  // ! vector variable
  // % number variable
  // what the fuck is string wow thx Hector

  setlength(words, length(words) + 1);
  words[high(words)] := '//';

  n := length(words);

  for i := 0 to high(words) do
    if words[i][1] = '!' then
    begin
      tmp := getVecVar(copy(words[i], 2, length(words[i]) - 1));

      setlength(words, n + 2);
      n := n + 2;

      if i <> n - 2 then
        for j := n - 1 downto i + 3 do
          words[j] := words[j - 2];

      words[i] := FloatToStr(tmp.x);
      words[i + 1] := FloatToStr(tmp.y);
      words[i + 2] := FloatToStr(tmp.z);

    end else
      if words[i][1] = '%' then
        words[i] := FloatToStr(getNumVar(copy(words[i], 2, length(words[i]) - 1)));

  //variables processed, lets count
  numnum:=0;
  varnum:=0;
  operator:= ' ';

  for i:=0 to n - 1 do
  begin
    val(words[i], value, error);

    if error = 0 then
    begin //number!
      inc(numnum); //count numbers in a row

      if numnum > 3 then
      begin
        scripterror('Unexpected fourth number: ' + words[i]);
        exit;
      end;

      nums[numnum - 1]:=value;

    end
    else
    begin

      if (operator <> ' ') then //operators
      begin
        if (numnum = 1) and (varnum = 1) then
        begin
          if operator = '+' then vars[0]:=vars[0] + nums[0];
          if operator = '-' then vars[0]:=vars[0] - nums[0];
          if operator = '*' then vars[0]:=vars[0] * nums[0];
          if operator = '/' then vars[0]:=vars[0] / nums[0];
        end else
          if (numnum = 3) and (varnum = 1) then
          begin
            if operator = '+' then
            begin
              scripterror('Single and vector addition');exit end;
            if operator = '-' then
            begin
              scripterror('Single and vector substraction');exit end;
            if operator = '*' then
            begin
              vars[0]:=vars[0] * nums[0];vars[1]:=vars[0] * nums[1];vars[2]:=vars[0] * nums[2]; end;
            if operator = '/' then
            begin
              vars[0]:=vars[0] / nums[0];vars[1]:=vars[0] / nums[1];vars[2]:=vars[0] / nums[2]; end;
          end else
            if (numnum = 1) and (varnum = 3) then
            begin
              if operator = '+' then
              begin
                scripterror('Single and vector addition');exit end;
              if operator = '-' then
              begin
                scripterror('Single and vector substraction');exit end;
              if operator = '*' then
              begin
                vars[0]:=vars[0] * nums[0];vars[1]:=vars[1] * nums[0];vars[2]:=vars[2] * nums[0]; end;
              if operator = '/' then
              begin
                scripterror('Vector and single division');exit end;
            end else
              if (numnum = 3) and (varnum = 3) then
              begin
                if operator = '+' then
                begin
                  vars[0]:=vars[0] + nums[0];vars[1]:=vars[1] + nums[1];vars[2]:=vars[2] + nums[2]; end;
                if operator = '-' then
                begin
                  vars[0]:=vars[0] - nums[0];vars[1]:=vars[1] - nums[2];vars[2]:=vars[2] - nums[2]; end;
                if operator = '*' then
                begin
                  vars[0]:=vars[0] * nums[0];vars[1]:=vars[1] * nums[1];vars[2]:=vars[2] * nums[2]; end;
                if operator = '/' then
                begin
                  vars[0]:=vars[0] / nums[0];vars[1]:=vars[1] / nums[1];vars[2]:=vars[2] / nums[2]; end;
              end else

                //if a tree falls in the forest...
      end
      else
      begin
        if (numnum = 1) then begin vars[0]:=nums[0];varnum:=1 end else
          if (numnum = 3) then begin vars[0]:=nums[0];vars[1]:=nums[1];vars[2]:=nums[2];varnum:=3 end;
      end;

      if (words[i] = '+') or (words[i] = '-') or (words[i] = '*') then
      begin
        if (numnum = 0) or (numnum = 2) then
        begin
          scripterror('Unexpected operator: ' + words[i]);
          exit;
        end;

        operator:=words[i][1];
        numnum:=0;

      end
      else
        if (words[i] = '//') then //end
        begin
          SetLength(r, 3);
          r[0]:=vars[0];
          r[1]:=vars[1];
          r[2]:=vars[2];
          result:=r;
        end
        else
        begin
          scripterror('Syntax error: ' + words[i]);
          exit;
        end;
    end;

  end;

end;


procedure TScriptsHandler.evalScript(name:string);
var
  i, j, n, m:integer;
begin
  laststate := 'TScriptsHandler.evalScript 1';

  if name = '' then exit;

  _scriptdepth:=0;                    
  laststate := 'TScriptsHandler.evalScript 2';
  _scriptevaling[_scriptdepth]:=true;    
  laststate := 'TScriptsHandler.evalScript 3';

  n:=Length(_scripts);
  for i:=0 to n - 1 do
  begin
    if _scripts[i].name = name then
    begin
      m:=Length(_scripts[i].instructions);
      _actualscript:=name;
      for j:=0 to m - 1 do
      begin
        _actualscriptline:=j + 1;
        evalscriptline(_scripts[i].instructions[j]);
      end;

      _scriptdepth:=0;
      _scriptevaling[_scriptdepth]:=true;

      exit;
    end;
  end;
end;

procedure TScriptsHandler.evalscriptline(line: string);
var
  args: TStringArray;
  parserResult: TArgsParserResult;
begin
  DecimalSeparator:= '.';  //for reading json in commands
  setlength(args, 0);

  //split to words
  args := explodeLine(line, args);

  //shits fucked
  if length(args) <= 0 then exit;

  //plugging in
  parserResult := parseGlobals(args);
  if parserResult.handled then exit;
  args := parserResult.args;

  //wow, its something
  parserResult := parseControls(args);
  if parserResult.handled then exit;
  args := parserResult.args;

  //sneaky short circuit
  if not _scriptevaling[_scriptdepth] then exit;

  //assignments
  parserResult := parseAssignments(args);
  if parserResult.handled then exit;
  args := parserResult.args;

  //new vars
  parserResult := parseDeclarations(args);
  if parserResult.handled then exit;
  args := parserResult.args;

  //commands
  parserResult := parseCommands(args, line);
  if parserResult.handled then exit;

  //unhandled
  multisc.chats[addchatindex].uzenet:= 'Unhandled scriptline: ' + line;
  addchatindex:=addchatindex + 1;
end;

//SCRIPT ENGINE AND DEBUG TOOLS

function getLangCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  i, j: integer;
  t, tmp: string;
begin
  result := false;

  if (args[0] = 'getlang') and (Length(args) > 1) then
  begin
    result := true;

    with handler do
    begin

      t:=args[1][1];
      if (t = '$') then
        for i:=0 to Length(_strvars) - 1 do
          if args[1] = '$' + _strvars[i].name then //container found
          begin
            tmp:= '';
            j:=trunc(computenums(copy(args, 2, length(args) - 2)));
            if sizeof(lang) < j then
              _strvars[i].text:=lang[j];

            exit;
          end;

    end;
  end;
end;

function bindCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  i: integer;
begin
  result := false;

  if (args[0] = 'bind') then
  begin
    result := true;

    with handler do
    begin

      if Length(args) < 3 then begin scripterror('Not enough paramater for bind');exit; end;
      if (args[1] = 'closedisplay') then
        displaycloseevent := args[2]
      else
      begin
        for i:=0 to Length(_binds) - 1 do
          if _binds[i].key = args[1][1] then
          begin
            _binds[i].script:=args[2];
            exit;
          end;
        SetLength(_binds, Length(_binds) + 1);
        _binds[Length(_binds) - 1].key:=args[1][1];
        _binds[Length(_binds) - 1].script:=args[2];
      end;
    end;
  end;
end;

function unbindCMD(args: TStringArray; out handler: TScriptsHandler): boolean; 
var
  i, j: integer;
begin
  result := false;

  if (args[0] = 'unbind') then
  begin
    result := true;

    with handler do
    begin

      if Length(args) < 2 then begin scripterror('Not enough paramater for unbind');exit; end;
      if (args[1] = 'closedisplay') then
        displaycloseevent:= ''
      else
      begin
        for i:=0 to Length(_binds) - 1 do
          if _binds[i].key = args[1][1] then
          begin
            for j:=i to Length(_binds) - 2 do
              _binds[j]:=_binds[j + 1];
            SetLength(_binds, length(_binds) - 1);
          end;
      end;
      exit;
    end;
  end;
end;

function unbindAllCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
begin
  result := false;

  if (args[0] = 'unbindall') then
  begin
    result := true;

    with handler do
    begin

      SetLength(_binds, 0);
      exit;
    end;
  end;
end;

function triggerEnableCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  i: integer;
  tmp: string;
begin
  result := false;

  if (args[0] = 'trigger_enable') and (Length(args) > 1) then
  begin
    result := true;

    with handler do
    begin

      tmp:=varToString(args[1]);
      for i:=0 to Length(triggers) - 1 do
        if triggers[i].name = tmp then
          triggers[i].active:=true;
      exit;
    end;
  end;
end;

function triggerDisableCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  i: integer;
  tmp: string;
  v1: single;
begin
  result := false;

  if (args[0] = 'trigger_disable') and (Length(args) > 2) then
  begin
    result := true;

    with handler do
    begin

      tmp:=varToString(args[1]);
      for i:=0 to Length(triggers) - 1 do
        if triggers[i].name = tmp then
        begin
          triggers[i].active:=false;
          v1:=computenums(copy(args, 2, length(args) - 2));
          if v1 = 0 then
            triggers[i].restart:=0
          else
            triggers[i].restart:=gettickcount + trunc(v1);
        end;
      exit;
    end;
  end;
end;
     
//big hud message in the center
function fastinfoCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  i: integer;
  tmp: string;
begin
  result := false;

  if (args[0] = 'fastinfo') then
  begin
    result := true;

    with handler do
    begin

      for i:=1 to Length(args) - 1 do
        tmp:=tmp + ' ' + varToString(args[i]);

      addHudMessage(tmp, 255, betuszin);
      exit;
    end;
  end;
end;

//big RED hud message in the center
function fastinfoRedCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  i: integer;
  tmp: string;
begin
  result := false;

  if (args[0] = 'fastinfored') then
  begin
    result := true;

    with handler do
    begin

      for i:=1 to Length(args) - 1 do
        tmp:=tmp + ' ' + varToString(args[i]);

      addHudMessage(tmp, $FF0000);
      exit;
    end;
  end;
end;
      
//chat message
function printCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  i: integer;
  tmp: string;
begin
  result := false;

  if (args[0] = 'print') then
  begin
    result := true;

    with handler do
    begin

      for i:=1 to Length(args) - 1 do
        tmp:=tmp + ' ' + varToString(args[i]);

      multisc.chats[addchatindex].uzenet:=tmp;
      addchatindex:=addchatindex + 1;
      exit;
    end;
  end;
end;

//global chat message
function chatmostCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  i: integer;
  tmp: string;
begin
  result := false;

  if (args[0] = 'chatmost') then
  begin
    result := true;

    with handler do
    begin

      tmp := '';
      for i:=1 to Length(args) - 1 do
        tmp := tmp + ' ' + varToString(args[i]);

      Multisc.Chat(tmp);
      exit;
    end;
  end;
end;
    
//window display
function displayCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  i: integer;
  tmp: string;
begin
  result := false;

  if (args[0] = 'display') then
  begin
    result := true;

    with handler do
    begin

      for i:=1 to Length(args) - 1 do
        tmp:=tmp + ' ' + varToString(args[i]);

      labeltext:=tmp;
      labelactive:=true;
      exit;
    end;
  end;
end;

//window display - close
function closedisplayCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
begin
  result := false;

  if (args[0] = 'closedisplay') then
  begin
    result := true;

    with handler do
    begin

      labelactive:=false;
      exit;
    end;
  end;
end;

//script call
function scriptCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
begin
  result := false;

  if (args[0] = 'script') and (Length(args) > 1) then
  begin
    result := true;

    with handler do
    begin

      evalScript(args[1]);
      exit;
    end;
  end;
end;

//script call - "async"
function timeoutCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  time: single;
begin
  result := false;

  if (args[0] = 'timeout') and (Length(args) > 2) then
  begin
    result := true;

    with handler do
    begin

      SetLength(_timedscripts, length(_timedscripts) + 1);
      with _timedscripts[length(_timedscripts) - 1] do
      begin
        script:=args[1];
        time:=gettickcount + trunc(computenums(copy(args, 2, length(args) - 2)));
      end;

      exit;
    end;
  end;
end;

// SCRIPT ENGINE AND DEBUG TOOLS END
// PARTICLES AND PROPS
          
//stop particle system
function particleStopCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  i: integer;
  v1: single;
begin
  result := false;

  if (args[0] = 'particle_stop') and (Length(args) > 2) then
  begin
    result := true;

    with handler do
    begin

      for i:=0 to Length(particlesSyses) - 1 do
        if particlesSyses[i].name = args[1] then
        begin
          particlesSyses[i].disabled:=true;
          v1:=computenums(copy(args, 2, length(args) - 2));
          if v1 = 0 then
            particlesSyses[i].restart:=0
          else
            particlesSyses[i].restart:=gettickcount + trunc(v1);
        end;
      exit;
    end;
  end;
end;

//start particle system
function particleStartCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  i: integer;
begin
  result := false;

  if (args[0] = 'particle_start') and (Length(args) > 1) then
  begin
    result := true;

    with handler do
    begin

      for i:=0 to Length(particlesSyses) - 1 do
        if particlesSyses[i].name = args[1] then
          particlesSyses[i].disabled:=false;

      exit;
    end;
  end;
end; 

function particlePositionCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  i: integer;
  tmp: string;
begin
  result := false;

  if (args[0] = 'particle_position') and (Length(args) > 4) then
  begin
    result := true;

    with handler do
    begin

      tmp:=varToString(args[1]);
      for i:=0 to length(particlesSyses) - 1 do
        if particlesSyses[i].name = tmp then
          particlesSyses[i].from:=computevecs(copy(args, 2, length(args) - 2));

      exit;
    end;
  end;
end;

//prop hide
function propHideCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
begin
  result := false;

  if (args[0] = 'prop_hide') and (Length(args) > 1) then
  begin
    result := true;

    with handler do
    begin

      propsystem.setVisibility(args[1], false);
      exit;
    end;
  end;
end;
         
//prop show
function propShowCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
begin
  result := false;

  if (args[0] = 'prop_show') and (Length(args) > 1) then
  begin
    result := true;

    with handler do
    begin

      propsystem.setVisibility(args[1], true);
      exit;
    end;
  end;
end;

function dynamizateCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  tmp: string;
begin
  result := false;

  if (args[0] = 'dynamizate') and (Length(args) > 1) then
  begin
    result := true;

    with handler do
    begin

      tmp:=varToString(args[1]);
      propsystem.dynamizate(tmp).speed:=D3DXVector3(0, 0.5, 0);
      exit;
    end;
  end;
end;

function dynamicSpeedCMD(args: TStringArray; out handler: TScriptsHandler): boolean; 
var
  tmp: string;
begin
  result := false;

  if (args[0] = 'dynamic_speed') and (Length(args) > 4) then
  begin
    result := true;

    with handler do
    begin

      tmp:=varToString(args[1]);
      propsystem.getdynamic(tmp).speed:=computevecs(copy(args, 2, length(args) - 2));

      exit;
    end;
  end;
end;

function propPositionCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
var
  tmp: string;
begin
  result := false;

  if (args[0] = 'prop_position') and (Length(args) > 4) then
  begin
    result := true;

    with handler do
    begin

      tmp:=varToString(args[1]);
      propsystem.getprop(tmp).pos:=computevecs(copy(args, 2, length(args) - 2));

      exit;
    end;
  end;
end;

function propRotationCMD(args: TStringArray; out handler: TScriptsHandler): boolean;  
var
  tmp: string;
begin
  result := false;

  if (args[0] = 'prop_rotation') and (Length(args) > 2) then
  begin
    result := true;

    with handler do
    begin

      tmp:=varToString(args[1]);
      propsystem.getprop(tmp).rot:=computenums(copy(args, 2, length(args) - 2));

      exit;
    end;
  end;
end;

//PARTICLES AND PROPS END
//BOT BATTLE STUFF

//wave
function botWaveCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
begin
  result := false;

  if (args[0] = 'wave') and (Length(args) > 1)then
  begin
    result := true;

    with handler do
    begin

      wave:= strtoint(args[1]);
      exit;
    end;
  end;
end;

//skirmish
function botSkirmishCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
begin
  result := false;

  if (args[0] = 'skirmish') then
  begin
    result := true;

    with handler do
    begin

      skirmish:= true;
      exit;
    end;
  end;
end;

//startbattle
function botStartBattleCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
begin
  result := false;

  if (args[0] = 'startbattle') then
  begin
    result := true;

    with handler do
    begin

      battle:=true;
      exit;
    end;
  end;
end;

//stopbattle
function botStopBattleCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
begin
  result := false;

  if (args[0] = 'stopbattle') then
  begin
    result := true;

    with handler do
    begin

      battle:=false;
      exit;
    end;
  end;
end;

//BOT BATTLE STUFF END
//MISC COMMANDS AND TEST TOOLS

//law explosion
function explodeCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
begin
  result := false;

  if (args[0] = 'explode') then
  begin
    result := true;

    with handler do
    begin

      AddLAW(D3DXVector3Zero, computevecs(copy(args, 1, length(args) - 1)), -1);
      exit;
    end;
  end;
end;

//TODO: respawn (waiting for more unit refacts)
{
function TScriptsHandler.respawnCMD(args: TStringArray): boolean;
begin
  result := false;

  if (args[0] = 'respawn') then
  begin
    result := true;

    respawn;
    exit;
  end;
end;
}

//sounds
function soundCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
begin
  result := false;

  if (args[0] = 'sound') and (Length(args) > 4) then
  begin
    result := true;

    with handler do
    begin

      playsound(StrToInt(args[1]), false, integer(timegettime) + random(10000), true, D3DXVector3(StrToFloat(args[2]), StrToFloat(args[3]), StrToFloat(args[4])));
      exit;
    end;  
  end;
end;

//fegyvskin load
function fegyvskinCMD(args: TStringArray; out handler: TScriptsHandler): boolean;
begin
  result := false;

  if (args[0] = 'fegyvskin') then
  begin
    result := true;

    with handler do
    begin

      //evalscriptline('display fegyvskin');
      case myfegyv of
        FEGYV_MPG: myfegyv_skin := fegyvskins[5];
        FEGYV_M82A1: myfegyv_skin := fegyvskins[1];
        FEGYV_M4A1: myfegyv_skin := fegyvskins[0];
        FEGYV_QUAD: myfegyv_skin := fegyvskins[6];
        FEGYV_NOOB: myfegyv_skin := fegyvskins[7];
        FEGYV_LAW: myfegyv_skin := fegyvskins[2];
        FEGYV_X72: myfegyv_skin := fegyvskins[8];
        FEGYV_MP5A3: myfegyv_skin := fegyvskins[3];
        FEGYV_H31_T: myfegyv_skin := FEGYV_H31_T;
        FEGYV_H31_G: myfegyv_skin := FEGYV_H31_G;
        FEGYV_HPL: myfegyv_skin := fegyvskins[9];
        FEGYV_BM3: myfegyv_skin := fegyvskins[4];
      end;

      exit;
    end;
  end;
end;

//TODO: spawn airboat/submarine (waiting for more unit refacts)
{
function TScriptsHandler.watercraftCMD(args: TStringArray): boolean;
begin
  result := false;

  if (args[0] = 'watercraft') and (Length(args) > 3) then
  begin
    result := true;

    if myfegyv > 127 then
      SpawnVehicle(computevecs(copy(args, 1, argnum - 1)), 2, 'airboat')
    else
      SpawnVehicle(computevecs(copy(args, 1, argnum - 1)), 1, 'submarine');

    exit;
  end;
end;
}

//MISC COMMANDS AND TEST TOOLS END

end.
