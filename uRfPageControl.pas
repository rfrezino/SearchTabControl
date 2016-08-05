unit uRfPageControl;

interface

uses
  SysUtils, Classes, Vcl.StdCtrls, System.Generics.Collections,
  Vcl.ExtCtrls, Winapi.Messages, Vcl.ComCtrls, Vcl.Controls;

type
  TFilterProcedure = procedure (const Value: String) of object;

  TRfFilterPageControl = class(TObject)
  private
    FEdit: TEdit;
    FTabFake: TTabSheet;
    FOwner: TPageControl;
  end;

  TRfTabsFilter = class(TList<TTabSheet>)
  private
    FOwner: TPageControl;

    function FilterMatchTab(const Filter: string; Tab: TTabSheet): Boolean;
    function IsSearchTab(Tab: TTabSheet): Boolean;
    function GetSearchTab: TTabSheet;
  public
    constructor Create(Owner: TPageControl);

    procedure Filter(FilterText: string);
  end;

  TRfPageControlFilterComponents = class(TObject)
  private
    FOwner: TPageControl;
    FTabSheet: TTabSheet;
    FEditSearch: TEdit;
    FSearchImage: TImage;
    FPanel: TPanel;
    FFilterProcedure: TFilterProcedure;
    FVisible: Boolean;
    FInternalVisible: Boolean;

    procedure CreateImage;
    procedure CreateEdit;
    procedure CreatePage;
    procedure DoEditChange(Sender: TObject);
    procedure SetVisible(const Value: Boolean);
    procedure SetInternalVisible(const Value: Boolean);

    property InternalVisible: Boolean read FInternalVisible write SetInternalVisible;
  public
    constructor Create(PageControl: TPageControl; FilterProcedure: TFilterProcedure);
    destructor Destroy; override;

    property Visible: Boolean read FVisible write SetVisible;

    function IsSearchItemVisibleOnNavigation(out CurTabIndex: Integer): Boolean;
  end;

  TRfPageControl = class(TPageControl)
  private
    FFilter: String;
    FFilterComponents: TRfPageControlFilterComponents;
    FShowSearchFilter: Boolean;
    procedure SetShowSearchFilter(const Value: Boolean);
    procedure CreateFilterComponents;

    function IsOnNavigatorNextButton(X, Y: Integer): Boolean;
    function IsOnNavigatorPriorButton(X, Y: Integer): Boolean;
  protected
    function MouseActivate(Button: TMouseButton; Shift: TShiftState; X, Y: Integer; HitTest: Integer): TMouseActivate; override;

    procedure Loaded; override;
    procedure Change; override;

    procedure SetFilter(const Value: String); virtual;

    function GetTabList: TRfTabsFilter;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Filter: String read FFilter write SetFilter;

    function GetFirstCaption: string;
  published
    property ShowSearchFilter: Boolean read FShowSearchFilter write SetShowSearchFilter;
  end;

  procedure Register;

implementation

uses
  Vcl.Graphics, Vcl.Imaging.pngimage, Winapi.CommCtrl, System.Types, Vcl.Forms;

const
  TAB_SEARCH = 57;

procedure Register;
begin
  Classes.RegisterComponents('RfComponents', [TRfPageControl]);
end;


procedure TRfPageControl.Change;
var
  ParentForm: TCustomForm;
begin
  inherited;

  ParentForm := GetParentForm(Self);
  if ParentForm <> nil then
    ParentForm.ActiveControl := Self;

  if (csDesigning in ComponentState) then
    Exit;

  if FShowSearchFilter then
  begin
    if (TabIndex = 0) and (Tabs.Count > 1) then
      ActivePageIndex := 1;
  end;
end;

constructor TRfPageControl.Create(AOwner: TComponent);
begin
  inherited;

end;

destructor TRfPageControl.Destroy;
begin
  FFilterComponents.Free;
  inherited;
end;

function TRfPageControl.GetFirstCaption: string;
begin
  Result := Tabs[0];
end;

function TRfPageControl.GetTabList: TRfTabsFilter;
var
  TabInList: TTabSheet;
  I: Integer;
begin
  Result := TRfTabsFilter.Create(Self);

  for I := 0 to PageCount -1 do
    Result.Add(Pages[I]);
end;

function TRfPageControl.IsOnNavigatorNextButton(X, Y: Integer): Boolean;
var
  Point: TPoint;
  ButtonNext: TRect;
begin
  Point.X := X;
  Point.Y := Y;

  ButtonNext.Left := Self.Width - 16;
  ButtonNext.Right := Self.Width;
  ButtonNext.Top := 2;
  ButtonNext.Bottom := ButtonNext.Top + 16;

  Result := PtInRect(ButtonNext, Point);
end;

function TRfPageControl.IsOnNavigatorPriorButton(X, Y: Integer): Boolean;
var
  Point: TPoint;
  ButtonNext: TRect;
begin
  Point.X := X;
  Point.Y := Y;

  ButtonNext.Left := Self.Width - 16 - 17;
  ButtonNext.Right := Self.Width - 17;
  ButtonNext.Top := 2;
  ButtonNext.Bottom := ButtonNext.Top + 16;

  Result := PtInRect(ButtonNext, Point);
end;

procedure TRfPageControl.Loaded;
begin
  inherited;

  if (csDesigning in ComponentState) then
    Exit;

  if FShowSearchFilter then
    CreateFilterComponents;

  if PageCount > 1 then
    if FShowSearchFilter then
      ActivePageIndex := 1
    else
      ActivePageIndex := 0;

  if Assigned(FFilterComponents) then
    FFilterComponents.Visible := FShowSearchFilter;
end;

function TRfPageControl.MouseActivate(Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer): TMouseActivate;
var
  IsShowingSearchTab: Boolean;
  CurTabIndex: Integer;
begin
  inherited;
  if (csDesigning in ComponentState) then
    Exit;

  if not FShowSearchFilter then
    Exit;

  IsShowingSearchTab := FFilterComponents.IsSearchItemVisibleOnNavigation(CurTabIndex);
  if IsOnNavigatorNextButton(X, Y) then
    FFilterComponents.InternalVisible := False
  else if IsOnNavigatorPriorButton(X, Y) and (CurTabIndex <= 1) then
    FFilterComponents.InternalVisible := True;
end;

procedure TRfPageControl.SetFilter(const Value: String);
var
  ListOfTabs: TRfTabsFilter;
  FilterText: string;
begin
  FilterText := LowerCase(Trim(Value));
  ListOfTabs := GetTabList;
  try
    ListOfTabs.Filter(FilterText);
  finally
    ListOfTabs.Free;
  end;
  Change;
end;

procedure TRfPageControl.CreateFilterComponents;
begin
  if FFilterComponents = nil then
    FFilterComponents := TRfPageControlFilterComponents.Create(Self, SetFilter);
end;

procedure TRfPageControl.SetShowSearchFilter(const Value: Boolean);
begin
  FShowSearchFilter := Value;
  if (csDesigning in ComponentState) then
    Exit;
  CreateFilterComponents;
end;

constructor TRfTabsFilter.Create(Owner: TPageControl);
begin
  inherited Create;
  FOwner := Owner;
end;

procedure TRfTabsFilter.Filter(FilterText: string);
var
  Tab: TTabSheet;
  FirstValidTab: TTabSheet;
  IsVisible: Boolean;
begin
  FirstValidTab := nil;
  for Tab in Self do
  begin
    IsVisible := FilterMatchTab(FilterText, Tab);
    Tab.TabVisible := IsVisible;
    Tab.Visible := IsVisible;

    if not Tab.TabVisible then
      Continue;

    if (not Assigned(FirstValidTab)) and (not IsSearchTab(Tab)) then
      FirstValidTab := Tab;
  end;

  if not Assigned(FirstValidTab) then
    FirstValidTab := GetSearchTab;

  FOwner.ActivePage := FirstValidTab;
end;

function TRfTabsFilter.FilterMatchTab(const Filter: string; Tab: TTabSheet): Boolean;
begin
  Result := IsSearchTab(Tab) or (Pos(Filter, LowerCase(Tab.Caption)) > 0) or Filter.IsEmpty;
end;

function TRfTabsFilter.GetSearchTab: TTabSheet;
var
  Tab: TTabSheet;
begin
  for Tab in Self do
    if IsSearchTab(Tab) then
    begin
      Result := Tab;
      Exit;
    end;
end;

function TRfTabsFilter.IsSearchTab(Tab: TTabSheet): Boolean;
begin
  Result := Tab.Tag = TAB_SEARCH;
end;

constructor TRfPageControlFilterComponents.Create(PageControl: TPageControl; FilterProcedure: TFilterProcedure);
begin
  FOwner := PageControl;
  FFilterProcedure := FilterProcedure;
  CreatePage;
  CreateEdit;
  CreateImage;
end;

procedure TRfPageControlFilterComponents.DoEditChange(Sender: TObject);
begin
  FFilterProcedure(FEditSearch.Text);
  FEditSearch.SetFocus;
  FEditSearch.SelStart := Length(FEditSearch.Text);
end;

function TRfPageControlFilterComponents.IsSearchItemVisibleOnNavigation(out CurTabIndex: Integer): Boolean;
var
  HitTest: TTCHitTestInfo;
begin
  HitTest.pt.X := 5;
  HitTest.pt.Y := 5;
  HitTest.flags := 0;

  CurTabIndex := FOwner.Perform(TCM_HITTEST, 0, LongInt(@HitTest));
  Result := CurTabIndex = 0;
end;

procedure TRfPageControlFilterComponents.SetInternalVisible(const Value: Boolean);
begin
  FInternalVisible := Value;
  FEditSearch.Visible := FInternalVisible;
  FSearchImage.Visible := FInternalVisible;
end;

procedure TRfPageControlFilterComponents.SetVisible(const Value: Boolean);
begin
  FVisible := Value;
  FEditSearch.Visible := FVisible;
  FTabSheet.Visible := FVisible;
  FTabSheet.TabVisible := FVisible;
  FSearchImage.Visible := FVisible;
end;

procedure TRfPageControlFilterComponents.CreateEdit;
begin
  FEditSearch := TEdit.Create(FOwner);
  with FEditSearch do
  begin
    Name := FOwner.Name + 'edtSearch';
    Left := 3;
    Top := 3;
    Width := 80;
    Height := 17;
    BevelInner := bvNone;
    BevelOuter := bvNone;
    BorderStyle := bsNone;
    Color := $00F4F4F4;
    TabOrder := 0;
    Text := '';
    StyleElements := [seFont];
    OnChange := DoEditChange;
  end;
  FEditSearch.Parent := FOwner;
end;

procedure TRfPageControlFilterComponents.CreateImage;
var
  ImageBase: String;
  ImageStream: TMemoryStream;
  ImageName: ShortString;
  ImageGraphic: TGraphic;
begin
  ImageBase := '0954506E67496D61676589504E470D0A1A0A0000000D49484452000000100000'
          + '001008060000001FF3FF610000000473424954080808087C0864880000000970'
          + '485973000000750000007501E3C207650000001974455874536F667477617265'
          + '007777772E696E6B73636170652E6F72679BEE3C1A000000EF4944415478DAAD'
          + '923B0AC2401086B3D7100F6110B415FBD8AB60E323E62262632DF15158A8BDB6'
          + '22D682E821C41B58C76F7003EB8A9A10073E36ECFCFB6766765514458E842258'
          + '3A5083A2F38C136C6016C5422B94EC7336C7F7122A7081A3CE97A0000768A2BD'
          + 'BD1968F6E0428068FD2250AACE32863354ED4AE4701726D0B00F5B262BE8A199'
          + 'DA065BC893709D2F8189547045E7D906D2D79684FFC32064F1D0E5FE6E90B985'
          + 'CC434C738DF2F7BB7995691E521F163A1FC4262AE15396AA7650D6FBD2862F26'
          + 'EAC313B767A0741BE64DCD657E890C0C93500F3D8E616203C344CA6FEBAD5B2A'
          + '03C364002D183D00658D8FCCCDEDEA100000000049454E44AE426082';

  ImageStream := TMemoryStream.Create;
  try
    ImageStream.Size := Length(ImageBase) div 2;
    HexToBin(PChar(ImageBase), ImageStream.Memory^, ImageStream.Size);

    ImageName := PShortString(ImageStream.Memory)^;

    ImageGraphic := TGraphicClass(FindClass(UTF8Decode(ImageName))).Create;
    try
      ImageStream.Position := 1 + Length(ImageName);
      ImageGraphic.LoadFromStream(ImageStream);

      FSearchImage := TImage.Create(FOwner);
      FSearchImage.Parent := FOwner;
      FSearchImage.Name := FOwner.Name + 'imgSearch';
      FSearchImage.Left := FEditSearch.Left + FEditSearch.Width + 3;
      FSearchImage.Top := 4;
      FSearchImage.Width := 18;
      FSearchImage.Height := 18;
      FSearchImage.Picture.Assign(ImageGraphic);
      FSearchImage.BringToFront;
    finally
      ImageGraphic.Free;
    end;
  finally
    ImageStream.Free;
  end;
end;

procedure TRfPageControlFilterComponents.CreatePage;
begin
  FTabSheet := TTabSheet.Create(FOwner);
  FTabSheet.Caption := '                               ';
  FTabSheet.Parent := FOwner;
  FTabSheet.PageControl := FOwner;
  FTabSheet.Name := FOwner.Name + 'tabSearch';
  FTabSheet.Tag := TAB_SEARCH;
  FTabSheet.PageIndex := 0;

  FPanel := TPanel.Create(FTabSheet);
  FPanel.Caption := 'No results found.';
  FPanel.Align := alClient;
  FPanel.Name := FOwner.Name + 'pnlSearch';
  FPanel.BevelOuter := bvNone;
  FPanel.Parent := FTabSheet;
end;

destructor TRfPageControlFilterComponents.Destroy;
begin
  FEditSearch.Free;
  FSearchImage.Free;
  inherited;
end;

initialization
  RegisterClass(TPngImage);

end.
