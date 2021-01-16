unit uFrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,uofflinereg, StdCtrls, ComCtrls, Menus,ClipBrd,ubcd;

type
  TForm1 = class(TForm)
    TreeView1: TTreeView;
    OpenDialog1: TOpenDialog;
    Edit1: TEdit;
    StatusBar1: TStatusBar;
    ListView1: TListView;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Open1: TMenuItem;
    Close1: TMenuItem;
    ools1: TMenuItem;
    Deleteselectedvalue1: TMenuItem;
    Deleteselectedkey1: TMenuItem;
    Save1: TMenuItem;
    SaveDialog1: TSaveDialog;
    N1: TMenuItem;
    Quit1: TMenuItem;
    N2: TMenuItem;
    Copyselectedvaluetoclipboard1: TMenuItem;
    Copypathfromselectedkeytoclipboard1: TMenuItem;
    EditValue1: TMenuItem;
    N3: TMenuItem;
    About1: TMenuItem;
    Me1: TMenuItem;
    CreateKey1: TMenuItem;
    CreateValuestring1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure TreeView1DblClick(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure TreeView1Click(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure Deleteselectedkey1Click(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure Deleteselectedvalue1Click(Sender: TObject);
    procedure Quit1Click(Sender: TObject);
    procedure Copyselectedvaluetoclipboard1Click(Sender: TObject);
    procedure Copypathfromselectedkeytoclipboard1Click(Sender: TObject);
    procedure EditValue1Click(Sender: TObject);
    procedure Me1Click(Sender: TObject);
    procedure TreeView1GetSelectedIndex(Sender: TObject; Node: TTreeNode);
    procedure CreateKey1Click(Sender: TObject);
    procedure CreateValuestring1Click(Sender: TObject);

  private
    { Private declarations }
    procedure enum_keys(node:ttreenode;skeyname:string);
    procedure enum_values(skeyname:string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  hkey:thandle;
  gmajor,gminor:dword;

implementation

{$R *.dfm}

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

procedure TForm1.enum_values(skeyname:string);
var
ret,dwvaluetype:dword;
hkresult:thandle;
wsubkeyname,wbackup:array[0..255] of widechar;
svalue:string;
list:tstrings;
idx:word;
lv:tlistitem;
begin
StatusBar1.SimpleText :='Fetching values...';
ListView1.Clear ;

if skeyname='.' then hkresult:=hkey
else
begin
StringToWideChar(skeyname, wsubkeyname, sizeof(wsubkeyname));
try ret:=OROpenKey (hkey,wsubkeyname,hkresult);except raise exception.Create('OROpenKey failed'); end;
if ret<>0 then showmessage('OROpenKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
end;

list:=tstringlist.Create ;
  if enumvalues(hkresult,list) then
    begin
    for idx:=0 to list.Count -1 do
      begin
      lv:=ListView1.Items.Add ;
      lv.Caption :=list[idx];
      setlength(svalue,2048);
      if getvalue2(hkresult,list[idx],svalue,dwvaluetype) then
        begin
        lv.SubItems.Add (oem(svalue));
        case dwvaluetype of
        REG_SZ:lv.SubItems.Add ('REG_SZ');
        REG_MULTI_SZ:lv.SubItems.Add ('REG_MULTI_SZ');
        REG_EXPAND_SZ:lv.SubItems.Add ('REG_EXPAND_SZ');
        REG_DWORD:lv.SubItems.Add ('REG_DWORD');
        REG_QWORD:lv.SubItems.Add ('REG_QWORD');
        REG_NONE:lv.SubItems.Add ('REG_NONE');
        REG_BINARY:lv.SubItems.Add ('REG_BINARY');
        else lv.SubItems.Add ('REG_UNKNOWN');
        end;
        end;
      end; //for idx:=0
    end;// if enumkeys
  list.Free ;

if (hkresult<>0) and (skeyname<>'.') then
  begin
  ret:=ORcloseKey (hkresult);
  if ret<>0 then writeln('ORcloseKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
  end;

StatusBar1.SimpleText :='DONE.';
end;

function GUID2Text(guid:string):string;
begin
result:=guid;
if lowercase(guid)=lowercase(EmsSettingsGroupId) then result:='EmsSettingsGroupId';
if lowercase(WindowsBootManagerId)=lowercase(WindowsBootManagerId) then result:='WindowsBootManagerId';

end;

procedure TForm1.enum_keys(node:ttreenode;skeyname:string);
var
ret:dword;
hkresult:thandle;
wsubkeyname,wbackup:array[0..255] of widechar;
list:tstrings;
idx:word;
tmp:string;
begin
StatusBar1.SimpleText :='Fetching keys...';


if skeyname='.' then hkresult:=hkey
else
begin
StringToWideChar(skeyname, wsubkeyname, sizeof(wsubkeyname));
try ret:=OROpenKey (hkey,wsubkeyname,hkresult);except raise exception.Create('OROpenKey failed'); end;
if ret<>0 then showmessage('OROpenKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
end;

list:=tstringlist.Create ;
  if enumkeys(hkresult,list) then
    begin
    if (node<>nil) and (node.HasChildren) then node.DeleteChildren; 
    for idx:=0 to list.Count -1 do
      begin
      //tmp:=(list[idx]);
      TreeView1.Items.Addchild (node,list[idx]);
      end; //for idx:=0
    end;// if enumkeys
  list.Free ;

if (hkresult<>0) and (skeyname<>'.') then
  begin
  ret:=ORcloseKey (hkresult);
  if ret<>0 then showmessage('ORcloseKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
  end;



StatusBar1.SimpleText :='DONE.';
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
hkey:=thandle(-1);
GetOSVersion(gmajor,gminor);
if init_offline=false then showmessage('offline init failed');
end;

procedure TForm1.TreeView1DblClick(Sender: TObject);
var node,parent:ttreenode;
skeyname:string;
begin
if TreeView1.Selected=nil then exit;
node:=TreeView1.Selected ;
skeyname:=node.text;
parent:=node.Parent ;
while Parent <>nil do
  begin
  skeyname:=parent.Text +'\'+skeyname;
  parent:=parent.Parent ;
  end;
enum_keys(node,skeyname ); 
end;

procedure TForm1.Open1Click(Sender: TObject);
var
shive:string;
ret:dword;
wpath:array[0..255] of widechar;
begin
if OpenDialog1.Execute=false then exit;
Edit1.Text :=OpenDialog1.FileName ;
//
shive:=edit1.Text ;
StringToWideChar(shive, wpath, sizeof(wpath));
try ret:=OROpenHive(wpath,hkey); except raise exception.Create('OROpenHive failed'); end;
if ret<>0 then showmessage('OROpenHive failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
//
enum_keys(nil,'.');
end;

procedure get_value(node:ttreenode);
var
parent:ttreenode;
skeyname:string;
begin
skeyname:=node.text;
parent:=node.Parent ;
while Parent <>nil do
  begin
  skeyname:=parent.Text +'\'+skeyname;
  parent:=parent.Parent ;
  end;
form1.enum_values(skeyname );
end;

procedure TForm1.TreeView1Click(Sender: TObject);
var
node:ttreenode;
begin
if TreeView1.Selected=nil then exit;
node:=TreeView1.Selected ;
get_value(node);
end;

procedure TForm1.Close1Click(Sender: TObject);
var ret:dword;
begin
if hkey=thandle(-1) then exit;
try ret:=ORCloseHive (hkey); except raise exception.Create('ORCloseHive failed'); end;
if ret<>0 then showmessage(inttostr(ret));
TreeView1.Items.Clear ;
ListView1.Clear ;
Edit1.Text :='';
hkey:=thandle(-1);
end;

procedure TForm1.Deleteselectedkey1Click(Sender: TObject);
var
node,parent:ttreenode;
skeyname:string;
begin
if TreeView1.Selected=nil then exit;
node:=TreeView1.Selected ;
skeyname:=node.text;
parent:=node.Parent ;
while Parent <>nil do
  begin
  skeyname:=parent.Text +'\'+skeyname;
  parent:=parent.Parent ;
  end;
  if messageboxa(0,pchar('delete '+skeyname),'offline registry',MB_YESNO)=idno then exit;
deletekey(hkey ,skeyname );
end;

procedure TForm1.Save1Click(Sender: TObject);
var
wbackup:array[0..255] of widechar;
ret:dword;
begin
if SaveDialog1.Execute=false then exit;
StringToWideChar(SaveDialog1.FileName , wbackup, sizeof(wbackup));
{$i-}deletefile(pchar(SaveDialog1.FileName));{$i-}
ret:=ORSaveHive (hkey,wbackup,gmajor,gminor);
if ret=0 then showmessage('saved to '+SaveDialog1.FileName+' ok') else showmessage('saved to '+SaveDialog1.FileName+ ' failed,'+inttostr(ret)) ;
end;

procedure TForm1.Deleteselectedvalue1Click(Sender: TObject);
var
node,parent:ttreenode;
skeyname:string;
ret:dword;
wsubkeyname:array[0..255] of widechar;
hkresult:thandle;
begin
if TreeView1.Selected=nil then exit;
if ListView1.Selected =nil then exit;
node:=TreeView1.Selected ;
skeyname:=node.text;
parent:=node.Parent ;
while Parent <>nil do
  begin
  skeyname:=parent.Text +'\'+skeyname;
  parent:=parent.Parent ;
  end;

StringToWideChar(skeyname, wsubkeyname, sizeof(wsubkeyname));
try ret:=OROpenKey (hkey,wsubkeyname,hkresult);except raise exception.Create('OROpenKey failed'); end;
if (ret<>0) then showmessage('OROpenKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret));

if messageboxa(0,pchar('delete '+listview1.selected.caption),'offline registry',MB_YESNO)=idno then exit;
deletevalue (hkresult ,listview1.selected.caption );

if hkresult<>0 then
  begin
  ret:=ORcloseKey (hkresult);
  if ret<>0 then showmessage('ORcloseKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
  end;

end;

procedure TForm1.Quit1Click(Sender: TObject);
begin
application.Terminate ;
end;

procedure TForm1.Copyselectedvaluetoclipboard1Click(Sender: TObject);
begin
if ListView1.Selected =nil then exit;
Clipboard.AsText := ListView1.Selected.SubItems [0];
end;

procedure TForm1.Copypathfromselectedkeytoclipboard1Click(Sender: TObject);
var
node,parent:ttreenode;
skeyname:string;
begin
if TreeView1.Selected=nil then exit;
node:=TreeView1.Selected ;
skeyname:=node.text;
parent:=node.Parent ;
while Parent <>nil do
  begin
  skeyname:=parent.Text +'\'+skeyname;
  parent:=parent.Parent ;
  end;
Clipboard.AsText :=skeyname ;
end;


procedure TForm1.EditValue1Click(Sender: TObject);
var
node,parent:ttreenode;
skeyname,svalue:string;
ret,dwvaluetype:dword;
wsubkeyname:array[0..255] of widechar;
hkresult:thandle;
begin
if TreeView1.Selected=nil then exit;
if ListView1.Selected =nil then exit;
node:=TreeView1.Selected ;
skeyname:=node.text;
parent:=node.Parent ;
while Parent <>nil do
  begin
  skeyname:=parent.Text +'\'+skeyname;
  parent:=parent.Parent ;
  end;

StringToWideChar(skeyname, wsubkeyname, sizeof(wsubkeyname));
try ret:=OROpenKey (hkey,wsubkeyname,hkresult);except raise exception.Create('OROpenKey failed'); end;
if (ret<>0) then showmessage('OROpenKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret));

//if messageboxa(0,pchar('edit '+listview1.selected.caption+'?'),'offline registry',MB_YESNO)=idno then exit;

if listview1.selected.subitems[1] ='REG_SZ' then dwvaluetype :=REG_SZ ;
if listview1.selected.subitems[1] ='REG_EXPAND_SZ' then dwvaluetype :=REG_EXPAND_SZ;
if listview1.selected.subitems[1] ='REG_BINARY' then dwvaluetype :=REG_BINARY  ;
if listview1.selected.subitems[1] ='REG_DWORD' then dwvaluetype :=REG_DWORD   ;
if listview1.selected.subitems[1] ='REG_MULTI_SZ' then dwvaluetype :=REG_MULTI_SZ   ;
if listview1.selected.subitems[1] ='REG_QWORD' then dwvaluetype :=REG_QWORD   ;
if listview1.selected.subitems[1] ='REG_NONE' then dwvaluetype :=REG_NONE   ;
if InputQuery('enter value','Offline Registry Editor',svalue)=false then exit;
if setvalue(hkresult,listview1.selected.caption,svalue,dwvaluetype)=false
  then showmessage('setvalue failed')
  else ListView1.Selected.SubItems [0]:=svalue;

if hkresult<>0 then
  begin
  ret:=ORcloseKey (hkresult);
  if ret<>0 then showmessage('ORcloseKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
  end;

end;

procedure TForm1.Me1Click(Sender: TObject);
begin
Showmessage('Erwan2212@gmail.com'+#13#10+'http://labalec.fr/erwan');
end;

procedure TForm1.TreeView1GetSelectedIndex(Sender: TObject;
  Node: TTreeNode);
begin
exit;
get_value(node);
end;

procedure TForm1.CreateKey1Click(Sender: TObject);
var
node,parent:ttreenode;
skeyname,tmp:string;
dummy:thandle;
begin
if TreeView1.Selected=nil then exit;
node:=TreeView1.Selected ;
skeyname:=node.text;
parent:=node.Parent ;
while Parent <>nil do
  begin
  skeyname:=parent.Text +'\'+skeyname;
  parent:=parent.Parent ;
  end;
InputQuery('createkey','enter key',tmp);
if tmp='' then exit;
if messageboxa(0,pchar('create '+skeyname+'\'+tmp),'offline registry',MB_YESNO)=idno then exit;
if createkey(hkey ,skeyname+'\'+tmp,dummy )=false
  then showmessage('createkey failed')
  else enum_keys(treeview1.selected,skeyname ); ; 
end;

procedure TForm1.CreateValuestring1Click(Sender: TObject);
var
node,parent:ttreenode;
skeyname,svalue:string;
ret,dwvaluetype:dword;
wsubkeyname:array[0..255] of widechar;
hkresult:thandle;
begin
if TreeView1.Selected=nil then exit;
node:=TreeView1.Selected ;
skeyname:=node.text;
parent:=node.Parent ;
while Parent <>nil do
  begin
  skeyname:=parent.Text +'\'+skeyname;
  parent:=parent.Parent ;
  end;

StringToWideChar(skeyname, wsubkeyname, sizeof(wsubkeyname));
try ret:=OROpenKey (hkey,wsubkeyname,hkresult);except raise exception.Create('OROpenKey failed'); end;
if (ret<>0) then
  begin
  showmessage('OROpenKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
  exit;
  end;

if InputQuery('enter valuename','Offline Registry Editor',svalue)=false then exit;
if setvalue(hkresult,svalue,'',1)=false
  then showmessage('setvalue failed')
  else get_value(treeview1.Selected );

if hkresult<>0 then
  begin
  ret:=ORcloseKey (hkresult);
  if ret<>0 then showmessage('ORcloseKey failed:'+inttostr(ret)+':'+SysErrorMessage(ret));
  end;

end;

end.
