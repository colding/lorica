;
;  lorica.nsi
;
;  Copyright (C) 2009 42tools ApS. All Rights Reserved.

;  ------------------------------------------
;       Installation script for Lorica
;  ------------------------------------------
;

;================================================================
; Header Files

!include "MUI2.nsh"
!include "Sections.nsh"
!include "LogicLib.nsh"
!include "WinVer.nsh"
!include "Memento.nsh"
!include "WordFunc.nsh"
!include "servicelib.nsh"
!include "EnvVarUpdate.nsh"

;================================================================
; Definitions

!define NAME 'Lorica'

; Lorica house keeping registry keys
!define 42TOOLS_COMPANY_REGKEY "SOFTWARE\42tools" 
!define BRUTUS_SERVER_REGKEY "${42TOOLS_COMPANY_REGKEY}\Brutus_Server" 
!define LORICA_REGKEY "${42TOOLS_COMPANY_REGKEY}\${NAME}" 
!define LORICA_UNINSTALL_REGKEY "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}"

!define VER_MAJOR '1'
!define VER_MINOR '0'
!define VER_REVISION '13'
!define VER_BUILD '0'
!define VERSION "${VER_MAJOR}.${VER_MINOR}.${VER_REVISION}"

; Windows services
!define LORICA_SERVICE_DESCRIPTION 'Lorica is a CORBA firewall conduit. Such products are commonly known as CORBA Firewalls.\lang1033\f1 Lorica is an open-source project developed and supported by 42tools. For more information and support regarding Lorica please use our homepage at http://www.42tools.com/.'
!define LORICA_SERVICE_NAME 'Lorica'

;================================================================
; Language Selection Dialog Settings

;Remember the installer language
!define MUI_LANGDLL_REGISTRY_ROOT "HKCU" 
!define MUI_LANGDLL_REGISTRY_KEY "${LORICA_REGKEY}" 
!define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"


;================================================================
; Configuration

; The name of the installer
Name "${NAME}"

; Caption
Caption "${NAME} ${VERSION} Setup"

; The file to write
OutFile "brutus-install.exe"

; CRC check
CRCCheck on

; XP look
XPStyle on

; Version Information
VIProductVersion "${VERSION}.${VER_BUILD}"
VIAddVersionKey "ProductName" "Lorica"
VIAddVersionKey "Comments" "Lorica is a generic CORBA firlewall conduit"
VIAddVersionKey "CompanyName" "42tools ApS"
VIAddVersionKey "LegalTrademarks" ""
VIAddVersionKey "LegalCopyright" "Copyright (C) 42tools ApS. All rights reserved."
VIAddVersionKey "FileDescription" "Lorica"
VIAddVersionKey "FileVersion" "${VERSION}"

; The default installation directory
InstallDir $PROGRAMFILES\Lorica

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM ${LORICA_REGKEY} ""

; Request application privileges for Windows Vista
RequestExecutionLevel admin

;================================================================
; Functions

!ifdef VER_MAJOR & VER_MINOR & VER_REVISION & VER_BUILD
  !insertmacro VersionCompare
!endif


;================================================================
; Pages

;Memento Settings
!define MEMENTO_REGISTRY_ROOT HKLM
!define MEMENTO_REGISTRY_KEY "${LORICA_UNINSTALL_REGKEY}"

;Interface Settings
!define MUI_ABORTWARNING

!define MUI_HEADERIMAGE

!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\orange.bmp"
!define MUI_WELCOMEPAGE_TITLE "Welcome to the ${NAME} ${VERSION} Setup Wizard"
!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of ${NAME} ${VERSION}. ${NAME} is a Windows based CORBA server which facilitates firewall traversal and network configuration for CORBA servers. For more information and support regarding Lorica please use our homepage at http://www.42tools.com/.$\r$\n$\r$\nThis is a FLOSS release of ${NAME} and you must abide by the terms of the GNU Affero General Public License.$\r$\n$\r$\nEnjoy,$\r$\n  The Lorica team at 42tools$\r$\n$\r$\n$_CLICK"
!insertmacro MUI_PAGE_WELCOME

!define MUI_LICENSEPAGE_RADIOBUTTONS
!insertmacro MUI_PAGE_LICENSE "../COPYING"

!ifdef VER_MAJOR & VER_MINOR & VER_REVISION & VER_BUILD
Page custom PageReinstall PageLeaveReinstall
!endif

!insertmacro MUI_PAGE_DIRECTORY

!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_NOREBOOTSUPPORT
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

;================================================================
; Languages

!insertmacro MUI_LANGUAGE "English"


;================================================================
; Reserve Files
  
;If you are using solid compression, files that are required before
;the actual installation should be stored first in the data block,
;because this will make your installer start faster.
  
!insertmacro MUI_RESERVEFILE_LANGDLL


;================================================================
; Installer Sections

${MementoSection} "" SecCore

  ; Check for and uninstall previous MSI package
  Call removeMSI
  
  ; Check for running Lorica service from previous NSIS installation
  !insertmacro SERVICE "installed" "${LORICA_SERVICE_NAME}" ""
  Pop $0
  StrCmp $0 "true" stop_lorica copy_files
  stop_lorica:
  DetailPrint "Waiting for ${LORICA_SERVICE_NAME} to stop..."
  !insertmacro SERVICE "stop" "${LORICA_SERVICE_NAME}" ""
  wait_for_lorica_to_stop:
  Sleep 100
  !insertmacro SERVICE "status" "${LORICA_SERVICE_NAME}" ""
  Pop $0
  StrCmp $0 "stopped" lorica_stopped wait_for_lorica_to_stop
  lorica_stopped:
  DetailPrint "${LORICA_SERVICE_NAME} service stopped"

  Sleep 500
  copy_files:
      
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  SetOverwrite on

  ; Put files there
  File "${NSISDIR}\Contrib\Graphics\Wizard\orange.bmp"
  File "..\..\..\..\..\ACE_wrappers\lib\ACE.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\ACE_SSL.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_AnyTypeCode.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_BiDirGIOP.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_CodecFactory.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_Codeset.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_DynamicAny.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_DynamicInterface.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_EndpointPolicy.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_IDL_BE.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_IDL_FE.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_IFRService.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_IFR_BE.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_IFR_Client.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_IORTable.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_ImR_Client.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_Messaging.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_PI.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_PI_Server.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_PortableServer.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_SSLIOP.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_Security.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_Svc_Utils.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_TypeCodeFactory.dll"
  File "..\..\..\..\..\ACE_wrappers\lib\TAO_Valuetype.dll"
  File "..\..\..\..\..\ACE_wrappers\TAO\orbsvcs\IFR_Service\Release\IFR_Service.exe"
  File "..\..\..\..\..\ACE_wrappers\bin\tao_ifr.exe"
  File "..\..\..\openssl\out32dll\libeay32.dll"
  File "..\..\..\openssl\out32dll\libeay32.dll.manifest"
  File "..\..\..\openssl\out32dll\ssleay32.dll"
  File "..\..\..\openssl\out32dll\ssleay32.dll.manifest"
  File "..\..\redist\Microsoft.VC90.CRT.manifest"
  File "..\..\redist\msvcp90.dll"
  File "..\..\redist\msvcr90.dll"
  File "..\bin\lorica.exe"
  File "..\lib\OCI_AsynchProxyTools.dll"
  File "..\lib\lorica_Client.dll"
  File "..\lib\lorica_EvaluatorBase.dll"
  File "..\lib\lorica_GenericEvaluator.dll"
  File "..\docs\Lorica.txt"

  SetOverwrite off
  File "..\src\proxy\lorica.conf"
  File "..\src\proxy\lorica.ssliop"
  SetOverwrite on
  
  ; Start Menu Shortcuts
  CreateDirectory "$SMPROGRAMS\${NAME}"
  CreateShortCut "$SMPROGRAMS\${NAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\${NAME}\Lorica.lnk" "$INSTDIR\Lorica.txt" "" "$INSTDIR\Lorica.txt" 0 

${MementoSectionEnd}

Section -post
  SetDetailsPrint textonly
  DetailPrint "Creating Registry Keys..."
  SetDetailsPrint listonly

  SetOutPath $INSTDIR

  ; Write the installation path into the registry
  WriteRegStr HKLM "${LORICA_REGKEY}" "" "$INSTDIR"
!ifdef VER_MAJOR & VER_MINOR & VER_REVISION & VER_BUILD
  WriteRegDword HKLM "${LORICA_REGKEY}" "VersionMajor" "${VER_MAJOR}"
  WriteRegDword HKLM "${LORICA_REGKEY}" "VersionMinor" "${VER_MINOR}"
  WriteRegDword HKLM "${LORICA_REGKEY}" "VersionRevision" "${VER_REVISION}"
  WriteRegDword HKLM "${LORICA_REGKEY}" "VersionBuild" "${VER_BUILD}"
!endif

  WriteRegExpandStr HKLM "${LORICA_UNINSTALL_REGKEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegExpandStr HKLM "${LORICA_UNINSTALL_REGKEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "${LORICA_UNINSTALL_REGKEY}" "DisplayName" "${NAME}"
  WriteRegStr HKLM "${LORICA_UNINSTALL_REGKEY}" "DisplayIcon" "$INSTDIR\brutus.ico"
  WriteRegStr HKLM "${LORICA_UNINSTALL_REGKEY}" "DisplayVersion" "${VERSION}"
!ifdef VER_MAJOR & VER_MINOR & VER_REVISION & VER_BUILD
  WriteRegDWORD HKLM "${LORICA_UNINSTALL_REGKEY}" "VersionMajor" "${VER_MAJOR}"
  WriteRegDWORD HKLM "${LORICA_UNINSTALL_REGKEY}" "VersionMinor" "${VER_MINOR}.${VER_REVISION}"
!endif
  WriteRegStr HKLM "${LORICA_UNINSTALL_REGKEY}" "URLInfoAbout" "http://www.42tools.com/"
  WriteRegStr HKLM "${LORICA_UNINSTALL_REGKEY}" "HelpLink" "http://www.42tools.com/support"
  WriteRegDWORD HKLM "${LORICA_UNINSTALL_REGKEY}" "NoModify" "1"
  WriteRegDWORD HKLM "${LORICA_UNINSTALL_REGKEY}" "NoRepair" "1"

  ; Add to %PATH%
  SetDetailsPrint textonly
  DetailPrint "Adjusting the system PATH..."
  SetDetailsPrint listonly
  ${EnvVarUpdate} $0 "PATH" "P" "HKLM" "$INSTDIR"

  ; Create Windows service
  SetDetailsPrint textonly
  DetailPrint "Creating Windows service..."
  SetDetailsPrint listonly
  !insertmacro SERVICE create "${LORICA_SERVICE_NAME}" "path=$INSTDIR\lorica.exe;autostart=1;interact=0;display=${LORICA_SERVICE_NAME};description=${LORICA_SERVICE_DESCRIPTION};"

  ; Write service recovery options
  ExecWait '"sc.exe" failure ${LORICA_SERVICE_NAME} reset= 864000 actions= restart/60000/restart/60000/restart/60000'

  WriteUninstaller "uninstall.exe"

  SetDetailsPrint both
SectionEnd

${MementoSectionDone}

;================================================================
; Installer Functions

Function .onInit
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "myMutex") i .r1 ?e'
    Pop $R0
 
  StrCmp $R0 0 +3
    MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running."
    Abort

  ${IfNot} ${AtLeastWin2000}
    MessageBox MB_OK|MB_ICONEXCLAMATION "${NAME} requires Windows 2000 or above"
    Quit
  ${EndIf}

  ; Check for presence of new Brutus Server
  push $R0
  ReadRegStr $R0 HKLM "${BRUTUS_SERVER_REGKEY}" ""
  ${IfNot} $R0 == ""
    MessageBox MB_OK|MB_ICONEXCLAMATION "${NAME} should not be installed alongside Brutus"
    Abort
  ${EndIf}
  pop $R0

  ; Check for presence of old Brutus Server
  push $R0
  ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\{7CB89BC2-42C2-48FD-8559-7B7D25E7871D}" "UninstallString"
  ${IfNot} $R0 == ""
    MessageBox MB_OK|MB_ICONEXCLAMATION "${NAME} should not be installed alongside Brutus"
    Abort
  ${EndIf}
  pop $R0

  ${MementoSectionRestore}
FunctionEnd

Function .onInstSuccess
  ${MementoSectionSave}
FunctionEnd

; Check for presence of old MSI version
; and prompts the user to remove it
Function removeMSI
  DetailPrint "Checking for old version"
  push $R0
  ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\{10F149F2-D0A3-4F62-A6DA-2BA0EE7BFB3E}" "UninstallString"
  StrCmp $R0 "" removeMSI_nomsi
    MessageBox MB_YESNOCANCEL|MB_ICONQUESTION  "A previous version of ${NAME} was found. You must uninstall it first.$\n$\nDo you want to do that now?" IDNO removeMSI_nomsi IDYES removeMSI_yesmsi
      Abort
removeMSI_yesmsi:
    DetailPrint "Removing old version"
    ExecWait "$R0"
removeMSI_nomsi: 
  pop $R0
FunctionEnd

;================================================================
; Uninstaller Functions

Function un.onInit
  !insertmacro MUI_UNGETLANGUAGE
FunctionEnd


!ifdef VER_MAJOR & VER_MINOR & VER_REVISION & VER_BUILD

Var ReinstallPageCheck

Function PageReinstall
  ReadRegStr $R0 HKLM "${LORICA_REGKEY}" ""

  ; Check for presence of Lorica
  ${If} $R0 == ""
    Abort
  ${EndIf}

  ReadRegDWORD $R0 HKLM "${LORICA_REGKEY}" "VersionMajor"
  ReadRegDWORD $R1 HKLM "${LORICA_REGKEY}" "VersionMinor"
  ReadRegDWORD $R2 HKLM "${LORICA_REGKEY}" "VersionRevision"
  ReadRegDWORD $R3 HKLM "${LORICA_REGKEY}" "VersionBuild"
  StrCpy $R0 $R0.$R1.$R2.$R3

  ${VersionCompare} ${VER_MAJOR}.${VER_MINOR}.${VER_REVISION}.${VER_BUILD} $R0 $R0
  ${If} $R0 == 0
    StrCpy $R1 "${NAME} ${VERSION} is already installed. Select the operation you want to perform and click Next to continue."
    StrCpy $R2 "Reinstall ${NAME}"
    StrCpy $R3 "Uninstall ${NAME}"
    !insertmacro MUI_HEADER_TEXT "Already Installed" "Choose the maintenance option to perform."
    StrCpy $R0 "2"
  ${ElseIf} $R0 == 1
    StrCpy $R1 "An older version of ${NAME} is installed on your system. It's recommended that you uninstall the current version before installing. Select the operation you want to perform and click Next to continue."
    StrCpy $R2 "Uninstall before installing"
    StrCpy $R3 "Do not uninstall"
    !insertmacro MUI_HEADER_TEXT "Already Installed" "Choose how you want to install ${NAME}."
    StrCpy $R0 "1"
  ${ElseIf} $R0 == 2
    StrCpy $R1 "A newer version of ${NAME} is already installed! It is not recommended that you install an older version. If you really want to install this older version, it's recommended to uninstall the current version first. Select the operation you want to perform and click Next to continue."
    StrCpy $R2 "Uninstall before installing"
    StrCpy $R3 "Do not uninstall"
    !insertmacro MUI_HEADER_TEXT "Already Installed" "Choose how you want to install ${NAME}."
    StrCpy $R0 "1"
  ${Else}
    Abort
  ${EndIf}

  nsDialogs::Create 1018
  Pop $R4

  ${NSD_CreateLabel} 0 0 100% 24u $R1
  Pop $R1

  ${NSD_CreateRadioButton} 30u 50u -30u 8u $R2
  Pop $R2
  ${NSD_OnClick} $R2 PageReinstallUpdateSelection

  ${NSD_CreateRadioButton} 30u 70u -30u 8u $R3
  Pop $R3
  ${NSD_OnClick} $R3 PageReinstallUpdateSelection

  ${If} $ReinstallPageCheck != 2
    SendMessage $R2 ${BM_SETCHECK} ${BST_CHECKED} 0
  ${Else}
    SendMessage $R3 ${BM_SETCHECK} ${BST_CHECKED} 0
  ${EndIf}

  ${NSD_SetFocus} $R2

  nsDialogs::Show
FunctionEnd

Function PageReinstallUpdateSelection
  Pop $R1

  ${NSD_GetState} $R2 $R1

  ${If} $R1 == ${BST_CHECKED}
    StrCpy $ReinstallPageCheck 1
  ${Else}
    StrCpy $ReinstallPageCheck 2
  ${EndIf}
FunctionEnd

Function PageLeaveReinstall
  ${NSD_GetState} $R2 $R1

  StrCmp $R0 "1" 0 +2
    StrCmp $R1 "1" reinst_uninstall reinst_done

  StrCmp $R0 "2" 0 +3
    StrCmp $R1 "1" reinst_done reinst_uninstall

  reinst_uninstall:
  ReadRegStr $R1 HKLM "${LORICA_UNINSTALL_REGKEY}" "UninstallString"

  ;Run uninstaller
  HideWindow

    ClearErrors
    ExecWait '$R1 _?=$INSTDIR'

    IfErrors no_remove_uninstaller
      Delete $R1
      RMDir $INSTDIR
    no_remove_uninstaller:

  StrCmp $R0 "2" 0 +2
    Quit

  BringToFront

  reinst_done:
FunctionEnd

!endif # VER_MAJOR & VER_MINOR & VER_REVISION & VER_BUILD

;================================================================
; Uninstaller Section

Section Uninstall
  !ifdef UN
    !undef UN
  !endif
  !define UN "un."

  ; Stop Lorica
  DetailPrint "Waiting for ${LORICA_SERVICE_NAME} to stop..."
  !insertmacro SERVICE "stop" "${LORICA_SERVICE_NAME}" ""
  wait_for_lorica_to_stop:
  Sleep 500
  !insertmacro SERVICE "status" "${LORICA_SERVICE_NAME}" ""
  Pop $0
  StrCmp $0 "stopped" lorica_stopped wait_for_lorica_to_stop
  lorica_stopped:
  DetailPrint "OK"
          
  ; Now remove Windows service
  !insertmacro SERVICE delete "${LORICA_SERVICE_NAME}" ""

  ; Remove from %PATH%
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR"
  
  ; Remove registry keys
  DeleteRegKey HKLM ${LORICA_UNINSTALL_REGKEY} 
  DeleteRegKey HKLM ${LORICA_REGKEY}
  DeleteRegKey /ifempty HKLM ${42TOOLS_COMPANY_REGKEY}
  
  ; Remove files and uninstaller
  Delete "$INSTDIR\orange.bmp"
  Delete "$INSTDIR\ACE.dll"
  Delete "$INSTDIR\ACE_SSL.dll"
  Delete "$INSTDIR\TAO.dll"
  Delete "$INSTDIR\TAO_AnyTypeCode.dll"
  Delete "$INSTDIR\TAO_BiDirGIOP.dll"
  Delete "$INSTDIR\TAO_CodecFactory.dll"
  Delete "$INSTDIR\TAO_Codeset.dll"
  Delete "$INSTDIR\TAO_DynamicAny.dll"
  Delete "$INSTDIR\TAO_DynamicInterface.dll"
  Delete "$INSTDIR\TAO_EndpointPolicy.dll"
  Delete "$INSTDIR\TAO_IDL_BE.dll"
  Delete "$INSTDIR\TAO_IDL_FE.dll"
  Delete "$INSTDIR\TAO_IFRService.dll"
  Delete "$INSTDIR\TAO_IFR_BE.dll"
  Delete "$INSTDIR\TAO_IFR_Client.dll"
  Delete "$INSTDIR\TAO_IORTable.dll"
  Delete "$INSTDIR\TAO_ImR_Client.dll"
  Delete "$INSTDIR\TAO_Messaging.dll"
  Delete "$INSTDIR\TAO_PI.dll"
  Delete "$INSTDIR\TAO_PI_Server.dll"
  Delete "$INSTDIR\TAO_PortableServer.dll"
  Delete "$INSTDIR\TAO_SSLIOP.dll"
  Delete "$INSTDIR\TAO_Security.dll"
  Delete "$INSTDIR\TAO_Svc_Utils.dll"
  Delete "$INSTDIR\TAO_TypeCodeFactory.dll"
  Delete "$INSTDIR\TAO_Valuetype.dll"
  Delete "$INSTDIR\IFR_Service.exe"
  Delete "$INSTDIR\tao_ifr.exe"
  Delete "$INSTDIR\libeay32.dll"
  Delete "$INSTDIR\libeay32.dll.manifest"
  Delete "$INSTDIR\ssleay32.dll"
  Delete "$INSTDIR\ssleay32.dll.manifest"
  Delete "$INSTDIR\lorica.exe"
  Delete "$INSTDIR\OCI_AsynchProxyTools.dll"
  Delete "$INSTDIR\lorica_Client.dll"
  Delete "$INSTDIR\lorica_EvaluatorBase.dll"
  Delete "$INSTDIR\lorica_GenericEvaluator.dll"
  Delete "$INSTDIR\Microsoft.VC90.CRT.manifest"
  Delete "$INSTDIR\msvcp90.dll"
  Delete "$INSTDIR\msvcr90.dll"
  Delete "$INSTDIR\Lorica.txt"
  Delete "$INSTDIR\lorica.conf"
  Delete "$INSTDIR\lorica.ssliop"
  Delete "$INSTDIR\*.*"

  ; Remove shortcuts
  Delete "$SMPROGRAMS\${NAME}\*.*"

  ; Remove directories used
  RMDir "$SMPROGRAMS\${NAME}"
  RMDir "$INSTDIR"
SectionEnd
