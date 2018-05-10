@echo off
setlocal

rem ������͉��H
rem �R�s�[�t���[��TS�t�@�C��(188byte�p�P�b�g)��ϊ����A�Ώۂ�REGZA���R�[�_�[(DLNA�T�[�o)�֓]������o�b�`�t�@�C��(DBR-Z150�œ���m�F)
rem ���g�����́H
rem ���̃o�b�`�ɓ]���Ώۂ̃t�@�C����D&D�������͈����Ɏw�肵�Ď��s���Ă��������B��������ꍇ�͒����]�����܂��B

rem �����ӎ�����
rem ��WoL����m�F�ς݃\�t�g�E�F�A
rem MagicSend Version 1.01(MagicSend.exe)
rem Wake-On-LAN Utility 1.5(wol.exe CUI)
rem DD-WRT(�u���[�h�L���X�g�A�h���X�͗v/32�ݒ�)
rem ��WoL����s�\�t�g�E�F�A
rem Wake up On Lan tool(wol.exe GUI)
rem �����̑�
rem �EDBR-Z150�͓d���I�t�{�^�������s���Ă�����ۂɑS��~����܂Ŗ�4�`5�����x��K�v�Ƃ��܂�(�ȃG�l�ҋ@�ݒ莞)
rem �E�u�^�C�j�[�ԑg�i�r�Q�[�^�v�Ń��R�[�_�[�̓d���̃I��/�I�t���������ꍇ�u���삷�郌�R�[�_��I������v�v���_�E������Ώۂ𖾊m�Ɏw�肵�Ď��s���邱��
rem �EWindows�ɕ����̃l�b�g���[�N�A�_�v�^����������Ă����B���̂Ȃ�IF�̃��g���b�N��������MagicPacket���Ӑ}���Ȃ�IF���瑗�o�����\�������邽�ߒ���

rem # �ڑ��擌�Ń��R�[�_�[���(MAC�A�h���X�̓n�C�t���������̓R�����ŕ������������Őݒ肵�Ă�������)
rem �@��FDBR-Z150
set REGZAREC_IP=192.168.1.100
set REGZAREC_MAC=12:34:56:78:9a:bc

rem # ���[�N�p�f�B���N�g���ݒ�
set regza_tmp_dir=I:\temp

rem # WoL�R�}���h�����s������Asleep��}�����鎞��(�b)
set wait_time=45

rem # �e��t�@�C���p�X
rem ### ts2pts(mod8)�ւ̃p�X
rem https://ja.osdn.net/projects/pmsforviera/downloads/66259/pms-setup-windows-1.74.5-VIERA.exe.zip/
set ts2pts_path=%USERPROFILE%\AppData\Local\rootfs\usr\ts2pts\ts2pts.exe

rem ### cciconv188to192�ւ̃p�X ���g�p���܂���
rem http://web.archive.org/web/20131228030958/http://bdindex.allalla.com/BD/cciconv/
set cciconv188to192_path=%USERPROFILE%\AppData\Local\rootfs\bin\cciconv188to192.exe

rem ### mk-createreq�ւ̃p�X
rem http://www1.axfc.net/uploader/File/so/44572.zip (pass:91)
set mk-createreq_path=%USERPROFILE%\AppData\Local\rootfs\bin\mk-createreq.exe

rem ### netdubhd-upload�ւ̃p�X
rem http://www1.axfc.net/uploader/File/so/44572.zip (pass:91)
set netdubhd-upload_path=%USERPROFILE%\AppData\Local\rootfs\bin\netdubhd-upload.exe

rem ### MagicSend�ւ̃p�X
rem http://www.vector.co.jp/soft/win95/net/se357465.html
set magicsend_path=%USERPROFILE%\AppData\Local\rootfs\usr\MagicSend\MagicSend.exe

rem ### Wake-On-LAN Utility(wol.exe)�ւ̃p�X
rem http://www.gammadyne.com/cmdline.htm
set wol_path=%USERPROFILE%\AppData\Local\rootfs\bin\wol.exe

rem #--- �����ݒ�I��� ---

:error_check
rem # bat ���_�u���N���b�N�Ȃ瑦�I��
if "%~1"=="" (
	rem # �G���[���b�Z�[�W�̐ݒ�
	set error_message=���̓t�@�C�����w�肵�Ă��������B
	goto :error
)
if not "%~x1"==".ts" (
	rem # �G���[���b�Z�[�W�̐ݒ�
	set error_message=���̃o�b�`��188byte��MPEG2-TS���g���q��.ts�̃t�@�C�����͂̂ݑΉ����Ă��܂��B
	goto :error
)

:param_check
rem # ARP���X�g���������邽�߂ƁAMagicSend�ɓǂݍ��܂��邽�߂ɂ̓R����(:)���n�C�t��(-)�ɕύX
set REGZAREC_MAC=%REGZAREC_MAC::=-%
set /a ping_retry_count=0
rem # �����m�F
if not exist "%regza_tmp_dir%" set regza_tmp_dir=%tmp%
if not "%regza_tmp_dir:~-1%"=="\" set regza_tmp_dir=%regza_tmp_dir%\
rem �e���s�t�@�C�����݊m�F�����PATH�T��
if not exist "%ts2pts_path%" call :find_ts2pts "%ts2pts_path%"
if "%ts2pts_path%"=="" set error_message=ts2pts��������܂���&goto :error
if not exist "%cciconv188to192_path%" call :find_cciconv188to192 "%cciconv188to192_path%"
if "%cciconv188to192_path%"=="" echo cciconv188to192��������܂���
if not exist "%mk-createreq_path%" call :find_mk-createreq "%mk-createreq_path%"
if "%mk-createreq_path%"=="" set error_message=mk-createreq_path��������܂���&goto :error
if not exist "%netdubhd-upload_path%" call :find_netdubhd-upload "%netdubhd-upload_path%"
if "%netdubhd-upload_path%"=="" set error_message=netdubhd-upload��������܂���&goto :error
if not exist "%magicsend_path%" call :find_magicsend "%magicsend_path%"
if "%magicsend_path%"=="" echo MagicSend��������܂���
if not exist "%wol_path%" call :find_wol "%wol_path%"
if "%wol_path%"=="" echo Wake-On-LAN Utility��������܂���

:main
rem # ���s�����J�n
set /a input_filesize_MB=%~z1/1048576
echo.
echo netdubhd-upload ���g����TS�t�@�C����REGZA���R�[�_�[�֓]�����܂�
echo ======================================================================
echo ���̓t�@�C��    �G%~f1
echo �t�@�C���T�C�Y  �F%input_filesize_MB% ^(MB^)
echo �]����IP�A�h���X�F%REGZAREC_IP%
echo ======================================================================
:retry_point
rem # �ڑ���z�X�g�̑��݊m�F
ping -n 1 %REGZAREC_IP% | find "ms TTL=" > NUL
if ERRORLEVEL 1 (
	if %ping_retry_count% GTR 1 (
		echo �]�����REGZA���R�[�_�[�̋N�����m�F�ł��܂���ł����B
		echo �N�����Ă��邩�A�������͑Ώ�IP�A�h���X���Ԉ���Ă��Ȃ����m�F���Ă��������B
		echo Windows�͕����̃l�b�g���[�N�A�_�v�^�[����������Ă���ꍇ�AMagic Packet��
		echo �Ӑ}�����Ƃ����IF���瑗�o����Ȃ��\��������܂��̂Œ��ӂ��Ă��������B
		echo �������I�����܂��B
		set error_message=�]����z�X�g���m�F�ł��܂���B
		goto :error
	) else (
		call :wakeup_recorder
		goto :retry_point
	)
)
echo ### �J�n����[%time%] ###
echo �]����IP�A�h���X�F%REGZAREC_IP%
echo.
set input_media_path=%~f1
if "%input_media_path:~0,2%"=="\\" (
	call :remote_media_detect "%~1"
) else (
	call :local_media_detect "%~1"
)
call :exec_ts2pts_job  "%~1"
call :exec_mk-createreq_job "%~1"
call :exec_netdubhd-upload_job "%~1"
call :delete_tmp_files "%~1"
echo ### �I������[%time%] ###
set input_media_path=
set trancefer_media_path=
set /a ping_retry_count=0
rem ### �o�b�`�p�����[�^���V�t�g ###
rem # %9 �� %8 �ɁA... %1 �� %0 ��
shift /1
rem # �o�b�`�p�����[�^����Ȃ�I��
if "%~1"=="" (
	echo.
	echo �S�Ă̓]���������������܂����B
	echo �u�^�C�j�[�ԑg�i�r�Q�[�^�v�Ȃǂ�REGZA���R�[�_�̓d�����I�t�ɂ��Ă��������B
	echo.
	pause
	exit /b
)
echo ------------------------------
echo.
goto :main
rem # main�֐���
exit /b

:remote_media_detect
echo "%input_media_path%" �������[�g�t�H���_��ɑ��݂��邽�߁A���[�J���Ɉ�U�R�s�[���܂�
echo �R�s�[��F%regza_tmp_dir%
copy "%input_media_path%" "%regza_tmp_dir%%~nx1"
set trancefer_media_path=%regza_tmp_dir%%~nx1
echo.
exit /b

:local_media_detect
echo "%input_media_path%" �����̂܂܏������܂�
set trancefer_media_path=%input_media_path%
echo.
exit /b

:exec_ts2pts_job
echo 188byte MPEG2-TS���A192byte MPEG2-PTS�ɕϊ����܂�
rem # BD����-b�I�v�V������p���ďo�͂��ꂽ188byte�t�@�C���ł�mk-createreq���������ԑg���𒊏o���邱�Ƃ��ł��܂���
rem # ts2pts�ŃI�v�V�����Ȃ���PTS�t�@�C���ϊ��̂ݎ��{���A���̌�cciconv188to192 -b�Ńp�P�b�g�ϊ����邱�Ƃ��\�ł�
echo ts2pts ���s�W���u
echo "%ts2pts_path%" -i "%trancefer_media_path%" -o "%regza_tmp_dir%%~n1.m2ts" -f
"%ts2pts_path%" -i "%trancefer_media_path%" -o "%regza_tmp_dir%%~n1.m2ts" -f
echo.
exit /b

:exec_mk-createreq_job
echo �g���q.req�̔ԑg���t�@�C�����쐬���܂�
echo mk-createreq ���s�W���u
echo echo y ^| "%mk-createreq_path%" "%regza_tmp_dir%%~n1.m2ts"
echo y | "%mk-createreq_path%" "%regza_tmp_dir%%~n1.m2ts"
echo.
exit /b

:exec_netdubhd-upload_job
echo �����[�gDLNA�T�[�o(%REGZAREC_IP%)�ɑ΂��ăt�@�C����]�����܂�
echo netdubhd-upload ���s�W���u
echo "%netdubhd-upload_path%" %REGZAREC_IP% "%regza_tmp_dir%%~n1.m2ts"
"%netdubhd-upload_path%" %REGZAREC_IP% "%regza_tmp_dir%%~n1.m2ts"
if ERRORLEVEL 1 (
	echo ���]�������s���܂�����
) else (
	echo �]������
)
echo.
exit /b

:delete_tmp_files
echo �e��ꎞ�t�@�C�����폜���܂�
if exist "%regza_tmp_dir%%~nx1" del "%regza_tmp_dir%%~nx1"
if exist "%regza_tmp_dir%%~n1.m2ts" del "%regza_tmp_dir%%~n1.m2ts"
if exist "%regza_tmp_dir%%~n1.req" del "%regza_tmp_dir%%~n1.req"
echo.
exit /b

:find_ts2pts
echo findexe�����F"%~1"
echo �Ώۂ̎��s�t�@�C����������܂���A�V�X�e���̊��ϐ���T�����܂��B
set ts2pts_path=%~$PATH:1
exit /b

:find_cciconv188to192
echo findexe�����F"%~1"
echo �Ώۂ̎��s�t�@�C����������܂���A�V�X�e���̊��ϐ���T�����܂��B
set cciconv188to192_path=%~$PATH:1
exit /b

:find_mk-createreq
echo findexe�����F"%~1"
echo �Ώۂ̎��s�t�@�C����������܂���A�V�X�e���̊��ϐ���T�����܂��B
set mk-createreq_path=%~$PATH:1
exit /b

:find_netdubhd-upload
echo findexe�����F"%~1"
echo �Ώۂ̎��s�t�@�C����������܂���A�V�X�e���̊��ϐ���T�����܂��B
set netdubhd-upload_path=%~$PATH:1
exit /b

:find_magicsend
echo findexe�����F"%~1"
echo �Ώۂ̎��s�t�@�C����������܂���A�V�X�e���̊��ϐ���T�����܂��B
set magicsend_path=%~$PATH:1
exit /b

:find_wol
echo findexe�����F"%~1"
echo �Ώۂ̎��s�t�@�C����������܂���A�V�X�e���̊��ϐ���T�����܂��B
set wol_path=%~$PATH:1
exit /b

:wakeup_recorder
set /a ping_retry_count=ping_retry_count+1
echo �]����z�X�g^(%REGZAREC_IP%^)���牞��������܂���B
echo Wake On Lan�ŋN�������݂܂��B^(%ping_retry_count% ���^)
if exist "%magicsend_path%" (
	echo MagicSend ��Magic Packet�𑗏o���܂��B
	echo "%magicsend_path%" %REGZAREC_MAC%
	"%magicsend_path%" %REGZAREC_MAC%
) else if exist "%wol_path%"  (
	echo Wake-On-LAN Utility ��Magic Packet�𑗏o���܂��B
	echo "%wol_path%" %REGZAREC_MAC:-=%
	"%wol_path%" %REGZAREC_MAC:-=%
) else (
	set error_message=Wake On Lan�Ή��c�[����������܂���B
	goto :error
)
echo %wait_time% �b�ԑҋ@���܂��B
timeout /T %wait_time%
for /f "usebackq eol=# tokens=1 delims= " %%I in (`arp -a ^| findstr /r "%REGZAREC_MAC%"`) do (
	if not "%%I"=="%REGZAREC_IP%" (
		echo ARP���X�g����擾����IP�A�h���X�����[�U�[�ɂ���Đݒ肳�ꂽ���̂ƈقȂ�܂��B
		echo �]����IP�A�h���X��ARP���X�g�̂��̂ɒu�������܂��B
		set REGZAREC_IP=%%I
		echo.
		exit /b
	)
)
echo.
exit /b

:error
echo.
echo ### �G���[�I ###
echo.
echo %error_message%
echo.
pause
exit /b
