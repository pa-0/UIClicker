{
    Copyright (C) 2024 VCC
    creation date: Dec 2019
    initial release date: 13 Sep 2022

    author: VCC
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
    OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}


unit ClickerActionExecution;

{$IFDEF FPC}
  //{$MODE Delphi}
{$ENDIF}

interface

uses
  Windows, Classes, SysUtils, Forms, Graphics, ExtCtrls,
  ClickerUtils, ClickerPrimitiveUtils, ClickerActionsFrame, ClickerIniFiles,
  InMemFileSystem, ControlInteraction;


type
  TOnSetEditorEnabledState = procedure(AEnabled: Boolean) of object;
  TOnSetEditorTimeoutProgressBarMax = procedure(AMaxValue: Integer) of object;
  TOnSetEditorTimeoutProgressBarPosition = procedure(APositionValue: Integer) of object;
  TOnWaitForBitmapsAvailability = procedure(ListOfBitmapFiles: TStringList) of object;
  TOnTerminateWaitForMultipleFilesAvailability = procedure of object;
  TOnCallTemplate = function(Sender: TObject; AFileNameToCall: string; ListOfVariables: TStrings; DebugBitmap: TBitmap; DebugGridImage: TImage; IsDebugging, AShouldStopAtBreakPoint: Boolean; AStackLevel: Integer; AExecutesRemotely: Boolean): Boolean of object;
  TOnSetEditorSleepInfo = procedure(AElapsedTime, ARemainingTime: string) of object;
  TOnGetSelfHandles = procedure(AListOfSelfHandles: TStringList) of object;
  TOnAddDefaultFontProfile = procedure(var AFindControlOptions: TClkFindControlOptions; var AActionOptions: TClkActionOptions) of object;

  TOnGetSetVarActionByName = function(var AClkSetVarOptions: TClkSetVarOptions; AActionName: string): Boolean of object;  //used before saving the action to file
  TOnUpdateSetVarActionByName = function(AClkSetVarOptions: TClkSetVarOptions; AActionName: string): Boolean of object;   //used after loading the action from file
  TOnBackupVars = procedure(AAllVars: TStringList) of object;
  TOnRestoreVars = procedure(AAllVars: TStringList) of object;

  TOnResolveTemplatePath = function(APath: string; ACustomSelfTemplateDir: string = ''; ACustomAppDir: string = ''): string of object;

  TActionExecution = class
  private
    FClickerVars: TStringList;  //not created here in this class, used from outside
    FStopAllActionsOnDemandFromParent: PBoolean;
    FStopAllActionsOnDemand: PBoolean;
    FPluginStepOver: PBoolean;
    FPluginContinueAll: PBoolean;
    FSelfTemplateFileName: PString;
    FExecutingActionFromRemote: PBoolean;
    FFileLocationOfDepsIsMem: PBoolean;
    FFullTemplatesDir: PString;
    FStackLevel: PInteger;
    FExecutesRemotely: PBoolean;
    FOwnerFrame: TObject;

    FAllowedFileDirsForServer: PString;
    FAllowedFileExtensionsForServer: PString;

    FfrClickerActions: TfrClickerActions;  ///////////////////////// temp

    FOnAddToLog: TOnAddToLog;
    FOnSetEditorEnabledState: TOnSetEditorEnabledState;
    FOnSetEditorTimeoutProgressBarMax: TOnSetEditorTimeoutProgressBarMax;
    FOnSetEditorTimeoutProgressBarPosition: TOnSetEditorTimeoutProgressBarPosition;
    FOnLoadBitmap: TOnLoadBitmap;
    FOnLoadRenderedBitmap: TOnLoadRenderedBitmap;
    FOnRenderBmpExternally: TOnRenderBmpExternally;
    FOnGetActionProperties: TOnGetActionProperties;
    FOnWaitForBitmapsAvailability: TOnWaitForBitmapsAvailability;
    FOnCallTemplate: TOnCallTemplate;
    FOnSetEditorSleepProgressBarMax: TOnSetEditorTimeoutProgressBarMax;
    FOnSetEditorSleepProgressBarPosition: TOnSetEditorTimeoutProgressBarPosition;
    FOnSetEditorSleepInfo: TOnSetEditorSleepInfo;
    FOnGetSelfHandles: TOnGetSelfHandles;
    FOnAddDefaultFontProfile: TOnAddDefaultFontProfile;
    FOnGetGridDrawingOption: TOnGetGridDrawingOption;
    FOnLoadPrimitivesFile: TOnLoadPrimitivesFile;

    FOnGetSetVarActionByName: TOnGetSetVarActionByName;
    FOnUpdateSetVarActionByName: TOnUpdateSetVarActionByName;
    FOnTClkIniReadonlyFileCreate: TOnTClkIniReadonlyFileCreate;
    FOnSaveStringListToFile: TOnSaveTemplateToFile;
    FOnBackupVars: TOnBackupVars;
    //FOnRestoreVars: TOnRestoreVars;
    FOnExecuteActionByName: TOnExecuteActionByName;
    FOnGetAllActions: TOnGetAllActions;
    FOnResolveTemplatePath: TOnResolveTemplatePath;
    FOnSetDebugPoint: TOnSetDebugPoint;
    FOnIsAtBreakPoint: TOnIsAtBreakPoint;

    FOnSaveFileToExtRenderingInMemFS: TOnSaveFileToExtRenderingInMemFS;

    function GetActionVarValue(VarName: string): string;
    procedure SetActionVarValue(VarName, VarValue: string);
    function EvaluateReplacements(s: string; Recursive: Boolean = True): string;
    procedure AppendErrorMessageToActionVar(NewErrMsg: string);
    procedure PrependErrorMessageToActionVar(NewErrMsg: string);
    function EvaluateHTTP(AValue: string; out AGeneratedException: Boolean): string;
    procedure PreviewTextOnBmp(var AFindControlOptions: TClkFindControlOptions; AEvaluatedText: string; AProfileIndex: Integer; ASearchedBmp: TBitmap);
    function GetActionProperties(AActionName: string): string;
    function ResolveAllowedFileDirs(AAllowedFileDirsForServer: string): string;

    procedure AddToLog(s: string);
    function DoOnExecuteActionByName(AActionName: string): Boolean;

    function DoOnGetAllActions: PClkActionsRecArr;
    function DoOnResolveTemplatePath(APath: string; ACustomSelfTemplateDir: string = ''; ACustomAppDir: string = ''): string;
    procedure DoOnSetDebugPoint(ADebugPoint: string);
    function DoOnIsAtBreakPoint(ADebugPoint: string): Boolean;

    procedure SetLastActionStatus(AActionResult, AAlowedToFail: Boolean);
    function CheckManualStopCondition: Boolean;

    procedure ExecuteClickAction(var AClickOptions: TClkClickOptions);
    function ExecuteFindControlAction(var AFindControlOptions: TClkFindControlOptions; var AActionOptions: TClkActionOptions; IsSubControl: Boolean): Boolean; //returns True if found
    function FillInFindControlInputData(var AFindControlOptions: TClkFindControlOptions; var AActionOptions: TClkActionOptions; IsSubControl: Boolean; out FindControlInputData: TFindControlInputData; out FontProfilesCount: Integer): Boolean;

    procedure DoOnSetEditorEnabledState(AEnabled: Boolean);
    procedure DoOnSetEditorTimeoutProgressBarMax(AMaxValue: Integer);
    procedure DoOnSetEditorTimeoutProgressBarPosition(APositionValue: Integer);
    function DoOnLoadBitmap(ABitmap: TBitmap; AFileName: string): Boolean;
    function DoOnLoadRenderedBitmap(ABitmap: TBitmap; AFileName: string): Boolean;
    function DoOnRenderBmpExternally(ARequest: string): string;
    function DoOnGetActionProperties(AActionName: string): PClkActionRec;
    procedure DoOnWaitForBitmapsAvailability(AListOfFiles: TStringList);
    procedure DoOnSetEditorSleepProgressBarMax(AMaxValue: Integer);
    procedure DoOnSetEditorSleepProgressBarPosition(APositionValue: Integer);
    procedure DoOnSetEditorSleepInfo(AElapsedTime, ARemainingTime: string);
    procedure DoOnGetSelfHandles(AListOfSelfHandles: TStringList);
    procedure DoOnAddDefaultFontProfile(var AFindControlOptions: TClkFindControlOptions; var AActionOptions: TClkActionOptions);
    function DoOnGetGridDrawingOption: TOnGetGridDrawingOption;
    procedure DoOnLoadPrimitivesFile(AFileName: string; var APrimitives: TPrimitiveRecArr; var AOrders: TCompositionOrderArr; var ASettings: TPrimitiveSettings);

    function DoOnGetSetVarActionByName(var AClkSetVarOptions: TClkSetVarOptions; AActionName: string): Boolean;
    function DoOnUpdateSetVarActionByName(AClkSetVarOptions: TClkSetVarOptions; AActionName: string): Boolean;
    function DoOnTClkIniReadonlyFileCreate(AFileName: string): TClkIniReadonlyFile;
    procedure DoOnSaveStringListToFile(AStringList: TStringList; const AFileName: string);
    procedure DoOnBackupVars(AAllVars: TStringList);
    procedure DoOnSaveFileToExtRenderingInMemFS(AFileName: string; AContent: Pointer; AFileSize: Int64);
    //procedure DoOnRestoreVars(AAllVars: TStringList);

    function HandleOnLoadBitmap(ABitmap: TBitmap; AFileName: string): Boolean;
    function HandleOnLoadRenderedBitmap(ABitmap: TBitmap; AFileName: string): Boolean;
    function HandleOnEvaluateReplacements(s: string; Recursive: Boolean = True): string;

    procedure HandleOnSetVar(AVarName, AVarValue: string);
    procedure HandleOnSetDebugPoint(ADebugPoint: string);
    function HandleOnIsAtBreakPoint(ADebugPoint: string): Boolean;
    procedure HandleOnSaveFileToExtRenderingInMemFS(AFileName: string; AContent: Pointer; AFileSize: Int64);
    function HandleOnScreenshotByActionName(AActionName: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function ExecuteMultiClickAction(var AClickOptions: TClkClickOptions): Boolean;
    function ExecuteExecAppAction(var AExecAppOptions: TClkExecAppOptions; var AActionOptions: TClkActionOptions): Boolean;
    function ExecuteFindControlActionWithTimeout(var AFindControlOptions: TClkFindControlOptions; var AActionOptions: TClkActionOptions; IsSubControl: Boolean): Boolean; //returns True if found
    function ExecuteSetControlTextAction(var ASetTextOptions: TClkSetTextOptions): Boolean;
    function ExecuteCallTemplateAction(var ACallTemplateOptions: TClkCallTemplateOptions; IsDebugging, AShouldStopAtBreakPoint: Boolean): Boolean; //to be moved to private, after ExecuteFindControlAction header
    function ExecuteLoopedCallTemplateAction(var ACallTemplateOptions: TClkCallTemplateOptions; IsDebugging, AShouldStopAtBreakPoint: Boolean): Boolean;
    function ExecuteSleepAction(var ASleepOptions: TClkSleepOptions; var AActionOptions: TClkActionOptions): Boolean;
    function ExecuteSetVarAction(var ASetVarOptions: TClkSetVarOptions): Boolean;
    function ExecuteWindowOperationsAction(var AWindowOperationsOptions: TClkWindowOperationsOptions): Boolean;
    function ExecuteLoadSetVarFromFileAction(var ALoadSetVarFromFileOptions: TClkLoadSetVarFromFileOptions): Boolean;
    function ExecuteSaveSetVarToFileAction(var ASaveSetVarToFileOptions: TClkSaveSetVarToFileOptions): Boolean;
    function ExecutePluginAction(var APluginOptions: TClkPluginOptions; AAllActions: PClkActionsRecArr; AListOfAllVars: TStringList; AResolvedPluginPath: string; IsDebugging, AShouldStopAtBreakPoint: Boolean): Boolean;

    function ExecuteClickActionAsString(AListOfClickOptionsParams: TStrings): Boolean;
    function ExecuteExecAppActionAsString(AListOfExecAppOptionsParams: TStrings): Boolean;
    function ExecuteFindControlActionAsString(AListOfFindControlOptionsParams: TStrings; AIsSubControl: Boolean): Boolean;
    function ExecuteSetControlTextActionAsString(AListOfSetControlTextOptionsParams: TStrings): Boolean;
    function ExecuteCallTemplateActionAsString(AListOfCallTemplateOptionsParams: TStrings): Boolean;
    function ExecuteSleepActionAsString(AListOfSleepOptionsParams: TStrings): Boolean;
    function ExecuteSetVarActionAsString(AListOfSetVarOptionsParams: TStrings): Boolean;
    function ExecuteWindowOperationsActionAsString(AListOfWindowOperationsOptionsParams: TStrings): Boolean;
    function ExecuteLoadSetVarFromFileActionAsString(AListOfLoadSetVarOptionsParams: TStrings): Boolean;
    function ExecuteSaveSetVarToFileActionAsString(AListOfSaveSetVarOptionsParams: TStrings): Boolean;
    function ExecutePluginActionAsString(APluginOptionsParams: TStrings): Boolean;

    //using pointers for the following properties, because the values they are pointing to, can be updated later, not when this class is created
    property ClickerVars: TStringList write FClickerVars;  //not created here in this class, used from outside
    property StopAllActionsOnDemandFromParent: PBoolean write FStopAllActionsOnDemandFromParent;
    property StopAllActionsOnDemand: PBoolean write FStopAllActionsOnDemand;
    property PluginStepOver: PBoolean write FPluginStepOver;
    property PluginContinueAll: PBoolean write FPluginContinueAll;

    property SelfTemplateFileName: PString write FSelfTemplateFileName;
    property ExecutingActionFromRemote: PBoolean write FExecutingActionFromRemote;
    property FileLocationOfDepsIsMem: PBoolean write FFileLocationOfDepsIsMem;
    property FullTemplatesDir: PString write FFullTemplatesDir;
    property StackLevel: PInteger write FStackLevel;
    property ExecutesRemotely: PBoolean write FExecutesRemotely;
    property OwnerFrame: TObject write FOwnerFrame;

    property AllowedFileDirsForServer: PString write FAllowedFileDirsForServer;
    property AllowedFileExtensionsForServer: PString write FAllowedFileExtensionsForServer;

    property frClickerActions: TfrClickerActions read FfrClickerActions write FfrClickerActions;  //not created here in this class, used from outside    ///////////////////////// temp

    property OnAddToLog: TOnAddToLog write FOnAddToLog;
    property OnSetEditorEnabledState: TOnSetEditorEnabledState write FOnSetEditorEnabledState;
    property OnSetEditorTimeoutProgressBarMax: TOnSetEditorTimeoutProgressBarMax write FOnSetEditorTimeoutProgressBarMax;
    property OnSetEditorTimeoutProgressBarPosition: TOnSetEditorTimeoutProgressBarPosition write FOnSetEditorTimeoutProgressBarPosition;
    property OnLoadBitmap: TOnLoadBitmap write FOnLoadBitmap;
    property OnLoadRenderedBitmap: TOnLoadRenderedBitmap write FOnLoadRenderedBitmap;
    property OnRenderBmpExternally: TOnRenderBmpExternally write FOnRenderBmpExternally;
    property OnGetActionProperties: TOnGetActionProperties write FOnGetActionProperties;
    property OnWaitForBitmapsAvailability: TOnWaitForBitmapsAvailability write FOnWaitForBitmapsAvailability;
    property OnCallTemplate: TOnCallTemplate write FOnCallTemplate;
    property OnSetEditorSleepProgressBarMax: TOnSetEditorTimeoutProgressBarMax write FOnSetEditorSleepProgressBarMax;
    property OnSetEditorSleepProgressBarPosition: TOnSetEditorTimeoutProgressBarPosition write FOnSetEditorSleepProgressBarPosition;
    property OnSetEditorSleepInfo: TOnSetEditorSleepInfo write FOnSetEditorSleepInfo;
    property OnGetSelfHandles: TOnGetSelfHandles write FOnGetSelfHandles;
    property OnAddDefaultFontProfile: TOnAddDefaultFontProfile write FOnAddDefaultFontProfile;
    property OnGetGridDrawingOption: TOnGetGridDrawingOption write FOnGetGridDrawingOption;
    property OnLoadPrimitivesFile: TOnLoadPrimitivesFile write FOnLoadPrimitivesFile;

    property OnGetSetVarActionByName: TOnGetSetVarActionByName write FOnGetSetVarActionByName;
    property OnUpdateSetVarActionByName: TOnUpdateSetVarActionByName write FOnUpdateSetVarActionByName;
    property OnTClkIniReadonlyFileCreate: TOnTClkIniReadonlyFileCreate write FOnTClkIniReadonlyFileCreate;
    property OnSaveStringListToFile: TOnSaveTemplateToFile write FOnSaveStringListToFile;
    property OnBackupVars: TOnBackupVars write FOnBackupVars;
    //property OnRestoreVars: TOnRestoreVars write FOnRestoreVars;
    property OnExecuteActionByName: TOnExecuteActionByName write FOnExecuteActionByName;
    property OnGetAllActions: TOnGetAllActions write FOnGetAllActions;
    property OnResolveTemplatePath: TOnResolveTemplatePath write FOnResolveTemplatePath;
    property OnSetDebugPoint: TOnSetDebugPoint write FOnSetDebugPoint;
    property OnIsAtBreakPoint: TOnIsAtBreakPoint write FOnIsAtBreakPoint;

    property OnSaveFileToExtRenderingInMemFS: TOnSaveFileToExtRenderingInMemFS write FOnSaveFileToExtRenderingInMemFS;
  end;


implementation


uses
  MouseStuff, Controls,
  {$IFnDEF FPC}
    ShellAPI,
  {$ELSE}
    Process,
  {$ENDIF}
  IdHTTP, ClickerPrimitivesCompositor, ClickerActionProperties,
  ClickerActionPluginLoader, ClickerActionPlugins, BitmapProcessing,
  ClickerActionsClient;


constructor TActionExecution.Create;
begin
  //inherited Create;
  FClickerVars := nil; //not created here in this class, used from outside
  FfrClickerActions := nil;
  FExecutingActionFromRemote := nil;
  FFileLocationOfDepsIsMem := nil;
  FFullTemplatesDir := nil;
  FStackLevel := nil;
  FExecutesRemotely := nil;
  FOwnerFrame := nil;

  FAllowedFileDirsForServer := nil;
  FAllowedFileExtensionsForServer := nil;

  FPluginStepOver := nil;
  FPluginContinueAll := nil;

  FOnAddToLog := nil;
  FOnSetEditorEnabledState := nil;
  FOnSetEditorTimeoutProgressBarMax := nil;
  FOnSetEditorTimeoutProgressBarPosition := nil;
  FOnLoadBitmap := nil;
  FOnLoadRenderedBitmap := nil;
  FOnRenderBmpExternally := nil;
  FOnGetActionProperties := nil;
  FOnWaitForBitmapsAvailability := nil;
  FOnCallTemplate := nil;
  FOnSetEditorSleepProgressBarMax := nil;
  FOnSetEditorSleepProgressBarPosition := nil;
  FOnSetEditorSleepInfo := nil;
  FOnGetSelfHandles := nil;
  FOnAddDefaultFontProfile := nil;
  FOnGetGridDrawingOption := nil;
  FOnLoadPrimitivesFile := nil;

  FOnGetSetVarActionByName := nil;
  FOnUpdateSetVarActionByName := nil;
  FOnTClkIniReadonlyFileCreate := nil;
  FOnSaveStringListToFile := nil;
  FOnBackupVars := nil;
  //FOnRestoreVars := nil;
  FOnExecuteActionByName := nil;
  FOnGetAllActions := nil;
  FOnResolveTemplatePath := nil;
  FOnSetDebugPoint := nil;
  FOnIsAtBreakPoint := nil;

  FOnSaveFileToExtRenderingInMemFS := nil;
end;


destructor TActionExecution.Destroy;
begin
  FClickerVars := nil;
  inherited Destroy;
end;


function TActionExecution.GetActionVarValue(VarName: string): string;
begin
  if FClickerVars = nil then
    raise Exception.Create('ClickerVars is not assigned.');

  Result := FClickerVars.Values[VarName];
end;


procedure TActionExecution.SetActionVarValue(VarName, VarValue: string);
begin
  FClickerVars.Values[VarName] := FastReplace_ReturnTo68(VarValue);  //Do not use EvaluateReplacements(VarValue) here, because there are calls which expect the value to be directly assigned !

  if VarName = '$ExecAction_Err$' then
    AddToLog(DateTimeToStr(Now) + '  ' + VarValue);
end;


function TActionExecution.EvaluateReplacements(s: string; Recursive: Boolean = True): string;
begin
  Result := EvaluateAllReplacements(FClickerVars, s, Recursive);
end;


procedure TActionExecution.AppendErrorMessageToActionVar(NewErrMsg: string);
begin
  SetActionVarValue('$ExecAction_Err$', GetActionVarValue('$ExecAction_Err$') + FastReplace_ReturnTo68(NewErrMsg));
end;


procedure TActionExecution.PrependErrorMessageToActionVar(NewErrMsg: string);
begin
  SetActionVarValue('$ExecAction_Err$', FastReplace_ReturnTo68(NewErrMsg) + GetActionVarValue('$ExecAction_Err$'));
end;


function TActionExecution.EvaluateHTTP(AValue: string; out AGeneratedException: Boolean): string;
var
  TempIdHTTP: TIdHTTP;
begin
  Result := AValue;
  AGeneratedException := False;

  if (Pos('$HTTP://', UpperCase(AValue)) > 0) or (Pos('$HTTPS://', UpperCase(AValue)) > 0) then
    if AValue[Length(AValue)] = '$' then
    begin
      AValue := Copy(AValue, 2, Length(AValue) - 2);
      AValue := EvaluateReplacements(AValue);

      try
        TempIdHTTP := TIdHTTP.Create(nil);
        try
          TempIdHTTP.ConnectTimeout := 1000;    //These values should be increased if using a remote server. However, they will slow down the execution in that case.
          TempIdHTTP.ReadTimeout := 1000;
          Result := TempIdHTTP.Get(AValue);
        finally
          TempIdHTTP.Free;
        end;
      except
        on E: Exception do
        begin
          Result := E.Message;
          AGeneratedException := True;
          AppendErrorMessageToActionVar(Result);
        end;
      end;
    end;
end;


procedure TActionExecution.PreviewTextOnBmp(var AFindControlOptions: TClkFindControlOptions; AEvaluatedText: string; AProfileIndex: Integer; ASearchedBmp: TBitmap);
const
  CFontQualitiesStr: array[TFontQuality] of string = ('Default', 'Draft', 'Proof', 'NonAntialiased', 'Antialiased', 'Cleartype', 'CleartypeNatural');
var
  TextDimensions: TSize;
  TextToDisplay: string;
  FontQualityReplacement: Integer;
  FontQualityReplacementStr: string;
  EvalFG, EvalBG: string;
  EvalFGCol, EvalBGCol: TColor;
  i: TFontQuality;
  CropLeft, CropTop, CropRight, CropBottom: Integer;
  APreviewBmp: TBitmap;
  TextWidthAfterCropping, TextHeightAfterCropping: Integer;
begin
  TextToDisplay := AEvaluatedText; //ask once    - it expects an already evaluated text, which is also used somewhere else, so evaluated as less as possible

  if Length(AFindControlOptions.MatchBitmapText) = 0 then
  begin
    AddToLog('No font profiles are available when previewing text on bmp.  Text = "' + AEvaluatedText + '".');
    Exit;
  end;

  APreviewBmp := TBitmap.Create;
  try
    APreviewBmp.PixelFormat := pf24bit;

    EvalFG := EvaluateReplacements(AFindControlOptions.MatchBitmapText[AProfileIndex].ForegroundColor, True);
    EvalBG := EvaluateReplacements(AFindControlOptions.MatchBitmapText[AProfileIndex].BackgroundColor, True);

    EvalFGCol := HexToInt(EvalFG);
    EvalBGCol := HexToInt(EvalBG);

    APreviewBmp.Canvas.Font.Color := EvalFGCol;
    APreviewBmp.Canvas.Font.Name := EvaluateReplacements(AFindControlOptions.MatchBitmapText[AProfileIndex].FontName);

    APreviewBmp.Canvas.Font.Size := AFindControlOptions.MatchBitmapText[AProfileIndex].FontSize;

    APreviewBmp.Canvas.Font.Style := [];

    if AFindControlOptions.MatchBitmapText[AProfileIndex].Bold then
      APreviewBmp.Canvas.Font.Style := APreviewBmp.Canvas.Font.Style + [fsBold];

    if AFindControlOptions.MatchBitmapText[AProfileIndex].Italic then
      APreviewBmp.Canvas.Font.Style := APreviewBmp.Canvas.Font.Style + [fsItalic];

    if AFindControlOptions.MatchBitmapText[AProfileIndex].Underline then
      APreviewBmp.Canvas.Font.Style := APreviewBmp.Canvas.Font.Style + [fsUnderline];

    if AFindControlOptions.MatchBitmapText[AProfileIndex].StrikeOut then
      APreviewBmp.Canvas.Font.Style := APreviewBmp.Canvas.Font.Style + [fsStrikeOut];

    if AFindControlOptions.MatchBitmapText[AProfileIndex].FontQualityUsesReplacement then
    begin
      FontQualityReplacementStr := EvaluateReplacements(AFindControlOptions.MatchBitmapText[AProfileIndex].FontQualityReplacement);  //should return a string in the following set: 'Default', 'Draft', 'Proof', 'NonAntialiased', 'Antialiased', 'Cleartype', 'CleartypeNatural'
      FontQualityReplacement := -1;
      for i := Low(TFontQuality) to High(TFontQuality) do
        if FontQualityReplacementStr = CFontQualitiesStr[i] then
        begin
          FontQualityReplacement := Ord(i);
          Break;
        end;

      if FontQualityReplacement = -1 then
        FontQualityReplacement := 0;  //default to fqDefault

      APreviewBmp.Canvas.Font.Quality := TFontQuality(FontQualityReplacement);
    end
    else
      APreviewBmp.Canvas.Font.Quality := TFontQuality(AFindControlOptions.MatchBitmapText[AProfileIndex].FontQuality);

    APreviewBmp.Canvas.Brush.Color := EvalBGCol;
    APreviewBmp.Canvas.Pen.Color := EvalBGCol;  //yes, BG

    TextDimensions := APreviewBmp.Canvas.TextExtent(TextToDisplay);
    APreviewBmp.Width := TextDimensions.cx;
    APreviewBmp.Height := TextDimensions.cy;

    APreviewBmp.Canvas.Rectangle(0, 0, APreviewBmp.Width - 1, APreviewBmp.Height - 1);
    APreviewBmp.Canvas.TextOut(0, 0, TextToDisplay);     //Do not use replacements here. The editbox should already be updated with replaced strings.

    CropLeft := Max(StrToIntDef(EvaluateReplacements(AFindControlOptions.MatchBitmapText[AProfileIndex].CropLeft), 0), 0);
    CropTop := Max(StrToIntDef(EvaluateReplacements(AFindControlOptions.MatchBitmapText[AProfileIndex].CropTop), 0), 0);
    CropRight := Max(StrToIntDef(EvaluateReplacements(AFindControlOptions.MatchBitmapText[AProfileIndex].CropRight), 0), 0);
    CropBottom := Max(StrToIntDef(EvaluateReplacements(AFindControlOptions.MatchBitmapText[AProfileIndex].CropBottom), 0), 0);

    ASearchedBmp.PixelFormat := pf24bit;
    ASearchedBmp.Canvas.Pen.Color := clLime;
    ASearchedBmp.Canvas.Brush.Color := clLime;
    if (CropLeft <> 0) or (CropTop <> 0) or (CropRight <> 0) or (CropBottom <> 0) then
    begin
      TextWidthAfterCropping := TextDimensions.cx - (CropLeft + CropRight); //CropLeft is increased as left -> right (towards the text). CropRight is increased right-> left  (towards the text).
      TextHeightAfterCropping := TextDimensions.cy - (CropTop + CropBottom);

      if TextWidthAfterCropping = 0 then
        raise Exception.Create('The text width, after cropping, is 0.');

      if TextHeightAfterCropping = 0 then
        raise Exception.Create('The text height, after cropping, is 0.');

      if TextWidthAfterCropping < 0 then
        raise Exception.Create('The text width, after cropping, is negative.');

      if TextHeightAfterCropping < 0 then
        raise Exception.Create('The text height, after cropping, is negative.');

      ASearchedBmp.Width := TextWidthAfterCropping;
      ASearchedBmp.Height := TextHeightAfterCropping;

      ASearchedBmp.Canvas.Rectangle(0, 0, ASearchedBmp.Width, ASearchedBmp.Height); //this rectangle is required, for proper content copying
      BitBlt(ASearchedBmp.Canvas.Handle, 0, 0, ASearchedBmp.Width, ASearchedBmp.Height, APreviewBmp.Canvas.Handle, CropLeft, CropTop, SRCCOPY);

      //HDC hdcDest, // handle to destination DC
      //int nXDest,  // x-coord of destination upper-left corner
      //int nYDest,  // y-coord of destination upper-left corner
      //int nWidth,  // width of destination rectangle
      //int nHeight, // height of destination rectangle
      //HDC hdcSrc,  // handle to source DC
      //int nXSrc,   // x-coordinate of source upper-left corner
      //int nYSrc,   // y-coordinate of source upper-left corner
      //DWORD dwRop  // raster operation code
    end
    else
    begin
      ASearchedBmp.Width := TextDimensions.cx;
      ASearchedBmp.Height := TextDimensions.cy;
      ASearchedBmp.Canvas.Rectangle(0, 0, ASearchedBmp.Width, ASearchedBmp.Height); //this rectangle is required, for proper content copying
      BitBlt(ASearchedBmp.Canvas.Handle, 0, 0, ASearchedBmp.Width, ASearchedBmp.Height, APreviewBmp.Canvas.Handle, 0, 0, SRCCOPY);
    end;
  finally
    APreviewBmp.Free;
  end;
end;


function TActionExecution.GetActionProperties(AActionName: string): string;
var
  Action: PClkActionRec;
begin
  Action := DoOnGetActionProperties(AActionName);
  if Action = nil then
  begin
    Result := 'Action name not found.';
    Exit;
  end;

  case Action^.ActionOptions.Action of
    acClick:
      Result := GetClickActionProperties(Action.ClickOptions);

    acExecApp:
      Result := GetExecAppActionProperties(Action.ExecAppOptions);

    acFindControl, acFindSubControl:
      Result := GetFindControlActionProperties(Action.FindControlOptions);

    acSetControlText:
      Result := GetSetControlTextActionProperties(Action.SetTextOptions);

    acCallTemplate:
      Result := GetCallTemplateActionProperties(Action.CallTemplateOptions);

    acSleep:
      Result := GetSleepActionProperties(Action.SleepOptions);

    acSetVar:
      Result := GetSetVarActionProperties(Action.SetVarOptions);

    acWindowOperations:
      Result := GetWindowOperationsActionProperties(Action.WindowOperationsOptions);

    acLoadSetVarFromFile:
      Result := GetLoadSetVarFromFileActionProperties(Action.LoadSetVarFromFileOptions);

    acSaveSetVarToFile:
      Result := GetSaveSetVarToFileActionProperties(Action.SaveSetVarToFileOptions);

    acPlugin:
      Result := GetPluginActionProperties(Action.PluginOptions);
  end;
end;


procedure TActionExecution.AddToLog(s: string);
begin
  if not Assigned(FOnAddToLog) then
    raise Exception.Create('OnAddToLog not assigned.');

  FOnAddToLog(s);
end;


procedure TActionExecution.SetLastActionStatus(AActionResult, AAlowedToFail: Boolean);
begin
  if AActionResult then
    SetActionVarValue('$LastAction_Status$', CActionStatusStr[asSuccessful])
  else
  begin
    if AAlowedToFail then
      SetActionVarValue('$LastAction_Status$', CActionStatusStr[asAllowedFailed])
    else
      SetActionVarValue('$LastAction_Status$', CActionStatusStr[asFailed])
  end;
end;


//function HandleOnLoadAllowedBitmap: ;

procedure TActionExecution.DoOnSetEditorEnabledState(AEnabled: Boolean);
begin
  if Assigned(FOnSetEditorEnabledState) then
    FOnSetEditorEnabledState(AEnabled)
  else
    raise Exception.Create('FOnSetEditorEnabledState is not assigned.');
end;


procedure TActionExecution.DoOnSetEditorTimeoutProgressBarMax(AMaxValue: Integer);
begin
  if Assigned(FOnSetEditorTimeoutProgressBarMax) then
    FOnSetEditorTimeoutProgressBarMax(AMaxValue)
  else
    raise Exception.Create('FOnSetEditorTimeoutProgressBarMax is not assigned.');
end;


procedure TActionExecution.DoOnSetEditorTimeoutProgressBarPosition(APositionValue: Integer);
begin
  if Assigned(FOnSetEditorTimeoutProgressBarPosition) then
    FOnSetEditorTimeoutProgressBarPosition(APositionValue)
  else
    raise Exception.Create('FOnSetEditorTimeoutProgressBarPosition is not assigned.');
end;


function TActionExecution.DoOnLoadBitmap(ABitmap: TBitmap; AFileName: string): Boolean;
begin
  if Assigned(FOnLoadBitmap) then
    Result := FOnLoadBitmap(ABitmap, AFileName)
  else
    raise Exception.Create('OnLoadBitmap is not assigned.');
end;


function TActionExecution.DoOnLoadRenderedBitmap(ABitmap: TBitmap; AFileName: string): Boolean;
begin
  if Assigned(FOnLoadRenderedBitmap) then
    Result := FOnLoadRenderedBitmap(ABitmap, AFileName)
  else
    raise Exception.Create('OnLoadRenderedBitmap is not assigned.');
end;


function TActionExecution.DoOnRenderBmpExternally(ARequest: string): string;
begin
  if Assigned(FOnRenderBmpExternally) then
    Result := FOnRenderBmpExternally(ARequest)
  else
    raise Exception.Create('OnRenderBmpExternally is not assigned.');
end;


function TActionExecution.DoOnGetActionProperties(AActionName: string): PClkActionRec;
begin
  if Assigned(FOnGetActionProperties) then
    Result := FOnGetActionProperties(AActionName)
  else
    raise Exception.Create('OnGetActionProperties is not assigned.');
end;


procedure TActionExecution.DoOnWaitForBitmapsAvailability(AListOfFiles: TStringList);
begin
  if Assigned(FOnWaitForBitmapsAvailability) then
    FOnWaitForBitmapsAvailability(AListOfFiles)
  else
    raise Exception.Create('OnWaitForBitmapsAvailability is not assigned.');
end;


procedure TActionExecution.DoOnSetEditorSleepProgressBarMax(AMaxValue: Integer);
begin
  if Assigned(FOnSetEditorSleepProgressBarMax) then
    FOnSetEditorSleepProgressBarMax(AMaxValue)
  else
    raise Exception.Create('FOnSetEditorSleepProgressBarMax is not assigned.');
end;


procedure TActionExecution.DoOnSetEditorSleepProgressBarPosition(APositionValue: Integer);
begin
  if Assigned(FOnSetEditorSleepProgressBarPosition) then
    FOnSetEditorSleepProgressBarPosition(APositionValue)
  else
    raise Exception.Create('FOnSetEditorSleepProgressBarPosition is not assigned.');
end;


procedure TActionExecution.DoOnSetEditorSleepInfo(AElapsedTime, ARemainingTime: string);
begin
  if Assigned(FOnSetEditorSleepInfo) then
    FOnSetEditorSleepInfo(AElapsedTime, ARemainingTime)
  else
    raise Exception.Create('FOnSetEditorSleepInfo is not assigned.');
end;


procedure TActionExecution.DoOnGetSelfHandles(AListOfSelfHandles: TStringList);
begin
  if Assigned(FOnGetSelfHandles) then
    FOnGetSelfHandles(AListOfSelfHandles)
  else
    raise Exception.Create('FOnGetSelfHandles is not assigned.');
end;


procedure TActionExecution.DoOnAddDefaultFontProfile(var AFindControlOptions: TClkFindControlOptions; var AActionOptions: TClkActionOptions);
begin
  if Assigned(FOnAddDefaultFontProfile) then
    FOnAddDefaultFontProfile(AFindControlOptions, AActionOptions)
  else
  begin     //this part is required when using ClickerActionExecution without UI
    SetLength(AFindControlOptions.MatchBitmapText, 1); //this is required, to execute the next for loop, without font profiles
                                                       //this code will have to be split in FindControl and FindSubControl. Then, this part will have to be deleted.
    AFindControlOptions.MatchBitmapText[0].FontName := 'Tahoma';
    AFindControlOptions.MatchBitmapText[0].FontSize := 8;
    AFindControlOptions.MatchBitmapText[0].ForegroundColor := '000000';
    AFindControlOptions.MatchBitmapText[0].BackgroundColor := '0000FF';
    AFindControlOptions.MatchBitmapText[0].ProfileName := CDefaultFontProfileName;
    frClickerActions.frClickerFindControl.AddNewFontProfile(AFindControlOptions.MatchBitmapText[0]);
  end;
end;


function TActionExecution.DoOnGetGridDrawingOption: TOnGetGridDrawingOption;
begin
  if not Assigned(FOnGetGridDrawingOption) then
    raise Exception.Create('OnGetGridDrawingOption not assigned.')
  else
    Result := FOnGetGridDrawingOption;
end;


procedure TActionExecution.DoOnLoadPrimitivesFile(AFileName: string; var APrimitives: TPrimitiveRecArr; var AOrders: TCompositionOrderArr; var ASettings: TPrimitiveSettings);
begin
  if not Assigned(FOnLoadPrimitivesFile) then
    raise Exception.Create('OnLoadPrimitivesFile not assigned.')
  else
    FOnLoadPrimitivesFile(AFileName, APrimitives, AOrders, ASettings);
end;


function TActionExecution.DoOnGetSetVarActionByName(var AClkSetVarOptions: TClkSetVarOptions; AActionName: string): Boolean;
begin
  if not Assigned(FOnGetSetVarActionByName) then
    raise Exception.Create('OnGetSetVarActionByName not assigned.')
  else
    Result := FOnGetSetVarActionByName(AClkSetVarOptions, AActionName);
end;


function TActionExecution.DoOnUpdateSetVarActionByName(AClkSetVarOptions: TClkSetVarOptions; AActionName: string): Boolean;
begin
  if not Assigned(FOnUpdateSetVarActionByName) then
    raise Exception.Create('OnUpdateSetVarActionByName not assigned.')
  else
    Result := FOnUpdateSetVarActionByName(AClkSetVarOptions, AActionName);
end;


function TActionExecution.DoOnTClkIniReadonlyFileCreate(AFileName: string): TClkIniReadonlyFile;
begin
  if not Assigned(FOnTClkIniReadonlyFileCreate) then
    raise Exception.Create('OnTClkIniReadonlyFileCreate not assigned.')
  else
    Result := FOnTClkIniReadonlyFileCreate(AFileName);
end;


procedure TActionExecution.DoOnSaveStringListToFile(AStringList: TStringList; const AFileName: string);
begin
  if not Assigned(FOnSaveStringListToFile) then
    raise Exception.Create('OnSaveStringListToFile not assigned.')
  else
    FOnSaveStringListToFile(AStringList, AFileName);
end;


procedure TActionExecution.DoOnBackupVars(AAllVars: TStringList);
begin
  if not Assigned(FOnBackupVars) then
    raise Exception.Create('OnBackupVars not assigned.')
  else
    FOnBackupVars(AAllVars);
end;


procedure TActionExecution.DoOnSaveFileToExtRenderingInMemFS(AFileName: string; AContent: Pointer; AFileSize: Int64);
begin
  if not Assigned(FOnSaveFileToExtRenderingInMemFS) then
    raise Exception.Create('OnSaveFileToExtRenderingInMemFS not assigned.')
  else
    FOnSaveFileToExtRenderingInMemFS(AFileName, AContent, AFileSize);
end;


//procedure TActionExecution.DoOnRestoreVars(AAllVars: TStringList);
//begin
//  if not Assigned(FOnRestoreVars) then
//    raise Exception.Create('OnRestoreVars not assigned.')
//  else
//    FOnRestoreVars(AAllVars);
//end;


function TActionExecution.DoOnExecuteActionByName(AActionName: string): Boolean;
begin
  if not Assigned(FOnExecuteActionByName) then
    raise Exception.Create('OnExecuteActionByName not assigned.');

  Result := FOnExecuteActionByName(AActionName);
end;


function TActionExecution.DoOnGetAllActions: PClkActionsRecArr;
begin
  if not Assigned(FOnGetAllActions) then
    raise Exception.Create('OnGetAllActions not assigned.');

  Result := FOnGetAllActions();
end;


function TActionExecution.DoOnResolveTemplatePath(APath: string; ACustomSelfTemplateDir: string = ''; ACustomAppDir: string = ''): string;
begin
  if not Assigned(FOnResolveTemplatePath) then
    raise Exception.Create('OnResolveTemplatePath not assigned.');

  Result := FOnResolveTemplatePath(APath, ACustomSelfTemplateDir, ACustomAppDir);
end;


procedure TActionExecution.DoOnSetDebugPoint(ADebugPoint: string);
begin
  if not Assigned(FOnSetDebugPoint) then
    raise Exception.Create('OnSetDebugPoint not assigned.');

  FOnSetDebugPoint(ADebugPoint);
end;


function TActionExecution.DoOnIsAtBreakPoint(ADebugPoint: string): Boolean;
begin
  if not Assigned(FOnIsAtBreakPoint) then
    raise Exception.Create('OnIsAtBreakPoint not assigned.');

  Result := FOnIsAtBreakPoint(ADebugPoint);
end;


function TActionExecution.ResolveAllowedFileDirs(AAllowedFileDirsForServer: string): string;
var
  ListOfDirs: TStringList;
  i: Integer;
begin
  ListOfDirs := TStringList.Create;
  try
    ListOfDirs.Text := AAllowedFileDirsForServer;

    Result := '';
    for i := 0 to ListOfDirs.Count - 1 do
      Result := Result + DoOnResolveTemplatePath(ListOfDirs.Strings[i]) + #13#10;
  finally
    ListOfDirs.Free;
  end;
end;


procedure TActionExecution.ExecuteClickAction(var AClickOptions: TClkClickOptions);
var
  MouseParams: TStringList;
  XClick, YClick: Integer;
  Control_Left, Control_Top, Control_Width, Control_Height: Integer;
  MXOffset, MYOffset: Integer;
begin
  MouseParams := TStringList.Create;
  try
    Control_Left := StrToIntDef(GetActionVarValue('$Control_Left$'), 0);
    Control_Top := StrToIntDef(GetActionVarValue('$Control_Top$'), 0);
    Control_Width := StrToIntDef(GetActionVarValue('$Control_Width$'), 0);
    Control_Height := StrToIntDef(GetActionVarValue('$Control_Height$'), 0);

    XClick := Control_Left; //global in screen
    YClick := Control_Top;

    MXOffset := StrToIntDef(EvaluateReplacements(AClickOptions.XOffset), 0);
    MYOffset := StrToIntDef(EvaluateReplacements(AClickOptions.YOffset), 0);

    case AClickOptions.XClickPointReference of
      xrefLeft: Inc(XClick, MXOffset);
      xrefRight: Inc(XClick, MXOffset + Control_Width);
      xrefWidth: Inc(XClick, MXOffset - Control_Width - Control_Left);    ///????????????????
      xrefVar: XClick := StrToIntDef(EvaluateReplacements(AClickOptions.XClickPointVar), 0) + MXOffset;
      xrefAbsolute: XClick := MXOffset;
    end;

    case AClickOptions.YClickPointReference of
      yrefTop: Inc(YClick, MYOffset);
      yrefBottom: Inc(YClick, MYOffset + Control_Height);
      yrefHeight: Inc(YClick, MYOffset - Control_Height - Control_Top);    ///????????????????
      yrefVar: YClick := StrToIntDef(EvaluateReplacements(AClickOptions.YClickPointVar), 0) + MYOffset;
      yrefAbsolute: YClick := MYOffset;
    end;

    MouseParams.Values[CMouseX] := IntToStr(XClick);
    MouseParams.Values[CMouseY] := IntToStr(YClick);

    case AClickOptions.MouseButton of
      mbLeft: MouseParams.Values[CMouseButton] := CMouseButtonLeft;
      mbRight: MouseParams.Values[CMouseButton] := CMouseButtonRight;
      mbMiddle: MouseParams.Values[CMouseButton] := CMouseButtonMiddle;
      else
      begin
      end;
    end;

    MouseParams.Values[CMouseShiftState] := '';
    if AClickOptions.ClickWithCtrl then
      MouseParams.Values[CMouseShiftState] := MouseParams.Values[CMouseShiftState] + CShiftStateCtrl;

    if AClickOptions.ClickWithAlt then
      MouseParams.Values[CMouseShiftState] := MouseParams.Values[CMouseShiftState] + ',' + CShiftStateAlt;

    if AClickOptions.ClickWithShift then
      MouseParams.Values[CMouseShiftState] := MouseParams.Values[CMouseShiftState] + ',' + CShiftStateShift;

    if AClickOptions.ClickWithDoubleClick then
      MouseParams.Values[CMouseShiftState] := MouseParams.Values[CMouseShiftState] + ',' + CShiftStateDoubleClick;

    MouseParams.Values[CMouseCursorLeaveMouse] := IntToStr(Ord(AClickOptions.LeaveMouse));
    MouseParams.Values[CMouseMoveWithoutClick] := IntToStr(Ord(AClickOptions.MoveWithoutClick));

    MouseParams.Values[CMouseClickType] := IntToStr(AClickOptions.ClickType);

    MouseParams.Values[CMouseDelayAfterMovingToDestination] := EvaluateReplacements(AClickOptions.DelayAfterMovingToDestination);
    MouseParams.Values[CMouseDelayAfterMouseDown] := EvaluateReplacements(AClickOptions.DelayAfterMouseDown);
    MouseParams.Values[CMouseMoveDuration] := EvaluateReplacements(AClickOptions.MoveDuration);

    if AClickOptions.ClickType = CMouseClickType_Drag then  ///Dest
    begin
      XClick := Control_Left; //global in screen
      YClick := Control_Top;

      MXOffset := StrToIntDef(EvaluateReplacements(AClickOptions.XOffsetDest), 0);
      MYOffset := StrToIntDef(EvaluateReplacements(AClickOptions.YOffsetDest), 0);

      case AClickOptions.XClickPointReferenceDest of
        xrefLeft: Inc(XClick, MXOffset);
        xrefRight: Inc(XClick, MXOffset + Control_Width);
        xrefWidth: Inc(XClick, MXOffset - Control_Width - Control_Left);    ///????????????????
        xrefVar: XClick := StrToIntDef(EvaluateReplacements(AClickOptions.XClickPointVarDest), 0) + MXOffset;
        xrefAbsolute: XClick := MXOffset;
      end;

      case AClickOptions.YClickPointReferenceDest of
        yrefTop: Inc(YClick, MYOffset);
        yrefBottom: Inc(YClick, MYOffset + Control_Height);
        yrefHeight: Inc(YClick, MYOffset - Control_Height - Control_Top);    ///????????????????
        yrefVar: YClick := StrToIntDef(EvaluateReplacements(AClickOptions.YClickPointVarDest), 0) + MYOffset;
        yrefAbsolute: YClick := MYOffset;
      end;

      MouseParams.Values[CMouseXDest] := IntToStr(XClick);
      MouseParams.Values[CMouseYDest] := IntToStr(YClick);
    end; ///Dest

    if AClickOptions.ClickType = CMouseClickType_Wheel then
    begin
      case AClickOptions.MouseWheelType of
        mwtVert:
          MouseParams.Values[CMouseWheelType] := CMouseWheelVertWheel;

        mwtHoriz:
          MouseParams.Values[CMouseWheelType] := CMouseWheelHorizWheel;
      end;

      MouseParams.Values[CMouseWheelAmount] := EvaluateReplacements(AClickOptions.MouseWheelAmount);
    end;

    case AClickOptions.ClickType of
      CMouseClickType_Click, CMouseClickType_Drag:
        ClickTControl(MouseParams);

      CMouseClickType_MouseDown:
        MouseDownTControl(MouseParams);

      CMouseClickType_MouseUp:
        MouseUpTControl(MouseParams);

      CMouseClickType_Wheel:
        MouseWheelTControl(MouseParams);
    end;
  finally
    MouseParams.Free;
  end;
end;


function TActionExecution.ExecuteMultiClickAction(var AClickOptions: TClkClickOptions): Boolean;
var
  i: Integer;
  StopAllActionsOnDemandAddr: PBoolean;
begin
  if FStopAllActionsOnDemandFromParent <> nil then
    StopAllActionsOnDemandAddr := FStopAllActionsOnDemandFromParent
  else
    StopAllActionsOnDemandAddr := FStopAllActionsOnDemand;

  Result := True;

  for i := 0 to AClickOptions.Count - 1 do
  begin
    ExecuteClickAction(AClickOptions);
    Application.ProcessMessages;
    Sleep(3);

    //memLogErr.Lines.Add('$Current_Mouse_Y$: ' + EvaluateReplacements('$Current_Mouse_Y$'));

    if (GetAsyncKeyState(VK_CONTROL) < 0) and (GetAsyncKeyState(VK_SHIFT) < 0) and (GetAsyncKeyState(VK_F2) < 0) then
    begin
      if FStopAllActionsOnDemandFromParent <> nil then
        FStopAllActionsOnDemandFromParent^ := True;

      FStopAllActionsOnDemand^ := True;
      Exit;
    end;

    if StopAllActionsOnDemandAddr^ then
    begin
      Result := False;
      Break;
    end;
  end;
end;


function TActionExecution.ExecuteExecAppAction(var AExecAppOptions: TClkExecAppOptions; var AActionOptions: TClkActionOptions): Boolean;
var
  ACmd, ErrMsg: string;
  i: Integer;
  AllParams: TStringList;
  s, SelfAppDir, TemplateDir: string;

  {$IFnDEF FPC}
    hwnd: THandle;
    ShellExecuteRes: Cardinal;
    AParams: string;
  {$ELSE}
    AProcess: TProcess;
    ExeInput, ExeOutput: string;
    TempStringList: TStringList;
    tk: QWord;
    TempBuffer: array of Byte;
    MemStream: TMemoryStream;
    TimeoutForAppRun: Integer;
  {$ENDIF}
begin
  SelfAppDir := ExtractFileDir(ParamStr(0));
  ACmd := AExecAppOptions.PathToApp;

  TemplateDir := '';
  if FSelfTemplateFileName = nil then
    TemplateDir := 'FSelfTemplateFileName not set in ExecApp.'
  else
  begin
    TemplateDir := ExtractFileDir(FSelfTemplateFileName^);
    ACmd := StringReplace(ACmd, '$SelfTemplateDir$', TemplateDir, [rfReplaceAll]);
    ACmd := StringReplace(ACmd, '$TemplateDir$', FFullTemplatesDir^, [rfReplaceAll]);
  end;

  ACmd := StringReplace(ACmd, '$AppDir$', SelfAppDir, [rfReplaceAll]);
  ACmd := EvaluateReplacements(ACmd);  //this call has to stay here, because the $SelfTemplateDir$ replacement is ''

  Result := True;

  if not FileExists(ACmd) then
  begin
    Result := False;
    SetActionVarValue('$ExecAction_Err$', 'File not found: ' + ACmd);
    Exit;
  end;

  AllParams := TStringList.Create;
  try
    AllParams.Text := AExecAppOptions.ListOfParams;


    {$IFnDEF FPC}   //backwards compatibility with Delphi, where there is no TProcess.  Still, there is CreateProcess and WaitForSingleObject.
      AParams := '';

      for i := 0 to AllParams.Count - 1 do
      begin
        s := EvaluateReplacements(AllParams.Strings[i]);
        s := StringReplace(s, '$AppDir$', SelfAppDir, [rfReplaceAll]);
        AParams := AParams + '"' + s + '" ';
      end;

      if AParams > '' then
        Delete(AParams, Length(AParams), 1); //delete last ' '

      if AExecAppOptions.WaitForApp then
        hwnd := Handle
      else
        hwnd := 0;

      ShellExecuteRes := ShellExecute(hwnd, 'open', PChar(ACmd), PChar(AParams), PChar(ExtractFileDir(ACmd)), SW_SHOW);
      if ShellExecuteRes > 32 then
      begin
        Result := True;
        SetActionVarValue('$ExecAction_Err$', '');
      end
      else
      begin
        Result := False;
        SetActionVarValue('$ExecAction_Err$', 'ShellExecute error code: ' + IntToStr(ShellExecuteRes));
      end;
    {$ELSE}
      try
        AProcess := TProcess.Create(nil);
        MemStream := TMemoryStream.Create;
        try
          AProcess.Executable := ACmd;

          for i := 0 to AllParams.Count - 1 do
          begin
            s := EvaluateReplacements(AllParams.Strings[i]);
            s := StringReplace(s, '$AppDir$', SelfAppDir, [rfReplaceAll]);
            AProcess.Parameters.Add(s);
          end;

          AProcess.Options := [poUsePipes, poStderrToOutPut{, poPassInput}];
          AProcess.StartupOptions := AProcess.StartupOptions + [suoUseShowWindow];

          if AExecAppOptions.NoConsole then
            AProcess.Options := AProcess.Options + [poNoConsole];

          case AExecAppOptions.UseInheritHandles of
            uihNo:
              AProcess.InheritHandles := False;

            uihYes:
              AProcess.InheritHandles := True;

            uihOnlyWithStdInOut:
               AProcess.InheritHandles := AExecAppOptions.WaitForApp or
                                         (AExecAppOptions.AppStdIn > '');
          end;  //when InheritHandles is True, the executed application may keep open a listening socket, after closing Clicker, preventing further Clicker processes to listen

          AProcess.ShowWindow := swoShow;

          AProcess.CurrentDirectory := EvaluateReplacements(AExecAppOptions.CurrentDir);
          if AProcess.CurrentDirectory = '' then
            AProcess.CurrentDirectory := ExtractFileDir(ACmd);

          //if AExecAppOptions.WaitForApp then
          //  AProcess.Options := AppProcess.Options + [poWaitOnExit];  //do not use poWaitOnExit, because it blocks the application

          AProcess.Execute;     //run here

          if AProcess.Input = nil then
          begin
            Result := False;
            SetActionVarValue('$ExecAction_Err$', 'Input stream is nil after exec.');
          end;

          ExeInput := EvaluateReplacements(FastReplace_45ToReturn(AExecAppOptions.AppStdIn));

          TempStringList := TStringList.Create;
          try
            TempStringList.Text := ExeInput;
            TempStringList.SaveToStream(AProcess.Input);
          finally
            TempStringList.Free;
          end;

          TimeoutForAppRun := AActionOptions.ActionTimeout;
          if AExecAppOptions.WaitForApp then
          begin
            DoOnSetEditorEnabledState(False);

            try
              DoOnSetEditorTimeoutProgressBarMax(TimeoutForAppRun);
              tk := GetTickCount64;

              repeat
                Application.ProcessMessages;
                Sleep(100);

                if (AProcess.Output <> nil) and (AProcess.Output.NumBytesAvailable > 0) then
                begin
                  SetLength(TempBuffer, AProcess.Output.NumBytesAvailable);
                  if Length(TempBuffer) > 0 then
                  begin
                    AProcess.Output.Read(TempBuffer[0], Length(TempBuffer));
                    MemStream.Write(TempBuffer[0], Length(TempBuffer));
                  end;
                end;

                DoOnSetEditorTimeoutProgressBarPosition(GetTickCount64 - tk);

                if GetTickCount64 - tk >= TimeoutForAppRun then
                begin
                  if FSelfTemplateFileName = nil then
                    raise Exception.Create('FSelfTemplateFileName not set.');

                  PrependErrorMessageToActionVar('Timeout at "' + AActionOptions.ActionName + '" in ' + FSelfTemplateFileName^);
                  Result := False;
                  Break;
                end;

                if ((FStopAllActionsOnDemand <> nil) and FStopAllActionsOnDemand^) or
                   ((FStopAllActionsOnDemandFromParent <> nil) and FStopAllActionsOnDemandFromParent^) then
                begin
                  PrependErrorMessageToActionVar('App Execution manually stopped at "' + AActionOptions.ActionName + '" in ' + FSelfTemplateFileName^);
                  Result := False;
                  Break;
                end;
              until not AProcess.Active;

              if Result then
                SetActionVarValue('$ExecAction_Err$', '');
            finally
              DoOnSetEditorEnabledState(True);
            end;
          end;

          TempStringList := TStringList.Create;
          try
            if (AProcess.Output <> nil) and (AProcess.Output.NumBytesAvailable > 0) then     //read once more (in case the timeout stopped the reading)
            begin
              SetLength(TempBuffer, AProcess.Output.NumBytesAvailable);
              AProcess.Output.Read(TempBuffer[0], Length(TempBuffer));
              MemStream.Write(TempBuffer[0], Length(TempBuffer));
            end;

            MemStream.Position := 0;
            TempStringList.LoadFromStream(MemStream);

            ExeOutput := TempStringList.Text;
          finally
            TempStringList.Free;
          end;
        finally
          AProcess.Free;
          MemStream.Free;
        end;

        SetActionVarValue('$ExecAction_StdOut$', FastReplace_ReturnTo45(ExeOutput));
      except
        on E: Exception do
        begin
          Result := False;
          if (Pos('Stream write error', E.Message) > 0) and
             (AExecAppOptions.UseInheritHandles = uihNo) then
            E.Message := E.Message + '  Make sure the UseInheritHandles option is set to "Yes" or "Only with StdIn / StdOut", when using StdIn or StdOut.';

          if FSelfTemplateFileName = nil then
            raise Exception.Create('FSelfTemplateFileName not set.');

          ErrMsg := StringReplace(SysErrorMessage(GetLastOSError), '%1', '"' + ACmd + '"', [rfReplaceAll]);
          SetActionVarValue('$ExecAction_Err$', 'Exception "' + E.Message + '" at "' + AActionOptions.ActionName + '" in ' + FSelfTemplateFileName^ + '   SysMsg: ' + ErrMsg);
        end;
      end;
    {$ENDIF}
  finally
    AllParams.Free;
  end;

  DoOnSetEditorTimeoutProgressBarPosition(0);
end;


function TActionExecution.FillInFindControlInputData(var AFindControlOptions: TClkFindControlOptions; var AActionOptions: TClkActionOptions; IsSubControl: Boolean; out FindControlInputData: TFindControlInputData; out FontProfilesCount: Integer): Boolean;
  procedure IgnoredColorsStrToArr(AIgnoredColorsStr: string; var AIgnoredColorsArr: TColorArr);
  var
    i: Integer;
    ColorsStr: string;
    ListOfIgnoredColors: TStringList;
  begin
    if AIgnoredColorsStr <> '' then
    begin
      ListOfIgnoredColors := TStringList.Create;
      try
        ListOfIgnoredColors.Text := StringReplace(AIgnoredColorsStr, ',', #13#10, [rfReplaceAll]);

        SetLength(AIgnoredColorsArr, ListOfIgnoredColors.Count);
        for i := 0 to ListOfIgnoredColors.Count - 1 do
        begin
          ColorsStr := Trim(ListOfIgnoredColors.Strings[i]);    //a bit ugly to reuse the variable
          ColorsStr := EvaluateReplacements(ColorsStr);
          AIgnoredColorsArr[i] := HexToInt(ColorsStr);
        end;
      finally
        ListOfIgnoredColors.Free;
      end;
    end;
  end;
begin
  Result := True;

  FindControlInputData.MatchingMethods := [];
  if AFindControlOptions.MatchCriteria.WillMatchText then
    FindControlInputData.MatchingMethods := FindControlInputData.MatchingMethods + [mmText];

  if AFindControlOptions.MatchCriteria.WillMatchClassName then
    FindControlInputData.MatchingMethods := FindControlInputData.MatchingMethods + [mmClass];

  if AFindControlOptions.MatchCriteria.WillMatchBitmapText then
    FindControlInputData.MatchingMethods := FindControlInputData.MatchingMethods + [mmBitmapText];

  if AFindControlOptions.MatchCriteria.WillMatchBitmapFiles then
    FindControlInputData.MatchingMethods := FindControlInputData.MatchingMethods + [mmBitmapFiles];

  if AFindControlOptions.MatchCriteria.WillMatchPrimitiveFiles then
    FindControlInputData.MatchingMethods := FindControlInputData.MatchingMethods + [mmPrimitiveFiles];

  FindControlInputData.SearchAsSubControl := IsSubControl;
  FindControlInputData.DebugBitmap := nil;

  FindControlInputData.ClassName := EvaluateReplacements(AFindControlOptions.MatchClassName);
  FindControlInputData.Text := EvaluateReplacements(AFindControlOptions.MatchText, True);
  FindControlInputData.GetAllHandles := AFindControlOptions.GetAllControls;

  if AFindControlOptions.MatchCriteria.WillMatchBitmapText then
    if FindControlInputData.Text = '' then
    begin
      SetActionVarValue('$ExecAction_Err$', 'The searched text is empty.');
      SetActionVarValue('$DebugVar_BitmapText$', 'Matching an empty string will lead to a false match.');
      Result := False;
      Exit;
    end;

  FindControlInputData.ClassNameSeparator := AFindControlOptions.MatchClassNameSeparator;
  FindControlInputData.TextSeparator := AFindControlOptions.MatchTextSeparator;
  FindControlInputData.ColorError := StrToIntDef(EvaluateReplacements(AFindControlOptions.ColorError), 0);
  FindControlInputData.AllowedColorErrorCount := StrToIntDef(EvaluateReplacements(AFindControlOptions.AllowedColorErrorCount), 0);
  FindControlInputData.DebugTemplateName := FSelfTemplateFileName^;

  FontProfilesCount := Length(AFindControlOptions.MatchBitmapText);
  if FontProfilesCount = 0 then
  begin
    AddToLog('Adding default font profile to action: "' + AActionOptions.ActionName + '", of ' + CClkActionStr[AActionOptions.Action] + ' type.');
    DoOnAddDefaultFontProfile(AFindControlOptions, AActionOptions); //Currently, both FindControl and FindSubControl require a default font profile, because of the "for j" loop below. Once these two actions are split, only FindSubControl will require it.
    FontProfilesCount := Length(AFindControlOptions.MatchBitmapText);
  end;

  FindControlInputData.StartSearchingWithCachedControl := AFindControlOptions.StartSearchingWithCachedControl;
  FindControlInputData.CachedControlLeft := StrToIntDef(EvaluateReplacements(AFindControlOptions.CachedControlLeft), 0);
  FindControlInputData.CachedControlTop := StrToIntDef(EvaluateReplacements(AFindControlOptions.CachedControlTop), 0);

  if AFindControlOptions.GetAllControls then
    if not IsSubControl then
      SetActionVarValue('$AllControl_Handles$', '');

  FindControlInputData.UseFastSearch := AFindControlOptions.UseFastSearch;
  if FindControlInputData.UseFastSearch then
    FindControlInputData.FastSearchAllowedColorErrorCount := StrToIntDef(EvaluateReplacements(AFindControlOptions.FastSearchAllowedColorErrorCount), -1)
  else
    FindControlInputData.FastSearchAllowedColorErrorCount := 0; //not used anyway

  if IsSubControl then
    AddToLog('Searching with:  ColorError = ' + IntToStr(FindControlInputData.ColorError) +
             '   AllowedColorErrorCount = ' + IntToStr(FindControlInputData.AllowedColorErrorCount) +
             '   FastSearchAllowedColorErrorCount = ' + IntToStr(FindControlInputData.FastSearchAllowedColorErrorCount));

  IgnoredColorsStrToArr(AFindControlOptions.IgnoredColors, FindControlInputData.IgnoredColorsArr);
  if Length(FindControlInputData.IgnoredColorsArr) > 0 then
    AddToLog('Ignoring colors: ' + AFindControlOptions.IgnoredColors);

  FindControlInputData.SleepySearch := 2; //this allows a call to AppProcMsg, but does not use Sleep.
  if AFindControlOptions.SleepySearch then
    FindControlInputData.SleepySearch := FindControlInputData.SleepySearch or 1;  //Bit 0 is SleepySearch. Bit 1 is AppProcMsg.

  FindControlInputData.StopSearchOnMismatch := AFindControlOptions.StopSearchOnMismatch;

  /////////////////////////////Moved section    - because GlobalSearchArea has to stay stable between "for j" iterations
  if AFindControlOptions.UseWholeScreen then
  begin
    FindControlInputData.GlobalSearchArea.Left := 0;
    FindControlInputData.GlobalSearchArea.Top := 0;
    FindControlInputData.GlobalSearchArea.Right := Screen.Width;
    FindControlInputData.GlobalSearchArea.Bottom := Screen.Height;
  end
  else
  begin
    FindControlInputData.GlobalSearchArea.Left := StrToIntDef(EvaluateReplacements(AFindControlOptions.InitialRectangle.Left), 0);
    FindControlInputData.GlobalSearchArea.Top := StrToIntDef(EvaluateReplacements(AFindControlOptions.InitialRectangle.Top), 0);
    FindControlInputData.GlobalSearchArea.Right := StrToIntDef(EvaluateReplacements(AFindControlOptions.InitialRectangle.Right), 0);
    FindControlInputData.GlobalSearchArea.Bottom := StrToIntDef(EvaluateReplacements(AFindControlOptions.InitialRectangle.Bottom), 0);
  end;

  if not AFindControlOptions.WaitForControlToGoAway then  //Do not move this if statement, because GlobalSearchArea is modified below:
  begin
    AddToLog('Find (Sub)Control with text = "' + FindControlInputData.Text + '"' +
             '    GetAllControls is set to ' + BoolToStr(AFindControlOptions.GetAllControls, True) +
             '    SearchMode: ' + CSearchForControlModeStr[AFindControlOptions.MatchCriteria.SearchForControlMode]);

    AddToLog('Raw GlobalSearchArea.Left = ' + IntToStr(FindControlInputData.GlobalSearchArea.Left));
    AddToLog('Raw GlobalSearchArea.Top = ' + IntToStr(FindControlInputData.GlobalSearchArea.Top));
    AddToLog('Raw GlobalSearchArea.Right = ' + IntToStr(FindControlInputData.GlobalSearchArea.Right));
    AddToLog('Raw GlobalSearchArea.Bottom = ' + IntToStr(FindControlInputData.GlobalSearchArea.Bottom));
  end;

  FindControlInputData.InitialRectangleOffsets.Left := StrToIntDef(EvaluateReplacements(AFindControlOptions.InitialRectangle.LeftOffset), 0);
  FindControlInputData.InitialRectangleOffsets.Top := StrToIntDef(EvaluateReplacements(AFindControlOptions.InitialRectangle.TopOffset), 0);
  FindControlInputData.InitialRectangleOffsets.Right := StrToIntDef(EvaluateReplacements(AFindControlOptions.InitialRectangle.RightOffset), 0);
  FindControlInputData.InitialRectangleOffsets.Bottom := StrToIntDef(EvaluateReplacements(AFindControlOptions.InitialRectangle.BottomOffset), 0);

  Inc(FindControlInputData.GlobalSearchArea.Left, FindControlInputData.InitialRectangleOffsets.Left);
  Inc(FindControlInputData.GlobalSearchArea.Top, FindControlInputData.InitialRectangleOffsets.Top);
  Inc(FindControlInputData.GlobalSearchArea.Right, FindControlInputData.InitialRectangleOffsets.Right);
  Inc(FindControlInputData.GlobalSearchArea.Bottom, FindControlInputData.InitialRectangleOffsets.Bottom);

  if not AFindControlOptions.WaitForControlToGoAway then
  begin
    AddToLog('(With Offset) GlobalSearchArea.Left = ' + IntToStr(FindControlInputData.GlobalSearchArea.Left));
    AddToLog('(With Offset) GlobalSearchArea.Top = ' + IntToStr(FindControlInputData.GlobalSearchArea.Top));
    AddToLog('(With Offset) GlobalSearchArea.Right = ' + IntToStr(FindControlInputData.GlobalSearchArea.Right));
    AddToLog('(With Offset) GlobalSearchArea.Bottom = ' + IntToStr(FindControlInputData.GlobalSearchArea.Bottom));
  end;
  /////////////////////////////End of moved section

  if (FindControlInputData.GlobalSearchArea.Right - FindControlInputData.GlobalSearchArea.Left < 1) or
     (FindControlInputData.GlobalSearchArea.Bottom - FindControlInputData.GlobalSearchArea.Top < 1) then
  begin
    frClickerActions.imgDebugBmp.Picture.Bitmap.Width := 300;
    frClickerActions.imgDebugBmp.Picture.Bitmap.Height := 300;
    frClickerActions.imgDebugBmp.Canvas.Brush.Color := clWhite;
    frClickerActions.imgDebugBmp.Canvas.Pen.Color := clRed;
    frClickerActions.imgDebugBmp.Canvas.Font.Color := clRed;
    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 0, 'Invalid search area:   ');
    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 15, 'Rectangle width: ' + IntToStr(FindControlInputData.GlobalSearchArea.Right - FindControlInputData.GlobalSearchArea.Left) + '   ');
    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 30, 'Rectangle height: ' + IntToStr(FindControlInputData.GlobalSearchArea.Bottom - FindControlInputData.GlobalSearchArea.Top) + '   ');
    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 45, 'Please verify offsets.   ');

    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 65, 'GlobalRectangle left (with offset): ' + IntToStr(FindControlInputData.GlobalSearchArea.Left) + '   ');
    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 80, 'GlobalRectangle top (with offset): ' + IntToStr(FindControlInputData.GlobalSearchArea.Top) + '   ');
    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 95, 'GlobalRectangle right (with offset): ' + IntToStr(FindControlInputData.GlobalSearchArea.Right) + '   ');
    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 110, 'GlobalRectangle bottom (with offset): ' + IntToStr(FindControlInputData.GlobalSearchArea.Bottom) + '   ');

    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 135, 'Left offset: ' + IntToStr(FindControlInputData.InitialRectangleOffsets.Left) + '   ');
    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 150, 'Top offset: ' + IntToStr(FindControlInputData.InitialRectangleOffsets.Top) + '   ');
    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 165, 'Right offset: ' + IntToStr(FindControlInputData.InitialRectangleOffsets.Right) + '   ');
    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 180, 'Bottom offset: ' + IntToStr(FindControlInputData.InitialRectangleOffsets.Bottom) + '   ');

    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 210, 'FileName: '+ ExtractFileName(FSelfTemplateFileName^));
    frClickerActions.imgDebugBmp.Canvas.TextOut(0, 225, 'Action: "' + AActionOptions.ActionName + '"');

    AddToLog('Exiting find control, because the search area is negative.');
    AddToLog('');

    Result := False;
    Exit;
  end;

  if FindControlInputData.MatchingMethods = [] then   //section moved from above (although useful there), to allow refactoring
  begin
    SetActionVarValue('$ExecAction_Err$', 'No match criteria set. Action: ' + AActionOptions.ActionName);
    AddToLog('No match criteria set.');
    Result := False;
  end;

  FindControlInputData.DebugBitmap := frClickerActions.imgDebugBmp.Picture.Bitmap;
  FindControlInputData.DebugGrid := frClickerActions.imgDebugGrid;

  FindControlInputData.ImageSource := AFindControlOptions.ImageSource;
end;


//this function should eventually be split into FindControl and FindSubControl
function TActionExecution.ExecuteFindControlAction(var AFindControlOptions: TClkFindControlOptions; var AActionOptions: TClkActionOptions; IsSubControl: Boolean): Boolean; //returns True if found
{$IFDEF FPC}
  //const
  //  clSystemColor = $FF000000;
{$ENDIF}

  procedure UpdateActionVarValuesFromControl(AControl: TCompRec; AUpdate_ResultedErrorCount: Boolean = False);
  var
    Control_Width, Control_Height: Integer;
  begin
    Control_Width := AControl.ComponentRectangle.Right - AControl.ComponentRectangle.Left;
    Control_Height := AControl.ComponentRectangle.Bottom - AControl.ComponentRectangle.Top;

    SetActionVarValue('$Control_Text$', AControl.Text);
    SetActionVarValue('$Control_Left$', IntToStr(AControl.ComponentRectangle.Left));
    SetActionVarValue('$Control_Top$', IntToStr(AControl.ComponentRectangle.Top));
    SetActionVarValue('$Control_Right$', IntToStr(AControl.ComponentRectangle.Right));
    SetActionVarValue('$Control_Bottom$', IntToStr(AControl.ComponentRectangle.Bottom));
    SetActionVarValue('$Control_Width$', IntToStr(Control_Width));
    SetActionVarValue('$Control_Height$', IntToStr(Control_Height));
    SetActionVarValue('$Half_Control_Width$', IntToStr(Control_Width shr 1));
    SetActionVarValue('$Half_Control_Height$', IntToStr(Control_Height shr 1));

    SetActionVarValue('$Control_Class$', AControl.ClassName);
    SetActionVarValue('$Control_Handle$', IntToStr(AControl.Handle));
    SetActionVarValue('$DebugVar_SubCnvXOffset$', IntToStr(AControl.XOffsetFromParent));
    SetActionVarValue('$DebugVar_SubCnvYOffset$', IntToStr(AControl.YOffsetFromParent));

    if AUpdate_ResultedErrorCount then
      SetActionVarValue('$ResultedErrorCount$', IntToStr(AControl.ResultedErrorCount));
  end;

  procedure UpdateActionVarValuesFromResultedControlArr(var AResultedControlArr: TCompRecArr);
  var
    Control_Width, Control_Height: Integer;
    AllControl_Lefts_Str: string;
    AllControl_Tops_Str: string;
    AllControl_Rights_Str: string;
    AllControl_Bottoms_Str: string;
    AllControl_Widths_Str: string;
    AllControl_Heights_Str: string;
    AllHalf_Control_Widths_Str: string;
    AllHalf_Control_Heights_Str: string;
    i: Integer;
  begin
    AllControl_Lefts_Str := '';
    AllControl_Tops_Str := '';
    AllControl_Rights_Str := '';
    AllControl_Bottoms_Str := '';
    AllControl_Widths_Str := '';
    AllControl_Heights_Str := '';
    AllHalf_Control_Widths_Str := '';
    AllHalf_Control_Heights_Str := '';

    for i := 0 to Length(AResultedControlArr) - 1 do
    begin
      Control_Width := AResultedControlArr[i].ComponentRectangle.Right - AResultedControlArr[i].ComponentRectangle.Left;
      Control_Height := AResultedControlArr[i].ComponentRectangle.Bottom - AResultedControlArr[i].ComponentRectangle.Top;

      AllControl_Lefts_Str := AllControl_Lefts_Str + IntToStr(AResultedControlArr[i].ComponentRectangle.Left) + #4#5;
      AllControl_Tops_Str := AllControl_Tops_Str + IntToStr(AResultedControlArr[i].ComponentRectangle.Top) + #4#5;
      AllControl_Rights_Str := AllControl_Rights_Str + IntToStr(AResultedControlArr[i].ComponentRectangle.Right) + #4#5;
      AllControl_Bottoms_Str := AllControl_Bottoms_Str + IntToStr(AResultedControlArr[i].ComponentRectangle.Bottom) + #4#5;
      AllControl_Widths_Str := AllControl_Widths_Str + IntToStr(Control_Width) + #4#5;
      AllControl_Heights_Str := AllControl_Heights_Str + IntToStr(Control_Height) + #4#5;
      AllHalf_Control_Widths_Str := AllHalf_Control_Widths_Str + IntToStr(Control_Width shr 1) + #4#5;
      AllHalf_Control_Heights_Str := AllHalf_Control_Heights_Str + IntToStr(Control_Height shr 1) + #4#5;
    end;

    SetActionVarValue('$AllControl_Lefts$', AllControl_Lefts_Str);
    SetActionVarValue('$AllControl_Tops$', AllControl_Tops_Str);
    SetActionVarValue('$AllControl_Rights$', AllControl_Rights_Str);
    SetActionVarValue('$AllControl_Bottoms$', AllControl_Bottoms_Str);
    SetActionVarValue('$AllControl_Widths$', AllControl_Widths_Str);
    SetActionVarValue('$AllControl_Heights$', AllControl_Heights_Str);
    SetActionVarValue('$AllHalf_Control_Widths$', AllHalf_Control_Widths_Str);
    SetActionVarValue('$AllHalf_Control_Heights$', AllHalf_Control_Heights_Str);
  end;

  procedure SetDbgImgPos(AMatchBitmapAlgorithm: TMatchBitmapAlgorithm; AFindControlInputData: TFindControlInputData; AResultedControl: TCompRec);
  begin
    case AFindControlOptions.MatchBitmapAlgorithm of
      mbaBruteForce:
      begin
        frClickerActions.imgDebugGrid.Left := AResultedControl.XOffsetFromParent;
        frClickerActions.imgDebugGrid.Top := AResultedControl.YOffsetFromParent;
      end;

      mbaXYMultipleAndOffsets:
      begin
        frClickerActions.imgDebugGrid.Left := AFindControlInputData.InitialRectangleOffsets.Left;
        frClickerActions.imgDebugGrid.Top := AFindControlInputData.InitialRectangleOffsets.Top;
      end;
    end; //case
  end;

  procedure SetAllControl_Handles_FromResultedControlArr(var AResultedControlArr: TCompRecArr; AMatchSource, ADetailedMatchSource: string);
  var
    i: Integer;
    s, xs, ys, ErrCnts: string;
  begin
    s := '';
    xs := '';
    ys := '';
    ErrCnts := '';

    for i := 0 to Length(AResultedControlArr) - 1 do
    begin
      s := s + IntToStr(AResultedControlArr[i].Handle) + #4#5;
      xs := xs + IntToStr(AResultedControlArr[i].XOffsetFromParent) + #4#5;
      ys := ys + IntToStr(AResultedControlArr[i].YOffsetFromParent) + #4#5;
      ErrCnts := ErrCnts + IntToStr(AResultedControlArr[i].ResultedErrorCount) + #4#5;
    end;

    SetActionVarValue('$AllControl_Handles$', s);
    SetActionVarValue('$AllControl_XOffsets$', xs);
    SetActionVarValue('$AllControl_YOffsets$', ys);

    SetActionVarValue('$AllControl_MatchSource$', AMatchSource);
    SetActionVarValue('$AllControl_DetailedMatchSource$', ADetailedMatchSource);
    SetActionVarValue('$AllControl_ResultedErrorCount$', ErrCnts);
  end;

  procedure AddInfoToMatchSource(AMatchSourceInfo, ADetailedMatchSourceInfo: string; ACount: Integer; var AMatchSource, ADetailedMatchSource: string);
  var
    ii: Integer;
  begin
    for ii := 0 to ACount - 1 do
    begin
      AMatchSource := AMatchSource + AMatchSourceInfo + #4#5;                         //see $AllControl_MatchSource$ var
      ADetailedMatchSource := ADetailedMatchSource + ADetailedMatchSourceInfo + #4#5; //see $AllControl_DetailedMatchSource$ var
    end;
  end;

  procedure LoadBitmapToSearchOn(AFindControlInputData: TFindControlInputData);
  var
    Res: Boolean;
    Fnm: string;
  begin
    if AFindControlOptions.ImageSource = isFile then
    begin
      Res := True;
      Fnm := DoOnResolveTemplatePath(AFindControlOptions.SourceFileName);

      case AFindControlOptions.ImageSourceFileNameLocation of
        isflDisk:
          Res := DoOnLoadBitmap(AFindControlInputData.BitmapToSearchOn, Fnm);

        isflMem:
          Res := DoOnLoadRenderedBitmap(AFindControlInputData.BitmapToSearchOn, Fnm);
      end;

      if not Res then
        AddToLog('Cannot load BitmapToSearchOn.  FileNameLocation = ' +
                 CImageSourceFileNameLocationStr[AFindControlOptions.ImageSourceFileNameLocation] +
                 '  FileName = "' + Fnm + '"');
    end
    else
      AddToLog('BitmapToSearchOn not used... Using screenshot.');
  end;

var
  i, j, k, n: Integer;
  ListOfBitmapFiles, ListOfPrimitiveFiles: TStringList;
  ResultedControl: TCompRec;
  ResultedControlArr, PartialResultedControlArr: TCompRecArr;
  ResultedControlArr_Text, ResultedControlArr_Bmp, ResultedControlArr_Pmtv: TCompRecArr;
  MatchSource, DetailedMatchSource: string;
  InitialTickCount, Timeout: QWord;
  FindControlInputData, WorkFindControlInputData: TFindControlInputData;
  StopAllActionsOnDemandAddr: Pointer;
  EvalFG, EvalBG: string;
  TemplateDir: string;

  TempPrimitives: TPrimitiveRecArr;
  TempOrders: TCompositionOrderArr;
  TempPrimitiveSettings: TPrimitiveSettings;
  PrimitivesCompositor: TPrimitivesCompositor;
  PrimitiveFound: Boolean;
  FindControlOnScreen_Result: Boolean;
begin
  Result := False;

  frClickerActions.DebuggingInfoAvailable := False;

  SetActionVarValue('$ExecAction_Err$', '');
  ResultedControl.XOffsetFromParent := 0; //init here, in case FindControlOnScreen does not update it
  ResultedControl.YOffsetFromParent := 0; //init here, in case FindControlOnScreen does not update it

  if not FillInFindControlInputData(AFindControlOptions, AActionOptions, IsSubControl, FindControlInputData, n) then
    Exit;

  InitialTickCount := GetTickCount64;
  if AActionOptions.ActionTimeout < 0 then
    Timeout := 0
  else
    Timeout := AActionOptions.ActionTimeout;

  if FStopAllActionsOnDemandFromParent <> nil then
  begin
    //MessageBox(Handle, 'Using global stop on demand.', PChar(Caption), MB_ICONINFORMATION);
    StopAllActionsOnDemandAddr := FStopAllActionsOnDemandFromParent;
  end
  else
  begin
    //MessageBox(Handle, 'Using local stop on demand.', PChar(Caption), MB_ICONINFORMATION);
    StopAllActionsOnDemandAddr := FStopAllActionsOnDemand;
  end;

  if not IsSubControl then
  begin  //FindControl
    case AFindControlOptions.MatchCriteria.SearchForControlMode of
      sfcmGenGrid:
      begin
        if (mmText in FindControlInputData.MatchingMethods) or
           (mmClass in FindControlInputData.MatchingMethods) then
        begin
          try
            SetLength(PartialResultedControlArr, 0);
            WorkFindControlInputData := FindControlInputData;
            if FindControlOnScreen(AFindControlOptions.MatchBitmapAlgorithm, AFindControlOptions.MatchBitmapAlgorithmSettings, WorkFindControlInputData, InitialTickCount, Timeout, StopAllActionsOnDemandAddr, PartialResultedControlArr, DoOnGetGridDrawingOption) then
            begin
              UpdateActionVarValuesFromControl(PartialResultedControlArr[0]);
              //frClickerActions.DebuggingInfoAvailable := True;
              //
              //if AFindControlOptions.GetAllControls then
              //begin
              //  SetAllControl_Handles_FromResultedControlArr(ResultedControlArr);
              //  UpdateActionVarValuesFromResultedControlArr(ResultedControlArr);
              //end;

              CopyPartialResultsToFinalResult(ResultedControlArr, PartialResultedControlArr);
              Result := True;
              AddToLog('Found text: "' + AFindControlOptions.MatchText + '" in ' + IntToStr(GetTickCount64 - InitialTickCount) + 'ms.');

              if AFindControlOptions.GetAllControls then
                AddToLog('Result count: ' + IntToStr(Length(PartialResultedControlArr)));

              if not AFindControlOptions.GetAllControls then
                Exit;  //to prevent further searching for bitmap files, primitives or other text profiles
            end;
          finally
            if Length(PartialResultedControlArr) > 0 then
              ResultedControl := PartialResultedControlArr[0];  //ResultedControl has some fields, initialized before the search. If no result is found, then call SetDbgImgPos with those values.

            SetDbgImgPos(AFindControlOptions.MatchBitmapAlgorithm, WorkFindControlInputData, ResultedControl);
          end;
        end;
      end;   //sfcmGenGrid

      sfcmEnumWindows:        //Caption OR Class
      begin
        if FindWindowOnScreenByCaptionOrClass(FindControlInputData, InitialTickCount, Timeout, StopAllActionsOnDemandAddr, ResultedControl) then
        begin
          UpdateActionVarValuesFromControl(ResultedControl);
          Result := True;
          frClickerActions.DebuggingInfoAvailable := True;
          Exit;  //to prevent further searching for bitmap files
        end;
      end;

      sfcmFindWindow:         //Caption AND Class
      begin
        if FindWindowOnScreenByCaptionAndClass(FindControlInputData, InitialTickCount, Timeout, StopAllActionsOnDemandAddr, ResultedControlArr) then
        begin
          UpdateActionVarValuesFromControl(ResultedControlArr[0]);
          Result := True;
          frClickerActions.DebuggingInfoAvailable := True;

          if AFindControlOptions.GetAllControls then
            SetAllControl_Handles_FromResultedControlArr(ResultedControlArr, '', '');

          Exit;  //to prevent further searching for bitmap files
        end;
      end;
    end; //case

    if Result then
      if Length(ResultedControlArr) > 0 then
      begin
        UpdateActionVarValuesFromControl(ResultedControlArr[0]);
        frClickerActions.DebuggingInfoAvailable := True;

        if AFindControlOptions.GetAllControls then
        begin
          SetAllControl_Handles_FromResultedControlArr(ResultedControlArr, '', '');
          UpdateActionVarValuesFromResultedControlArr(ResultedControlArr);
        end;
      end;

    Exit;
  end; //FindControl

  SetLength(ResultedControlArr_Text, 0);
  SetLength(ResultedControlArr_Bmp, 0);
  SetLength(ResultedControlArr_Pmtv, 0);

  MatchSource := '';
  DetailedMatchSource := '';
  try
    if AFindControlOptions.MatchCriteria.WillMatchBitmapText then
    begin
      SetLength(ResultedControlArr, 0);
      for j := 0 to n - 1 do //number of font profiles
      begin
        if j > n - 1 then  //it seems that a FP bug allows "j" to go past n - 1. It may happen on EnumerateWindows only. At best, the memory is overwritten, which causes this behavior.
          Break;

        FindControlInputData.BitmapToSearchFor := TBitmap.Create;
        FindControlInputData.BitmapToSearchOn := TBitmap.Create;
        try
          FindControlInputData.BitmapToSearchFor.PixelFormat := pf24bit;
          LoadBitmapToSearchOn(FindControlInputData);

          //if AFindControlOptions.MatchCriteria.WillMatchBitmapText then
          begin
            EvalFG := EvaluateReplacements(AFindControlOptions.MatchBitmapText[j].ForegroundColor, True);
            EvalBG := EvaluateReplacements(AFindControlOptions.MatchBitmapText[j].BackgroundColor, True);
            AddToLog('Searching with text profile[' + IntToStr(j) + ']: ' + AFindControlOptions.MatchBitmapText[j].ProfileName);

            SetActionVarValue('$DebugVar_TextColors$',
                              'FileName=' + FSelfTemplateFileName^ +
                              //' FG=' + IntToHex(frClickerActions.frClickerFindControl.BMPTextFontProfiles[j].FGColor, 8) +
                              //' BG=' + IntToHex(frClickerActions.frClickerFindControl.BMPTextFontProfiles[j].BGColor, 8) +
                              ' Eval(FG)=' + EvaluateReplacements(AFindControlOptions.MatchBitmapText[j].ForegroundColor, False) + '=' + EvalFG +
                              ' Eval(BG)=' + EvaluateReplacements(AFindControlOptions.MatchBitmapText[j].BackgroundColor, False) + '=' + EvalBG );

            //if frClickerActions.frClickerFindControl.BMPTextFontProfiles[j].FGColor and clSystemColor <> 0 then  //clSystemColor is declared above
            //begin
            //  frClickerActions.frClickerFindControl.BMPTextFontProfiles[j].FGColor := clFuchsia;
            //  AddToLog('System color found on text FG: $' + IntToHex(frClickerActions.frClickerFindControl.BMPTextFontProfiles[j].FGColor, 8));
            //end;
            //
            //if frClickerActions.frClickerFindControl.BMPTextFontProfiles[j].BGColor and clSystemColor <> 0 then  //clSystemColor is declared above
            //begin
            //  frClickerActions.frClickerFindControl.BMPTextFontProfiles[j].BGColor := clLime;
            //  AddToLog('System color found on text BG: $' + IntToHex(frClickerActions.frClickerFindControl.BMPTextFontProfiles[j].BGColor, 8));
            //end;

            SetActionVarValue('$DebugVar_BitmapText$', FindControlInputData.Text);

            // frClickerActions.frClickerFindControl.PreviewText;

            try
              PreviewTextOnBmp(AFindControlOptions, FindControlInputData.Text, j, FindControlInputData.BitmapToSearchFor);
            except
              on E: Exception do
              begin
                AddToLog('Can''t preview bmp text. Ex: "' + E.Message + '".  Action: "' + AActionOptions.ActionName + '" of ' + CClkActionStr[AActionOptions.Action] + ' type.');
                // frClickerActions.frClickerFindControl.BMPTextFontProfiles[j].ProfileName  is no longer available, since no UI is updated on remote execution. It is replaced by AFindControlOptions.MatchBitmapText[j].ProfileName.
                raise Exception.Create(E.Message + '  Profile[' + IntToStr(j) + ']: "' + AFindControlOptions.MatchBitmapText[j].ProfileName + '".   Searched text: "' + FindControlInputData.Text + '"');
              end;
            end;
            //This is the original code for getting the text from the editor, instead of rendering with PreviewTextOnBmp. It should do the same thing.
            //FindControlInputData.BitmapToSearchFor.Width := frClickerActions.frClickerFindControl.BMPTextFontProfiles[j].PreviewImageBitmap.Width;
            //FindControlInputData.BitmapToSearchFor.Height := frClickerActions.frClickerFindControl.BMPTextFontProfiles[j].PreviewImageBitmap.Height;
            //FindControlInputData.BitmapToSearchFor.Canvas.Draw(0, 0, frClickerActions.frClickerFindControl.BMPTextFontProfiles[j].PreviewImageBitmap);   //updated above by PreviewText
          end;  //WillMatchBitmapText

          //if AFindControlOptions.MatchCriteria.WillMatchPrimitiveFiles then   //dbg only
          //begin
          //  FindControlInputData.BitmapToSearchFor.Canvas.Pen.Color := clRed;
          //  FindControlInputData.BitmapToSearchFor.Canvas.Line(20, 30, 60, 70);
          //end;


          //negative area verification - moved above "for j" loop

          FindControlInputData.IgnoreBackgroundColor := AFindControlOptions.MatchBitmapText[j].IgnoreBackgroundColor;
          FindControlInputData.BackgroundColor := HexToInt(EvalBG);


          //clear debug image
          frClickerActions.imgDebugBmp.Canvas.Pen.Color := clWhite;
          frClickerActions.imgDebugBmp.Canvas.Brush.Color := clWhite;
          frClickerActions.imgDebugBmp.Canvas.Rectangle(0, 0, frClickerActions.imgDebugBmp.Width, frClickerActions.imgDebugBmp.Height);

          //FindControlInputData.DebugBitmap := frClickerActions.imgDebugBmp.Picture.Bitmap;    //section moved above :for j" loop
          //FindControlInputData.DebugGrid := frClickerActions.imgDebugGrid;

          try
            SetLength(PartialResultedControlArr, 0);
            WorkFindControlInputData := FindControlInputData;
            FindControlOnScreen_Result := FindControlOnScreen(AFindControlOptions.MatchBitmapAlgorithm,
                                                              AFindControlOptions.MatchBitmapAlgorithmSettings,
                                                              WorkFindControlInputData,
                                                              InitialTickCount,
                                                              Timeout,
                                                              StopAllActionsOnDemandAddr,
                                                              PartialResultedControlArr,
                                                              DoOnGetGridDrawingOption);

            if FindControlOnScreen_Result or not FindControlInputData.StopSearchOnMismatch then
            begin
              if not FindControlOnScreen_Result and not FindControlInputData.StopSearchOnMismatch then
                AddToLog('Can''t find the subcontrol (text), but the searching went further, to get the error count. See $ResultedErrorCount$.');

              if Length(PartialResultedControlArr) = 0 then  //it looks like FindControlOnScreen may return with an empty array and a result set to True
                SetLength(PartialResultedControlArr, 1);

              UpdateActionVarValuesFromControl(PartialResultedControlArr[0], not FindControlInputData.StopSearchOnMismatch);
              //frClickerActions.DebuggingInfoAvailable := True;
              //
              //if AFindControlOptions.GetAllControls then
              //begin
              //  SetAllControl_Handles_FromResultedControlArr(ResultedControlArr);
              //  UpdateActionVarValuesFromResultedControlArr(ResultedControlArr);
              //end;

              CopyPartialResultsToFinalResult(ResultedControlArr_Text, PartialResultedControlArr);

              Result := True;
              AddToLog('Found text: "' + AFindControlOptions.MatchText + '" in ' + IntToStr(GetTickCount64 - InitialTickCount) + 'ms.');

              if AFindControlOptions.GetAllControls then
              begin
                AddToLog('Result count: ' + IntToStr(Length(PartialResultedControlArr)));
                AddInfoToMatchSource('txt[' + IntToStr(j) + ']', 'txt[' + IntToStr(j) + '][0]', Length(PartialResultedControlArr), MatchSource, DetailedMatchSource); //hardcoded to [0] as no other subfeature is implemented
              end;

              if not AFindControlOptions.GetAllControls then
                Exit;  //to prevent further searching for bitmap files, primitives or other text profiles
            end;
          finally
            if Length(PartialResultedControlArr) > 0 then
              ResultedControl := PartialResultedControlArr[0];  //ResultedControl has some fields, initialized before the search. If no result is found, then call SetDbgImgPos with those values.

            SetDbgImgPos(AFindControlOptions.MatchBitmapAlgorithm, WorkFindControlInputData, ResultedControl);
          end;
        finally
          FindControlInputData.BitmapToSearchFor.Free;
          FindControlInputData.BitmapToSearchOn.Free;
        end;

        if Result and not AFindControlOptions.GetAllControls then
          Break;
      end;  //for j  - font profiles

      AddToLog('MatchSource: ' + MatchSource);
      AddToLog('DetailedMatchSource: ' + DetailedMatchSource);
    end; //WillMatchBitmapText


    if mmBitmapFiles in FindControlInputData.MatchingMethods then
    begin
      FindControlInputData.BitmapToSearchFor := TBitmap.Create;
      FindControlInputData.BitmapToSearchOn := TBitmap.Create;
      try
        FindControlInputData.BitmapToSearchFor.PixelFormat := pf24bit;
        LoadBitmapToSearchOn(FindControlInputData);

        ListOfBitmapFiles := TStringList.Create;
        try
          ListOfBitmapFiles.Text := AFindControlOptions.MatchBitmapFiles;
          AddToLog('Bmp file count to search with: ' + IntToStr(ListOfBitmapFiles.Count));

          if FExecutingActionFromRemote = nil then
            raise Exception.Create('FExecutingActionFromRemote is not assigned.');

          if FFileLocationOfDepsIsMem = nil then
            raise Exception.Create('FFileLocationOfDepsIsMem is not assigned.');

          if FSelfTemplateFileName = nil then
            TemplateDir := 'FSelfTemplateFileName not set.'
          else
            TemplateDir := ExtractFileDir(FSelfTemplateFileName^);

          for i := 0 to ListOfBitmapFiles.Count - 1 do
            ListOfBitmapFiles.Strings[i] := StringReplace(ListOfBitmapFiles.Strings[i], '$SelfTemplateDir$', TemplateDir, [rfReplaceAll]);

          for i := 0 to ListOfBitmapFiles.Count - 1 do
            ListOfBitmapFiles.Strings[i] := StringReplace(ListOfBitmapFiles.Strings[i], '$TemplateDir$', FFullTemplatesDir^, [rfReplaceAll]);

          //Leave this section commented, it exists after the DoOnWaitForBitmapsAvailability call!
          //if not FExecutingActionFromRemote^ then
          //begin
          //  for i := 0 to ListOfBitmapFiles.Count - 1 do
          //    ListOfBitmapFiles.Strings[i] := StringReplace(ListOfBitmapFiles.Strings[i], '$AppDir$', ExtractFileDir(ParamStr(0)), [rfReplaceAll]);
          //end;

          if FExecutingActionFromRemote^ and FFileLocationOfDepsIsMem^ then
          begin
            AddToLog('Might wait for some bitmap files to be present in memory..');
            DoOnWaitForBitmapsAvailability(ListOfBitmapFiles);
          end;

          //resolving the $AppDir$ replacement after having all files available
          for i := 0 to ListOfBitmapFiles.Count - 1 do
            ListOfBitmapFiles.Strings[i] := StringReplace(ListOfBitmapFiles.Strings[i], '$AppDir$', ExtractFileDir(ParamStr(0)), [rfReplaceAll]);

          for i := 0 to ListOfBitmapFiles.Count - 1 do
          begin
            if not DoOnLoadBitmap(FindControlInputData.BitmapToSearchFor, ListOfBitmapFiles.Strings[i]) then
            begin
              AppendErrorMessageToActionVar('File not found: "' + ListOfBitmapFiles.Strings[i] + '" ');
              Continue;
            end;

            //memLogErr.Lines.Add('DebugBitmap pixel format: ' + IntToStr(Ord(FindControlInputData.DebugBitmap.PixelFormat))); // [6]  - 24-bit

            InitialTickCount := GetTickCount64;
            if AActionOptions.ActionTimeout < 0 then
              Timeout := 0
            else
              Timeout := AActionOptions.ActionTimeout;

            SetLength(PartialResultedControlArr, 0);
            WorkFindControlInputData := FindControlInputData;
            FindControlOnScreen_Result := FindControlOnScreen(AFindControlOptions.MatchBitmapAlgorithm,
                                                              AFindControlOptions.MatchBitmapAlgorithmSettings,
                                                              WorkFindControlInputData,
                                                              InitialTickCount,
                                                              Timeout,
                                                              StopAllActionsOnDemandAddr,
                                                              PartialResultedControlArr,
                                                              DoOnGetGridDrawingOption);

            if FindControlOnScreen_Result or not FindControlInputData.StopSearchOnMismatch then
            begin
              if not FindControlOnScreen_Result and not FindControlInputData.StopSearchOnMismatch then
                AddToLog('Can''t find the subcontrol (bmp), but the searching went further, to get the error count. See $ResultedErrorCount$.');

              if Length(PartialResultedControlArr) = 0 then  //it looks like FindControlOnScreen may return with an empty array and a result set to True
                SetLength(PartialResultedControlArr, 1);

              UpdateActionVarValuesFromControl(PartialResultedControlArr[0], not FindControlInputData.StopSearchOnMismatch);
              frClickerActions.DebuggingInfoAvailable := True;

              CopyPartialResultsToFinalResult(ResultedControlArr_Bmp, PartialResultedControlArr);
              Result := True;

              if AFindControlOptions.GetAllControls then
              begin
                //SetAllControl_Handles_FromResultedControlArr(ResultedControlArr);
                //UpdateActionVarValuesFromResultedControlArr(ResultedControlArr);

                AddToLog('Result count: ' + IntToStr(Length(PartialResultedControlArr)));
                AddInfoToMatchSource('bmp[' + IntToStr(i) + ']', 'bmp[' + IntToStr(i) + '][0]', Length(PartialResultedControlArr), MatchSource, DetailedMatchSource); //hardcoded to [0] as no other subfeature is implemented
              end
              else
                Exit;  //to prevent further searching for other bitmap files
            end;
          end; //for i
        finally
          ListOfBitmapFiles.Free;
          if Length(PartialResultedControlArr) > 0 then
            ResultedControl := PartialResultedControlArr[0];

          SetDbgImgPos(AFindControlOptions.MatchBitmapAlgorithm, WorkFindControlInputData, ResultedControl);
        end;
      finally
        FindControlInputData.BitmapToSearchFor.Free;
        FindControlInputData.BitmapToSearchOn.Free;
      end;

      AddToLog('MatchSource: ' + MatchSource);
      AddToLog('DetailedMatchSource: ' + DetailedMatchSource);
    end; //WillMatchBitmapFiles

    if AFindControlOptions.MatchCriteria.WillMatchPrimitiveFiles then
    begin
      FindControlInputData.BitmapToSearchFor := TBitmap.Create;
      FindControlInputData.BitmapToSearchOn := TBitmap.Create;
      try
        FindControlInputData.BitmapToSearchFor.PixelFormat := pf24bit;
        LoadBitmapToSearchOn(FindControlInputData);

        ListOfPrimitiveFiles := TStringList.Create;
        try
          ListOfPrimitiveFiles.Text := AFindControlOptions.MatchPrimitiveFiles;
          AddToLog('Pmtv file count to search with: ' + IntToStr(ListOfPrimitiveFiles.Count));

          if FSelfTemplateFileName = nil then
            TemplateDir := 'FSelfTemplateFileName not set.'
          else
            TemplateDir := ExtractFileDir(FSelfTemplateFileName^);

          for i := 0 to ListOfPrimitiveFiles.Count - 1 do
            ListOfPrimitiveFiles.Strings[i] := StringReplace(ListOfPrimitiveFiles.Strings[i], '$SelfTemplateDir$', TemplateDir, [rfReplaceAll]);

          for i := 0 to ListOfPrimitiveFiles.Count - 1 do
            ListOfPrimitiveFiles.Strings[i] := StringReplace(ListOfPrimitiveFiles.Strings[i], '$TemplateDir$', FFullTemplatesDir^, [rfReplaceAll]);

          //Leave this section commented, it exists after the DoOnWaitForBitmapsAvailability call!
          //if not FExecutingActionFromRemote^ then   //files from client will not have the $AppDir$ replacement resolved here, because of requesting them with original name
          //begin
          //  for i := 0 to ListOfPrimitiveFiles.Count - 1 do
          //    ListOfPrimitiveFiles.Strings[i] := StringReplace(ListOfPrimitiveFiles.Strings[i], '$AppDir$', ExtractFileDir(ParamStr(0)), [rfReplaceAll]);
          //end;

          if FExecutingActionFromRemote^ and FFileLocationOfDepsIsMem^ then
          begin
            AddToLog('Might wait for some primitives files to be present in memory..');
            DoOnWaitForBitmapsAvailability(ListOfPrimitiveFiles);    //might also work for pmtv files
                                                                     //ComposePrimitive_Image also has to wait for bmp files
          end;

          //resolving the $AppDir$ replacement after having all files available
          for i := 0 to ListOfPrimitiveFiles.Count - 1 do
            ListOfPrimitiveFiles.Strings[i] := StringReplace(ListOfPrimitiveFiles.Strings[i], '$AppDir$', ExtractFileDir(ParamStr(0)), [rfReplaceAll]);


          for i := 0 to ListOfPrimitiveFiles.Count - 1 do
          begin
            PrimitiveFound := False;
            DoOnLoadPrimitivesFile(ListOfPrimitiveFiles.Strings[i], TempPrimitives, TempOrders, TempPrimitiveSettings);
            //if not DoOnLoadPrimitivesFile(ListOfPrimitiveFiles.Strings[i], TempPrimitives, TempOrders, TempPrimitiveSettings)then
            //begin
            //  AppendErrorMessageToActionVar('File not found: "' + ListOfPrimitiveFiles.Strings[i] + '" ');
            //  Continue;
            //end;

            if Length(TempPrimitives) = 0 then
            begin
              if FExecutingActionFromRemote^ and (Pos('$AppDir$', ListOfPrimitiveFiles.Strings[i]) > 0) then
                AddToLog('Primitives file: "' + ExtractFileName(ListOfPrimitiveFiles.Strings[i]) + '" has no primitives because is is not loaded. It should have been received from client but it has an illegal path, which contains "$AppDir$".')
              else
                AddToLog('Primitives file: "' + ExtractFileName(ListOfPrimitiveFiles.Strings[i]) + '" has no primitives.');

              Continue;
            end;

            PrimitivesCompositor := TPrimitivesCompositor.Create;
            try
              PrimitivesCompositor.FileIndex := i;
              PrimitivesCompositor.OnEvaluateReplacementsFunc := HandleOnEvaluateReplacements;
              PrimitivesCompositor.OnLoadBitmap := HandleOnLoadBitmap;
              PrimitivesCompositor.OnLoadRenderedBitmap := HandleOnLoadRenderedBitmap;

              FindControlInputData.BitmapToSearchFor.Width := PrimitivesCompositor.GetMaxX(FindControlInputData.BitmapToSearchFor.Canvas, TempPrimitives) + 1;
              FindControlInputData.BitmapToSearchFor.Height := PrimitivesCompositor.GetMaxY(FindControlInputData.BitmapToSearchFor.Canvas, TempPrimitives) + 1;

              if (FindControlInputData.BitmapToSearchFor.Width = 0) or (FindControlInputData.BitmapToSearchFor.Height = 0) then
              begin
                AddToLog('Primitives file: "' + ExtractFileName(ListOfPrimitiveFiles.Strings[i]) + '" has a zero width or height');
                Continue;
              end;

              for k := 0 to Length(TempOrders) - 1 do
              begin
                InitialTickCount := GetTickCount64;
                if AActionOptions.ActionTimeout < 0 then
                  Timeout := 0
                else
                  Timeout := AActionOptions.ActionTimeout;

                //no need to clear the bitmap, it is already implemented in ComposePrimitives
                PrimitivesCompositor.ComposePrimitives(FindControlInputData.BitmapToSearchFor, k, False, TempPrimitives, TempOrders, TempPrimitiveSettings);

                SetLength(PartialResultedControlArr, 0);
                WorkFindControlInputData := FindControlInputData;
                FindControlOnScreen_Result := FindControlOnScreen(AFindControlOptions.MatchBitmapAlgorithm,
                                                                  AFindControlOptions.MatchBitmapAlgorithmSettings,
                                                                  WorkFindControlInputData,
                                                                  InitialTickCount,
                                                                  Timeout,
                                                                  StopAllActionsOnDemandAddr,
                                                                  PartialResultedControlArr,
                                                                  DoOnGetGridDrawingOption);

                if FindControlOnScreen_Result or not FindControlInputData.StopSearchOnMismatch then
                begin
                  if not FindControlOnScreen_Result and not FindControlInputData.StopSearchOnMismatch then
                    AddToLog('Can''t find the subcontrol (pmtv), but the searching went further, to get the error count. See $ResultedErrorCount$.');

                  if Length(PartialResultedControlArr) = 0 then  //it looks like FindControlOnScreen may return with an empty array and a result set to True
                    SetLength(PartialResultedControlArr, 1);

                  PrimitiveFound := True;
                  UpdateActionVarValuesFromControl(PartialResultedControlArr[0], not FindControlInputData.StopSearchOnMismatch);
                  frClickerActions.DebuggingInfoAvailable := True;

                  CopyPartialResultsToFinalResult(ResultedControlArr_Pmtv, PartialResultedControlArr);
                  Result := True;
                  AddToLog('Matched by primitives file: "' + ExtractFileName(ListOfPrimitiveFiles.Strings[i]) + '"  at order ' + IntToStr(k) + '.  Bmp w/h: ' + IntToStr(FindControlInputData.BitmapToSearchFor.Width) + ' / ' + IntToStr(FindControlInputData.BitmapToSearchFor.Height) + '  Result count: ' + IntToStr(Length(ResultedControlArr)));

                  if AFindControlOptions.GetAllControls then
                  begin
                    AddToLog('Result count: ' + IntToStr(Length(PartialResultedControlArr)));
                    AddInfoToMatchSource('pmtv[' + IntToStr(i * Length(TempOrders) + k) + ']', 'pmtv[' + IntToStr(i) + '][' + IntToStr(k) + ']', Length(PartialResultedControlArr), MatchSource, DetailedMatchSource);
                  end;

                  if not AFindControlOptions.GetAllControls then
                  begin
                    //SetAllControl_Handles_FromResultedControlArr(ResultedControlArr);
                    //UpdateActionVarValuesFromResultedControlArr(ResultedControlArr);
                    //Do not call UpdateActionVarValuesFromResultedControlArr and SetAllControl_Handles_FromResultedControlArr here, because this loop is about primitives orders
                    Break;  //to prevent further searching for other primitive compositions
                  end;
                end;
              end; //for k
            finally
              PrimitivesCompositor.Free;
            end;

            if PrimitiveFound then     //use PrimitiveFound outside of "for k" loop
            begin
              if AFindControlOptions.GetAllControls then
              begin
                //SetAllControl_Handles_FromResultedControlArr(ResultedControlArr);
                //UpdateActionVarValuesFromResultedControlArr(ResultedControlArr);
              end
              else
                Exit;  //to prevent further searching for other primitive compositions
            end;
          end; //for i   -  primitives
        finally
          ListOfPrimitiveFiles.Free;
          if Length(PartialResultedControlArr) > 0 then
            ResultedControl := PartialResultedControlArr[0];

          SetDbgImgPos(AFindControlOptions.MatchBitmapAlgorithm, WorkFindControlInputData, ResultedControl);
        end;
      finally
        FindControlInputData.BitmapToSearchFor.Free;
        FindControlInputData.BitmapToSearchOn.Free;
      end;

      AddToLog('MatchSource: ' + MatchSource);
      AddToLog('DetailedMatchSource: ' + DetailedMatchSource);
    end; //WillMatchPrimitiveFiles
  finally
    if Result then
    begin
      CopyPartialResultsToFinalResult(ResultedControlArr, ResultedControlArr_Text);
      CopyPartialResultsToFinalResult(ResultedControlArr, ResultedControlArr_Bmp);
      CopyPartialResultsToFinalResult(ResultedControlArr, ResultedControlArr_Pmtv);

      if Length(ResultedControlArr) > 0 then
      begin
        UpdateActionVarValuesFromControl(ResultedControlArr[0]);
        frClickerActions.DebuggingInfoAvailable := True;

        if AFindControlOptions.GetAllControls then
        begin
          SetAllControl_Handles_FromResultedControlArr(ResultedControlArr, MatchSource, DetailedMatchSource);
          UpdateActionVarValuesFromResultedControlArr(ResultedControlArr);
        end;
      end;
    end;

    SetLength(ResultedControlArr, 0);
    SetLength(PartialResultedControlArr, 0);
    SetLength(ResultedControlArr_Text, 0);
    SetLength(ResultedControlArr_Bmp, 0);
    SetLength(ResultedControlArr_Pmtv, 0);
  end;
end;


function TActionExecution.ExecuteFindControlActionWithTimeout(var AFindControlOptions: TClkFindControlOptions; var AActionOptions: TClkActionOptions; IsSubControl: Boolean): Boolean; //returns True if found
var
  tk, CurrentActionElapsedTime: QWord;
  AttemptCount: Integer;
begin
  tk := GetTickCount64;
  frClickerActions.prbTimeout.Max := AActionOptions.ActionTimeout;
  frClickerActions.prbTimeout.Position := 0;
  Result := False;
  AttemptCount := 0;

  repeat
    if (GetAsyncKeyState(VK_CONTROL) < 0) and (GetAsyncKeyState(VK_SHIFT) < 0) and (GetAsyncKeyState(VK_F2) < 0) then
    begin
      if FStopAllActionsOnDemandFromParent <> nil then
        FStopAllActionsOnDemandFromParent^ := True;

      if FStopAllActionsOnDemand <> nil then
        FStopAllActionsOnDemand^ := True;
    end;

    if FStopAllActionsOnDemandFromParent <> nil then
      if FStopAllActionsOnDemandFromParent^ then
        if FStopAllActionsOnDemand <> nil then
          FStopAllActionsOnDemand^ := True;

    if FStopAllActionsOnDemand^ then
    begin
      PrependErrorMessageToActionVar('Stopped by user at "' + AActionOptions.ActionName + '" in ' + FSelfTemplateFileName^ + '  ');
      Break;
    end;

    Result := ExecuteFindControlAction(AFindControlOptions, AActionOptions, IsSubControl);

    if AFindControlOptions.WaitForControlToGoAway then  //the control should not be found
      Result := not Result;

    if not Result and AFindControlOptions.AllowToFail then
      Break; //do not set result to True, because it is required to be detected where ExecuteFindControlActionWithTimeout is called

    if Result then
      Break;

    CurrentActionElapsedTime := GetTickCount64 - tk;
    frClickerActions.prbTimeout.Position := CurrentActionElapsedTime;
    Application.ProcessMessages;

    Inc(AttemptCount);

    if (frClickerActions.prbTimeout.Max > 0) and (frClickerActions.prbTimeout.Position >= frClickerActions.prbTimeout.Max) then
    begin
      PrependErrorMessageToActionVar('Timeout at "' + AActionOptions.ActionName +
                                     '" in ' + FSelfTemplateFileName^ +
                                     '  ActionTimeout=' + IntToStr(AActionOptions.ActionTimeout) + ' Duration=' + IntToStr(CurrentActionElapsedTime) +
                                     '  AttemptCount=' + IntToStr(AttemptCount) +
                                     '  Search: ' +
                                     '  $Control_Left$=' + EvaluateReplacements('$Control_Left$') + //same as "global...", but are required here, to be displayed in caller template log
                                     '  $Control_Top$=' + EvaluateReplacements('$Control_Top$') +
                                     '  $Control_Right$=' + EvaluateReplacements('$Control_Right$') +
                                     '  $Control_Bottom$=' + EvaluateReplacements('$Control_Bottom$') +
                                     '  $Control_Text$="' + EvaluateReplacements('$Control_Text$') + '"' +
                                     '  $Control_Class$="' + EvaluateReplacements('$Control_Class$') + '"' +
                                     '  SearchedText="' + EvaluateReplacements(AFindControlOptions.MatchText) + '"' +
                                     '  SearchedClass="' + EvaluateReplacements(AFindControlOptions.MatchClassName) + '"' +
                                     '  ');
      Break;
    end;

    Sleep(2);
  until False;

  frClickerActions.prbTimeout.Position := 0;
end;


function TActionExecution.ExecuteSetControlTextAction(var ASetTextOptions: TClkSetTextOptions): Boolean;
var
  Control_Handle: THandle;
  i, j, k, Idx: Integer;
  TextToSend: string;
  KeyStrokes: array of TINPUT;
  Err: Integer;
  ErrStr: string;
  DelayBetweenKeyStrokesInt: Integer;
  Count: Integer;
  GeneratedException: Boolean;
begin
  Result := True;

  Control_Handle := StrToIntDef(GetActionVarValue('$Control_Handle$'), 0);
  TextToSend := EvaluateReplacements(ASetTextOptions.Text);
  TextToSend := EvaluateHTTP(TextToSend, GeneratedException);
  Count := Min(65535, Max(0, StrToIntDef(EvaluateReplacements(ASetTextOptions.Count), 1)));

  if ASetTextOptions.ControlType = stKeystrokes then
    DelayBetweenKeyStrokesInt := StrToIntDef(EvaluateReplacements(ASetTextOptions.DelayBetweenKeyStrokes), 0)
  else
    DelayBetweenKeyStrokesInt := 0;

  for k := 1 to Count do
  begin
    case ASetTextOptions.ControlType of
      stEditBox: SetControlText(Control_Handle, TextToSend);

      stComboBox: SelectComboBoxItem(Control_Handle, 0, TextToSend);

      stKeystrokes:
      begin
        SetLength(KeyStrokes, Length(TextToSend) shl 1);
        try
          for i := 0 to Length(TextToSend) - 1 do   //string len, not array len
          begin
            Idx := i shl 1;
            KeyStrokes[Idx]._Type := INPUT_KEYBOARD; //not sure if needed
            KeyStrokes[Idx].ki.wVk := 0;
            KeyStrokes[Idx].ki.wScan := Ord(TextToSend[i + 1]);
            KeyStrokes[Idx].ki.dwFlags := KEYEVENTF_UNICODE; //0;
            KeyStrokes[Idx].ki.Time := 0;
            KeyStrokes[Idx].ki.ExtraInfo := 0;

            KeyStrokes[Idx + 1]._Type := INPUT_KEYBOARD; //not sure if needed
            KeyStrokes[Idx + 1].ki.wVk := 0;
            KeyStrokes[Idx + 1].ki.wScan := Ord(TextToSend[i + 1]);
            KeyStrokes[Idx + 1].ki.dwFlags := KEYEVENTF_UNICODE or KEYEVENTF_KEYUP;
            KeyStrokes[Idx + 1].ki.Time := 0;
            KeyStrokes[Idx + 1].ki.ExtraInfo := 0;
          end;

          SetLastError(0);
          if DelayBetweenKeyStrokesInt = 0 then
          begin
            if Integer(SendInput(Length(KeyStrokes), @KeyStrokes[0], SizeOf(TINPUT))) <> Length(KeyStrokes) then
            begin
              Err := GetLastOSError;
              ErrStr := 'KeyStrokes error: ' + IntToStr(Err) + '  ' + SysErrorMessage(GetLastOSError) + '  Keystrokes count: ' + IntToStr(Length(KeyStrokes));
              SetActionVarValue('$ExecAction_Err$', ErrStr);
              Result := False;
            end;
          end
          else
          begin
            for i := 0 to Length(TextToSend) - 1 do
            begin
              if Integer(SendInput(2, @KeyStrokes[i shl 1], SizeOf(TINPUT))) <> 2 then
              begin
                Err := GetLastOSError;
                ErrStr := 'KeyStrokes error: ' + IntToStr(Err) + '  ' + SysErrorMessage(GetLastOSError) + '  Keystrokes count: ' + IntToStr(Length(KeyStrokes));
                SetActionVarValue('$ExecAction_Err$', ErrStr);
                Result := False;
              end;

              for j := 1 to DelayBetweenKeyStrokesInt do
              begin
                Sleep(1);  //this is way longer than a ms, but it allows checking for stop condition

                if CheckManualStopCondition then
                begin
                  Result := False;
                  Break;     //break inner for
                end;
              end;

              if CheckManualStopCondition then
              begin
                Result := False;
                Break;       //break outer for
              end;
            end;
          end; //using delays
        finally
          SetLength(KeyStrokes, 0);
        end;
      end;
    end; //case

    if CheckManualStopCondition then
    begin
      Result := False;
      Break;     //break for k
    end;

    Sleep(DelayBetweenKeyStrokesInt);
  end; //for k
end;


function TActionExecution.CheckManualStopCondition: Boolean;
begin
  Result := False;

  if (GetAsyncKeyState(VK_CONTROL) < 0) and (GetAsyncKeyState(VK_SHIFT) < 0) and (GetAsyncKeyState(VK_F2) < 0) then
  begin
    Result := True;

    if FStopAllActionsOnDemandFromParent <> nil then
      FStopAllActionsOnDemandFromParent^ := True;

    if FStopAllActionsOnDemand <> nil then
      FStopAllActionsOnDemand^ := True;
  end;

  if FStopAllActionsOnDemandFromParent <> nil then
    if FStopAllActionsOnDemandFromParent^ then
      if FStopAllActionsOnDemand <> nil then
        FStopAllActionsOnDemand^ := True;
end;


function TActionExecution.ExecuteCallTemplateAction(var ACallTemplateOptions: TClkCallTemplateOptions; IsDebugging, AShouldStopAtBreakPoint: Boolean): Boolean;
var
  i: Integer;
  CustomVars: TStringList;
  KeyName, KeyValue, RowString: string;
  Fnm, TemplateDir: string;
  GeneratedException: Boolean;
begin
  Result := False;
  if not Assigned(FOnCallTemplate) then
  begin
    AppendErrorMessageToActionVar('OnCallTemplate not assigned');
    Exit;
  end;

  CustomVars := TStringList.Create;
  try
    CustomVars.Text := FastReplace_45ToReturn(ACallTemplateOptions.ListOfCustomVarsAndValues);

    for i := 0 to CustomVars.Count - 1 do
    begin
      try
        RowString := CustomVars.Strings[i];
        KeyName := Copy(RowString, 1, Pos('=', RowString) - 1);
        KeyValue := Copy(RowString, Pos('=', RowString) + 1, MaxInt);
        KeyValue := EvaluateHTTP(KeyValue, GeneratedException);

        if ACallTemplateOptions.EvaluateBeforeCalling then
          SetActionVarValue(KeyName, EvaluateReplacements(KeyValue))
        else
          SetActionVarValue(KeyName, KeyValue);
      except
        //who knows...
      end;
    end;
  finally
    CustomVars.Free;
  end;

  if ACallTemplateOptions.CallOnlyIfCondition then
  begin
    MessageBox(Application.MainForm.Handle, PChar('Using this condition mechanism is deprecated. Please move this condition to the "Condition" tab.' + #13#10 + 'Filename: ' + FSelfTemplateFileName^), PChar(Application.Title), MB_ICONWARNING);

    KeyName := ACallTemplateOptions.CallOnlyIfConditionVarName;
    KeyValue := ACallTemplateOptions.CallOnlyIfConditionVarValue;

    if GetActionVarValue(KeyName) <> KeyValue then
    begin
      Result := True;  //allow further execution
      SetActionVarValue('$ExecAction_Err$', 'Condition not met: ' + GetActionVarValue(KeyName) + ' <> ' + KeyValue);
      Exit;
    end;
  end;

  Fnm := ACallTemplateOptions.TemplateFileName;
  TemplateDir := '';
  if FSelfTemplateFileName = nil then
    TemplateDir := 'FSelfTemplateFileName not set in CallTemplate.'
  else
  begin
    TemplateDir := ExtractFileDir(FSelfTemplateFileName^);
    Fnm := StringReplace(Fnm, '$SelfTemplateDir$', TemplateDir, [rfReplaceAll]);
    Fnm := StringReplace(Fnm, '$TemplateDir$', FFullTemplatesDir^, [rfReplaceAll]);
  end;

  // the FileExists verification has to be done after checking CallOnlyIfCondition, to allow failing the action based on condition

  Fnm := StringReplace(Fnm, '$AppDir$', ExtractFileDir(ParamStr(0)), [rfReplaceAll]);
  Fnm := EvaluateReplacements(Fnm);  //this call has to stay here, after the $SelfTemplateDir$, $TemplateDir$ and $AppDir$ replacements, because $SelfTemplateDir$ will be evaluated to ''.

  if not FFileLocationOfDepsIsMem^ then
    if ExtractFileName(Fnm) = Fnm then  //Fnm does not contain a path
    begin
      if FFullTemplatesDir = nil then
        raise Exception.Create('FFullTemplatesDir is not assigned.');

      Fnm := FFullTemplatesDir^ + '\' + Fnm;
    end;

  if FOwnerFrame = nil then
    raise Exception.Create('FOwnerFrame is not assigned.');

  //do not verify here if the file exists or not, because this verification is done by FOnCallTemplate, both for disk and in-mem FS
  Result := FOnCallTemplate(FOwnerFrame, Fnm, FClickerVars, frClickerActions.imgDebugBmp.Picture.Bitmap, frClickerActions.imgDebugGrid, IsDebugging, AShouldStopAtBreakPoint, FStackLevel^, FExecutesRemotely^);

  if GetActionVarValue('$ExecAction_Err$') <> '' then   ////////////////// ToDo:  improve the error logging
    AddToLog(DateTimeToStr(Now) + '  ' + GetActionVarValue('$ExecAction_Err$'));
end;


function TActionExecution.ExecuteLoopedCallTemplateAction(var ACallTemplateOptions: TClkCallTemplateOptions; IsDebugging, AShouldStopAtBreakPoint: Boolean): Boolean;
var
  i: Integer;
  StartValue, StopValue: Integer;
  TempACallTemplateOptions: TClkCallTemplateOptions;
begin
  if not ACallTemplateOptions.CallTemplateLoop.Enabled then
    Result := ExecuteCallTemplateAction(ACallTemplateOptions, IsDebugging, AShouldStopAtBreakPoint)
  else
  begin
    StartValue := StrToIntDef(EvaluateReplacements(ACallTemplateOptions.CallTemplateLoop.InitValue), 0);
    StopValue := StrToIntDef(EvaluateReplacements(ACallTemplateOptions.CallTemplateLoop.EndValue), 0);

    Result := True;
    case ACallTemplateOptions.CallTemplateLoop.Direction of
      ldInc:
      begin
        for i := StartValue to StopValue do
        begin
          SetActionVarValue(ACallTemplateOptions.CallTemplateLoop.Counter, IntToStr(i));

          if ACallTemplateOptions.CallTemplateLoop.BreakCondition <> '' then
            if ACallTemplateOptions.CallTemplateLoop.EvalBreakPosition = lebpBeforeContent then
              if EvaluateActionCondition(ACallTemplateOptions.CallTemplateLoop.BreakCondition, EvaluateReplacements) then
                Break;

          Result := Result and ExecuteCallTemplateAction(ACallTemplateOptions, IsDebugging, AShouldStopAtBreakPoint);

          if ACallTemplateOptions.CallTemplateLoop.BreakCondition <> '' then
            if ACallTemplateOptions.CallTemplateLoop.EvalBreakPosition = lebpAfterContent then
              if EvaluateActionCondition(ACallTemplateOptions.CallTemplateLoop.BreakCondition, EvaluateReplacements) then
                Break;

          CheckManualStopCondition;
          if FStopAllActionsOnDemand <> nil then
            if FStopAllActionsOnDemand^ then
              Break;
        end;
      end;

      ldDec:
      begin
        for i := StartValue downto StopValue do
        begin
          SetActionVarValue(ACallTemplateOptions.CallTemplateLoop.Counter, IntToStr(i));

          if ACallTemplateOptions.CallTemplateLoop.EvalBreakPosition = lebpBeforeContent then
            if EvaluateActionCondition(ACallTemplateOptions.CallTemplateLoop.BreakCondition, EvaluateReplacements) then
              Break;

          Result := Result and ExecuteCallTemplateAction(ACallTemplateOptions, IsDebugging, AShouldStopAtBreakPoint);

          if ACallTemplateOptions.CallTemplateLoop.EvalBreakPosition = lebpBeforeContent then
            if EvaluateActionCondition(ACallTemplateOptions.CallTemplateLoop.BreakCondition, EvaluateReplacements) then
              Break;

          CheckManualStopCondition;
          if FStopAllActionsOnDemand <> nil then
            if FStopAllActionsOnDemand^ then
              Break;
        end;
      end;

      ldAuto:
      begin
        TempACallTemplateOptions := ACallTemplateOptions;
        if StartValue < StopValue then
          TempACallTemplateOptions.CallTemplateLoop.Direction := ldInc
        else
          TempACallTemplateOptions.CallTemplateLoop.Direction := ldDec;

        Result := ExecuteLoopedCallTemplateAction(TempACallTemplateOptions, IsDebugging, AShouldStopAtBreakPoint)
      end;

      else
      begin
        Result := False;
        SetActionVarValue('$ExecAction_Err$', 'Unknown loop direction');
      end;
    end;
  end;
end;


function TActionExecution.ExecuteSleepAction(var ASleepOptions: TClkSleepOptions; var AActionOptions: TClkActionOptions): Boolean;
var
  ValueInt: Integer;
  tk1, tk2, ElapsedTime, RemainingTime: Int64;
begin
  //eventually, implement some fast-forward option, to skip the sleep action while debugging
  ValueInt := StrToIntDef(EvaluateReplacements(ASleepOptions.Value), -1);

  if ValueInt < 0 then
  begin
    Result := False;
    SetActionVarValue('$ExecAction_Err$', 'Invalid sleep value: ' + EvaluateReplacements(ASleepOptions.Value));
    Exit;
  end;

  Result := True;

  if ValueInt < 1 then
    Exit;

  DoOnSetEditorSleepProgressBarMax(ValueInt);

  tk1 := GetTickCount64;
  ElapsedTime := 0;
  repeat
    tk2 := GetTickCount64;

    if tk2 < tk1 then  // In case of a wrap around, call this function again. It will get it right, at the cost of an additional delay.
    begin
      ExecuteSleepAction(ASleepOptions, AActionOptions);
      Break;
    end;

    if (GetAsyncKeyState(VK_CONTROL) < 0) and (GetAsyncKeyState(VK_SHIFT) < 0) and (GetAsyncKeyState(VK_F2) < 0) then
    begin
      if FStopAllActionsOnDemandFromParent <> nil then
        FStopAllActionsOnDemandFromParent^ := True;

      if FStopAllActionsOnDemand <> nil then
        FStopAllActionsOnDemand^ := True;
    end;

    if FStopAllActionsOnDemandFromParent <> nil then
      if FStopAllActionsOnDemandFromParent^ then
        if FStopAllActionsOnDemand <> nil then
          FStopAllActionsOnDemand^ := True;

    if FStopAllActionsOnDemand^ then
    begin
      PrependErrorMessageToActionVar('Stopped by user at "' + AActionOptions.ActionName + '" in ' + FSelfTemplateFileName^ + '  ');
      Result := False;
      Break;
    end;

    ElapsedTime := tk2 - tk1;
    RemainingTime := ValueInt - ElapsedTime;

    DoOnSetEditorSleepInfo('Elapsed Time [ms]: ' + IntToStr(ElapsedTime), 'Remaining Time [ms]: ' + IntToStr(RemainingTime));
    DoOnSetEditorSleepProgressBarPosition(ElapsedTime);

    Application.ProcessMessages;
    Sleep(1);
  until ElapsedTime >= ValueInt;
end;


function TActionExecution.ExecuteSetVarAction(var ASetVarOptions: TClkSetVarOptions): Boolean;
var
  TempListOfSetVarNames: TStringList;
  TempListOfSetVarValues: TStringList;
  TempListOfSetVarEvalBefore: TStringList;
  i, j: Integer;
  VarName, VarValue: string;
  RenderBmpExternallyResult: string;
  ListOfSelfHandles: TStringList;
  GeneratedException: Boolean;
begin
  Result := False;
  TempListOfSetVarNames := TStringList.Create;
  TempListOfSetVarValues := TStringList.Create;
  TempListOfSetVarEvalBefore := TStringList.Create;
  try
    TempListOfSetVarNames.Text := ASetVarOptions.ListOfVarNames;
    TempListOfSetVarValues.Text := ASetVarOptions.ListOfVarValues;
    TempListOfSetVarEvalBefore.Text := ASetVarOptions.ListOfVarEvalBefore;

    if (TempListOfSetVarNames.Count = 1) and (TempListOfSetVarValues.Count = 0) then //the only variable, passed here, is set to ''
      TempListOfSetVarValues.Add('');

    if TempListOfSetVarNames.Count <> TempListOfSetVarValues.Count then
    begin
      SetActionVarValue('$ExecAction_Err$', 'SetVar: The list of var names has a different length than the list of var values.');
      Exit;
    end;

    if TempListOfSetVarEvalBefore.Count <> TempListOfSetVarNames.Count then
    begin
      SetActionVarValue('$ExecAction_Err$', 'SetVar: The list of var eval infos has a different length than the list of var names.');
      Exit;
    end;

    for i := 0 to TempListOfSetVarNames.Count - 1 do
    begin
      VarName := TempListOfSetVarNames.Strings[i];
      VarValue := TempListOfSetVarValues.Strings[i];

      if (Pos('$Exit(', VarName) = 1) and (VarName[Length(VarName)] = '$') and (VarName[Length(VarName) - 1] = ')') then
      begin
        VarValue := Copy(VarName, Pos('(', VarName) + 1, MaxInt);
        VarValue := Copy(VarValue, 1, Length(VarValue) - 2);
        SetActionVarValue('$ExecAction_Err$', 'Terminating template execution on request.');
        SetActionVarValue('$ExitCode$', VarValue);

        Result := VarValue = '0';
        Exit;
      end;

      if VarName = '$GetSelfHandles()$' then
      begin
        ListOfSelfHandles := TStringList.Create;
        try
          DoOnGetSelfHandles(ListOfSelfHandles);

          for j := 0 to ListOfSelfHandles.Count - 1 do
            SetActionVarValue('$' + ListOfSelfHandles.Names[j] + '$', ListOfSelfHandles.ValueFromIndex[j]);
        finally
          ListOfSelfHandles.Free;
        end;

        Continue; //use this to prevent adding '$GetSelfHandles()$' as a variable
      end;

      if TempListOfSetVarEvalBefore.Strings[i] = '1' then
        VarValue := EvaluateReplacements(VarValue);

      VarValue := EvaluateHTTP(VarValue, GeneratedException);
      if GeneratedException then
        if ASetVarOptions.FailOnException then
        begin
          SetActionVarValue('$ExecAction_Err$', VarValue);
          Exit;
        end;

      if (Pos('$RenderBmpExternally(', VarName) = 1) and (VarName[Length(VarName)] = '$') and (VarName[Length(VarName) - 1] = ')') then
      begin
        RenderBmpExternallyResult := DoOnRenderBmpExternally(VarValue);
        SetActionVarValue('$ExternallyRenderedBmpResult$', RenderBmpExternallyResult);
        if Pos(CClientExceptionPrefix, RenderBmpExternallyResult) = 1 then
          if ASetVarOptions.FailOnException then
          begin
            SetActionVarValue('$ExecAction_Err$', RenderBmpExternallyResult);
            Exit;
          end;
      end;

      if (Pos('$GetActionProperties(', VarName) = 1) and (VarName[Length(VarName)] = '$') and (VarName[Length(VarName) - 1] = ')') then
        SetActionVarValue('$ActionPropertiesResult$', GetActionProperties(VarValue));

      SetActionVarValue(VarName, VarValue);
    end;
  finally
    TempListOfSetVarNames.Free;
    TempListOfSetVarValues.Free;
    TempListOfSetVarEvalBefore.Free;
  end;

  Result := True;
end;


function TActionExecution.ExecuteWindowOperationsAction(var AWindowOperationsOptions: TClkWindowOperationsOptions): Boolean;
var
  Hw: THandle;
  Flags: DWord;
  X, Y, cx, cy: LongInt;
begin
  Result := False;
  Hw := StrToIntDef(EvaluateReplacements('$Control_Handle$'), 0);
  if Hw = 0 then
  begin
    SetActionVarValue('$ExecAction_Err$', 'Cannot execute window operations on invalid handle.');
    Exit;
  end;

  case AWindowOperationsOptions.Operation of
    woBringToFront:
    begin
      SetForegroundWindow(Hw);
      Result := True;
    end;

    woMoveResize:
    begin
      Flags := SWP_ASYNCWINDOWPOS or SWP_NOACTIVATE or SWP_NOOWNERZORDER or SWP_NOZORDER;

      if AWindowOperationsOptions.NewPositionEnabled then
      begin
        X := StrToIntDef(EvaluateReplacements(AWindowOperationsOptions.NewX), 0);
        Y := StrToIntDef(EvaluateReplacements(AWindowOperationsOptions.NewY), 0);
      end
      else
        Flags := Flags or SWP_NOMOVE;

      if AWindowOperationsOptions.NewSizeEnabled then
      begin
        cx := StrToIntDef(EvaluateReplacements(AWindowOperationsOptions.NewWidth), 0);
        cy := StrToIntDef(EvaluateReplacements(AWindowOperationsOptions.NewHeight), 0);
      end
      else
        Flags := Flags or SWP_NOSIZE;

      Result := SetWindowPos(Hw, HWND_TOP, X, Y, cx, cy, Flags);

      if not Result then
        SetActionVarValue('$ExecAction_Err$', SysErrorMessage(GetLastError));
    end;

    woClose:
    begin
      SendMessage(Hw, WM_CLOSE, 0, 0);
      Result := True;
    end;

    else
    begin
      Result := False;
    end;
  end;
end;


//Loads action var values from file and updates action vars (to the list of action vars) mentioned by a SetVar action.
//The SetVar action is used only as a list of var names. This way, the same SetVar action can be used on both loading and saving.
function TActionExecution.ExecuteLoadSetVarFromFileAction(var ALoadSetVarFromFileOptions: TClkLoadSetVarFromFileOptions): Boolean;
var
  Ini: TClkIniReadonlyFile;
  LoadedListOfVarNames, LoadedListOfVarValues, VarNamesToBeUpdated: TStringList;
  i: Integer;
  SetVarActionToBeUpdated: TClkSetVarOptions;
begin
  Result := False;
  if not DoOnGetSetVarActionByName(SetVarActionToBeUpdated, ALoadSetVarFromFileOptions.SetVarActionName) then
  begin
    SetActionVarValue('$ExecAction_Err$', 'Error: SetVar action not found when executing LoadSetVarFromFile: "' + ALoadSetVarFromFileOptions.SetVarActionName + '".');
    Exit;
  end;

  Ini := DoOnTClkIniReadonlyFileCreate(ALoadSetVarFromFileOptions.FileName);
  LoadedListOfVarNames := TStringList.Create;
  LoadedListOfVarValues := TStringList.Create;
  VarNamesToBeUpdated := TStringList.Create;
  try
    LoadedListOfVarNames.Text := FastReplace_45ToReturn(Ini.ReadString('Vars', 'ListOfVarNames', ''));
    LoadedListOfVarValues.Text := FastReplace_45ToReturn(Ini.ReadString('Vars', 'ListOfVarValues', ''));

    if LoadedListOfVarNames.Count <> LoadedListOfVarValues.Count then
    begin
      SetActionVarValue('$ExecAction_Err$', 'Error: Loaded SetVar action has a different number of var names than var values: ' + IntToStr(LoadedListOfVarNames.Count) + ' vs. ' + IntToStr(LoadedListOfVarValues.Count));
      Exit;
    end;

    VarNamesToBeUpdated.Text := SetVarActionToBeUpdated.ListOfVarNames;

    for i := 0 to LoadedListOfVarNames.Count - 1 do    //this list might not match SetVarActionToBeUpdated.ListOfVarNames;
      if VarNamesToBeUpdated.IndexOf(LoadedListOfVarNames.Strings[i]) <> -1 then  //only mentioned vars should be updated, not everything that comes from file
        SetActionVarValue(LoadedListOfVarNames.Strings[i], LoadedListOfVarValues.Strings[i]);

    Result := True;
  finally
    Ini.Free;
    LoadedListOfVarNames.Free;
    LoadedListOfVarValues.Free;
    VarNamesToBeUpdated.Free;
  end;
end;


//Takes action var values as they are, from the list of action vars, then saves them to file.
//The SetVar action is used only as a list of var names. This way, the same SetVar action can be used on both loading and saving.
function TActionExecution.ExecuteSaveSetVarToFileAction(var ASaveSetVarToFileOptions: TClkSaveSetVarToFileOptions): Boolean;
var
  Bkp, FileContent, VarNamesToBeSaved: TStringList;
  SetVarActionToBeSaved: TClkSetVarOptions;
  ListOfVarNames, ListOfVarValues: string;
  i: Integer;
  VarName: string;
begin
  Result := False;
  if not DoOnGetSetVarActionByName(SetVarActionToBeSaved, ASaveSetVarToFileOptions.SetVarActionName) then
  begin
    SetActionVarValue('$ExecAction_Err$', 'Error: SetVar action not found when executing SaveSetVarToFile: "' + ASaveSetVarToFileOptions.SetVarActionName + '".');
    Exit;
  end;

  Bkp := TStringList.Create;
  VarNamesToBeSaved := TStringList.Create;
  try
    DoOnBackupVars(Bkp);
    VarNamesToBeSaved.Text := SetVarActionToBeSaved.ListOfVarNames;

    ListOfVarNames := '';
    ListOfVarValues := '';
    for i := 0 to VarNamesToBeSaved.Count - 1 do
    begin
      VarName := VarNamesToBeSaved.Strings[i];
      ListOfVarNames := ListOfVarNames + VarName + #4#5;
      ListOfVarValues := ListOfVarValues + Bkp.Values[VarName] + #4#5;
    end;

    FileContent := TStringList.Create;
    try
      FileContent.Add('[Vars]');
      FileContent.Add('ListOfVarNames=' + ListOfVarNames);
      FileContent.Add('ListOfVarValues=' + ListOfVarValues);

      DoOnSaveStringListToFile(FileContent, ASaveSetVarToFileOptions.FileName);
      Result := True;
    finally
      FileContent.Free;
    end;
  finally
    Bkp.Free;
    VarNamesToBeSaved.Free;
  end;
end;


function TActionExecution.ExecutePluginAction(var APluginOptions: TClkPluginOptions; AAllActions: PClkActionsRecArr; AListOfAllVars: TStringList; AResolvedPluginPath: string; IsDebugging, AShouldStopAtBreakPoint: Boolean): Boolean;
var
  ActionPlugin: TActionPlugin;
  tk: Int64;
begin
  Result := False;

  AddToLog('Executing plugin on a template with ' + IntToStr(Length(AAllActions^)) + ' action(s)...');
  if IsDebugging then
    AddToLog('Plugin debugging is active. It can be stepped over using F8 shortcut, or stopped using Ctrl-Shift-F2 shortcut.');

  //clear debug image
  frClickerActions.imgDebugBmp.Width := 300;    //some default values
  frClickerActions.imgDebugBmp.Height := 300;
  frClickerActions.imgDebugBmp.Picture.Bitmap.Width := frClickerActions.imgDebugBmp.Width;
  frClickerActions.imgDebugBmp.Picture.Bitmap.Height := frClickerActions.imgDebugBmp.Height;
  frClickerActions.imgDebugBmp.Canvas.Pen.Color := clWhite;
  frClickerActions.imgDebugBmp.Canvas.Brush.Color := clWhite;
  frClickerActions.imgDebugBmp.Canvas.Rectangle(0, 0, frClickerActions.imgDebugBmp.Width, frClickerActions.imgDebugBmp.Height);

  tk := GetTickCount64;
  try
    if not ActionPlugin.LoadToExecute(AResolvedPluginPath,
                                      AddToLog,
                                      DoOnExecuteActionByName,
                                      HandleOnSetVar,
                                      HandleOnSetDebugPoint,
                                      HandleOnIsAtBreakPoint,
                                      FOnLoadBitmap,
                                      FOnLoadRenderedBitmap,
                                      HandleOnSaveFileToExtRenderingInMemFS,
                                      HandleOnScreenshotByActionName,
                                      IsDebugging,
                                      AShouldStopAtBreakPoint,
                                      FStopAllActionsOnDemand{FromParent},
                                      FPluginStepOver,
                                      FPluginContinueAll,
                                      frClickerActions.imgDebugBmp.Picture.Bitmap,
                                      FFullTemplatesDir^,
                                      FAllowedFileDirsForServer^, //ResolvedAllowedFileDirs,
                                      FAllowedFileExtensionsForServer^,
                                      AAllActions,
                                      AListOfAllVars) then
    begin
      SetActionVarValue('$ExecAction_Err$', ActionPlugin.Err);
      AddToLog(ActionPlugin.Err);
      Exit;
    end;

    try
      Result := ActionPlugin.ExecutePlugin(APluginOptions.ListOfPropertiesAndValues);
      if not Result then
        AddToLog('Plugin execution failed with: ' + GetActionVarValue(CActionPlugin_ExecutionResultErrorVar))
      else
        AddToLog('Plugin executed successfully.');
    finally
      if not ActionPlugin.Unload then
        AddToLog(ActionPlugin.Err);
    end;

    frClickerActions.imgDebugBmp.Width := Max(10, Min(frClickerActions.imgDebugBmp.Picture.Bitmap.Width, 7680));   //Limit to 8K resolution for now. Sometimes, imgDebugBmp might not be initialized, causing AVs (div by 0 or heap overflow).
    frClickerActions.imgDebugBmp.Height := Max(10, Min(frClickerActions.imgDebugBmp.Picture.Bitmap.Height, 4320)); //Limit to 8K resolution for now.
  finally
    AddToLog('Plugin executed in ' + IntToStr(GetTickCount64 - tk) + 'ms.  Total action count: ' + IntToStr(Length(AAllActions^)) + ' action(s)...');
  end;
end;


function TActionExecution.ExecuteClickActionAsString(AListOfClickOptionsParams: TStrings): Boolean;
var
  ClickOptions: TClkClickOptions;
  Err: string;
begin
  Result := False;
  SetActionVarValue('$ExecAction_Err$', '');
  try
    Err := SetClickActionProperties(AListOfClickOptionsParams, ClickOptions);
    if Err <> '' then
    begin
      SetActionVarValue('$ExecAction_Err$', Err);
      Exit;
    end;

    Result := ExecuteMultiClickAction(ClickOptions);
  finally
    SetLastActionStatus(Result, False);
  end;
end;


function TActionExecution.ExecuteExecAppActionAsString(AListOfExecAppOptionsParams: TStrings): Boolean;
var
  ExecAppOptions: TClkExecAppOptions;
  ActionOptions: TClkActionOptions;
  Err: string;
begin
  Result := False;
  SetActionVarValue('$ExecAction_Err$', '');
  try
    Err := SetExecAppActionProperties(AListOfExecAppOptionsParams, ExecAppOptions, ActionOptions);
    if Err <> '' then
    begin
      SetActionVarValue('$ExecAction_Err$', Err);
      Exit;
    end;

    Result := ExecuteExecAppAction(ExecAppOptions, ActionOptions);
  finally
    SetLastActionStatus(Result, False);
  end;
end;


function TActionExecution.ExecuteFindControlActionAsString(AListOfFindControlOptionsParams: TStrings; AIsSubControl: Boolean): Boolean;
var
  FindControlOptions: TClkFindControlOptions;
  ActionOptions: TClkActionOptions;
  Err: string;
begin
  Result := False;
  SetActionVarValue('$ExecAction_Err$', '');
  try
    Err := SetFindControlActionProperties(AListOfFindControlOptionsParams, AIsSubControl, AddToLog, FindControlOptions, ActionOptions);
    if Err <> '' then
    begin
      SetActionVarValue('$ExecAction_Err$', Err);
      Exit;
    end;

    Result := ExecuteFindControlActionWithTimeout(FindControlOptions, ActionOptions, AIsSubControl);
  finally
    SetLastActionStatus(Result, FindControlOptions.AllowToFail);
  end;
end;


function TActionExecution.ExecuteSetControlTextActionAsString(AListOfSetControlTextOptionsParams: TStrings): Boolean;
var
  SetTextOptions: TClkSetTextOptions;
  Err: string;
begin
  Result := False;
  SetActionVarValue('$ExecAction_Err$', '');
  try
    Err := SetSetControlTextActionProperties(AListOfSetControlTextOptionsParams, SetTextOptions);
    if Err <> '' then
    begin
      SetActionVarValue('$ExecAction_Err$', Err);
      Exit;
    end;

    Result := ExecuteSetControlTextAction(SetTextOptions);
  finally
    SetLastActionStatus(Result, False);
  end;
end;


function TActionExecution.ExecuteCallTemplateActionAsString(AListOfCallTemplateOptionsParams: TStrings): Boolean;
var
  CallTemplateOptions: TClkCallTemplateOptions;
  IsDebugging: Boolean;
  Err: string;
begin
  Result := False;
  SetActionVarValue('$ExecAction_Err$', '');
  try
    IsDebugging := AListOfCallTemplateOptionsParams.Values['IsDebugging'] = '1';

    Err := SetCallTemplateActionProperties(AListOfCallTemplateOptionsParams, CallTemplateOptions);
    if Err <> '' then
    begin
      SetActionVarValue('$ExecAction_Err$', Err);
      Exit;
    end;

    Result := ExecuteLoopedCallTemplateAction(CallTemplateOptions, IsDebugging, IsDebugging); //not sure if AShouldStopAtBreakPoint should be the same as IsDebugging or if it should be another http param

    if not Result then
      AddToLog(DateTimeToStr(Now) + '  /ExecuteCallTemplateAction is False. $ExecAction_Err$: ' + EvaluateReplacements('$ExecAction_Err$'))
    else
      AddToLog(DateTimeToStr(Now) + '  /ExecuteCallTemplateAction is True.');
  finally
    //SetLastActionStatus(Result, False);  //leave the action status as set by the called template
  end;
end;


function TActionExecution.ExecuteSleepActionAsString(AListOfSleepOptionsParams: TStrings): Boolean;
var
  SleepOptions: TClkSleepOptions;
  ActionOptions: TClkActionOptions;
  Err: string;
begin
  Result := False;
  SetActionVarValue('$ExecAction_Err$', '');
  try
    Err := SetSleepActionProperties(AListOfSleepOptionsParams, SleepOptions, ActionOptions);
    if Err <> '' then
    begin
      SetActionVarValue('$ExecAction_Err$', Err);
      Exit;
    end;

    Result := ExecuteSleepAction(SleepOptions, ActionOptions);
  finally
    SetLastActionStatus(Result, False);
  end;
end;


function TActionExecution.ExecuteSetVarActionAsString(AListOfSetVarOptionsParams: TStrings): Boolean;
var
  SetVarOptions: TClkSetVarOptions;
  Err: string;
begin
  Result := False;
  SetActionVarValue('$ExecAction_Err$', '');
  try
    Err := SetSetVarActionProperties(AListOfSetVarOptionsParams, SetVarOptions);
    if Err <> '' then
    begin
      SetActionVarValue('$ExecAction_Err$', Err);
      Exit;
    end;

    Result := ExecuteSetVarAction(SetVarOptions);
  finally
    SetLastActionStatus(Result, False);
  end;
end;


function TActionExecution.ExecuteWindowOperationsActionAsString(AListOfWindowOperationsOptionsParams: TStrings): Boolean;
var
  WindowOperationsOptions: TClkWindowOperationsOptions;
  Err: string;
begin
  Result := False;
  SetActionVarValue('$ExecAction_Err$', '');
  try
    Err := SetWindowOperationsActionProperties(AListOfWindowOperationsOptionsParams, WindowOperationsOptions);
    if Err <> '' then
    begin
      SetActionVarValue('$ExecAction_Err$', Err);
      Exit;
    end;

    Result := ExecuteWindowOperationsAction(WindowOperationsOptions);
  finally
    SetLastActionStatus(Result, False);
  end;
end;


function TActionExecution.ExecuteLoadSetVarFromFileActionAsString(AListOfLoadSetVarOptionsParams: TStrings): Boolean;
var
  LoadSetVarFromFileOptions: TClkLoadSetVarFromFileOptions;
  Err: string;
begin
  Result := False;
  SetActionVarValue('$ExecAction_Err$', '');
  try
    Err := SetLoadSetVarFromFileActionProperties(AListOfLoadSetVarOptionsParams, LoadSetVarFromFileOptions);
    if Err <> '' then
    begin
      SetActionVarValue('$ExecAction_Err$', Err);
      Exit;
    end;

    Result := ExecuteLoadSetVarFromFileAction(LoadSetVarFromFileOptions);
  finally
    SetLastActionStatus(Result, False);
  end;
end;


function TActionExecution.ExecuteSaveSetVarToFileActionAsString(AListOfSaveSetVarOptionsParams: TStrings): Boolean;
var
  SaveSetVarToFileOptions: TClkSaveSetVarToFileOptions;
  Err: string;
begin
  Result := False;
  SetActionVarValue('$ExecAction_Err$', '');
  try
    Err := SetSaveSetVarToFileActionProperties(AListOfSaveSetVarOptionsParams, SaveSetVarToFileOptions);
    if Err <> '' then
    begin
      SetActionVarValue('$ExecAction_Err$', Err);
      Exit;
    end;

    Result := ExecuteSaveSetVarToFileAction(SaveSetVarToFileOptions);
  finally
    SetLastActionStatus(Result, False);
  end;
end;


function TActionExecution.ExecutePluginActionAsString(APluginOptionsParams: TStrings): Boolean;
var
  PluginOptions: TClkPluginOptions;
  TempAllActions: PClkActionsRecArr;
  TempListOfAllVars: TStringList;
  IsDebugging: Boolean;
  Err: string;
begin
  Result := False;
  SetActionVarValue('$ExecAction_Err$', '');
  try
    Err := SetPluginActionProperties(APluginOptionsParams, PluginOptions);
    if Err <> '' then
    begin
      SetActionVarValue('$ExecAction_Err$', Err);
      Exit;
    end;

    IsDebugging := APluginOptionsParams.Values['IsDebugging'] = '1';
    TempAllActions := DoOnGetAllActions;

    TempListOfAllVars := TStringList.Create;
    try
      DoOnBackupVars(TempListOfAllVars);
      Result := ExecutePluginAction(PluginOptions, TempAllActions, TempListOfAllVars, DoOnResolveTemplatePath(PluginOptions.FileName), IsDebugging, IsDebugging); //passing two IsDebugging params. ToDo:  review the logic
    finally
      TempListOfAllVars.Free;
    end;
  finally
    SetLastActionStatus(Result, False);
  end;
end;


//some handlers for primitives compositor
function TActionExecution.HandleOnLoadBitmap(ABitmap: TBitmap; AFileName: string): Boolean;
begin
  Result := DoOnLoadBitmap(ABitmap, AFileName)
end;


function TActionExecution.HandleOnLoadRenderedBitmap(ABitmap: TBitmap; AFileName: string): Boolean;
begin
  Result := DoOnLoadRenderedBitmap(ABitmap, AFileName);
end;


function TActionExecution.HandleOnEvaluateReplacements(s: string; Recursive: Boolean = True): string;
begin
  Result := EvaluateReplacements(s, Recursive);
end;


procedure TActionExecution.HandleOnSetVar(AVarName, AVarValue: string);
begin
  SetActionVarValue(AVarName, AVarValue);
end;


procedure TActionExecution.HandleOnSetDebugPoint(ADebugPoint: string);
begin
  DoOnSetDebugPoint(ADebugPoint);
end;


function TActionExecution.HandleOnIsAtBreakPoint(ADebugPoint: string): Boolean;
begin
  Result := DoOnIsAtBreakPoint(ADebugPoint);
end;


procedure TActionExecution.HandleOnSaveFileToExtRenderingInMemFS(AFileName: string; AContent: Pointer; AFileSize: Int64);
begin
  DoOnSaveFileToExtRenderingInMemFS(AFileName, AContent, AFileSize);
end;


function TActionExecution.HandleOnScreenshotByActionName(AActionName: string): Boolean;
var
  ActionContent: PClkActionRec;
  AActionOptions: TClkActionOptions;
  IsSubControl: Boolean;
  FindControlInputData: TFindControlInputData;
  TxtProfileCount: Integer;
  CompAtPoint: TCompRec;
  tp: TPoint;
  ScrShot_Left, ScrShot_Top, ScrShot_Width, ScrShot_Height, CompWidth, CompHeight: Integer;
  MemStream: TMemoryStream;
begin
  Result := False;

  // This screenshot works with FindSubControl only (no FindControl). Its input settings should be the values of all variables set by a FindControl action, executed prior to this screenshot.

  ActionContent := DoOnGetActionProperties(AActionName);

  if ActionContent = nil then
  begin
    AddToLog('Action not found (' + AActionName + ') when taking a screenshot.');
    Exit;
  end;

  if not FillInFindControlInputData(ActionContent^.FindControlOptions, AActionOptions, IsSubControl, FindControlInputData, TxtProfileCount) then
    Exit;

  AddToLog('Taking screenshot by action: ' + AActionName);

  tp.X := FindControlInputData.GlobalSearchArea.Left;
  tp.Y := FindControlInputData.GlobalSearchArea.Top;

  CompAtPoint := GetWindowClassRec(tp);
  CompAtPoint.XOffsetFromParent := 0;
  CompAtPoint.YOffsetFromParent := 0;

  ComputeScreenshotArea(FindControlInputData, CompAtPoint, ScrShot_Left, ScrShot_Top, ScrShot_Width, ScrShot_Height, CompWidth, CompHeight);

  if FindControlInputData.DebugBitmap <> nil then
  begin
    ScreenShot(CompAtPoint.Handle, FindControlInputData.DebugBitmap, ScrShot_Left, ScrShot_Top, ScrShot_Width, ScrShot_Height);

    MemStream := TMemoryStream.Create;
    try
      FindControlInputData.DebugBitmap.SaveToStream(MemStream);
      DoOnSaveFileToExtRenderingInMemFS(CScreenshotFilename, MemStream.Memory, MemStream.Size);
    finally
      MemStream.Free;
    end;

    AddToLog('ScrShot_Left: ' + IntToStr(ScrShot_Left) + '  ScrShot_Top:' + IntToStr(ScrShot_Top));
    AddToLog('CompWidth: ' + IntToStr(CompHeight) + '  CompHeight:' + IntToStr(CompHeight));
    AddToLog('CompHandle: ' + IntToStr(CompAtPoint.Handle) + '  ControlClass: ' + CompAtPoint.ClassName);

    Result := True;
  end;
end;

end.

