object fThreads: TfThreads
  Left = 0
  Top = 0
  Caption = 'Threads'
  ClientHeight = 320
  ClientWidth = 480
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object labThreads: TLabel
    Left = 0
    Top = 0
    Width = 480
    Height = 13
    Align = alTop
    Alignment = taRightJustify
    Caption = '0'
    ExplicitLeft = 474
    ExplicitWidth = 6
  end
  object Label2: TLabel
    Left = 0
    Top = 47
    Width = 480
    Height = 13
    Align = alTop
    Caption = 'Intervalo m'#225'ximo(em milissegundos)'
    ExplicitWidth = 173
  end
  object Label3: TLabel
    Left = 0
    Top = 13
    Width = 480
    Height = 13
    Align = alTop
    Caption = 'N'#250'mero Threads'
    ExplicitWidth = 79
  end
  object edtIntervalo: TEdit
    Left = 0
    Top = 60
    Width = 480
    Height = 21
    Align = alTop
    TabOrder = 4
    Text = '100'
  end
  object edtQuantidade: TEdit
    Left = 0
    Top = 26
    Width = 480
    Height = 21
    Align = alTop
    TabOrder = 0
    Text = '1'
  end
  object btIniciar: TButton
    AlignWithMargins = True
    Left = 3
    Top = 84
    Width = 474
    Height = 25
    Align = alTop
    Caption = 'Iniciar'
    TabOrder = 1
    OnClick = btIniciarClick
  end
  object pgrThreads: TProgressBar
    AlignWithMargins = True
    Left = 3
    Top = 115
    Width = 474
    Height = 25
    Align = alTop
    TabOrder = 2
  end
  object mmoLog: TMemo
    Left = 0
    Top = 143
    Width = 480
    Height = 177
    Align = alClient
    ScrollBars = ssVertical
    TabOrder = 3
  end
end
