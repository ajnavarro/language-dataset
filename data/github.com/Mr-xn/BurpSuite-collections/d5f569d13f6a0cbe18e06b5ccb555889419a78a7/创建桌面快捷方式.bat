chcp 936
REM ����936�����ֹĳЩ����·������������ʧЧ
@echo off
setlocal enabledelayedexpansion
mode con cols=94 lines=30&color 0a&title ����Burp Suiteһ�������ű���ݷ�ʽ
echo ======================================================
echo m    m                             mm   m          m
echo ##  ##  m mm  m   m  m mm          #"m  #  mmm   mm#mm
echo # ## #  #"  "  #m#   #"  #         # #m # #"  #    #
echo # "" #  #      m#m   #   #         #  # # #""""    #
echo #    #  #     m" "m  #   #    #    #   ## "#mm"    "mm
echo =======================================================  
echo.
echo [+] ��л�ƽ�����^&��������^&Burp�ٷ�^&�����������^&��лEveryOne!
echo.
echo [+] ��ӭ��λ���ѹ����Ҳ���@_@��https://mrxn.net
echo.
echo [+] ��õ�ǰ·��:%~dp0
set path=%~dp0Burp_start.bat
echo.
if exist %path% (
echo [+] ����Burpһ�������ű�Burp_start.bat
echo.
echo [+] �����ű�·����
echo.
echo [+] %path%
echo.
goto :creat
) else (
echo [-] ע��,δ���������ű�Burp_start.bat����ע���Ƿ����,�����˳�... 
echo.
pause
exit
)

:creat
echo [+] ��ʼ������ݷ�ʽ...
echo.
rem ���ó��������·��(��Ҫ)
set Program=%path%
rem ���ÿ�ݷ�ʽ����(��Ҫ)
set LinkName=Burp_Suite
rem ������·��
set WorkDir=%~dp0
rem ���ÿ�ݷ�ʽ˵��
set Desc=BurpSuite������һ������
rem ���ÿ�ݷ�ʽͼ��
set icon=%~dp0/img/Goescat-Macaron-Burp-suite.ico
if not defined WorkDir call:GetWorkDir "%Program%"
(echo Set WshShell=CreateObject("WScript.Shell"^)
echo strDesKtop=WshShell.SpecialFolders("DesKtop"^)
echo Set oShellLink=WshShell.CreateShortcut(strDesKtop^&"\%LinkName%.lnk"^)
echo oShellLink.TargetPath="%Program%"
echo oShellLink.WorkingDirectory="%WorkDir%"
echo oShellLink.WindowStyle=1
echo oShellLink.Description="%Desc%"
echo oShellLink.IconLocation="%icon%"
echo oShellLink.Save)>makelnk.vbs
echo [+] �����ݷ�ʽ�����ɹ�!!
echo.
makelnk.vbs
del /f /q makelnk.vbs
pause
goto :eof
:GetWorkDir
set WorkDir=%~dp1
set WorkDir=%WorkDir:~,-1%
pause
goto :eof