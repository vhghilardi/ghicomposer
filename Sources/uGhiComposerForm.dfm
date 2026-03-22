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
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 760
    Height = 248
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
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
      Width = 736
      Height = 72
      ScrollBars = ssVertical
      TabOrder = 0
      WantReturns = True
      WordWrap = True
    end
    object chkSelOnly: TCheckBox
      Left = 12
      Top = 108
      Width = 320
      Height = 17
      Caption = 'Apenas texto selecionado (senao, ficheiro inteiro)'
      TabOrder = 1
    end
    object lblFile: TLabel
      Left = 12
      Top = 132
      Width = 736
      Height = 17
      AutoSize = False
      Caption = 'Ficheiro:'
    end
    object grpConn: TGroupBox
      Left = 12
      Top = 156
      Width = 736
      Height = 84
      Caption = 'Ligacao (API estilo OpenAI)'
      TabOrder = 2
      object lblUrl: TLabel
        Left = 12
        Top = 24
        Width = 52
        Height = 17
        Caption = 'Endpoint'
      end
      object edtUrl: TEdit
        Left = 100
        Top = 21
        Width = 616
        Height = 25
        TabOrder = 0
      end
      object lblModel: TLabel
        Left = 12
        Top = 52
        Width = 40
        Height = 17
        Caption = 'Modelo'
      end
      object edtModel: TEdit
        Left = 100
        Top = 49
        Width = 200
        Height = 25
        TabOrder = 1
      end
      object lblKey: TLabel
        Left = 320
        Top = 52
        Width = 48
        Height = 17
        Caption = 'API Key'
      end
      object edtApiKey: TEdit
        Left = 380
        Top = 49
        Width = 336
        Height = 25
        PasswordChar = '*'
        TabOrder = 2
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
    TabOrder = 1
    object btnRun: TButton
      Left = 12
      Top = 6
      Width = 120
      Height = 28
      Caption = 'Executar'
      Default = True
      TabOrder = 0
      OnClick = btnRunClick
    end
    object btnClose: TButton
      Left = 140
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Fechar'
      TabOrder = 1
      OnClick = btnCloseClick
    end
  end
  object lblStatus: TLabel
    Left = 0
    Top = 248
    Width = 760
    Height = 17
    Align = alTop
    Caption = 'Resultado / estado'
  end
  object memStatus: TMemo
    Left = 0
    Top = 265
    Width = 760
    Height = 255
    Align = alClient
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 2
    WordWrap = False
  end
end
