# offlinereg-fpc
A command line tool that will allow one to read and write to an offline registry hive.
<br>
Command line usage :
<br>
OfflineReg a_hive_file a_key_path a_verb [a_value_name] [a_value]
<br>
Main Usage : OfflineReg hivepath keypath verb argument(s)<br>
Example : OfflineReg "c:\temp\system" a_key_path getvalue a_value_name<br>
Example : OfflineReg "c:\temp\system" a_key_path getvalue a_value_name<br>
Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_sz_value a_new_value<br>
Example : OfflineReg "c:\temp\system" a_key_path setvalue " " a_new_value -> will set default key<br>
Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_dword_value a_dword_value 4<br>
Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_qword_value a_qword_value 11<br>
Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_binary_value 0a,0b,0c,0d,0e,0f 3<br>
Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_multi_sz_value "blah blah blah" 7<br>
Example : OfflineReg "c:\temp\system" a_key_path setvalue a_reg_expand_sz_value "blah blah blah" 2<br>
Example : OfflineReg "c:\temp\system" a_key_path deletevalue a_value<br>
Example : OfflineReg "c:\temp\system" a_key_path deletekey a_key<br>
Example : OfflineReg "c:\temp\system" a_key_path deletekey<br>
Example : OfflineReg "c:\temp\system" a_key_path deletekeys<br>
Example : OfflineReg "c:\temp\system" a_key_path createkey a_key<br>
Example : OfflineReg "c:\temp\system" a_key_path createkey<br>
Example : OfflineReg "c:\temp\system" " " createkey a_key -> will create a key under root<br>
Example : OfflineReg "c:\temp\system" a_key_path enumkeys<br>
Example : OfflineReg "c:\temp\system" a_key_path enumvalues<br>
Example : OfflineReg "c:\temp\system" a_key_path enumallvalues<br>
Example : OfflineReg "c:\temp\system" a_key_path create<br>
Example : OfflineReg "c:\temp\system" " " create<br>
Example : OfflineReg "c:\temp\system" " " import commands.reg<br>
Example : OfflineReg "c:\temp\system" " " run commands.txt<br>
A real life example :<br>
OfflineReg "D:\Windows\system32\config\system" ControlSet001\Control\ProductOptions getvalue "ProductType".<br>
<br>
Should display :<br>
"ProductType"=WinNT<br>
