program offlinereg;

{Copyright 2010 Erwan LABALEC}

{This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.}


{$APPTYPE CONSOLE}
{$IFDEF VER260}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
//{$SetPEFlags IMAGE_FILE_RELOCS_STRIPPED}
{$ENDIF}

//{$IFDEF win64}{$EXTENSION '64.exe'}{$ENDIF}
//{$IFDEF win32}{$EXTENSION '32.exe'}{$ENDIF}

uses
  {$IFDEF VER260}AnsiStrings,{$ENDIF}
  SysUtils,activex,
  windows,
  classes,
  strutils,
  inifiles;

type
PCWSTR=pwidechar;
PWSTR=pwidechar;
PVOID=Pointer;

Const REG_NONE  = 0;
Const REG_SZ  = 1;
Const REG_EXPAND_SZ  = 2;
Const REG_BINARY  = 3;
Const REG_DWORD  = 4;
Const REG_DWORD_LITTLE_ENDIAN  = 4;
Const REG_DWORD_BIG_ENDIAN  = 5;
Const REG_LINK  = 6;
Const REG_MULTI_SZ  = 7;
Const REG_RESOURCE_LIST  = 8;
const REG_FULL_RESOURCE_DESCRIPTOR = 9;
const REG_RESOURCE_REQUIREMENTS_LIST = 10;
Const REG_QWORD  = 11;

var
//http://msdn.microsoft.com/en-us/library/ee210756%28v=VS.85%29.aspx
ORCreateHive: function(var ORHKEY :tHandle):dword;stdcall;
OROpenHive: function (lpHivePath:PCWSTR;var phkResult:thandle):dword;stdcall;
ORCloseHive:function (ORHKEY:tHandle):dword;stdcall;
OROpenKey:function (ORHKEY:tHandle;lpSubKeyName:PCWSTR;var phkResult:thandle):DWORD;stdcall;
ORCloseKey:function(ORHKEY:tHandle):DWORD;stdcall;
ORGetValue:function(ORHKEY:tHandle;lpSubKey:PCWSTR;lpValue:PCWSTR; pdwType:PDWORD; pvData:PVOID; pcbData:PDWORD):DWORD;stdcall;
ORSetValue:function(ORHKEY:tHandle;lpValueName:PCWSTR;dwType:dword;lpData:pvoid;cbData:dword):dword;stdcall;
ORGetVersion:procedure( var pdwMajorVersion:dword; var pdwMinorVersion:dword);stdcall;
ORSaveHive:function(ORHKEY:tHandle;lpHivePath:PCWSTR;dwOsMajorVersion:dword;dwOsMinorVersion:dword):dword;stdcall;
ORDeleteValue:function(ORHKEY:tHandle;lpValueName:PCWSTR):DWORD;stdcall;
ORDeleteKey:function(ORHKEY:tHandle;lpSubKey:PCWSTR):DWORD;stdcall;
ORCreateKey:function(
  ORHKEY:tHandle;
  lpSubKey:PCWSTR;
  lpClass:PWSTR;
  dwOptions:DWORD;
  pSecurityDescriptor:PSECURITY_DESCRIPTOR;
  phkResult:pointer;
  pdwDisposition:PDWORD):DWORD;stdcall;
OREnumKey:function(
  ORHKEY:tHandle;
  dwIndex:dword;
  lpName:pwstr;
  lpcName:pdword;
  lpClass:PWSTR;
  lpcClass:PDWORD;
  lpftLastWriteTime:PFILETIME):dWORD;stdcall;
 OREnumValue:function(
  ORHKEY:tHandle;
  dwIndex:DWORD;
  lpValueName:PWSTR;
  lpcValueName:PDWORD;
  lpType:PDWORD;
  lpData:PBYTE;
  lpcbData:PDWORD):WORD;stdcall;


ghive,gkeyname,gverb,gvaluename,gvalue:string;
gmajor,gminor,gvaluetype:dword;
i:byte;
bool,last_run:boolean;
commands,params:tstringlist;
global_hkey:thandle=0;

function GetOSVersion(var MajorVersion,MinorVersion:dword):boolean;
var
VersionInfo: TOSVersionInfo;
//MajorVersion,MinorVersion,Build: DWORD;
//Platform: string;
begin
  VersionInfo.dwOSVersionInfoSize := SizeOf(VersionInfo);
  if GetVersionEx(VersionInfo) then
  begin
  result:=true;
  with VersionInfo do
  begin
  {
  case dwPlatformId of
   VER_PLATFORM_WIN32s:        Platform := 'Windows 3x';
   VER_PLATFORM_WIN32_WINDOWS: Platform := 'Windows 95';
   VER_PLATFORM_WIN32_NT:      Platform := 'Windows NT';
  end;
  }
  MajorVersion := dwMajorVersion;
  MinorVersion := dwMinorVersion;
  //Build := dwBuildNumber;
  end;
  end; //if GetVersionEx(VersionInfo) then
end;

function Oem (const st : String) : String;
var
  TempBuffer : Array[0..2047] of ansiChar ;
begin

  //fillchar(tempbuffer,sizeof(tempbuffer),0);
  //if st<>'' then CharToOem(Pchar(st),@TempBuffer);
  //result:={$IFDEF VER260}AnsiStrings.{$ENDIF}StrPas(@TempBuffer);

  result:=st;
  UniqueString(result);
  if st<>'' then CharToOemA(Pansichar(st),Pansichar(result));
end;

function strip_quotes(value:string):string;
begin
result:=StringReplace (value,'"','',[rfReplaceAll, rfIgnoreCase]) ;
end;

function Split(chaine : String; delimiteur : string) : TStringList;
var
L : TStringList;
begin
  L:=TStringList.create;
  L.text := StringReplace(chaine, delimiteur, #13#10, [rfReplaceAll]);
  result:=L;
end;

function HexToByte(v:string):byte;
//var
   //sMy: string[5];
   //wMy: Word;
begin
     //sMy := 'FFFF';
     //wMy := StrToInt64('$' + sMy);
     result := StrToInt('$' + v);
end;

Function NewStringReplace(const S, OldPattern, NewPattern: string;  Flags: TReplaceFlags): string;
var
  OldPat,Srch: string; // Srch and Oldp can contain uppercase versions of S,OldPattern
  PatLength,NewPatLength,P,i,PatCount,PrevP: Integer;
  c,d: pchar;
begin
  PatLength:=Length(OldPattern);
  if PatLength=0 then begin
    Result:=S;
    exit;
  end;

  if rfIgnoreCase in Flags then begin
    Srch:=AnsiUpperCase(S);
    OldPat:=AnsiUpperCase(OldPattern);
  end else begin
    Srch:=S;
    OldPat:=OldPattern;
  end;

  PatLength:=Length(OldPat);
  if Length(NewPattern)=PatLength then begin
    //Result length will not change
    Result:=S;
    P:=1;
    repeat
      P:=PosEx(OldPat,Srch,P);
      if P>0 then begin
        for i:=1 to PatLength do
          Result[P+i-1]:=NewPattern[i];
        if not (rfReplaceAll in Flags) then exit;
        inc(P,PatLength);
      end;
    until p=0;
  end else begin
    //Different pattern length -> Result length will change
    //To avoid creating a lot of temporary strings, we count how many
    //replacements we're going to make.
    P:=1; PatCount:=0;
    repeat
      P:=PosEx(OldPat,Srch,P);
      if P>0 then begin
        inc(P,PatLength);
        inc(PatCount);
        if not (rfReplaceAll in Flags) then break;
      end;
    until p=0;
    if PatCount=0 then begin
      Result:=S;
      exit;
    end;
    NewPatLength:=Length(NewPattern);
    SetLength(Result,Length(S)+PatCount*(NewPatLength-PatLength));
    P:=1; PrevP:=0;
    c:=pchar(Result); d:=pchar(S);
    repeat
      P:=PosEx(OldPat,Srch,P);
      if P>0 then begin
        for i:=PrevP+1 to P-1 do begin
          c^:=d^;
          inc(c); inc(d);
        end;
        for i:=1 to NewPatLength do begin
          c^:=NewPattern[i];
          inc(c);
        end;
        if not (rfReplaceAll in Flags) then exit;
        inc(P,PatLength);
        inc(d,PatLength);
        PrevP:=P-1;
      end else begin
        for i:=PrevP+1 to Length(S) do begin
          c^:=d^;
          inc(c); inc(d);
        end;
      end;
    until p=0;
  end;
end;
//*****************************************************************************************************

function del_enumkeys(hkey:thandle):boolean;
var
ret:dword;
lpname:pwidechar;
lpcname:pdword;
idx:word;
ws:widestring;
wsubkeyname:array[0..255] of widechar;
hkresult:thandle;
begin
result:=false;
try
idx:=0;
getmem(lpname,256);
getmem(lpcname ,sizeof(dword));
ret:=0;
while ret=0 do
  begin
  lpcname^:=256;
  ret:=OREnumKey(hkey,idx,lpname,lpcname,nil,nil,nil);
  if ret=0 then
    begin
    setlength(ws,lpcname^);
    copymemory(@ws[1],lpname,lpcname^*2);
    StringToWideChar(string(ws), wsubkeyname, sizeof(wsubkeyname));
    if OROpenKey (hkey,wsubkeyname,hkresult)=0 then
      begin
      if del_enumkeys(hkresult)=false then
        begin
        ret:=ORDeleteKey (hkey,wsubkeyname);
        end;
      ret:=ORcloseKey (hkresult);
      end;
    inc(idx);
    end;//if ret=0 then
  end;//while ret=0 do
if idx>0 then result:=true;
except
on e:exception do writeln('EnumKeys error:'+e.message);
end;
end;

function getvaluePTR(key:thandle;svaluename:string;var data:pointer):integer;
var
ret:dword;
wvaluename:array[0..255] of widechar;
pvdata:pointer;
pdwtype,pcbData:pdword;
b:array of byte;
begin
result:=-1;
try
fillchar(wvaluename,sizeof(wvaluename),#0);
StringToWideChar(svaluename, wvaluename, length(svaluename)+1);
getmem(pdwType,sizeof(dword));

getmem(pcbdata,sizeof(dword));pcbdata^:=0;
pvdata:=nil;
ret:=ORGetValue (key,nil,wvaluename,pdwtype,pvdata,pcbData);
if ret<>0 then raise exception.Create('ORGetValue failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
if pcbData^=0 then
    begin
    result:=0;
    exit;
    end;

getmem(pvdata,pcbdata^);
ret:=ORGetValue (key,nil,wvaluename,pdwtype,pvdata,pcbData);
if ret<>0
  then raise exception.Create('ORGetValue failed:'+inttostr(ret)+':'+SysErrorMessage(ret))
  else
  begin
  result:=pcbdata^;
  if pdwtype^=reg_binary then
    begin
    getmem(data,pcbdata^);
    CopyMemory(data,pvdata,pcbdata^);
    end;
  end;
freemem(pdwtype);
freemem(pvdata);
freemem(pcbdata);
except
on e:exception do raise exception.Create('getvalue error:'+e.message);
end;
end;

function getvaluebyteat(key:thandle;svaluename:string;offset:word;var value:byte):boolean;
var
ptr:pointer;
size:integer;
begin
result:=false;
size:=getvaluePTR(key,svaluename ,ptr);
if offset+1>size then
  begin
  writeln('offset+1>size');
  exit;
  end;
if size>0 then
  begin
  copymemory(@value,pointer(integer(ptr)+offset),sizeof(value));
  result:=true;
  end;
end;

function getvalue(key:thandle;svaluename:string;var svalue:string;var dwtype:dword):boolean;
var
ret:dword;
wvaluename:array[0..255] of widechar;
binary:array of byte;
pvdata:pointer;
pdwtype,pcbData:pdword;
ws:widestring;
dw:dword;
i:word;
ascii:boolean;
begin
svalue:='';
result:=false;
ascii:=false;if dwtype=$ff then ascii:=true;
try
fillchar(wvaluename,sizeof(wvaluename),#0);
StringToWideChar(svaluename, wvaluename, length(svaluename)+1);
getmem(pdwType,sizeof(dword));

getmem(pcbdata,sizeof(dword));pcbdata^:=0;
pvdata:=nil;
ret:=ORGetValue (key,nil,wvaluename,pdwtype,pvdata,pcbData);
if ret=0 then
  begin
  if pcbData^=0 then
    begin
    result:=true;
    exit;
    end;
  getmem(pvdata,pcbdata^);
  end
  else
  begin
  writeln('ORGetValue failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
  exit;
  end;
  
ret:=ORGetValue (key,nil,wvaluename,pdwtype,pvdata,pcbData);
if ret<>0
  then writeln('ORGetValue failed:'+inttostr(ret)+':'+SysErrorMessage(ret))
  else
  begin
  dwtype :=pdwtype^;
  result:=true;
  if (pdwtype^=reg_sz) or (pdwtype^=reg_multi_sz) or (pdwtype^=REG_EXPAND_SZ) then
    begin
    setlength(ws,pcbdata^);
    CopyMemory(@ws[1],pvdata,pcbdata^);
    //setlength(svalue,pcbdata^);
    svalue:=ws;
    svalue:=copy(svalue,1,(length(svalue) div 2) -1);
    end;
  if pdwtype^=reg_dword then
    begin
    CopyMemory(@dw,pvdata,pcbdata^);
    svalue:=inttostr(dw);
    end;
  if pdwtype^=reg_binary then
    begin
    setlength(binary,pcbdata^);
    CopyMemory(@binary[0],pvdata,pcbdata^);
    if ascii=true then
      for i:=0 to pcbdata^-1 do if (binary[i]>=32) and (binary[i]<=126) then svalue:=svalue+' '+chr(binary[i]) else svalue:=svalue+'.';
    if ascii=false then
      for i:=0 to pcbdata^-1 do svalue:=svalue+' '+inttohex(binary[i],2);

    delete(svalue,1,1);
    end;
  end;
freemem(pdwtype);
freemem(pvdata);
freemem(pcbdata);
except
on e:exception do writeln('getvalue error:'+e.message);
end;
end;

function createkey(key:thandle;skeyname:string;var hkey:thandle):boolean;
var
ret:dword;
//wkeyname:pwidechar;
wkeyname:array[0..511] of widechar;
//hkey:thandle;
begin
result:=false;
if skeyname=' ' then skeyname:='';
if skeyname='' then begin result:=true;exit;end;
try
//getmem(wkeyname ,length(skeyname)+1);
fillchar(wkeyname,sizeof(wkeyname),#0);
StringToWideChar(skeyname, wkeyname, length(skeyname)+1);
ret:=ORCreateKey (key,wkeyname,nil,0,nil,@hkey,nil );
if ret<>0
  then writeln('createkey failed:'+inttostr(ret)+':'+SysErrorMessage(ret))
  else result:=true;
except
on e:exception do writeln('createkey error:'+e.message);
end;
end;

procedure createkeys(hkey:thandle;skeyname:string);
var
list:tstrings;
idx:word;
hcreatedkey:thandle;
begin
if skeyname ='' then exit;
hcreatedkey:=0;
list:=tstringlist.create;
   list.Clear;
   ExtractStrings(['\'], [], pchar(skeyname), list);
   //list.Delimiter := '\';
   //list.DelimitedText := skeyname;
   //list.strictdelimiter:=true; //does not work on delphi7 !!!
   for idx:=0 to list.Count -1 do
    begin
    //writeln(list[idx]);
    if idx=0
      then createkey(hkey,list[idx],hcreatedkey )
      else createkey(hcreatedkey,list[idx],hcreatedkey );
    end;
   list.Free ;
end;

function deletekey(key:thandle;skeyname:string):boolean;
var
ret:dword;
wkeyname:array[0..255] of widechar;
begin
try
result:=false;
if skeyname=' ' then skeyname:='';
fillchar(wkeyname,sizeof(wkeyname),#0);
StringToWideChar(skeyname, wkeyname, length(skeyname) +1);
ret:=ORDeleteKey  (key,wkeyname );
if ret<>0
  then writeln('ORDeleteKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret))
  else result:=true;
except
on e:exception do writeln('deletekey error:'+e.message);
end;
end;

function deletekeys(key:thandle):boolean;
var
b:boolean;
begin
result:=false;
b:=del_enumkeys(key);
if b=false then exit;
while b=true do b:=del_enumkeys(key);
result:=true;
end;

function deletevalue(key:thandle;svaluename:string):boolean;
var
ret:dword;
wvaluename:array[0..255] of widechar;
begin
result:=false;
try
fillchar(wvaluename,sizeof(wvaluename),#0);
StringToWideChar(svaluename, wvaluename, length(svaluename) +1);
ret:=ORDeleteValue (key,wvaluename );
if ret<>0
  then writeln('ORDeleteValue failed:'+inttostr(ret)+':'+SysErrorMessage(ret))
  else result:=true;
except
on e:exception do writeln('deletevalue error:'+e.message);
end;
end;

function BinToInt64(value:string):int64;
var
sl:tstringlist;
c:byte;
buf:array[0..7] of byte;
begin
try
sl:=tstringlist.create;
ExtractStrings([','], [], pchar(value), sl);
for c:=0 to sl.Count -1 do buf[c]:=hextobyte(sl[c]);
copymemory(@result,@buf[0],8);
sl.Free
except
on e:exception do writeln('BinToInt64 error:'+e.message);
end;
end;


function setvaluePTR(key:thandle;svaluename:string;data:pointer;cb:dword):boolean;
var
dwtype,ret:dword;
wvaluename:array[0..255] of widechar;
begin
result:=false;
try
fillchar(wvaluename,sizeof(wvaluename),#0);
StringToWideChar(svaluename, wvaluename, length(svaluename)+1);

dwtype:=REG_BINARY ;
ret:=ORsetValue (key,wvaluename,dwtype,data,cb);
if ret<>0
    then raise exception.Create('ORsetValue failed:'+inttostr(ret)+':'+SysErrorMessage(ret))
    else result:=true;

except
on e:exception do raise exception.Create('setvalue error:'+e.message);
end;
end;

function setvaluebyteat(key:thandle;svaluename:string;value:byte;offset:word):boolean;
var
ptr:pointer;
size:integer;
begin
result:=false;
size:=getvaluePTR(key,svaluename ,ptr);
if offset+1>size then
  begin
  writeln('offset+1>size');
  exit;
  end;
if size>0 then
  begin
  copymemory(pointer(integer(ptr)+offset),@value,sizeof(value));
  result:=setvaluePTR(key,svaluename ,ptr,size);
  end;
end;

function setvalue(key:thandle;svaluename,svalue:string;valuetype:dword):boolean;
var
e:integer;
ret:dword;
wvaluename:array[0..255] of widechar;
//wvalue:array[0..1023] of widechar;
pvalue:pwidechar;
pvdata:pointer;
dwtype,cbData,dw:longword;
i64:int64;
//ws:widestring;
tmp:string;
t:tstrings;
//binary:array[0..511] of byte;
binary:array of byte;
i:integer;
begin
result:=false;
try
if svaluename=' ' then svaluename:='';
fillchar(wvaluename,sizeof(wvaluename),#0);
StringToWideChar(svaluename, wvaluename, length(svaluename) +1);
if (valuetype=reg_sz) or (valuetype=reg_multi_sz) or (valuetype=reg_expand_sz) then
begin
  if (valuetype=reg_multi_sz) then svalue:=AnsiReplacestr(svalue,' ',chr(0)); //multi_sz, one line separated by a #0 or #0#0 ?
  //fillchar(wvalue,sizeof(wvalue),#0);
  //StringToWideChar(svalue, wvalue, length(svalue)+1);
  pvalue:=StringToOleStr(svalue);
  if length(svalue)=0 then cbdata:=0 else cbdata:=length(svalue)*2+2;
  if valuetype=reg_multi_sz then inc(cbdata,2);
  //getmem(pvdata,cbData );
  //copymemory(pvdata,@wvalue[0],cbdata);
  dwtype:=valuetype;
  //ret:=ORsetValue (key,wvaluename,dwtype,pvdata,cbData);
  ret:=ORsetValue (key,wvaluename,dwtype,pvalue,cbData);
  SysFreeString(pvalue);
  if ret<>0
    then writeln('ORsetValue failed:'+inttostr(ret)+':'+SysErrorMessage(ret))
    else result:=true;
  //freemem(pvdata);
end; //if (valuetype=reg_sz) or (valuetype=reg_multi_sz) then
if (valuetype=reg_dword) then
begin
  dwtype:=valuetype;
  cbdata:=sizeof(dword);
  //dw:=strtoint(svalue);
  e:=0;
  Val(svalue, dw, e);
  if e<>0 then raise exception.Create('not a valid integer value');
  getmem(pvdata,cbData );
  copymemory(pvdata,@dw,sizeof(dword));
  ret:=ORsetValue (key,wvaluename,dwtype,pvdata,cbData);
  if ret<>0
    then writeln('ORsetValue failed:'+inttostr(ret)+':'+SysErrorMessage(ret))
    else result:=true;
  freemem(pvdata);
end; //if (valuetype=reg_dword) then
if (valuetype=reg_qword) then
begin
  dwtype:=valuetype;
  cbdata:=sizeof(int64);
  if pos(',',svalue)>0
    then i64:=BinToInt64(svalue)
    else i64:=StrToInt64 (svalue);
  getmem(pvdata,cbData );
  copymemory(pvdata,@i64,sizeof(int64));
  ret:=ORsetValue (key,wvaluename,dwtype,pvdata,cbData);
  if ret<>0
    then writeln('ORsetValue failed:'+inttostr(ret)+':'+SysErrorMessage(ret))
    else result:=true;
  freemem(pvdata);
end; //if (valuetype=reg_dword) then
if (valuetype=reg_binary) then
begin
  t:=tstringlist.Create ;
  t.delimiter :=',';
  t.delimitedtext :=svalue;
  setlength(binary,t.Count);
  for i:=0 to t.Count -1 do binary[i]:=hextobyte(t[i]);
  cbdata:=t.Count;
  t.Free ;
  getmem(pvdata,cbData );
  copymemory(pvdata,@binary[0],cbdata );
  dwtype:=valuetype;
  ret:=ORsetValue (key,wvaluename,dwtype,pvdata,cbData);
  if ret<>0
    then writeln('ORsetValue failed:'+inttostr(ret)+':'+SysErrorMessage(ret))
    else result:=true;
  freemem(pvdata);
end;
if (valuetype=reg_none) then
begin
  dwtype:=valuetype;
  cbdata:=sizeof(dword);
  ret:=ORsetValue (key,wvaluename,dwtype,nil,0);
  if ret<>0
    then writeln('ORsetValue failed:'+inttostr(ret)+':'+SysErrorMessage(ret))
    else result:=true;
end; //if (valuetype=reg_dword) then
except
on e:exception do writeln('setvalue error:'+e.message);
end;
end;

function EnumValues(hkey:thandle;var list:tstrings):boolean;
var
ret:dword;
lpname:pwidechar;
lpcname:pdword;
idx:word;
ws:widestring;
lptype:pdword;
begin
result:=false;
try
idx:=0;
getmem(lpname,256);
getmem(lpcname ,sizeof(dword));
getmem(lptype ,sizeof(dword));
ret:=0;
while ret=0 do
  begin
  lpcname^:=256;
  ret:=OREnumValue (hkey,idx,lpname,lpcname,lptype,nil,nil);
  if ret=0 then
    begin
    setlength(ws,lpcname^);
    copymemory(@ws[1],lpname,lpcname^*2);
    list.Add (string(ws));
    inc(idx);
    end;//if ret=0 then
  end;//while ret=0 do
if idx>0 then result:=true else writeln('OREnumValue failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
except
on e:exception do writeln('EnumValues error:'+e.message);
end;
end;

function EnumValuesAll(hkresult:thandle):boolean;
var
list:tstrings;
idx:word;
s:string;
dwtype:dword;
begin
list:=tstringlist.Create ;
  if enumvalues(hkresult,list) then
    begin
    for idx:=0 to list.Count -1 do
      begin
      //writeln(list[idx]);

      if getvalue(hkresult,list[idx],s,dwtype) then
        begin
        case dwtype of
        reg_sz:writeln('"'+list[idx]+'"=reg_sz:"'+oem(s)+'"');
        reg_multi_sz:writeln('"'+list[idx]+'"=reg_multi_sz:"'+oem(s)+'"');
        reg_expand_sz:writeln('"'+list[idx]+'"=reg_expand_sz:"'+oem(s)+'"');
        reg_binary:writeln('"'+list[idx]+'"=reg_binary:"'+oem(s)+'"');
        reg_dword:writeln('"'+list[idx]+'"=reg_dword:'+oem(s));
        REG_QWORD:writeln('"'+list[idx]+'"=reg_qword:'+oem(s));
        reg_none:writeln('"'+list[idx]+'"=reg_none:'+oem(s));
        else writeln('"'+list[idx]+'"=reg_unknown:'+oem(s));
        end;//case
        end; //if getvalue ...
      end; //for idx:=0
    end;// if enumkeys
  list.Free ;
end;

function EnumKeys(hkey:thandle;var list:tstrings):boolean;
var
ret:dword;
lpname:pwidechar;
lpcname:pdword;
idx:word;
ws:widestring;
begin
result:=false;
try
idx:=0;
getmem(lpname,256);
getmem(lpcname ,sizeof(dword));
ret:=0;
while ret=0 do
  begin
  lpcname^:=256;
  ret:=OREnumKey(hkey,idx,lpname,lpcname,nil,nil,nil);
  if ret=0 then
    begin
    setlength(ws,lpcname^);
    copymemory(@ws[1],lpname,lpcname^*2);
    list.Add (string(ws));
    inc(idx);
    end;//if ret=0 then
  end;//while ret=0 do
if idx>0 then result:=true else writeln('OREnumKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
except
on e:exception do writeln('EnumKeys error:'+e.message);
end;
end;

function EnumkeysR(hkey:thandle;const parent:string=''):boolean;
var
ret:dword;
lpname:pwidechar;
lpcname:pdword;
idx:word;
ws:widestring;
path:string;
wsubkeyname:array[0..255] of widechar;
hkresult:thandle;
begin
result:=false;
try
idx:=0;
getmem(lpname,256);
getmem(lpcname ,sizeof(dword));
ret:=0;
while ret=0 do
  begin
  lpcname^:=256;
  ret:=OREnumKey(hkey,idx,lpname,lpcname,nil,nil,nil);
  if ret=0 then
    begin
    setlength(ws,lpcname^);
    copymemory(@ws[1],lpname,lpcname^*2);
    if parent=''
      then path:=(string(ws))
      else path:=(parent+'\'+string(ws));
    writeln(path);
    //EnumValuesAll(hkey);
    fillchar(wsubkeyname,sizeof(wsubkeyname),#0);
    StringToWideChar(string(ws), wsubkeyname, sizeof(wsubkeyname));
    if OROpenKey (hkey,wsubkeyname,hkresult)=0 then
      begin
      EnumkeysR (hkresult,path);
      ret:=ORcloseKey (hkresult);
      end;
    inc(idx);
    end;//if ret=0 then
  end;//while ret=0 do
if idx>0 then result:=true;
except
on e:exception do writeln('EnumKeysR error:'+e.message);
end;
end;

function shorten_path(gkeyname:string):string;
begin
gkeyname :=StringReplace (gkeyname,'HKEY_CURRENT_CONFIG\','',[rfReplaceAll, rfIgnoreCase]) ;
gkeyname :=StringReplace (gkeyname,'HKEY_CURRENT_USER\','',[rfReplaceAll, rfIgnoreCase]) ;
gkeyname :=StringReplace (gkeyname,'HKEY_LOCAL_MACHINE\SAM\','',[rfReplaceAll, rfIgnoreCase]) ;
gkeyname :=StringReplace (gkeyname,'HKEY_LOCAL_MACHINE\BCD00000000\','',[rfReplaceAll, rfIgnoreCase]) ;
gkeyname :=StringReplace (gkeyname,'HKEY_LOCAL_MACHINE\SECURITY\','',[rfReplaceAll, rfIgnoreCase]) ;
gkeyname :=StringReplace (gkeyname,'HKEY_LOCAL_MACHINE\SOFTWARE\','',[rfReplaceAll, rfIgnoreCase]) ;
gkeyname :=StringReplace (gkeyname,'HKEY_LOCAL_MACHINE\SYSTEM\','',[rfReplaceAll, rfIgnoreCase]) ;
gkeyname :=StringReplace (gkeyname,'HKEY_USERS\.DEFAULT\','',[rfReplaceAll, rfIgnoreCase]) ;
result:=gkeyname ;
end;



function get_currentcontrolset(hkey:thandle;skeyname:string):string;
var
wsubkeyname:array[0..255] of widechar;
hkresult:thandle;
value:string;
ret,dwtype:dword;
begin
result:=skeyname;
if pos('CURRENTCONTROLSET',uppercase(skeyname) )>0 then
begin
  fillchar(wsubkeyname,sizeof(wsubkeyname),#0);
  StringToWideChar('select', wsubkeyname, length('select')+1);
  try ret:=OROpenKey (hkey,wsubkeyname,hkresult); except raise exception.Create('OROpenKey failed'); end;
  if ret=0 then
  begin
  getvalue(hkresult,'Current',value,dwtype);
  if value<>'' then result:=stringreplace(skeyname,'currentcontrolset','controlset00'+value,[rfReplaceAll, rfIgnoreCase]);
  ret:=ORcloseKey (hkresult);
  end;//if ret=0 then
end;//if pos
end;

function wideSmallFileFindAndReplace(FileName, Find_, ReplaceWith: string):boolean;
var
f:textfile;
s,t:string;
c1,c2:char;
i:byte;
myfile:tstrings;
ws:widestring;
begin
result:=false;
assignfile(f,filename);
reset(f);
read(f,c1);read(f,c2);
if (c1=chr($ff)) and (c2=chr($fe)) then //ucs-2
begin
while Not(eof(f)) do
begin
  //readln(f,ws);
  //t:=t+Utf16ToAnsi(ws);

  ReadLn(f, s);
  for i:=1 to length(s) do
    begin
    //if i mod 2<>0 then t:=t+s[i];
    if s[i]<>chr(0) then t:=t+s[i];
    end;
  
    t:=t+#13#10;
end; //while Not(eof(f)) do
t:=newstringreplace(t,'\'+#13#10,'',[rfReplaceAll, rfIgnoreCase]);
t:=newstringreplace(t,',  ',',',[rfReplaceAll, rfIgnoreCase]);
//
myfile:=TStringList.Create;
myfile.Text := t;
myfile.SaveToFile(FileName+'.new');
myfile.Free;
//
result:=true;
end; //if (c1=chr($ff)) and (c2=chr($fe)) then //ucs-2
CloseFile(f);

end;

procedure SmallFileFindAndReplace(FileName, Find_, ReplaceWith: string);
var
s:tstrings;
begin
s:=TStringList.Create;
s.LoadFromFile(FileName);
s.Text := StringReplace(s.Text, Find_, ReplaceWith, [rfReplaceAll, rfIgnoreCase]);
s.SaveToFile(FileName+'.new');
s.Free;
end;

{
procedure FileReplaceString(const FileName, searchstring, replacestring: string);
var
  fs: TFileStream;
  S: string;
begin
  fs := TFileStream.Create(FileName, fmOpenread or fmShareDenyNone);
  try
    SetLength(S, fs.Size);
    fs.ReadBuffer(S[1], fs.Size);
  finally
    fs.Free;
  end;
  S  := StringReplace(S, SearchString, replaceString, [rfReplaceAll, rfIgnoreCase]);
  fs := TFileStream.Create(FileName, fmCreate);
  try
    fs.WriteBuffer(S[1], Length(S));
  finally
    fs.Free;
  end;
end;
}


function import(hkey:thandle;filename:string):boolean;
var
ini:tinifile;
values,sections,s:tstrings;
value1,value2,chars:tstringlist;
e,i,j,k:integer;
key,subkey,value,svalue_type,tmp:string;
ret:dword;
wkey:array[0..511] of widechar;
hkresult,hcreatedkey:thandle;
value_type:cardinal;
//
f_in,f_out:textfile;
//
fs: TFileStream;
begin
result:=false;
{$i-}deletefile(pchar(FileName+'.new'));{$i+}
if wideSmallFileFindAndReplace(filename,'\'+#13#10,'')=false then
  begin
  //writeln('creating: '+ FileName+'.new' );
  s:=TStringList.Create;
  s.LoadFromFile(FileName);
  s.Text := newstringreplace(s.Text ,'\'+#13#10,'',[rfReplaceAll, rfIgnoreCase]);
  s.Text := newstringreplace(s.Text ,',  ',',',[rfReplaceAll, rfIgnoreCase]);
  s.SaveToFile(FileName+'.new');
  s.Free;
  end;
if fileexists(filename+'.new')
  then ini:=tinifile.Create(filename+'.new')
  else ini:=tinifile.Create(filename);
//writeln('parsing: '+ ini.FileName );
sections:=tstringlist.Create ;
ini.ReadSections(sections);
if sections.Count >0 then
begin
for i:=0 to sections.Count -1 do
  begin
  key:= shorten_path(sections[i]);
  key:=get_currentcontrolset(hkey,key);
  writeln('['+key+']');
  if uppercase(key)='HKEY_LOCAL_MACHINE\HARWDARE' then key:='';
  if uppercase(key)='HKEY_LOCAL_MACHINE\SAM' then key:='';
  if uppercase(key)='HKEY_LOCAL_MACHINE\SECURITY' then key:='';
  if uppercase(key)='HKEY_LOCAL_MACHINE\SOFTWARE' then key:='';
  if uppercase(key)='HKEY_LOCAL_MACHINE\SYSTEM' then key:='';
  values:=tstringlist.Create ;
  //ini.ReadSection(sections[i],values);
  ini.ReadSectionValues(sections[i],values);
  //if values.Count =0 then createkey(hkey,key,hcreatedkey);
  if key[1]='-'
     then
     begin
     delete(key,1,1);
     writeln('deletekey:'+key);
     //are there any sbkeys?
     ret:=OROpenKey (hkey,pwidechar(widestring(key)),hkresult);
     if ret=0 then
       begin
       deletekeys (hkresult);
       ORcloseKey (hkresult);
       end;
     deletekey (hkey,key);
     end
     else if key[1]<>';' then createkeys(hkey,key); //for section create the multi level path key
  if values.Count >0 then
  begin
  for j:=0 to values.count -1 do
    begin
    //memo1.Lines.Add(values[j]);
     value1:=split(values[j],'=');
    subkey:=strip_quotes(value1[0]);
    if value1.count=1 then value1.add('');
    if (pos('dword:',value1[1])>0) or (pos('hex:',value1[1])>0) or (pos('hex(',value1[1])>0) then
      begin
      value2:=split(value1[1],':');
      svalue_type:=value2[0];
      if value2.count>1 then value:=value2[1];  //c4,0f,ac,1d,95,05,d0,01
      if value1.Count>2 then value:=value+value1[2]; //ugly patch (for now) if the value contains a '='
      if assigned(value2) then value2.free;
      end
      else
      begin
      svalue_type:='string';
      value:=value1[1];
      if value1.Count >2 then value:=value+value1[2]; //ugly patch (for now) if the value contains a '='
      end;

    //

    if svalue_type ='string' then value_type :=REG_SZ ;
    if svalue_type ='dword'  then value_type :=REG_DWORD;
    if svalue_type ='hex(0)' then value_type :=REG_NONE    ;
    if svalue_type ='hex(2)' then value_type :=REG_EXPAND_SZ   ;
    if svalue_type ='hex(3)' then value_type :=3   ;
    if svalue_type ='hex(4)' then value_type :=4   ;
    if svalue_type ='hex(5)' then value_type :=5   ;
    if svalue_type ='hex(6)' then value_type :=6   ;
    if svalue_type ='hex(7)' then value_type :=REG_MULTI_SZ  ;
    if svalue_type ='hex(8)' then value_type :=8  ;
    if svalue_type ='hex(9)' then value_type :=9  ;
    if svalue_type ='hex(a)' then value_type :=REG_RESOURCE_REQUIREMENTS_LIST   ;
    if svalue_type ='hex(b)' then value_type :=REG_QWORD   ;
    if svalue_type ='hex' then  value_type :=REG_BINARY ; //REG_BINARY ;

    if value_type =REG_DWORD then
      begin
      //lets remove comments at end of line
      if pos(';',value)>0 then delete(value,pos(';',value)-1,255);
      val('$'+value,ret,e);
      if e<>0 then raise exception.Create('not a valid integer value');
      value:=inttostr(ret);
      end;

    if value_type =reg_none then value:=#0;

    if (value_type =reg_sz) then
      begin
      //writeln(value+'.'); //debug
      if value='' then value :=chr(0);
      //do we have a comment at the end of the string
      if value[1]='"' then
        begin
        tmp:=value;
        delete(tmp,1,1);
        //we have a ';' aka comment after the end of the string
        if pos(';',tmp)>pos('"',tmp) then
        begin
        delete(tmp,pos(';',tmp)-1,255);
        tmp:=trim(tmp);
        if tmp[length(tmp)]='"' then delete(tmp,length(tmp),1);
        value:=tmp;
        end; //if pos(';',tmp)>pos('"',tmp) then
        end;//if value[1]='"' then
      end;

    if (value_type =reg_expand_sz) or (value_type =reg_multi_sz) then
      begin
      value:=StringReplace(value,',00,00',',ZZ,ZZ',[rfReplaceAll]);
      value:=StringReplace(value,',00','',[rfReplaceAll]);
      value:=StringReplace(value,',ZZ,ZZ',',00',[rfReplaceAll]);
      chars:=split(value,',');
      if chars.count>0 then
        begin
        value:='';
        for k:=0 to chars.Count -1 do {if strtoint('$'+chars[k])<>0 then}
          begin
          try
          value:=value+chr(strtoint('$'+chars[k]));
          except
          on e:exception do writeln('import: '+e.Message );
          end;
          end;
        end;
      if assigned(chars) then chars.free;
      //if pos(';',value)>0 then delete(value,pos(';',value)-1,255);
      end;

    fillchar(wkey,sizeof(wkey),#0);
    StringToWideChar(key, wkey, length(key)+1);
    try ret:=OROpenKey (hkey,wkey,hkresult);except raise exception.Create('OROpenKey failed'); end;
    if ret<>0 then
      begin
      createkey(hkey,key,hcreatedkey);
      try ret:=OROpenKey (hkey,wkey,hkresult);except raise exception.Create('OROpenKey failed'); end;
      end;
    if ret=0 then
      begin
      if subkey='@' then subkey:='';

      if (subkey[1]<>';') and (value[1]='-') then
         begin
         writeln('deletevalue:'+subkey);
         deletevalue  (hkresult,subkey) ;
         end;

      if (subkey[1]<>';') and (subkey[1]<>'-') and (value<>'-')
         then if setvalue(hkresult ,subkey,value,value_type )=true
              then writeln('added -> '+subkey+'='+svalue_type+':'+value);
      ret:=ORcloseKey (hkresult);
      if ret<>0 then writeln('ORcloseKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
      end
      else
      writeln('could not open '+key);

    //
    if assigned(value1) then value1.free;
    end;//j
  if assigned(values) then values.free;
  end; //if values.Count >0 then
  end;//i
if assigned(sections) then sections.free;
end; //if sections.Count >0 then
{$i-}DeleteFile (pchar(filename+'.new'));{$i+};
end;

function init:boolean;
var lib:hmodule;
begin
result:=false;
try
lib:=0;
    {$IFDEF win64}lib:=loadlibrary('offreg64.dll');{$endif}
    {$IFDEF win32}lib:=loadlibrary('offreg.dll');{$endif}
if lib<=0 then
  begin
  writeln('could not loadlibrary:'+inttostr(getlasterror));
  exit;
  end;
ORGetVersion:=getProcAddress(lib,'ORGetVersion');
ORCreateHive:=getProcAddress(lib,'ORCreateHive');
OROpenHive:=getProcAddress(lib,'OROpenHive');
ORCloseHive:=getProcAddress(lib,'ORCloseHive');
ORSaveHive:=getProcAddress(lib,'ORSaveHive');
OROpenKey:=getProcAddress(lib,'OROpenKey');
ORCloseKey:=getProcAddress(lib,'ORCloseKey');
ORGetValue:=getProcAddress(lib,'ORGetValue');
ORSetValue:=getProcAddress(lib,'ORSetValue');
ORDeleteValue:=getProcAddress(lib,'ORDeleteValue');
ORDeleteKey:=getProcAddress(lib,'ORDeleteKey');
ORCreateKey:=getProcAddress(lib,'ORCreateKey');
OREnumKey:=getProcAddress(lib,'OREnumKey');
OREnumValue:=getProcAddress(lib,'OREnumValue');
result:=true;
except
on e:exception do writeln('init error:'+e.message);
end;
end;

procedure main(shive,skeyname,sverb,svaluename:string;svalue:string='';svaluetype:dword=1;no_backup:boolean=false);
var
list:tstrings;
hkey,hkresult,hcreatedkey:thandle;
ret:dword;
wpath,wsubkeyname,wbackup:array[0..255] of widechar;
dwMajorVersion,dwMinorVersion,dwtype:dword;
sbackup,s:string;
idx:word;
changed,saved:boolean;
b:byte;
begin
try
ret:=0;
changed:=false;
saved:=false;
dwMajorVersion:=0;dwMinorVersion:=0;
hkey:=thandle(-1);
if init=false then exit;
// ****************** CREATE *****************************
try
if sverb='create' then
  begin
  ret:=ORCreateHive (hkey);
  if (ret<>0) then writeln('ORCreateHive failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
  if skeyname<>' ' then
    begin
    createkey(hkey,skeyname,hcreatedkey);
    writeln('createkey '+svaluename+' ok');
    end;
    fillchar(wbackup,sizeof(wbackup),#0);
    StringToWideChar(shive, wbackup, length(shive)+1);
    ret:=ORSaveHive (hkey,wbackup,gmajor,gminor);
    if ret=0 then writeln('saved to '+shive+' ok') else writeln('saved to '+shive+ ' failed,'+SysErrorMessage(ret)) ;
    //exitcode:=ret;
    exit;
  end;
except
  on e:exception  do raise exception.Create('ORCreateHive failed,'+e.Message );
end;
//********************* END CREATE **************************
fillchar(wpath,sizeof(wpath),#0);
StringToWideChar(shive, wpath, length(shive)+1);
if global_hkey <>0
  then hkey:=global_hkey //we are running a set of command - we dont want to re open the key or else changes are lost
  else try ret:=OROpenHive(wpath,hkey); except raise exception.Create('OROpenHive failed'); end;
if ret<>0
then writeln('OROpenHive failed:'+inttostr(ret)+':'+SysErrorMessage(ret))
else
// ************** VERBS ************************************************
begin
global_hkey :=hkey;
//do things...
//replace currentcontrolset by the real controlset00x
skeyname:=get_currentcontrolset(hkey,skeyname);
//handle multi level path
fillchar(wsubkeyname,sizeof(wsubkeyname),#0);
StringToWideChar(skeyname, wsubkeyname, length(skeyname)+1);
if (sverb='createkey') or (sverb='setvalue') or (sverb='createvalue') then
  begin
   createkeys(hkey,skeyname); 
  end;
//
if skeyname<>' '
  then try ret:=OROpenKey (hkey,wsubkeyname,hkresult);except raise exception.Create('OROpenKey failed'); end
  else hkresult :=hkey ;
if (ret<>0) and (sverb<>'import')
then writeln('OROpenKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret))
else
begin
if sverb='enumvalues' then
  begin
  changed:=false ;
  list:=tstringlist.Create ;
  if enumvalues(hkresult,list) then
    begin
    for idx:=0 to list.Count -1 do
      begin
      writeln(list[idx]);
      end; //for idx:=0
    end;// if enumkeys
  list.Free ;
  end;
if (sverb='enumallvalues') or (sverb='enumvaluesall')  then
  begin
  changed:=false ;
  EnumValuesAll(hkresult);
  end;
if sverb='enumkeys' then
  begin
  changed:=false ;
  list:=tstringlist.Create ;
  if enumkeys(hkresult,list) then
    begin
    for idx:=0 to list.Count -1 do
      begin
      writeln(list[idx]);
      end; //for idx:=0
    end;// if enumkeys
  list.Free ;
  end;
if sverb='enumkeysr' then
  begin
  changed:=false ;
  enumkeysR(hkresult);
  end;
if sverb='createkey'
  then if {createkey(hkey,svaluename) then}  createkey(hkresult,svaluename,hcreatedkey ) then
  begin
  writeln('createkey '+svaluename+' ok');
  changed:=true;
  end;
if sverb='deletekey'
  then if deletekey(hkresult,svaluename) then
  begin
  writeln('deletekey '+svaluename+' ok');
  changed:=true;
  end;
if sverb='deletekeys'
  then if deletekeys(hkresult) then
  begin
  writeln('deletekeys ok');
  if deletekey(hkey,skeyname )=true then writeln(skeyname+' deleted ok');
  changed:=true;
  end;
if sverb='deletevalue'
  then if deletevalue(hkresult,svaluename) then
  begin
  writeln('deletevalue '+svaluename+' ok');
  changed:=true;
  end;
dwtype:=gvaluetype ;  
if sverb='getvalue'
  then if getvalue(hkresult,svaluename,s,dwtype) then //writeln('"'+svaluename+'"='+oem(s));
        begin
        changed:=false ;
        case dwtype of
        reg_sz:writeln('"'+svaluename+'"=reg_sz:"'+oem(s)+'"');
        reg_multi_sz:writeln('"'+svaluename+'"=reg_multi_sz:"'+oem(s)+'"');
        reg_expand_sz:writeln('"'+svaluename+'"=reg_expand_sz:"'+oem(s)+'"');
        reg_binary:writeln('"'+svaluename+'"=reg_binary:"'+oem(s)+'"');
        reg_dword:writeln('"'+svaluename+'"=reg_dword:'+oem(s));
        else writeln('"'+svaluename+'"=reg_unknown:'+oem(s));
        end;//case
        end; //if getvalue ...
if sverb='getvaluebyteat'
  then if getvaluebyteat (hkresult ,svaluename,strtoint(svalue),b) then
  begin
  changed:=false ;
  writeln(svaluename+'@'+svalue+'='+inttostr(b));
  end;
if sverb='setvalue'
  then if setvalue(hkresult ,svaluename,svalue,svaluetype) then
  begin
  writeln('setvalue '+svaluename+' ok');
  changed:=true;
  end;
if sverb='setvaluebyteat'
  then if setvaluebyteat (hkresult ,svaluename,strtoint(svalue),svaluetype) then
  begin
  writeln('setvaluebyteat '+svaluename+' ok');
  changed:=true;
  end;
{
if sverb='createvalue'
  then if setvalue(hkresult ,svaluename,'',svaluetype) then
  begin
  writeln('createvalue '+svaluename+' ok');
  changed:=true;
  end;
}  
if sverb='import' then
  begin
  import(hkey,svaluename);
  changed:=true;
  end;
if (hkresult<>0) and (skeyname<>' ') then
  begin
  ret:=ORcloseKey (hkresult);
  if ret<>0 then writeln('ORcloseKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
  end;
end; //OROpenKey
// *********************** END VERBS ******************************
if (pos('enum',sverb)>0) or (pos('getvalue',sverb)>0) then
   begin
   try ret:=ORCloseHive (hkey); except raise exception.Create('ORCloseHive failed'); end;
   exit;
   end;
//backup file
  sbackup:=ChangeFileExt(shive,'.new');
  fillchar(wbackup,sizeof(wbackup),#0);
  StringToWideChar(sbackup, wbackup, length(sbackup)+1);
//was there a change and is it the last_run (or unique run)? DEFAULT CASE
if (changed=true) and (last_run=true) then
  begin
  {$i-}deletefile(pchar(sbackup));{$i-}
  ret:=ORSaveHive (hkey,wbackup,gmajor,gminor);
  if ret=0
    then begin if no_backup=false then writeln('saved to '+sbackup+' ok');end
    else writeln('saved to '+sbackup+ ' failed,'+inttostr(ret)) ;
  saved:=true;
  end;
//may be there was no change, but still is the last run?
//in case last run did not trigger a change ... we still want to save it.
if (last_run =true) and (saved=false) then
  begin
  {$i-}deletefile(pchar(sbackup));{$i-}
  ret:=ORSaveHive (hkey,wbackup,gmajor,gminor);
  if ret<>0 then writeln('saved to '+sbackup+ ' failed,'+inttostr(ret)) ;
  saved:=true;
  end;
//was hive saved? if so we need to close or else we keep it for re use
if saved=true then //should we close? or do we want to reuse that opened hive?
  begin
  try ret:=ORCloseHive (hkey); except raise exception.Create('ORCloseHive failed'); end;
  if ret<>0 then writeln('ORCloseHive failed: '+inttostr(ret));
  end;
end; //OROpenHive
//if the hive was saved, we need to delete/Rename some files...
if (saved=true) {and (last_run=true)} then
begin
  if no_backup =true then
    begin
    //{$i-}deletefile(pchar(ChangeFileExt(shive,'.old')));{$i-}
    //RenameFile(shive,ChangeFileExt(shive,'.old'));
    //writeln('renamed '+shive+' to '+ChangeFileExt(shive,'.old'));
    {$i-}deletefile(pchar(shive));{$i-} //delete original
    //writeln('deleted '+shive);
    RenameFile(sbackup,shive); //rename backup to original
    writeln('saved to '+shive+' ok');
    end;
end;
//exitcode:=ret;
except
on e:exception do writeln('main error:'+e.message);
end;
end;

//******************************************************************

begin
GetOSVersion(gmajor,gminor);
if (gmajor=6) and (gminor=2) then gminor:=1;
//writeln('OS '+inttostr(gmajor)+'.'+inttostr(gminor));
//writeln(inttostr(paramcount));
if paramcount=0 then
  begin
  writeln('OfflineReg v1.0.3 by Erwan.L - http://erwan.labalec.fr/ - erwan2212@gmail.fr');
  writeln('Main Usage : OfflineReg hivepath keypath verb argument(s)');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path getvalue a_value_name');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path getvaluebyteat a_value_name offset');
  //writeln('Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_sz_value a_new_value nobackup');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_sz_value a_new_value');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path setvalue " " a_new_value -> will set default key');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_dword_value a_dword_value 4 ');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_qword_value a_qword_value 11 ');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_binary_value 0a,0b,0c,0d,0e,0f 3 ');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_binary_value "0a 0b 0c 0d 0e 0f" 3 ');  
  writeln('Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_multi_sz_value "blah blah blah" 7');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_expand_sz_value "blah blah blah" 2');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path setvaluebyteat a_reg_binary_value a_byte_value offset');
  //writeln('Example : OfflineReg "c:\temp\system" a_key_path createvalue a_reg_sz_value 1');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path deletevalue a_value');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path deletekey a_key');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path deletekey');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path deletekeys');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path createkey a_key');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path createkey');
  writeln('Example : OfflineReg "c:\temp\system" " " createkey a_key -> will create a key under root');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path enumkeys');
  writeln('Example : OfflineReg "c:\temp\system" " " enumkeys -> will enum keys under root');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path enumkeysR');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path enumvalues');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path enumvaluesall');
  writeln('Example : OfflineReg "c:\temp\system" a_key_path create');
  writeln('Example : OfflineReg "c:\temp\system" " " create');
  writeln('Example : OfflineReg "c:\temp\system" " " import commands.reg');
  writeln('Example : OfflineReg "c:\temp\system" " " run commands.txt');
  exit;
  end;
if paramcount>=3 then
begin
gvaluename:='';gvalue:='';gvaluetype:=1;
ghive :=paramstr(1);
gkeyname:=paramstr(2);
gkeyname:=shorten_path(gkeyname);
gverb:=paramstr(3);
if paramcount>=4 then gvaluename :=string(paramstr(4));
if paramcount>=5 then gvalue:=string(paramstr(5));
if paramcount>=6 then gvaluetype:=strtoint(paramstr(6));
//if lowercase(gverb)='createvalue' then gvaluetype:=strtoint(paramstr(5));
//for i:=1 to ParamCount do if lowercase(paramstr(i))='nobackup' then bool:=true else bool:=false;
bool:=true;
last_run:=true;
if gverb <>'run'
  then main(ghive,gkeyname,gverb,gvaluename,gvalue,gvaluetype,bool);
if gverb='run' then
  begin
  commands:=TStringList.Create ;
  commands.LoadFromFile(paramstr(4));
  //dont_save:=true;
  last_run:=false;
  for i:=0 to commands.Count -1 do
    begin
    params:=tstringlist.create;
    params.Clear;
    params.Delimiter := ' ';
    params.DelimitedText := commands[i];
    //if i=commands.Count -1 then dont_save:=false; //time to toggle the save flag
    if i=commands.Count -1 then last_run:=true; //time to toggle the save flag
    gvaluename:='';gvalue:='';gvaluetype:=1;
    if params.Count >=3 then gvaluename :=params[2];
    if params.Count >=4 then gvalue :=params[3];
    if params.Count >=5 then gvaluetype :=strtoint(params[4]);
    //hive, path, verb, value/key name, value, valuetype, nobackup
    main(ghive,params[0],params[1],gvaluename,gvalue,gvaluetype,bool);
    end;
  commands.Free ;
  end; //if gverb='run' then
end;
end.
