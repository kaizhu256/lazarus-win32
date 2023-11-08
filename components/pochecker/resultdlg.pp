unit ResultDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Buttons, ClipBrd, LCLType, LCLProc, ComCtrls, Menus, SynEdit,
  SynHighlighterPo, PoFamilies, PoFamilyLists, GraphStat, PoCheckerConsts,
  PoCheckerSettings, Types;

type

  { TResultDlgForm }

  TResultDlgForm = class(TForm)
    GraphStatBtn: TBitBtn;
    CopyMenuItem: TMenuItem;
    SaveAsMenuItem: TMenuItem;
    MemoPopupMenu: TPopupMenu;
    StatMemo: TSynEdit;
    ResultPageControl: TPageControl;
    CloseBtn: TBitBtn;
    Panel1: TPanel;
    SaveDialog: TSaveDialog;
    LogMemo: TSynEdit;
    GeneralTabSheet: TTabSheet;
    StatisticsTabSheet: TTabSheet;
    DuplicatesTabSheet: TTabSheet;
    DupMemo: TSynEdit;
    procedure CopyMenuItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure GraphStatBtnClick(Sender: TObject);
    procedure SaveAsMenuItemClick(Sender: TObject);
  private
    PoHL: TSynPoSyn;
    FSettings: TPoCheckerSettings;
    procedure GetCurrentMemo(var CurrentMemo: TSynEdit);
    procedure LoadConfig;
    procedure SaveConfig;
  public
    property Settings: TPoCheckerSettings read FSettings write FSettings;
  end; 

implementation

{$R *.lfm}

{ TResultDlgForm }

procedure TResultDlgForm.FormCreate(Sender: TObject);
begin
  Caption := sResults;
  GeneralTabSheet.Caption := sGeneralInfo;
  StatisticsTabSheet.Caption := sTranslationStatistics;
  DuplicatesTabSheet.Caption := sDuplicateOriginalsTab;
  CopyMenuItem.Caption := sCopy;
  SaveAsMenuItem.Caption := sSaveAs;

  LogMemo.Lines.Clear;
  StatMemo.Lines.Clear;
  PoHL := TSynPoSyn.Create(Self);
  LogMemo.Highlighter := PoHL;
  GraphStatBtn.Caption := sShowStatGraph;
end;

procedure TResultDlgForm.CopyMenuItemClick(Sender: TObject);
var
  CurMemo: TSynEdit;
begin
  GetCurrentMemo(CurMemo);
  if CurMemo <> nil then
    ClipBoard.AsText := CurMemo.Text;
end;

procedure TResultDlgForm.FormDestroy(Sender: TObject);
begin
  SaveConfig;
end;

procedure TResultDlgForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  CurMemo: TSynEdit;
begin
  GetCurrentMemo(CurMemo);
  if (Key = VK_Tab) and (Shift = []) and (Assigned(CurMemo) and CurMemo.Focused) then
  begin
    //Workaroud: cannot tab out of LogMemo/StatMemo
    GraphStatBtn.SetFocus;
    //debugln('Tab');
    Key := 0;
  end;
end;

procedure TResultDlgForm.FormShow(Sender: TObject);
begin
  LogMemo.Lines.Assign(PoFamilyList.InfoLog);
  StatMemo.Lines.Assign(PoFamilyList.StatLog);
  DupMemo.Lines.Assign(PoFamilyList.DupLog);
  GraphStatBtn.Visible := (PoFamilyList.PoFamilyStats <> nil) and (PoFamilyList.PoFamilyStats.Count > 0);
  LoadConfig;
  WindowState := Settings.ResultsFormWindowState;
end;

procedure TResultDlgForm.GraphStatBtnClick(Sender: TObject);
var
  mr: TModalResult;
begin
  GraphStatForm := TGraphStatForm.Create(nil);
  try
    GraphStatForm.Settings := Self.Settings;

    if PoFamilyList.LangID <> lang_all then
    begin
      GraphStatForm.TranslatedLabel.Caption := Format(sTranslatedStringsTotal, [
        IntToStr(PoFamilyList.PoFamilyListStats.Translated), PoFamilyList.StatPerc(PoFamilyList.PoFamilyListStats.Translated)]);
      GraphStatForm.UnTranslatedLabel.Caption := Format(sUntranslatedStringsTotal
        , [IntToStr(PoFamilyList.PoFamilyListStats.Untranslated)]);
      GraphStatForm.FuzzyLabel.Caption := Format(sFuzzyStringsTotal, [IntToStr(
        PoFamilyList.PoFamilyListStats.Fuzzy)]);
    end
    else
    begin
      GraphStatForm.TranslatedLabel.Caption := sTranslatedStrings;
      GraphStatForm.UnTranslatedLabel.Caption := sUntranslatedStrings;
      GraphStatForm.FuzzyLabel.Caption := sFuzzyStrings;
    end;
    mr := GraphStatForm.ShowModal;
    if mr = mrOpenEditorFile then ModalResult := mr; // To inform pocheckermain
  finally
    FreeAndNil(GraphStatForm);
  end;
end;

procedure TResultDlgForm.SaveAsMenuItemClick(Sender: TObject);
var
  CurMemo: TSynEdit;
begin
  GetCurrentMemo(CurMemo);
  if (CurMemo <> nil) and (SaveDialog.Execute) then
  begin
    try
      CurMemo.Lines.SaveToFile(SaveDialog.FileName);
    except
      on E: EStreamError do MessageDlg('POChecker',Format(sSaveError,[SaveDialog.FileName]),mtError, [mbOk],0);
    end;
  end;
end;

procedure TResultDlgForm.GetCurrentMemo(var CurrentMemo: TSynEdit);
begin
  case ResultPageControl.PageIndex of
    0: CurrentMemo := LogMemo;
    1: CurrentMemo := StatMemo;
    2: CurrentMemo := DupMemo;
  else
    CurrentMemo := nil;
  end;
end;

procedure TResultDlgForm.LoadConfig;
var
  ARect: TRect;
begin
  if not Assigned(FSettings) then Exit;
  ARect := FSettings.ResultsFormGeometry;
  //debugln('TResultDlgForm.LoadConfig: ARect = ',dbgs(ARect));
  if not IsDefaultRect(ARect) and IsValidRect(ARect) then
  begin
    ARect := FitToRect(ARect, Screen.WorkAreaRect);
    BoundsRect := ARect;
  end;
  if Settings.DisableAntialiasing then
  begin
    LogMemo.Font.Quality := fqNonAntialiased;
    StatMemo.Font.Quality := fqNonAntialiased;
    DupMemo.Font.Quality := fqNonAntialiased;
  end
  else
  begin
    LogMemo.Font.Quality := fqDefault;
    StatMemo.Font.Quality := fqDefault;
    DupMemo.Font.Quality := fqDefault;
  end;
end;

procedure TResultDlgForm.SaveConfig;
begin
  //debugln('TResultDlgForm.SaveConfig: BoundsRect = ',dbgs(BoundsRect));
  if not Assigned(FSettings) then Exit;
  Settings.ResultsFormWindowState := WindowState;
  if (WindowState = wsNormal) then
    Settings.ResultsFormGeometry := BoundsRect
  else
    Settings.ResultsFormGeometry := Rect(RestoredLeft, RestoredTop, RestoredLeft + RestoredWidth, RestoredTop + RestoredHeight);
end;

end.

