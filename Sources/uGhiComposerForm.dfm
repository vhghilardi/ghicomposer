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
        Height = 120
        Anchors = [akLeft, akTop, akRight]
        ScrollBars = ssVertical
        TabOrder = 0
        WantReturns = True
        WordWrap = True
      end
      object chkSelOnly: TCheckBox
        Left = 12
        Top = 156
        Width = 520
        Height = 17
        Caption = 'Apenas texto selecionado (senão, arquivo inteiro)'
        TabOrder = 1
      end
      object lblFile: TLabel
        Left = 12
        Top = 180
        Width = 720
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        Caption = 'Arquivo:'
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
        Caption = 'Endpoint e credenciais (API no estilo OpenAI)'
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
        object edtModel: TEdit
          Left = 12
          Top = 100
          Width = 400
          Height = 25
          TabOrder = 1
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
          TabOrder = 2
        end
      end
    end
    object tabAdvanced: TTabSheet
      Caption = 'Opções avançadas'
      object grpAdvanced: TGroupBox
        Left = 0
        Top = 0
        Width = 752
        Height = 228
        Align = alClient
        Caption = 'Requisição HTTP / corpo JSON opcional'
        TabOrder = 0
        object lblSystemPrompt: TLabel
          Left = 12
          Top = 20
          Width = 400
          Height = 17
          Caption = 'Prompt de sistema (vazio = padrão do GhiComposer)'
        end
        object memSystemPrompt: TMemo
          Left = 12
          Top = 40
          Width = 712
          Height = 64
          Anchors = [akLeft, akTop, akRight]
          ScrollBars = ssVertical
          TabOrder = 0
          WantReturns = True
          WordWrap = True
        end
        object lblConnTimeout: TLabel
          Left = 12
          Top = 112
          Width = 140
          Height = 17
          Caption = 'Timeout de conexão (ms)'
        end
        object edtConnTimeout: TEdit
          Left = 160
          Top = 109
          Width = 80
          Height = 25
          TabOrder = 1
        end
        object lblRespTimeout: TLabel
          Left = 280
          Top = 112
          Width = 130
          Height = 17
          Caption = 'Timeout resposta (ms)'
        end
        object edtRespTimeout: TEdit
          Left = 420
          Top = 109
          Width = 80
          Height = 25
          TabOrder = 2
        end
        object chkStripFences: TCheckBox
          Left = 12
          Top = 144
          Width = 520
          Height = 17
          Caption = 'Remover cercas markdown da resposta do modelo'
          Checked = True
          TabOrder = 3
        end
        object lblTemperature: TLabel
          Left = 12
          Top = 172
          Width = 200
          Height = 17
          Caption = 'Temperatura (vazio = omitir no JSON)'
        end
        object edtTemperature: TEdit
          Left = 220
          Top = 169
          Width = 64
          Height = 25
          TabOrder = 4
        end
        object lblMaxTokens: TLabel
          Left = 320
          Top = 172
          Width = 160
          Height = 17
          Caption = 'Max tokens (0 ou vazio = omitir)'
        end
        object edtMaxTokens: TEdit
          Left = 490
          Top = 169
          Width = 80
          Height = 25
          TabOrder = 5
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
    Top = 260
    Width = 760
    Height = 17
    Align = alTop
    Caption = 'Resultado / status'
  end
  object memStatus: TMemo
    Left = 0
    Top = 277
    Width = 760
    Height = 243
    Align = alClient
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
end
