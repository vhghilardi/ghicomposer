object frmGhiComposer: TfrmGhiComposer
  Left = 0
  Top = 0
  Caption = 'GhiComposer'
  ClientHeight = 560
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 17
  object pgcMain: TPageControl
    Left = 0
    Top = 0
    Width = 760
    Height = 260
    Align = alTop
    TabOrder = 0
    object tabChat: TTabSheet
      Caption = 'Chat'
      object lblPrompt: TLabel
        Left = 12
        Top = 8
        Width = 38
        Height = 17
        Caption = 'Prompt'
      end
      object memPrompt: TMemo
        Left = 12
        Top = 28
        Width = 720
        Height = 140
        Anchors = [akLeft, akTop, akRight]
        ScrollBars = ssVertical
        TabOrder = 0
        WantReturns = True
        WordWrap = True
      end
      object btnRun: TButton
        Left = 12
        Top = 176
        Width = 120
        Height = 28
        Caption = 'Executar'
        Default = True
        TabOrder = 1
        OnClick = btnRunClick
      end
    end
    object tabApi: TTabSheet
      Caption = 'API'
      object grpConn: TGroupBox
        Left = 0
        Top = 0
        Width = 752
        Height = 228
        Align = alClient
        Caption = ' '
        TabOrder = 0
        object lblUrl: TLabel
          Left = 12
          Top = 24
          Width = 52
          Height = 17
          Caption = 'Endpoint'
        end
        object edtUrl: TEdit
          Left = 12
          Top = 44
          Width = 712
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
        end
        object lblModel: TLabel
          Left = 12
          Top = 80
          Width = 40
          Height = 17
          Caption = 'Modelo'
        end
        object cboModel: TComboBox
          Left = 12
          Top = 100
          Width = 520
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          Style = csDropDown
          TabOrder = 1
        end
        object btnRefreshModels: TButton
          Left = 544
          Top = 98
          Width = 180
          Height = 28
          Anchors = [akTop, akRight]
          Caption = 'Atualizar modelos'
          TabOrder = 2
          OnClick = btnRefreshModelsClick
        end
        object lblKey: TLabel
          Left = 12
          Top = 136
          Width = 48
          Height = 17
          Caption = 'API Key'
        end
        object edtApiKey: TEdit
          Left = 12
          Top = 156
          Width = 712
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          PasswordChar = '*'
          TabOrder = 3
        end
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 520
    Width = 760
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnApply: TButton
      Left = 12
      Top = 6
      Width = 120
      Height = 28
      Caption = 'Aplicar'
      Enabled = False
      TabOrder = 0
      OnClick = btnApplyClick
    end
  end
  object lblStatus: TLabel
    Left = 0
    Top = 260
    Width = 760
    Height = 17
    Align = alTop
    Caption = ' '
  end
  object reStatus: TRichEdit
    Left = 0
    Top = 277
    Width = 760
    Height = 243
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    HideSelection = False
    PlainText = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
end
