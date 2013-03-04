unit KM_GUIMenuLobby;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  Controls,Math, SysUtils,
  KM_CommonTypes, KM_Defaults,
  KM_Controls, KM_Maps, KM_Saves, KM_Pics, KM_InterfaceDefaults, KM_Minimap, KM_ServerQuery, KM_Networking;


type
  TKMGUIMenuLobby = class
  private
    fOnPageChange: TGUIEventText; //will be in ancestor class

    fMapsMP: TKMapsCollection;
    fSavesMP: TKMSavesCollection;
    fMinimap: TKMMinimap;
    fNetworking: TKMNetworking;

    procedure Lobby_Reset(aKind: TNetPlayerKind; aPreserveMessage: Boolean = False; aPreserveMaps: Boolean = False);
    procedure Lobby_GameOptionsChange(Sender: TObject);
    procedure Lobby_PlayersSetupChange(Sender: TObject);
    procedure Lobby_MapColumnClick(aValue: Integer);
    procedure Lobby_MapTypeSelect(Sender: TObject);
    procedure Lobby_SortUpdate(Sender: TObject);
    procedure Lobby_ScanUpdate(Sender: TObject);
    procedure Lobby_RefreshMapList(aJumpToSelected: Boolean);
    procedure Lobby_RefreshSaveList(aJumpToSelected: Boolean);
    procedure Lobby_MapSelect(Sender: TObject);
    procedure Lobby_PostKey(Sender: TObject; Key: Word);

    procedure Lobby_OnDisconnect(const aData:string);
    procedure Lobby_OnGameOptions(Sender: TObject);
    procedure Lobby_OnMapName(const aData:string);
    procedure Lobby_OnMessage(const aData:string);
    procedure Lobby_OnPingInfo(Sender: TObject);
    procedure Lobby_OnPlayersSetup(Sender: TObject);
    procedure Lobby_OnReassignedToHost(Sender: TObject);

    procedure BackClick(Sender: TObject);
    procedure SettingsClick(Sender: TObject);
    procedure StartClick(Sender: TObject);
  protected
    Panel_Lobby: TKMPanel;
      Panel_LobbySettings: TKMPanel;
        Edit_LobbyDescription: TKMEdit;
        Edit_LobbyPassword: TKMEdit;
        Button_LobbySettingsSave: TKMButton;
        Button_LobbySettingsCancel: TKMButton;

      Panel_LobbyServerName: TKMPanel;
        Label_LobbyServerName: TKMLabel;

      Panel_LobbyPlayers: TKMPanel;
        CheckBox_LobbyHostControl: TKMCheckBox;
        Image_LobbyFlag: array [0..MAX_PLAYERS-1] of TKMImage;
        DropBox_LobbyPlayerSlot: array [0..MAX_PLAYERS-1] of TKMDropList;
        Label_LobbyPlayer: array [0..MAX_PLAYERS-1] of TKMLabel;
        DropBox_LobbyLoc: array [0..MAX_PLAYERS-1] of TKMDropList;
        DropBox_LobbyTeam: array [0..MAX_PLAYERS-1] of TKMDropList;
        Drop_LobbyColors: array [0..MAX_PLAYERS-1] of TKMDropColumns;
        Image_LobbyReady: array [0..MAX_PLAYERS-1] of TKMImage;
        Label_LobbyPing: array [0..MAX_PLAYERS-1] of TKMLabel;

      Panel_LobbySetup: TKMPanel;
        Label_LobbyChooseMap: TKMLabel;
        Radio_LobbyMapType: TKMRadioGroup;
        DropCol_LobbyMaps: TKMDropColumns;
        Label_LobbyMapName: TKMLabel;
        Memo_LobbyMapDesc: TKMMemo;
        TrackBar_LobbyPeacetime: TKMTrackBar;
        TrackBar_LobbySpeedPT, TrackBar_LobbySpeedAfterPT: TKMTrackBar;
        MinimapView_Lobby: TKMMinimapView;

      Memo_LobbyPosts: TKMMemo;
      Label_LobbyPost: TKMLabel;
      Edit_LobbyPost: TKMEdit;

      Button_LobbyBack: TKMButton;
      Button_LobbyChangeSettings: TKMButton;
      Button_LobbyStart: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aOnPageChange: TGUIEventText);
    destructor Destroy; override;

    function GetChatText: string;
    function GetChatMessages: string;
    procedure Show(aKind: TNetPlayerKind; aNetworking: TKMNetworking);
    procedure UpdateState(aTickCount: Cardinal);
  end;


implementation
uses KM_TextLibrary, KM_Locales, KM_Utils, KM_Sound, KM_RenderUI;


{ TKMGUIMenuLobby }
constructor TKMGUIMenuLobby.Create(aParent: TKMPanel; aOnPageChange: TGUIEventText);
  procedure LobbySettingsPopUp;
  begin
    Panel_LobbySettings := TKMPanel.Create(aParent, 362, 250, 320, 300);
    Panel_LobbySettings.Anchors := [];
      TKMBevel.Create(Panel_LobbySettings, -1000,  -1000, 4000, 4000);
      TKMImage.Create(Panel_LobbySettings, -20, -75, 340, 310, 15, rxGuiMain);
      TKMBevel.Create(Panel_LobbySettings,   0,  0, 320, 300);
      TKMLabel.Create(Panel_LobbySettings,  20, 10, 280, 20, 'Room settings', fnt_Outline, taCenter);

      TKMLabel.Create(Panel_LobbySettings, 20, 50, 156, 20, 'Description', fnt_Outline, taLeft);
      Edit_LobbyDescription := TKMEdit.Create(Panel_LobbySettings, 20, 70, 152, 20, fnt_Grey);
      Edit_LobbyDescription.AllowedChars := acText;

      TKMLabel.Create(Panel_LobbySettings, 20, 100, 156, 20, 'Password', fnt_Outline, taLeft);
      Edit_LobbyPassword := TKMEdit.Create(Panel_LobbySettings, 20, 120, 152, 20, fnt_Grey);
      Edit_LobbyPassword.AllowedChars := acText;

      Button_LobbySettingsSave := TKMButton.Create(Panel_LobbySettings, 20, 160, 280, 30, 'Ok', bsMenu);
      Button_LobbySettingsSave.OnClick := SettingsClick;
      Button_LobbySettingsCancel := TKMButton.Create(Panel_LobbySettings, 20, 200, 280, 30, fTextLibrary[TX_MP_MENU_FIND_SERVER_CANCEL], bsMenu);
      Button_LobbySettingsCancel.OnClick := SettingsClick;
  end;
const
  CW = 690; C1 = 35; C2 = 195; C3 = 355; C4 = 445; C5 = 570; C6 = 650;
var
  i,k,top:integer;
begin
  inherited Create;

  fOnPageChange := aOnPageChange;

  fMinimap := TKMMinimap.Create(True, False, True);

  fMapsMP := TKMapsCollection.Create(True);
  fSavesMP := TKMSavesCollection.Create;

  Panel_Lobby := TKMPanel.Create(aParent,0,0,aParent.Width, aParent.Height);
  Panel_Lobby.Stretch;

    LobbySettingsPopUp;

    //Server Name
    Panel_LobbyServerName := TKMPanel.Create(Panel_Lobby, 30, 30, CW, 30);
      TKMBevel.Create(Panel_LobbyServerName,   0,  0, CW, 30);
      Label_LobbyServerName := TKMLabel.Create(Panel_LobbyServerName, 10, 10, CW-20, 20, '', fnt_Metal, taLeft);

    //Players
    Panel_LobbyPlayers := TKMPanel.Create(Panel_Lobby, 30, 65, CW, 260);
      TKMBevel.Create(Panel_LobbyPlayers,  0,  0, CW, 260);

      CheckBox_LobbyHostControl := TKMCheckBox.Create(Panel_LobbyPlayers, 10, 10, 450, 20, fTextLibrary[TX_LOBBY_HOST_DOES_SETUP], fnt_Metal);
      CheckBox_LobbyHostControl.OnClick := Lobby_PlayersSetupChange;

      TKMLabel.Create(Panel_LobbyPlayers, C1, 40, 150,  20, fTextLibrary[TX_LOBBY_HEADER_PLAYERS], fnt_Outline, taLeft);
      TKMLabel.Create(Panel_LobbyPlayers, C2, 40, 150,  20, fTextLibrary[TX_LOBBY_HEADER_STARTLOCATION], fnt_Outline, taLeft);
      TKMLabel.Create(Panel_LobbyPlayers, C3, 40,  80,  20, fTextLibrary[TX_LOBBY_HEADER_TEAM], fnt_Outline, taLeft);
      TKMLabel.Create(Panel_LobbyPlayers, C4, 40,  80,  20, fTextLibrary[TX_LOBBY_HEADER_FLAGCOLOR], fnt_Outline, taLeft);
      TKMLabel.Create(Panel_LobbyPlayers, C5, 40, fTextLibrary[TX_LOBBY_HEADER_READY], fnt_Outline, taCenter);
      TKMLabel.Create(Panel_LobbyPlayers, C6, 40, fTextLibrary[TX_LOBBY_HEADER_PING], fnt_Outline, taCenter);

      for i:=0 to MAX_PLAYERS-1 do begin
        top := 60+i*24;
        Image_LobbyFlag[i] := TKMImage.Create(Panel_LobbyPlayers, 10, top+3, 16, 11, 0, rxGuiMain);

        Label_LobbyPlayer[i] := TKMLabel.Create(Panel_LobbyPlayers, C1, top+2, 150, 20, '', fnt_Grey, taLeft);
        Label_LobbyPlayer[i].Hide;

        DropBox_LobbyPlayerSlot[i] := TKMDropList.Create(Panel_LobbyPlayers, C1, top, 150, 20, fnt_Grey, '', bsMenu);
        DropBox_LobbyPlayerSlot[i].Add(fTextLibrary[TX_LOBBY_SLOT_OPEN]); //Player can join into this slot
        DropBox_LobbyPlayerSlot[i].Add(fTextLibrary[TX_LOBBY_SLOT_CLOSED]); //Closed, nobody can join it
        DropBox_LobbyPlayerSlot[i].Add(fTextLibrary[TX_LOBBY_SLOT_AI_PLAYER]); //This slot is an AI player
        DropBox_LobbyPlayerSlot[i].ItemIndex := 0; //Open
        DropBox_LobbyPlayerSlot[i].OnChange := Lobby_PlayersSetupChange;

        DropBox_LobbyLoc[i] := TKMDropList.Create(Panel_LobbyPlayers, C2, top, 150, 20, fnt_Grey, '', bsMenu);
        DropBox_LobbyLoc[i].Add(fTextLibrary[TX_LOBBY_RANDOM]);
        DropBox_LobbyLoc[i].OnChange := Lobby_PlayersSetupChange;

        DropBox_LobbyTeam[i] := TKMDropList.Create(Panel_LobbyPlayers, C3, top, 80, 20, fnt_Grey, '', bsMenu);
        DropBox_LobbyTeam[i].Add('-');
        for k:=1 to 4 do DropBox_LobbyTeam[i].Add(IntToStr(k));
        DropBox_LobbyTeam[i].OnChange := Lobby_PlayersSetupChange;

        Drop_LobbyColors[i] := TKMDropColumns.Create(Panel_LobbyPlayers, C4, top, 80, 20, fnt_Grey, '', bsMenu);
        Drop_LobbyColors[i].SetColumns(fnt_Outline, [''], [0]);
        Drop_LobbyColors[i].List.ShowHeader := False;
        Drop_LobbyColors[i].FadeImageWhenDisabled := False;
        Drop_LobbyColors[i].Add(MakeListRow([''], [$FFFFFFFF], [MakePic(rxGuiMain, 31)], 0));
        for K := Low(MP_TEAM_COLORS) to High(MP_TEAM_COLORS) do
          Drop_LobbyColors[i].Add(MakeListRow([''], [MP_TEAM_COLORS[K]], [MakePic(rxGuiMain, 30)]));
        Drop_LobbyColors[i].OnChange := Lobby_PlayersSetupChange;

        Image_LobbyReady[i] := TKMImage.Create(Panel_LobbyPlayers, C5-8, top, 16, 16, 32, rxGuiMain);
        Label_LobbyPing[i] := TKMLabel.Create(Panel_LobbyPlayers, C6, top, '', fnt_Metal, taCenter);
      end;

    //Chat
    Memo_LobbyPosts := TKMMemo.Create(Panel_Lobby, 30, 330, CW, 320, fnt_Metal, bsMenu);
    Memo_LobbyPosts.AutoWrap := True;
    Memo_LobbyPosts.ScrollDown := True;
    Memo_LobbyPosts.Anchors := [akLeft, akTop, akBottom];
    Label_LobbyPost := TKMLabel.Create(Panel_Lobby, 30, 655, CW, 20, fTextLibrary[TX_LOBBY_POST_WRITE], fnt_Outline, taLeft);
    Label_LobbyPost.Anchors := [akLeft, akBottom];
    Edit_LobbyPost := TKMEdit.Create(Panel_Lobby, 30, 675, CW, 20, fnt_Metal);
    Edit_LobbyPost.OnKeyDown := Lobby_PostKey;
    Edit_LobbyPost.Anchors := [akLeft, akBottom];
    Edit_LobbyPost.ShowColors := True;

    //Setup
    Panel_LobbySetup := TKMPanel.Create(Panel_Lobby, 725, 30, 270, 712);
    Panel_LobbySetup.Anchors := [akLeft, akTop, akBottom];
      with TKMBevel.Create(Panel_LobbySetup,  0,  0, 270, 712) do Stretch;
      Label_LobbyChooseMap := TKMLabel.Create(Panel_LobbySetup, 10, 10, 250, 20, fTextLibrary[TX_LOBBY_MAP_TYPE], fnt_Outline, taLeft);
      Radio_LobbyMapType := TKMRadioGroup.Create(Panel_LobbySetup, 10, 29, 250, 80, fnt_Metal);
      Radio_LobbyMapType.Add(fTextLibrary[TX_LOBBY_MAP_BUILD]);
      Radio_LobbyMapType.Add(fTextLibrary[TX_LOBBY_MAP_FIGHT]);
      Radio_LobbyMapType.Add(fTextLibrary[TX_LOBBY_MAP_COOP]);
      Radio_LobbyMapType.Add(fTextLibrary[TX_LOBBY_MAP_SPECIAL]);
      Radio_LobbyMapType.Add(fTextLibrary[TX_LOBBY_MAP_SAVED]);
      Radio_LobbyMapType.ItemIndex := 0;
      Radio_LobbyMapType.OnChange := Lobby_MapTypeSelect;

      DropCol_LobbyMaps := TKMDropColumns.Create(Panel_LobbySetup, 10, 119, 250, 20, fnt_Metal, fTextLibrary[TX_LOBBY_MAP_SELECT], bsMenu);
      DropCol_LobbyMaps.DropCount := 19;
      DropCol_LobbyMaps.DropWidth := 430; //Wider to fit mapnames well
      DropCol_LobbyMaps.SetColumns(fnt_Outline, [fTextLibrary[TX_MENU_MAP_TITLE], '#', fTextLibrary[TX_MENU_MAP_SIZE]], [0, 290, 320]);
      DropCol_LobbyMaps.List.OnColumnClick := Lobby_MapColumnClick;
      DropCol_LobbyMaps.List.SearchColumn := 0;
      DropCol_LobbyMaps.OnChange := Lobby_MapSelect;
      Label_LobbyMapName := TKMLabel.Create(Panel_LobbySetup, 10, 119, 250, 20, '', fnt_Metal, taLeft);

      TKMBevel.Create(Panel_LobbySetup, 35, 144, 199, 199);
      MinimapView_Lobby := TKMMinimapView.Create(Panel_LobbySetup, 39, 148, 191, 191);
      MinimapView_Lobby.ShowLocs := True; //In the minimap we want player locations to be shown

      Memo_LobbyMapDesc := TKMMemo.Create(Panel_LobbySetup, 10, 348, 250, 194, fnt_Game, bsMenu);
      Memo_LobbyMapDesc.Anchors := [akLeft,akTop,akBottom];
      Memo_LobbyMapDesc.AutoWrap := True;
      Memo_LobbyMapDesc.ItemHeight := 16;

      with TKMLabel.Create(Panel_LobbySetup, 10, 546, 250, 20, fTextLibrary[TX_LOBBY_GAME_OPTIONS], fnt_Outline, taLeft) do Anchors := [akLeft,akBottom];
      TrackBar_LobbyPeacetime := TKMTrackBar.Create(Panel_LobbySetup, 10, 568, 250, 0, 120);
      TrackBar_LobbyPeacetime.Anchors := [akLeft,akBottom];
      TrackBar_LobbyPeacetime.Caption := fTextLibrary[TX_LOBBY_PEACETIME];
      TrackBar_LobbyPeacetime.Step := 5; //Round to 5min steps
      TrackBar_LobbyPeacetime.OnChange := Lobby_GameOptionsChange;

      TrackBar_LobbySpeedPT := TKMTrackBar.Create(Panel_LobbySetup, 10, 614, 250, 1, 5);
      TrackBar_LobbySpeedPT.Anchors := [akLeft,akBottom];
      TrackBar_LobbySpeedPT.Caption := 'Game speed (peacetime)';
      TrackBar_LobbySpeedPT.ThumbWidth := 45; //Enough to fit 'x2.5'
      TrackBar_LobbySpeedPT.OnChange := Lobby_GameOptionsChange;

      TrackBar_LobbySpeedAfterPT := TKMTrackBar.Create(Panel_LobbySetup, 10, 658, 250, 1, 5);
      TrackBar_LobbySpeedAfterPT.Anchors := [akLeft,akBottom];
      TrackBar_LobbySpeedAfterPT.Caption := 'Game speed';
      TrackBar_LobbySpeedAfterPT.ThumbWidth := 45; //Enough to fit 'x2.5'
      TrackBar_LobbySpeedAfterPT.OnChange := Lobby_GameOptionsChange;

    Button_LobbyBack := TKMButton.Create(Panel_Lobby, 30, 712, 220, 30, fTextLibrary[TX_LOBBY_QUIT], bsMenu);
    Button_LobbyBack.Anchors := [akLeft, akBottom];
    Button_LobbyBack.OnClick := BackClick;

    Button_LobbyChangeSettings := TKMButton.Create(Panel_Lobby, 265, 712, 220, 30, 'Room Settings', bsMenu);
    Button_LobbyChangeSettings.OnClick := SettingsClick;

    Button_LobbyStart := TKMButton.Create(Panel_Lobby, 500, 712, 220, 30, NO_TEXT, bsMenu);
    Button_LobbyStart.Anchors := [akLeft, akBottom];
    Button_LobbyStart.OnClick := StartClick;
end;


destructor TKMGUIMenuLobby.Destroy;
begin
  fMapsMP.Free;
  fSavesMP.Free;
  fMinimap.Free;

  inherited;
end;


//Access text that user was typing to copy it over to gameplay chat
function TKMGUIMenuLobby.GetChatText: string;
begin
  Result := Edit_LobbyPost.Text;
end;


//Access chat messages history to copy it over to gameplay chat
function TKMGUIMenuLobby.GetChatMessages: string;
begin
  Result := Memo_LobbyPosts.Text;
end;


procedure TKMGUIMenuLobby.Show(aKind: TNetPlayerKind; aNetworking: TKMNetworking);
begin
  fNetworking := aNetworking;

  Lobby_Reset(aKind);

  //Events binding is the same for Host and Joiner because of stand-alone Server
  //E.g. If Server fails, Host can be disconnected from it as well as a Joiner
  fNetworking.OnTextMessage  := Lobby_OnMessage;
  fNetworking.OnPlayersSetup := Lobby_OnPlayersSetup;
  fNetworking.OnGameOptions  := Lobby_OnGameOptions;
  fNetworking.OnMapName      := Lobby_OnMapName;
  fNetworking.OnPingInfo     := Lobby_OnPingInfo;
  //fNetworking.OnStartMap - already assigned in fGameApp when Net is created
  //fNetworking.OnStartSave - already assigned in fGameApp when Net is created
  fNetworking.OnDisconnect   := Lobby_OnDisconnect;
  fNetworking.OnReassignedHost := Lobby_OnReassignedToHost;

  Panel_Lobby.Show;
end;


procedure TKMGUIMenuLobby.BackClick(Sender: TObject);
begin
  fNetworking.AnnounceDisconnect;
  fNetworking.Disconnect;

  fOnPageChange(Self, gpMultiplayer, fTextLibrary[TX_GAME_ERROR_DISCONNECT]);
end;


//Reset everything to it's defaults depending on users role (Host/Joiner/Reassigned)
procedure TKMGUIMenuLobby.Lobby_Reset(aKind: TNetPlayerKind; aPreserveMessage: Boolean = False; aPreserveMaps: Boolean = False);
var I: Integer;
begin
  Label_LobbyServerName.Caption := '';

  for I := 0 to MAX_PLAYERS - 1 do
  begin
    Label_LobbyPlayer[I].Caption := '.';
    Label_LobbyPlayer[I].FontColor := $FFFFFFFF;
    Image_LobbyFlag[I].TexID := 0;
    Label_LobbyPlayer[I].Hide;
    DropBox_LobbyPlayerSlot[I].Show;
    DropBox_LobbyPlayerSlot[I].Disable;
    DropBox_LobbyLoc[I].ItemIndex := 0;
    DropBox_LobbyLoc[I].Disable;
    DropBox_LobbyTeam[I].Disable;
    DropBox_LobbyTeam[I].ItemIndex := 0;
    Drop_LobbyColors[I].Disable;
    Drop_LobbyColors[I].ItemIndex := 0;
    DropBox_LobbyPlayerSlot[I].ItemIndex := 0; //Open
    Image_LobbyReady[I].TexID := 0;
    Label_LobbyPing[I].Caption := '';
  end;

  if not aPreserveMessage then Memo_LobbyPosts.Clear;
  Edit_LobbyPost.Text := '';

  Label_LobbyMapName.Caption := '';
  Memo_LobbyMapDesc.Clear;

  TrackBar_LobbyPeacetime.Position := 0; //Default peacetime = 0
  TrackBar_LobbySpeedPT.Position := 1; //Default speed = 1
  TrackBar_LobbySpeedPT.ThumbText := 'x1';
  TrackBar_LobbySpeedAfterPT.Position := 1; //Default speed = 1
  TrackBar_LobbySpeedAfterPT.ThumbText := 'x1';

  Lobby_OnMapName('');

  //Setup for Host
  if aKind = lpk_Host then
  begin
    Radio_LobbyMapType.Enable;
    Radio_LobbyMapType.ItemIndex := 0;
    if not aPreserveMaps then Lobby_MapTypeSelect(nil);
    DropCol_LobbyMaps.Show;
    Label_LobbyMapName.Hide;
    Label_LobbyChooseMap.Show;
    Button_LobbyStart.Caption := fTextLibrary[TX_LOBBY_START]; //Start
    Button_LobbyStart.Disable;
    TrackBar_LobbyPeacetime.Disable;
    TrackBar_LobbySpeedPT.Disable;
    TrackBar_LobbySpeedAfterPT.Disable;
    CheckBox_LobbyHostControl.Enable;
    Button_LobbyChangeSettings.Show;
  end
  else //Setup for Joiner
  begin
    Radio_LobbyMapType.Disable;
    Radio_LobbyMapType.ItemIndex := 0;
    DropCol_LobbyMaps.Hide;
    Label_LobbyMapName.Show;
    Label_LobbyChooseMap.Hide;
    Button_LobbyStart.Caption := fTextLibrary[TX_LOBBY_READY]; //Ready
    Button_LobbyStart.Enable;
    TrackBar_LobbyPeacetime.Disable;
    TrackBar_LobbySpeedPT.Disable;
    TrackBar_LobbySpeedAfterPT.Disable;
    CheckBox_LobbyHostControl.Disable;
    Button_LobbyChangeSettings.Hide;
  end;
end;



procedure TKMGUIMenuLobby.Lobby_GameOptionsChange(Sender: TObject);
begin
  //Set the peacetime
  fNetworking.NetGameOptions.Peacetime := EnsureRange(TrackBar_LobbyPeacetime.Position, 0, 300);
  fNetworking.NetGameOptions.SpeedPT := (TrackBar_LobbySpeedPT.Position - 1) / 2 + 1;
  fNetworking.NetGameOptions.SpeedAfterPT := (TrackBar_LobbySpeedAfterPT.Position - 1) / 2 + 1;
  fNetworking.SendGameOptions;

  //Refresh the data to controls
  Lobby_OnGameOptions(nil);
end;


procedure TKMGUIMenuLobby.Lobby_OnGameOptions(Sender: TObject);
begin
  TrackBar_LobbyPeacetime.Position    := fNetworking.NetGameOptions.Peacetime;

  TrackBar_LobbySpeedPT.Enabled   := (TrackBar_LobbyPeacetime.Position > 0) and TrackBar_LobbySpeedAfterPT.Enabled;
  TrackBar_LobbySpeedPT.Position  := Round((fNetworking.NetGameOptions.SpeedPT - 1) * 2 + 1);
  TrackBar_LobbySpeedPT.ThumbText := 'x' + FloatToStr(fNetworking.NetGameOptions.SpeedPT);

  TrackBar_LobbySpeedAfterPT.Position   := Round((fNetworking.NetGameOptions.SpeedAfterPT - 1) * 2 + 1);
  TrackBar_LobbySpeedAfterPT.ThumbText  := 'x' + FloatToStr(fNetworking.NetGameOptions.SpeedAfterPT);
end;


//Try to change players setup, Networking will check if it can be done under current
//conditions immediately and reverts the change without disturbing Host.
//If the change is possible Networking will send query to the Host.
//Host will reply with OnPlayersSetup event and data will be actualized.
procedure TKMGUIMenuLobby.Lobby_PlayersSetupChange(Sender: TObject);
var i:integer;
begin
  //Host control toggle
  if Sender = CheckBox_LobbyHostControl then
  begin
    fNetworking.NetPlayers.HostDoesSetup := CheckBox_LobbyHostControl.Checked;
    fNetworking.SendPlayerListAndRefreshPlayersSetup;
  end;

  for i:=0 to MAX_PLAYERS-1 do
  begin
    //Starting location
    if (Sender = DropBox_LobbyLoc[i]) and DropBox_LobbyLoc[i].Enabled then
    begin
      fNetworking.SelectLoc(DropBox_LobbyLoc[i].GetSelectedTag, i+1);
      //Host with HostDoesSetup could have given us some location we don't know about from a map/save we don't have
      if fNetworking.SelectGameKind <> ngk_None then
        DropBox_LobbyLoc[i].SelectByTag(fNetworking.NetPlayers[i+1].StartLocation);
    end;

    //Team
    if (Sender = DropBox_LobbyTeam[i]) and DropBox_LobbyTeam[i].Enabled then
      fNetworking.SelectTeam(DropBox_LobbyTeam[i].ItemIndex, i+1);

    //Color
    if (Sender = Drop_LobbyColors[i]) and Drop_LobbyColors[i].Enabled then
    begin
      fNetworking.SelectColor(Drop_LobbyColors[i].ItemIndex, i+1);
      Drop_LobbyColors[i].ItemIndex := fNetworking.NetPlayers[i+1].FlagColorID;
    end;

    if Sender = DropBox_LobbyPlayerSlot[i] then
    begin
      //Modify an existing player
      if (i < fNetworking.NetPlayers.Count) then
      begin
        case DropBox_LobbyPlayerSlot[i].ItemIndex of
          0: //Open
            begin
              if fNetworking.NetPlayers[i+1].IsComputer then
                fNetworking.NetPlayers.RemAIPlayer(i+1)
              else if fNetworking.NetPlayers[i+1].IsClosed then
                fNetworking.NetPlayers.RemClosedPlayer(i+1);
            end;
          1: //Closed
            fNetworking.NetPlayers.AddClosedPlayer(i+1); //Replace it
          2: //AI
            fNetworking.NetPlayers.AddAIPlayer(i+1); //Replace it
        end;
      end
      else
      begin
        //Add a new player
        if DropBox_LobbyPlayerSlot[i].ItemIndex = 1 then //Closed
          fNetworking.NetPlayers.AddClosedPlayer;
        if DropBox_LobbyPlayerSlot[i].ItemIndex = 2 then //AI
        begin
          fNetworking.NetPlayers.AddAIPlayer;
          if fNetworking.SelectGameKind = ngk_Save then
            fNetworking.MatchPlayersToSave(fNetworking.NetPlayers.Count); //Match new AI player in save
        end;
      end;
      fNetworking.SendPlayerListAndRefreshPlayersSetup;
    end;
  end;
end;


//Players list has been updated
//We should reflect it to UI
procedure TKMGUIMenuLobby.Lobby_OnPlayersSetup(Sender: TObject);
var
  I,K,ID,LocaleID: Integer;
  MyNik, CanEdit, HostCanEdit, IsSave, IsValid: Boolean;
begin
  IsSave := fNetworking.SelectGameKind = ngk_Save;

  //Go through active players first
  for I:=0 to fNetworking.NetPlayers.Count - 1 do
  begin
    //Flag icon
    LocaleID := fLocales.GetIDFromCode(fNetworking.NetPlayers[I+1].LangCode);
    if LocaleID <> -1 then
      Image_LobbyFlag[I].TexID := fLocales[LocaleID].FlagSpriteID
    else
      if fNetworking.NetPlayers[I+1].IsComputer then
        Image_LobbyFlag[I].TexID := 62 //PC icon
      else
        Image_LobbyFlag[I].TexID := 0;

    //Players list
    if fNetworking.IsHost and (not fNetworking.NetPlayers[I+1].IsHuman) then
    begin
      Label_LobbyPlayer[I].Hide;
      DropBox_LobbyPlayerSlot[I].Enable;
      DropBox_LobbyPlayerSlot[I].Show;
      if fNetworking.NetPlayers[I+1].IsComputer then
        DropBox_LobbyPlayerSlot[I].ItemIndex := 2 //AI
      else
        DropBox_LobbyPlayerSlot[I].ItemIndex := 1; //Closed
    end
    else
    begin
      Label_LobbyPlayer[I].Caption := fNetworking.NetPlayers[I+1].GetNickname;
      if fNetworking.NetPlayers[I+1].FlagColorID = 0 then
        Label_LobbyPlayer[I].FontColor := $FFFFFFFF
      else
        Label_LobbyPlayer[I].FontColor := FlagColorToTextColor(fNetworking.NetPlayers[I+1].FlagColor);
      Label_LobbyPlayer[I].Show;
      DropBox_LobbyPlayerSlot[I].Disable;
      DropBox_LobbyPlayerSlot[I].Hide;
      DropBox_LobbyPlayerSlot[I].ItemIndex := 0; //Open
    end;

    //If we can't load the map, don't attempt to show starting locations
    IsValid := false;
    DropBox_LobbyLoc[I].Clear;
    if fNetworking.SelectGameKind = ngk_None then
      DropBox_LobbyLoc[I].Add(fTextLibrary[TX_LOBBY_RANDOM], 0);

    if fNetworking.SelectGameKind = ngk_Save then
    begin
      IsValid := fNetworking.SaveInfo.IsValid;
      DropBox_LobbyLoc[I].Add(fTextLibrary[TX_LOBBY_SELECT], 0);
      if fNetworking.NetPlayers[I+1].IsHuman then //Cannot add AIs to MP save, they are filled automatically
        for K := 0 to fNetworking.SaveInfo.Info.PlayerCount - 1 do
          if fNetworking.SaveInfo.Info.Enabled[K]
          and (fNetworking.SaveInfo.Info.CanBeHuman[K] or ALLOW_TAKE_AI_PLAYERS) then
            DropBox_LobbyLoc[I].Add(fNetworking.SaveInfo.Info.LocationName[K], K+1);
    end;
    if fNetworking.SelectGameKind = ngk_Map then
    begin
      IsValid := fNetworking.MapInfo.IsValid;
      DropBox_LobbyLoc[I].Add(fTextLibrary[TX_LOBBY_RANDOM], 0);
      for K := 0 to fNetworking.MapInfo.PlayerCount - 1 do
        if fNetworking.MapInfo.CanBeHuman[K] or ALLOW_TAKE_AI_PLAYERS then
        begin
          if fNetworking.NetPlayers[I+1].IsHuman
          or (fNetworking.NetPlayers[I+1].IsComputer and fNetworking.MapInfo.CanBeAI[K]) then
            DropBox_LobbyLoc[I].Add(fNetworking.MapInfo.LocationName(K), K+1);
        end;
    end;
    if IsValid then
      DropBox_LobbyLoc[I].SelectByTag(fNetworking.NetPlayers[I+1].StartLocation)
    else
      DropBox_LobbyLoc[I].ItemIndex := 0;

    DropBox_LobbyTeam[I].ItemIndex := fNetworking.NetPlayers[I+1].Team;
    Drop_LobbyColors[I].ItemIndex := fNetworking.NetPlayers[I+1].FlagColorID;
    if fNetworking.NetPlayers[I+1].IsClosed then
      Image_LobbyReady[I].TexID := 0
    else
      Image_LobbyReady[I].TexID := 32+Byte(fNetworking.NetPlayers[I+1].ReadyToStart);

    MyNik := (I+1 = fNetworking.MyIndex); //Our index
    //We are allowed to edit if it is our nickname and we are set as NOT ready,
    //or we are the host and this player is an AI
    CanEdit := (MyNik and (fNetworking.IsHost or not fNetworking.NetPlayers.HostDoesSetup) and
                          (fNetworking.IsHost or not fNetworking.NetPlayers[I+1].ReadyToStart)) or
               (fNetworking.IsHost and fNetworking.NetPlayers[I+1].IsComputer);
    HostCanEdit := (fNetworking.IsHost and fNetworking.NetPlayers.HostDoesSetup and
                    not fNetworking.NetPlayers[I+1].IsClosed);
    DropBox_LobbyLoc[I].Enabled := (CanEdit or HostCanEdit);
    DropBox_LobbyTeam[I].Enabled := (CanEdit or HostCanEdit) and not IsSave; //Can't change color or teams in a loaded save
    Drop_LobbyColors[I].Enabled := (CanEdit or (MyNik and not fNetworking.NetPlayers[I+1].ReadyToStart)) and not IsSave;
    if MyNik and not fNetworking.IsHost then
    begin
      if fNetworking.NetPlayers[I+1].ReadyToStart then
        Button_LobbyStart.Caption := fTextLibrary[TX_LOBBY_NOT_READY]
      else
        Button_LobbyStart.Caption := fTextLibrary[TX_LOBBY_READY];
    end
  end;

  //Disable rest of the players
  for I := fNetworking.NetPlayers.Count to MAX_PLAYERS - 1 do
  begin
    Label_LobbyPlayer[I].Caption := '';
    Image_LobbyFlag[I].TexID := 0;
    Label_LobbyPlayer[I].Hide;
    DropBox_LobbyPlayerSlot[I].Show;
    DropBox_LobbyPlayerSlot[I].ItemIndex := 0; //Open
    DropBox_LobbyLoc[I].ItemIndex := 0;
    DropBox_LobbyTeam[I].ItemIndex := 0;
    Drop_LobbyColors[I].ItemIndex := 0;
    //Only host may change player slots, and only the first unused slot may be changed (so there are no gaps in net players list)
    DropBox_LobbyPlayerSlot[I].Enabled := fNetworking.IsHost and (I = fNetworking.NetPlayers.Count);
    Image_LobbyReady[I].TexID := 0; //Hidden
    DropBox_LobbyLoc[I].Disable;
    DropBox_LobbyTeam[I].Disable;
    Drop_LobbyColors[I].Disable;
  end;

  //Update the minimap preivew with player colors
  for I := 1 to MAX_PLAYERS do
  begin
    ID := fNetworking.NetPlayers.StartingLocToLocal(I);
    if ID <> -1 then
      fMinimap.PlayerColors[I] := fNetworking.NetPlayers[ID].FlagColor
    else
      fMinimap.PlayerColors[I] := $7F000000; //Semi-transparent when not selected
  end;
  //If we have a map selected update the preview
  if (fNetworking.SelectGameKind = ngk_Map) and fNetworking.MapInfo.IsValid then
  begin
    fMinimap.Update(not fNetworking.MapInfo.IsCoop);
    MinimapView_Lobby.SetMinimap(fMinimap);
  end;

  CheckBox_LobbyHostControl.Checked := fNetworking.NetPlayers.HostDoesSetup;
  if fNetworking.IsHost then
    Button_LobbyStart.Enabled := fNetworking.CanStart;
  //If the game can't be started the text message with explanation will appear in chat area
end;


procedure TKMGUIMenuLobby.Lobby_OnPingInfo(Sender: TObject);
var i:integer;
begin
  for i:=0 to MAX_PLAYERS-1 do
  if (fNetworking.Connected) and (i < fNetworking.NetPlayers.Count) and
     (fNetworking.NetPlayers[i+1].IsHuman) then
  begin
    Label_LobbyPing[i].Caption := IntToStr(fNetworking.NetPlayers[i+1].GetInstantPing);
    Label_LobbyPing[i].FontColor := GetPingColor(fNetworking.NetPlayers[i+1].GetInstantPing);
  end
  else
    Label_LobbyPing[i].Caption := '';
  Label_LobbyServerName.Caption := fNetworking.ServerName+' #'+IntToStr(fNetworking.ServerRoom+1)+
                                   '  '+fNetworking.ServerAddress+' : '+fNetworking.ServerPort;
end;


procedure TKMGUIMenuLobby.Lobby_MapTypeSelect(Sender: TObject);
begin
  //Terminate any running scans otherwise they will continue to fill the drop box in the background
  fMapsMP.TerminateScan;
  fSavesMP.TerminateScan;
  DropCol_LobbyMaps.Clear; //Clear previous items in case scanning finds no maps/saves
  case Radio_LobbyMapType.ItemIndex of
    0,  //Build Map
    1,  //Fight Map
    2,  //Co-op Map
    3:  //Special map Map
        begin
          fMapsMP.Refresh(Lobby_ScanUpdate);
          DropCol_LobbyMaps.DefaultCaption := fTextLibrary[TX_LOBBY_MAP_SELECT];
          DropCol_LobbyMaps.List.Header.Columns[0].Caption := fTextLibrary[TX_MENU_MAP_TITLE];
          DropCol_LobbyMaps.List.Header.Columns[2].Caption := fTextLibrary[TX_MENU_MAP_SIZE];
        end;
    4:  //Saved Game
        begin
          fSavesMP.Refresh(Lobby_ScanUpdate, True);
          DropCol_LobbyMaps.DefaultCaption := fTextLibrary[TX_LOBBY_MAP_SELECT_SAVED];
          DropCol_LobbyMaps.List.Header.Columns[0].Caption := fTextLibrary[TX_MENU_LOAD_FILE];
          DropCol_LobbyMaps.List.Header.Columns[2].Caption := fTextLibrary[TX_MENU_SAVE_TIME];
        end;
    else
        begin
          DropCol_LobbyMaps.DefaultCaption := NO_TEXT;
        end;
  end;
  DropCol_LobbyMaps.ItemIndex := -1; //Clear previously selected item

  //The Sender is nil in Reset_Lobby when we are not connected
  if Sender <> nil then
    fNetworking.SelectNoMap(fTextLibrary[TX_LOBBY_MAP_NONE]);
end;


procedure TKMGUIMenuLobby.Lobby_SortUpdate(Sender: TObject);
begin
  //After sorting jump to the selected item
  if Sender = fSavesMP then
    Lobby_RefreshSaveList(True);
  if Sender = fMapsMP then
    Lobby_RefreshMapList(True);
end;


procedure TKMGUIMenuLobby.Lobby_ScanUpdate(Sender: TObject);
begin
  //Don't jump to selected with each scan update
  if Sender = fSavesMP then
    Lobby_RefreshSaveList(False);
  if Sender = fMapsMP then
    Lobby_RefreshMapList(False);
end;


procedure TKMGUIMenuLobby.Lobby_RefreshMapList(aJumpToSelected:Boolean);
var
  I, OldTopIndex: Integer;
  PrevMap: string;
  AddMap: Boolean;
begin
  fMapsMP.Lock;
    //Remember previous map selected
    if DropCol_LobbyMaps.ItemIndex <> -1 then
      PrevMap := DropCol_LobbyMaps.Item[DropCol_LobbyMaps.ItemIndex].Cells[0].Caption
    else
      PrevMap := '';

    OldTopIndex := DropCol_LobbyMaps.List.TopIndex;
    DropCol_LobbyMaps.Clear;

    for I := 0 to fMapsMP.Count - 1 do
    begin
      //Different modes allow different maps
      case Radio_LobbyMapType.ItemIndex of
        0:    AddMap := (fMapsMP[I].MissionMode = mm_Normal) and not fMapsMP[I].IsCoop and not fMapsMP[I].IsSpecial; //BuildMap
        1:    AddMap := (fMapsMP[I].MissionMode = mm_Tactic) and not fMapsMP[I].IsCoop and not fMapsMP[I].IsSpecial; //FightMap
        2:    AddMap := fMapsMP[I].IsCoop; //CoopMap
        3:    AddMap := fMapsMP[I].IsSpecial; //Special map
        else  AddMap := False; //Other cases are already handled in Lobby_MapTypeSelect
      end;

      if AddMap then
        DropCol_LobbyMaps.Add(MakeListRow([fMapsMP[I].FileName,
                                           IntToStr(fMapsMP[I].HumanPlayerCount),
                                           fMapsMP[I].SizeText], I));
    end;

    //Restore previously selected map
    if PrevMap <> '' then
      for I := 0 to DropCol_LobbyMaps.Count - 1 do
        if DropCol_LobbyMaps.Item[I].Cells[0].Caption = PrevMap then
          DropCol_LobbyMaps.ItemIndex := I;

    //Restore the top index
    DropCol_LobbyMaps.List.TopIndex := OldTopIndex;
    if aJumpToSelected and (DropCol_LobbyMaps.List.ItemIndex <> -1)
    and not InRange(DropCol_LobbyMaps.List.ItemIndex - DropCol_LobbyMaps.List.TopIndex, 0, DropCol_LobbyMaps.List.GetVisibleRows - 1) then
    begin
      if DropCol_LobbyMaps.List.ItemIndex < DropCol_LobbyMaps.List.TopIndex + DropCol_LobbyMaps.List.GetVisibleRows - 1 then
        DropCol_LobbyMaps.List.TopIndex := DropCol_LobbyMaps.List.ItemIndex
      else
      if DropCol_LobbyMaps.List.ItemIndex > DropCol_LobbyMaps.List.TopIndex + DropCol_LobbyMaps.List.GetVisibleRows - 1 then
        DropCol_LobbyMaps.List.TopIndex := DropCol_LobbyMaps.List.ItemIndex - DropCol_LobbyMaps.List.GetVisibleRows + 1;
    end;
  fMapsMP.Unlock;
end;


procedure TKMGUIMenuLobby.Lobby_RefreshSaveList(aJumpToSelected:Boolean);
var I, OldTopIndex: Integer; PrevSave: string;
begin
  fSavesMP.Lock;
    //Remember previous save selected
    if DropCol_LobbyMaps.ItemIndex <> -1 then
      PrevSave := DropCol_LobbyMaps.Item[DropCol_LobbyMaps.ItemIndex].Cells[0].Caption
    else
      PrevSave := '';

    OldTopIndex := DropCol_LobbyMaps.List.TopIndex;
    DropCol_LobbyMaps.Clear;
    for I := 0 to fSavesMP.Count - 1 do
      if fSavesMP[I].IsValid then
        DropCol_LobbyMaps.Add(MakeListRow([fSavesMP[I].FileName,
                                           IntToStr(fSavesMP[I].Info.PlayerCount),
                                           fSavesMP[I].Info.GetTimeText], I))
      else
        DropCol_LobbyMaps.Add(MakeListRow([fSavesMP[I].FileName, '', ''], I));

    //Restore previously selected save
    if PrevSave <> '' then
      for I := 0 to DropCol_LobbyMaps.Count - 1 do
        if DropCol_LobbyMaps.Item[I].Cells[0].Caption = PrevSave then
          DropCol_LobbyMaps.ItemIndex := I;

    //Restore the top index
    DropCol_LobbyMaps.List.TopIndex := OldTopIndex;
    if aJumpToSelected and (DropCol_LobbyMaps.List.ItemIndex <> -1)
    and not InRange(DropCol_LobbyMaps.List.ItemIndex - DropCol_LobbyMaps.List.TopIndex, 0, DropCol_LobbyMaps.List.GetVisibleRows - 1) then
    begin
      if DropCol_LobbyMaps.List.ItemIndex < DropCol_LobbyMaps.List.TopIndex + DropCol_LobbyMaps.List.GetVisibleRows - 1 then
        DropCol_LobbyMaps.List.TopIndex := DropCol_LobbyMaps.List.ItemIndex
      else
      if DropCol_LobbyMaps.List.ItemIndex > DropCol_LobbyMaps.List.TopIndex + DropCol_LobbyMaps.List.GetVisibleRows - 1 then
        DropCol_LobbyMaps.List.TopIndex := DropCol_LobbyMaps.List.ItemIndex - DropCol_LobbyMaps.List.GetVisibleRows + 1;
    end;
  fSavesMP.Unlock;
end;


procedure TKMGUIMenuLobby.Lobby_MapColumnClick(aValue: Integer);
var
  SM: TMapsSortMethod;
  SSM: TSavesSortMethod;
begin

  if Radio_LobbyMapType.ItemIndex < 4 then
  begin
    //Determine Sort method depending on which column user clicked
    with DropCol_LobbyMaps.List do
    case SortIndex of
      0:  if SortDirection = sdDown then
            SM := smByNameDesc
          else
            SM := smByNameAsc;
      1:  if SortDirection = sdDown then
            SM := smByHumanPlayersDesc
          else
            SM := smByHumanPlayersAsc;
      2:  if SortDirection = sdDown then
            SM := smBySizeDesc
          else
            SM := smBySizeAsc;
      else SM := smByNameAsc;
    end;
    fMapsMP.Sort(SM, Lobby_SortUpdate);
  end
  else
  begin
    //Determine Sort method depending on which column user clicked
    with DropCol_LobbyMaps.List do
    case SortIndex of
      0:  if SortDirection = sdDown then
            SSM := smByFileNameDesc
          else
            SSM := smByFileNameAsc;
      1:  if SortDirection = sdDown then
            SSM := smByPlayerCountDesc
          else
            SSM := smByPlayerCountAsc;
      2:  if SortDirection = sdDown then
            SSM := smByTimeDesc
          else
            SSM := smByTimeAsc;
      else SSM := smByFileNameAsc;
    end;
    fSavesMP.Sort(SSM, Lobby_SortUpdate);
  end;
end;


//Just pass FileName to Networking, it will check validity itself
procedure TKMGUIMenuLobby.Lobby_MapSelect(Sender: TObject);
begin
  if Radio_LobbyMapType.ItemIndex < 4 then
  begin
    fMapsMP.Lock;
      fNetworking.SelectMap(fMapsMP[DropCol_LobbyMaps.Item[DropCol_LobbyMaps.ItemIndex].Tag].FileName);
    fMapsMP.Unlock;
  end
  else
  begin
    fSavesMP.Lock;
      fNetworking.SelectSave(fSavesMP[DropCol_LobbyMaps.Item[DropCol_LobbyMaps.ItemIndex].Tag].FileName);
    fSavesMP.Unlock;
  end;
end;


procedure TKMGUIMenuLobby.Lobby_OnMapName(const aData: string);
var
  M: TKMapInfo;
  S: TKMSaveInfo;
begin
  //Common settings
  MinimapView_Lobby.Visible := (fNetworking.SelectGameKind = ngk_Map) and fNetworking.MapInfo.IsValid;
  TrackBar_LobbyPeacetime.Enabled := fNetworking.IsHost and (fNetworking.SelectGameKind = ngk_Map) and fNetworking.MapInfo.IsValid;
  TrackBar_LobbySpeedPT.Enabled := TrackBar_LobbyPeacetime.Enabled and (TrackBar_LobbyPeacetime.Position > 0);
  TrackBar_LobbySpeedAfterPT.Enabled := TrackBar_LobbyPeacetime.Enabled;

  case  fNetworking.SelectGameKind of
    ngk_None: begin
                Memo_LobbyMapDesc.Clear;
                if aData = fTextLibrary[TX_LOBBY_MAP_NONE] then
                  Label_LobbyMapName.Caption := aData
                else
                begin
                  Label_LobbyMapName.Caption := '';
                  Memo_LobbyMapDesc.Text := aData; //aData is some error message
                end;
              end;
    ngk_Save: begin
                S := fNetworking.SaveInfo;
                if not fNetworking.IsHost then
                  Radio_LobbyMapType.ItemIndex := 4;

                Label_LobbyMapName.Caption := S.FileName;
                Memo_LobbyMapDesc.Text := S.Info.GetTitleWithTime;
              end;
    ngk_Map:  begin
                M := fNetworking.MapInfo;
                if not fNetworking.IsHost then
                begin
                  if M.IsCoop then
                    Radio_LobbyMapType.ItemIndex := 2
                  else
                    if M.IsSpecial then
                      Radio_LobbyMapType.ItemIndex := 3
                    else
                      if M.MissionMode = mm_Tactic then
                        Radio_LobbyMapType.ItemIndex := 1
                      else
                        Radio_LobbyMapType.ItemIndex := 0;
                end;

                //Only load the minimap preview if the map is valid
                if M.IsValid then
                begin
                  fMinimap.LoadFromMission(M.FullPath('.dat'), M.HumanUsableLocations);
                  fMinimap.Update(not M.IsCoop);
                  MinimapView_Lobby.SetMinimap(fMinimap);
                end;
                Label_LobbyMapName.Caption := M.FileName;
                Memo_LobbyMapDesc.Text := M.BigDesc;
            end;
  end;
end;


//We have been assigned to be the host of the game because the host disconnected. Reopen lobby page in correct mode.
procedure TKMGUIMenuLobby.Lobby_OnReassignedToHost(Sender: TObject);
  procedure SelectByName(aName: string);
  var I: Integer;
  begin
    DropCol_LobbyMaps.ItemIndex := -1;
    for I := 0 to DropCol_LobbyMaps.Count - 1 do
      if DropCol_LobbyMaps.Item[I].Cells[0].Caption = aName then
      begin
        DropCol_LobbyMaps.ItemIndex := I;
        Break;
      end;
  end;
var OldMapType: byte;
begin
  Lobby_Reset(lpk_Host, True, True); //Will reset the lobby page into host mode, preserving messages/maps
  OldMapType := Radio_LobbyMapType.ItemIndex;
  if fNetworking.SelectGameKind = ngk_None then
    Radio_LobbyMapType.ItemIndex := 0 //Default
  else
    if fNetworking.SelectGameKind = ngk_Save then
      Radio_LobbyMapType.ItemIndex := 4
    else
      if fNetworking.MapInfo.IsCoop then
        Radio_LobbyMapType.ItemIndex := 2
      else
        if fNetworking.MapInfo.IsSpecial then
          Radio_LobbyMapType.ItemIndex := 3
        else
          if fNetworking.MapInfo.MissionMode = mm_Tactic then
            Radio_LobbyMapType.ItemIndex := 1
          else
            Radio_LobbyMapType.ItemIndex := 0;

  //Don't force rescanning all the maps unless the map type changed or no map was selected
  if (Radio_LobbyMapType.ItemIndex <> OldMapType) or (DropCol_LobbyMaps.ItemIndex = -1) then
    Lobby_MapTypeSelect(nil)
  else
    Lobby_RefreshMapList(False); //Just fill the list from fMapMP

  if fNetworking.SelectGameKind = ngk_Save then
    SelectByName(fNetworking.SaveInfo.FileName) //Select the map
  else
    if fNetworking.SelectGameKind = ngk_Map then
      SelectByName(fNetworking.MapInfo.FileName); //Select the map

  Lobby_OnGameOptions(nil);
  if fNetworking.SelectGameKind = ngk_Save then
    Lobby_OnMapName(fNetworking.SaveInfo.FileName)
  else
    if fNetworking.SelectGameKind = ngk_Map then
      Lobby_OnMapName(fNetworking.MapInfo.FileName);
end;


//Post what user has typed
procedure TKMGUIMenuLobby.Lobby_PostKey(Sender: TObject; Key: Word);
var ChatMessage: string;
begin
  if (Key <> VK_RETURN) or (Trim(Edit_LobbyPost.Text) = '') then exit;
  ChatMessage := Edit_LobbyPost.Text;
  //Check for console commands
  if (Length(ChatMessage) > 1) and (ChatMessage[1] = '/')
  and (ChatMessage[2] <> '/') then //double slash is the escape to place a slash at the start of a sentence
    fNetworking.ConsoleCommand(ChatMessage)
  else
  begin
    if (Length(ChatMessage) > 1) and (ChatMessage[1] = '/') and (ChatMessage[2] = '/') then
      Delete(ChatMessage, 1, 1); //Remove one of the /'s
    fNetworking.PostMessage(ChatMessage, True);
  end;

  Edit_LobbyPost.Text := '';
end;


procedure TKMGUIMenuLobby.Lobby_OnMessage(const aData:string);
begin
  Memo_LobbyPosts.Add(aData);
end;


//We were disconnected from Server. Either we were kicked, or connection broke down
procedure TKMGUIMenuLobby.Lobby_OnDisconnect(const aData:string);
begin
  fNetworking.Disconnect;
  fSoundLib.Play(sfxn_Error);

  fOnPageChange(Self, gpMultiplayer, aData);
end;


procedure TKMGUIMenuLobby.StartClick(Sender: TObject);
begin
  if fNetworking.IsHost then
    fNetworking.StartClick
  else
  begin
    if fNetworking.ReadyToStart then
      Button_LobbyStart.Caption := fTextLibrary[TX_LOBBY_NOT_READY]
    else
      Button_LobbyStart.Caption := fTextLibrary[TX_LOBBY_READY];
  end;
end;


procedure TKMGUIMenuLobby.SettingsClick(Sender: TObject);
begin
  if Sender = Button_LobbyChangeSettings then
  begin
    Edit_LobbyDescription.Text := fNetworking.Description;
    Edit_LobbyPassword.Text := fNetworking.Password;
    Panel_LobbySettings.Show;
  end;

  if Sender = Button_LobbySettingsCancel then
  begin
    Panel_LobbySettings.Hide;
  end;

  if Sender = Button_LobbySettingsSave then
  begin
    Panel_LobbySettings.Hide;
    fNetworking.Description := Edit_LobbyDescription.Text;
    fNetworking.SetPassword(Edit_LobbyPassword.Text);
  end;
end;




//Should update anything we want to be updated, obviously
procedure TKMGUIMenuLobby.UpdateState(aTickCount: Cardinal);
begin
  if fMapsMP <> nil then fMapsMP.UpdateState;
  if fSavesMP <> nil then fSavesMP.UpdateState;
end;


end.