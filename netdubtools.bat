@echo off
setlocal

rem ●これは何？
rem コピーフリーのTSファイル(188byteパケット)を変換し、対象のREGZAレコーダー(DLNAサーバ)へ転送するバッチファイル(DBR-Z150で動作確認)
rem ●使い方は？
rem このバッチに転送対象のファイルをD&Dもしくは引数に指定して実行してください。複数ある場合は逐次転送します。

rem ※注意事項※
rem ●WoL動作確認済みソフトウェア
rem MagicSend Version 1.01(MagicSend.exe)
rem Wake-On-LAN Utility 1.5(wol.exe CUI)
rem DD-WRT(ブロードキャストアドレスは要/32設定)
rem ●WoL動作不可ソフトウェア
rem Wake up On Lan tool(wol.exe GUI)
rem ●その他
rem ・DBR-Z150は電源オフボタンを実行してから実際に全停止するまで約4～5分程度を必要とします(省エネ待機設定時)
rem ・「タイニー番組ナビゲータ」でレコーダーの電源のオン/オフ操作をする場合「操作するレコーダを選択する」プルダウンから対象を明確に指定して実行すること
rem ・Windowsに複数のネットワークアダプタが実装されてかつ到達性のないIFのメトリックが高いとMagicPacketが意図しないIFから送出される可能性があるため注意

rem # 接続先東芝レコーダー情報(MACアドレスはハイフンもしくはコロンで分割した書式で設定してください)
rem 機種：DBR-Z150
set REGZAREC_IP=192.168.1.100
set REGZAREC_MAC=12:34:56:78:9a:bc

rem # ワーク用ディレクトリ設定
set regza_tmp_dir=I:\temp

rem # WoLコマンドを実行した後、sleepを挿入する時間(秒)
set wait_time=45

rem # 各種ファイルパス
rem ### ts2pts(mod8)へのパス
rem https://ja.osdn.net/projects/pmsforviera/downloads/66259/pms-setup-windows-1.74.5-VIERA.exe.zip/
set ts2pts_path=%USERPROFILE%\AppData\Local\rootfs\usr\ts2pts\ts2pts.exe

rem ### cciconv188to192へのパス ※使用しません
rem http://web.archive.org/web/20131228030958/http://bdindex.allalla.com/BD/cciconv/
set cciconv188to192_path=%USERPROFILE%\AppData\Local\rootfs\bin\cciconv188to192.exe

rem ### mk-createreqへのパス
rem http://www1.axfc.net/uploader/File/so/44572.zip (pass:91)
set mk-createreq_path=%USERPROFILE%\AppData\Local\rootfs\bin\mk-createreq.exe

rem ### netdubhd-uploadへのパス
rem http://www1.axfc.net/uploader/File/so/44572.zip (pass:91)
set netdubhd-upload_path=%USERPROFILE%\AppData\Local\rootfs\bin\netdubhd-upload.exe

rem ### MagicSendへのパス
rem http://www.vector.co.jp/soft/win95/net/se357465.html
set magicsend_path=%USERPROFILE%\AppData\Local\rootfs\usr\MagicSend\MagicSend.exe

rem ### Wake-On-LAN Utility(wol.exe)へのパス
rem http://www.gammadyne.com/cmdline.htm
set wol_path=%USERPROFILE%\AppData\Local\rootfs\bin\wol.exe

rem #--- 初期設定終わり ---

:error_check
rem # bat をダブルクリックなら即終了
if "%~1"=="" (
	rem # エラーメッセージの設定
	set error_message=入力ファイルを指定してください。
	goto :error
)
if not "%~x1"==".ts" (
	rem # エラーメッセージの設定
	set error_message=このバッチは188byteのMPEG2-TSかつ拡張子が.tsのファイル入力のみ対応しています。
	goto :error
)

:param_check
rem # ARPリストを検索するためと、MagicSendに読み込ませるためにはコロン(:)をハイフン(-)に変更
set REGZAREC_MAC=%REGZAREC_MAC::=-%
set /a ping_retry_count=0
rem # 環境情報確認
if not exist "%regza_tmp_dir%" set regza_tmp_dir=%tmp%
if not "%regza_tmp_dir:~-1%"=="\" set regza_tmp_dir=%regza_tmp_dir%\
rem 各実行ファイル存在確認およびPATH探索
if not exist "%ts2pts_path%" call :find_ts2pts "%ts2pts_path%"
if "%ts2pts_path%"=="" set error_message=ts2ptsが見つかりません&goto :error
if not exist "%cciconv188to192_path%" call :find_cciconv188to192 "%cciconv188to192_path%"
if "%cciconv188to192_path%"=="" echo cciconv188to192が見つかりません
if not exist "%mk-createreq_path%" call :find_mk-createreq "%mk-createreq_path%"
if "%mk-createreq_path%"=="" set error_message=mk-createreq_pathが見つかりません&goto :error
if not exist "%netdubhd-upload_path%" call :find_netdubhd-upload "%netdubhd-upload_path%"
if "%netdubhd-upload_path%"=="" set error_message=netdubhd-uploadが見つかりません&goto :error
if not exist "%magicsend_path%" call :find_magicsend "%magicsend_path%"
if "%magicsend_path%"=="" echo MagicSendが見つかりません
if not exist "%wol_path%" call :find_wol "%wol_path%"
if "%wol_path%"=="" echo Wake-On-LAN Utilityが見つかりません

:main
rem # 実行処理開始
set /a input_filesize_MB=%~z1/1048576
echo.
echo netdubhd-upload を使ってTSファイルをREGZAレコーダーへ転送します
echo ======================================================================
echo 入力ファイル    ；%~f1
echo ファイルサイズ  ：%input_filesize_MB% ^(MB^)
echo 転送先IPアドレス：%REGZAREC_IP%
echo ======================================================================
:retry_point
rem # 接続先ホストの存在確認
ping -n 1 %REGZAREC_IP% | find "ms TTL=" > NUL
if ERRORLEVEL 1 (
	if %ping_retry_count% GTR 1 (
		echo 転送先のREGZAレコーダーの起動が確認できませんでした。
		echo 起動しているか、もしくは対象IPアドレスを間違っていないか確認してください。
		echo Windowsは複数のネットワークアダプターが実装されている場合、Magic Packetが
		echo 意図したとおりのIFから送出されない可能性がありますので注意してください。
		echo 処理を終了します。
		set error_message=転送先ホストが確認できません。
		goto :error
	) else (
		call :wakeup_recorder
		goto :retry_point
	)
)
echo ### 開始時刻[%time%] ###
echo 転送先IPアドレス：%REGZAREC_IP%
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
echo ### 終了時刻[%time%] ###
set input_media_path=
set trancefer_media_path=
set /a ping_retry_count=0
rem ### バッチパラメータをシフト ###
rem # %9 は %8 に、... %1 は %0 に
shift /1
rem # バッチパラメータが空なら終了
if "%~1"=="" (
	echo.
	echo 全ての転送処理が完了しました。
	echo 「タイニー番組ナビゲータ」などでREGZAレコーダの電源をオフにしてください。
	echo.
	pause
	exit /b
)
echo ------------------------------
echo.
goto :main
rem # main関数閉じ
exit /b

:remote_media_detect
echo "%input_media_path%" がリモートフォルダ上に存在するため、ローカルに一旦コピーします
echo コピー先：%regza_tmp_dir%
copy "%input_media_path%" "%regza_tmp_dir%%~nx1"
set trancefer_media_path=%regza_tmp_dir%%~nx1
echo.
exit /b

:local_media_detect
echo "%input_media_path%" をこのまま処理します
set trancefer_media_path=%input_media_path%
echo.
exit /b

:exec_ts2pts_job
echo 188byte MPEG2-TSを、192byte MPEG2-PTSに変換します
rem # BD向け-bオプションを用いて出力された188byteファイルではmk-createreqが正しく番組情報を抽出することができません
rem # ts2ptsでオプションなしのPTSファイル変換のみ実施し、その後cciconv188to192 -bでパケット変換することも可能です
echo ts2pts 実行ジョブ
echo "%ts2pts_path%" -i "%trancefer_media_path%" -o "%regza_tmp_dir%%~n1.m2ts" -f
"%ts2pts_path%" -i "%trancefer_media_path%" -o "%regza_tmp_dir%%~n1.m2ts" -f
echo.
exit /b

:exec_mk-createreq_job
echo 拡張子.reqの番組情報ファイルを作成します
echo mk-createreq 実行ジョブ
echo echo y ^| "%mk-createreq_path%" "%regza_tmp_dir%%~n1.m2ts"
echo y | "%mk-createreq_path%" "%regza_tmp_dir%%~n1.m2ts"
echo.
exit /b

:exec_netdubhd-upload_job
echo リモートDLNAサーバ(%REGZAREC_IP%)に対してファイルを転送します
echo netdubhd-upload 実行ジョブ
echo "%netdubhd-upload_path%" %REGZAREC_IP% "%regza_tmp_dir%%~n1.m2ts"
"%netdubhd-upload_path%" %REGZAREC_IP% "%regza_tmp_dir%%~n1.m2ts"
if ERRORLEVEL 1 (
	echo ※転送が失敗しました※
) else (
	echo 転送完了
)
echo.
exit /b

:delete_tmp_files
echo 各種一時ファイルを削除します
if exist "%regza_tmp_dir%%~nx1" del "%regza_tmp_dir%%~nx1"
if exist "%regza_tmp_dir%%~n1.m2ts" del "%regza_tmp_dir%%~n1.m2ts"
if exist "%regza_tmp_dir%%~n1.req" del "%regza_tmp_dir%%~n1.req"
echo.
exit /b

:find_ts2pts
echo findexe引数："%~1"
echo 対象の実行ファイルが見つかりません、システムの環境変数を探索します。
set ts2pts_path=%~$PATH:1
exit /b

:find_cciconv188to192
echo findexe引数："%~1"
echo 対象の実行ファイルが見つかりません、システムの環境変数を探索します。
set cciconv188to192_path=%~$PATH:1
exit /b

:find_mk-createreq
echo findexe引数："%~1"
echo 対象の実行ファイルが見つかりません、システムの環境変数を探索します。
set mk-createreq_path=%~$PATH:1
exit /b

:find_netdubhd-upload
echo findexe引数："%~1"
echo 対象の実行ファイルが見つかりません、システムの環境変数を探索します。
set netdubhd-upload_path=%~$PATH:1
exit /b

:find_magicsend
echo findexe引数："%~1"
echo 対象の実行ファイルが見つかりません、システムの環境変数を探索します。
set magicsend_path=%~$PATH:1
exit /b

:find_wol
echo findexe引数："%~1"
echo 対象の実行ファイルが見つかりません、システムの環境変数を探索します。
set wol_path=%~$PATH:1
exit /b

:wakeup_recorder
set /a ping_retry_count=ping_retry_count+1
echo 転送先ホスト^(%REGZAREC_IP%^)から応答がありません。
echo Wake On Lanで起動を試みます。^(%ping_retry_count% 回目^)
if exist "%magicsend_path%" (
	echo MagicSend でMagic Packetを送出します。
	echo "%magicsend_path%" %REGZAREC_MAC%
	"%magicsend_path%" %REGZAREC_MAC%
) else if exist "%wol_path%"  (
	echo Wake-On-LAN Utility でMagic Packetを送出します。
	echo "%wol_path%" %REGZAREC_MAC:-=%
	"%wol_path%" %REGZAREC_MAC:-=%
) else (
	set error_message=Wake On Lan対応ツールが見つかりません。
	goto :error
)
echo %wait_time% 秒間待機します。
timeout /T %wait_time%
for /f "usebackq eol=# tokens=1 delims= " %%I in (`arp -a ^| findstr /r "%REGZAREC_MAC%"`) do (
	if not "%%I"=="%REGZAREC_IP%" (
		echo ARPリストから取得したIPアドレスがユーザーによって設定されたものと異なります。
		echo 転送先IPアドレスをARPリストのものに置き換えます。
		set REGZAREC_IP=%%I
		echo.
		exit /b
	)
)
echo.
exit /b

:error
echo.
echo ### エラー！ ###
echo.
echo %error_message%
echo.
pause
exit /b
