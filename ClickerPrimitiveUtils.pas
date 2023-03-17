{
    Copyright (C) 2023 VCC
    creation date: Mar 2023
    initial release date: 11 Mar 2023

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


unit ClickerPrimitiveUtils;

{$H+}
{$IFDEF FPC}
  //{$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, Graphics, FPCanvas, ClickerUtils;

type
  TClkSetPen = record
    Color: string; //TColor;
    Style: string; //TFPPenStyle;
    Width: string; //Integer;
    Mode: string; //TFPPenMode;
    Pattern: string; //LongWord;
    EndCap: string; //TFPPenEndCap;
    JoinStyle: string; //TFPPenJoinStyle;
  end;

  TClkSetBrush = record
    Color: string; //TColor;
    Style: string; //TFPBrushStyle;
    Pattern: string; //TBrushPattern;
  end;

  TClkSetMisc = record
    AntialiasingMode: string; //TAntialiasingMode
  end;

  TClkSetFont = TClkFindControlMatchBitmapText;

  TClkImage = record
    X1: string;
    X2: string;
    Y1: string;
    Y2: string;
    Path: string; //path to a bmp (or png) file, which will be part of the composition
    Stretch: string; //Boolean
  end;

  TClkLine = record
    X1: string;
    X2: string;
    Y1: string;
    Y2: string;
  end;

  TClkRect = record
    X1: string;
    X2: string;
    Y1: string;
    Y2: string;
  end;

  TClkGradientFill = record
    X1: string;
    X2: string;
    Y1: string;
    Y2: string;
    StartColor: string;
    StopColor: string;
    Direction: string; //TGradientDirection;
  end;

  TClkText = record
    Text: string;
    X: string;
    Y: string;
    //Evaluate: Boolean;  //Add this field if ever needed. Otherwise, the text is automatically evaluated. (i.e. all replacements in "Text" are evaluated to their values)
  end;


const
  CClkSetPenPrimitiveCmdIdx = 0;
  CClkSetBrushPrimitiveCmdIdx = 1;
  CClkSetMiscPrimitiveCmdIdx = 2;
  CClkSetFontPrimitiveCmdIdx = 3;
  CClkImagePrimitiveCmdIdx = 4;
  CClkLinePrimitiveCmdIdx = 5;
  CClkRectPrimitiveCmdIdx = 6;
  CClkGradientFill = 7;
  CClkText = 8;


type
  TPrimitiveRec = record        //Only one of the "primitive" fields is used at a time. This is similar to TClkActionRec.
    PrimitiveType: Integer; //index of one of the following fields
    PrimitiveName: string;

    ClkSetPen: TClkSetPen;
    ClkSetBrush: TClkSetBrush;
    ClkSetMisc: TClkSetMisc;
    ClkSetFont: TClkSetFont;
    ClkImage: TClkImage;
    ClkLine: TClkLine;
    ClkRect: TClkRect;
    ClkGradientFill: TClkGradientFill;
    ClkText: TClkText;
  end;

  PPrimitiveRec = ^TPrimitiveRec;

  TPrimitiveRecArr = array of TPrimitiveRec;

  TIntArr = array of Integer;         //redefined from BinSearchValues
  TCompositionOrder = record
    Items: TIntArr;
    Name: string;
  end;

  TCompositionOrderArr = array of TCompositionOrder;

  TOnLoadPrimitivesFile = procedure(AFileName: string; var APrimitives: TPrimitiveRecArr; var AOrders: TCompositionOrderArr) of object;
  TOnSavePrimitivesFile = procedure(AFileName: string; var APrimitives: TPrimitiveRecArr; var AOrders: TCompositionOrderArr) of object;


const
  CPrimitiveTypeCount = 9;
  CPrimitiveNames: array[0..CPrimitiveTypeCount - 1] of string = (
    'SetPen', 'SetBrush', 'SetMisc', 'SetFont', 'Image', 'Line', 'Rect', 'GradientFill', 'Text');

  CPenStyleStr: array[TPenStyle] of string = ('psSolid', 'psDash', 'psDot', 'psDashDot', 'psDashDotDot', 'psinsideFrame', 'psPattern', 'psClear');
  CPenModeStr: array[TPenMode] of string = (
    'pmBlack', 'pmWhite', 'pmNop', 'pmNot', 'pmCopy', 'pmNotCopy',
    'pmMergePenNot', 'pmMaskPenNot', 'pmMergeNotPen', 'pmMaskNotPen', 'pmMerge',
    'pmNotMerge', 'pmMask', 'pmNotMask', 'pmXor', 'pmNotXor'
  );

  CPenEndCapStr: array[TPenEndCap] of string = ('pecRound', 'pecSquare', 'pecFlat');
  CPenJoinStyleStr: array[TPenJoinStyle] of string = ('pjsRound', 'pjsBevel', 'pjsMiter');

  CBrushStyleStr: array[TBrushStyle] of string = (
    'bsSolid', 'bsClear', 'bsHorizontal', 'bsVertical', 'bsFDiagonal',
    'bsBDiagonal', 'bsCross', 'bsDiagCross', 'bsImage', 'bsPattern'
  );

  CAntialiasingModeStr: array[TAntialiasingMode] of string = ('amDontCare', 'amOn', 'amOff');
  CGradientDirectionStr: array[TGradientDirection] of string = ('gdVertical', 'gdHorizontal');

function PrimitiveTypeNameToIndex(AName: string): Integer;

function PenStyleNameToIndex(AName: string): TPenStyle;
function PenModeNameToIndex(AName: string): TPenMode;
function PenEndCapNameToIndex(AName: string): TPenEndCap;
function PenJoinStyleNameToIndex(AName: string): TPenJoinStyle;
function BrushStyleNameToIndex(AName: string): TBrushStyle;


implementation


function PrimitiveTypeNameToIndex(AName: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to CPrimitiveTypeCount - 1 do
    if CPrimitiveNames[i] = AName then
    begin
      Result := i;
      Break;
    end;
end;


function PenStyleNameToIndex(AName: string): TPenStyle;
var
  i: TPenStyle;
begin
  Result := Low(TPenStyle);
  for i := Low(TPenStyle) to High(TPenStyle) do
    if CPenStyleStr[i] = AName then
    begin
      Result := i;
      Break;
    end;
end;


function PenModeNameToIndex(AName: string): TPenMode;
var
  i: TPenMode;
begin
  Result := Low(TPenMode);
  for i := Low(TPenMode) to High(TPenMode) do
    if CPenModeStr[i] = AName then
    begin
      Result := i;
      Break;
    end;
end;


function PenEndCapNameToIndex(AName: string): TPenEndCap;
var
  i: TPenEndCap;
begin
  Result := Low(TPenEndCap);
  for i := Low(TPenEndCap) to High(TPenEndCap) do
    if CPenEndCapStr[i] = AName then
    begin
      Result := i;
      Break;
    end;
end;


function PenJoinStyleNameToIndex(AName: string): TPenJoinStyle;
var
  i: TPenJoinStyle;
begin
  Result := Low(TPenJoinStyle);
  for i := Low(TPenJoinStyle) to High(TPenJoinStyle) do
    if CPenJoinStyleStr[i] = AName then
    begin
      Result := i;
      Break;
    end;
end;


function BrushStyleNameToIndex(AName: string): TBrushStyle;
var
  i: TBrushStyle;
begin
  Result := Low(TBrushStyle);
  for i := Low(TBrushStyle) to High(TBrushStyle) do
    if CBrushStyleStr[i] = AName then
    begin
      Result := i;
      Break;
    end;
end;

end.

