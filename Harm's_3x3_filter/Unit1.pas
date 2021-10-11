unit Unit1;

{An example of a 3 x 3 convolution using 24-bit bitmaps and scanline.

 Harm

 1/1/2000

 http://www.users.uswest.net/~sharman1/

 sharman1@uswest.net

 NOTE!  Because I'm lazy, I didn't add all the nice try..finally stuff.
        Since this is an example, I think logic is more important than
        error protection.  If you use this in a real application, you
        should add this, i.e.

        try
          try
            OrigBMP := TBitmap.Create;
          finally
            OrigBMP.Free;
          end;
        except
          raise ESomeErrorWarning.Create('Kaboom!);
        end;

}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Grids, ExtDlgs, ExtCtrls, jpeg, Buttons;

{Some edge detection filters:

laplace      hipass     find edges   sharpen    edge enhance  color emboss
                        (top down)                            (well, kinda)
-1 -1 -1    -1 -1 -1     1  1  1     -1 -1 -1     0 -1  0       1  0  1
-1  8 -1    -1  9 -1     1 -2  1     -1 16 -1    -1  5 -1       0  0  0
-1 -1 -1    -1 -1 -1    -1 -1 -1     -1 -1 -1     0 -1  0       1  0 -2

    1           1           1            8           1             1

 Soften        blur    Soften (less)

 2  2  2     3  3  3     0  1  0
 2  0  2     3  8  3     1  2  1
 2  2  2     3  3  3     0  1  0

   16          32           6
}

type    // For scanline simplification
  TRGBArray = ARRAY[0..32767] OF TRGBTriple;
  pRGBArray = ^TRGBArray;

type
  TForm1 = class(TForm)
    Button1: TButton;  // Open Image
    OpenPictureDialog1: TOpenPictureDialog;
    StringGrid1: TStringGrid;  //  Holds filter values
    Edit1: TEdit;  // Divisor value
    Label1: TLabel;
    Button2: TButton;  // Apply Filter to Image
    Button3: TButton;  // Reset Image to Original
    ComboBox1: TComboBox;  // List of preset filters
    CheckBox1: TCheckBox;  // Reset Image before applying each filter?
    SpeedButton1: TSpeedButton;
    Button4: TButton;
    rgEdge: TRadioGroup;
    ScrollBox1: TScrollBox;
    Image1: TImage;
    Label2: TLabel;   // Edge processing options
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    OriginalBMP : TBitmap; // Store Image for 'reset'
    procedure CopyMe(tobmp: TBitmap; frbmp : TGraphic); // Simple copy
    procedure SetGrid(ray : array of integer); // Set grid values
{I have three flavors of the 3 x 3 filter, depending on the RadioGroup
 selection for edge processing.  More detail in the procedures themselves}
    procedure ConvolveM(ray : array of integer; z : word; aBmp : TBitmap);
    procedure ConvolveE(ray : array of integer; z : word; aBmp : TBitmap);
    procedure ConvolveI(ray : array of integer; z : word; aBmp : TBitmap);
  end;

var
  Form1: TForm1;

implementation

uses Unit2;

{$R *.DFM}

{A simple procedure to copy any TGraphic to a 24-bit TBitmap}
procedure TForm1.CopyMe(tobmp: TBitmap; frbmp : TGraphic);
begin
  tobmp.Width := frbmp.Width;
  tobmp.Height := frbmp.Height;
  tobmp.PixelFormat := pf24bit;
  tobmp.Canvas.Draw(0,0,frbmp);
end;

{This just forces a value to be 0 - 255 for rgb purposes.  I used asm in an
 attempt at speed, but I don't think it helps much.}
function Set255(Clr : integer) : integer;
asm
  MOV  EAX,Clr  // store value in EAX register (32-bit register)
  CMP  EAX,254  // compare it to 254
  JG   @SETHI   // if greater than 254 then go set to 255 (max value)
  CMP  EAX,1    // if less than 255, compare to 1
  JL   @SETLO   // if less than 1 go set to 0 (min value)
  RET           // otherwise it doesn't change, just exit
@SETHI:         // Set value to 255
  MOV  EAX,255  // Move 255 into the EAX register
  RET           // Exit (result value is the EAX register value)
@SETLO:         // Set value to 0
  MOV  EAX,0    // Move 0 into EAX register
end;            // Result is in EAX

{The mirror version of a 3 x 3 convolution.

 The 3 x 3 convolve uses the eight surrounding pixels as part of the
 calculation.  But, for the pixels on the edges, there is nothing to use
 for the top row values.  In other words, the leftmost pixel in the 3rd
 row, or scanline, has no pixels on its left to use in the calculations.
 I compensate for this by increasing the size of the bitmap by one pixel
 on top, left, bottom, and right.  The mirror version is used in an
 application that creates seamless tiles, so I copy the opposite sides to
 maintain the seamless integrity.  }
procedure TForm1.ConvolveM(ray : array of integer; z : word; aBmp : TBitmap);
var
  O, T, C, B : pRGBArray;  // Scanlines
  x, y : integer;
  tBufr : TBitmap; // temp bitmap for 'enlarged' image
begin
  tBufr := TBitmap.Create;
  tBufr.Width:=aBmp.Width+2;  // Add a box around the outside...
  tBufr.Height:=aBmp.Height+2;
  tBufr.PixelFormat := pf24bit;
  O := tBufr.ScanLine[0];   // Copy top corner pixels
  T := aBmp.ScanLine[0];
  O[0] := T[0];  // Left
  O[tBufr.Width - 1] := T[aBmp.Width - 1];  // Right
  // Copy bottom line to our top - trying to remain seamless...
  tBufr.Canvas.CopyRect(RECT(1,0,tBufr.Width - 1,1),aBmp.Canvas,
          RECT(0,aBmp.Height - 1,aBmp.Width,aBmp.Height-2));

  O := tBufr.ScanLine[tBufr.Height - 1]; // Copy bottom corner pixels
  T := aBmp.ScanLine[aBmp.Height - 1];
  O[0] := T[0];
  O[tBufr.Width - 1] := T[aBmp.Width - 1];
  // Copy top line to our bottom
  tBufr.Canvas.CopyRect(RECT(1,tBufr.Height-1,tBufr.Width - 1,tBufr.Height),
         aBmp.Canvas,RECT(0,0,aBmp.Width,1));
  // Copy left to our right
  tBufr.Canvas.CopyRect(RECT(tBufr.Width-1,1,tBufr.Width,tBufr.Height-1),
         aBmp.Canvas,RECT(0,0,1,aBmp.Height));
  // Copy right to our left
  tBufr.Canvas.CopyRect(RECT(0,1,1,tBufr.Height-1),
         aBmp.Canvas,RECT(aBmp.Width - 1,0,aBmp.Width,aBmp.Height));
  // Now copy main rectangle
  tBufr.Canvas.CopyRect(RECT(1,1,tBufr.Width - 1,tBufr.Height - 1),
    aBmp.Canvas,RECT(0,0,aBmp.Width,aBmp.Height));
  // bmp now enlarged and copied, apply convolve
  for x := 0 to aBmp.Height - 1 do begin  // Walk scanlines
    O := aBmp.ScanLine[x];      // New Target (Original)
    T := tBufr.ScanLine[x];     //old x-1  (Top)
    C := tBufr.ScanLine[x+1];   //old x    (Center)
    B := tBufr.ScanLine[x+2];   //old x+1  (Bottom)
  // Now do the main piece
    for y := 1 to (tBufr.Width - 2) do begin  // Walk pixels
      O[y-1].rgbtRed := Set255(
          ((T[y-1].rgbtRed*ray[0]) +
          (T[y].rgbtRed*ray[1]) + (T[y+1].rgbtRed*ray[2]) +
          (C[y-1].rgbtRed*ray[3]) +
          (C[y].rgbtRed*ray[4]) + (C[y+1].rgbtRed*ray[5])+
          (B[y-1].rgbtRed*ray[6]) +
          (B[y].rgbtRed*ray[7]) + (B[y+1].rgbtRed*ray[8])) div z
          );
      O[y-1].rgbtBlue := Set255(
          ((T[y-1].rgbtBlue*ray[0]) +
          (T[y].rgbtBlue*ray[1]) + (T[y+1].rgbtBlue*ray[2]) +
          (C[y-1].rgbtBlue*ray[3]) +
          (C[y].rgbtBlue*ray[4]) + (C[y+1].rgbtBlue*ray[5])+
          (B[y-1].rgbtBlue*ray[6]) +
          (B[y].rgbtBlue*ray[7]) + (B[y+1].rgbtBlue*ray[8])) div z
          );
      O[y-1].rgbtGreen := Set255(
          ((T[y-1].rgbtGreen*ray[0]) +
          (T[y].rgbtGreen*ray[1]) + (T[y+1].rgbtGreen*ray[2]) +
          (C[y-1].rgbtGreen*ray[3]) +
          (C[y].rgbtGreen*ray[4]) + (C[y+1].rgbtGreen*ray[5])+
          (B[y-1].rgbtGreen*ray[6]) +
          (B[y].rgbtGreen*ray[7]) + (B[y+1].rgbtGreen*ray[8])) div z
          );
    end;
  end;
  tBufr.Free;
end;

{The Expand version of a 3 x 3 convolution.

 This approach is similar to the mirror version, except that it copies
 or duplicates the pixels from the edges to the same edge.  This is
 probably the best version if you're interested in quality, but don't need
 a tiled (seamless) image. }
procedure TForm1.ConvolveE(ray : array of integer; z : word; aBmp : TBitmap);
var
  O, T, C, B : pRGBArray;  // Scanlines
  x, y : integer;
  tBufr : TBitmap; // temp bitmap for 'enlarged' image
begin
  tBufr := TBitmap.Create;
  tBufr.Width:=aBmp.Width+2;  // Add a box around the outside...
  tBufr.Height:=aBmp.Height+2;
  tBufr.PixelFormat := pf24bit;
  O := tBufr.ScanLine[0];   // Copy top corner pixels
  T := aBmp.ScanLine[0];
  O[0] := T[0];  // Left
  O[tBufr.Width - 1] := T[aBmp.Width - 1];  // Right
  // Copy top lines
  tBufr.Canvas.CopyRect(RECT(1,0,tBufr.Width - 1,1),aBmp.Canvas,
          RECT(0,0,aBmp.Width,1));

  O := tBufr.ScanLine[tBufr.Height - 1]; // Copy bottom corner pixels
  T := aBmp.ScanLine[aBmp.Height - 1];
  O[0] := T[0];
  O[tBufr.Width - 1] := T[aBmp.Width - 1];
  // Copy bottoms
  tBufr.Canvas.CopyRect(RECT(1,tBufr.Height-1,tBufr.Width - 1,tBufr.Height),
         aBmp.Canvas,RECT(0,aBmp.Height-1,aBmp.Width,aBmp.Height));
  // Copy rights
  tBufr.Canvas.CopyRect(RECT(tBufr.Width-1,1,tBufr.Width,tBufr.Height-1),
         aBmp.Canvas,RECT(aBmp.Width-1,0,aBmp.Width,aBmp.Height));
  // Copy lefts
  tBufr.Canvas.CopyRect(RECT(0,1,1,tBufr.Height-1),
         aBmp.Canvas,RECT(0,0,1,aBmp.Height));
  // Now copy main rectangle
  tBufr.Canvas.CopyRect(RECT(1,1,tBufr.Width - 1,tBufr.Height - 1),
    aBmp.Canvas,RECT(0,0,aBmp.Width,aBmp.Height));
  // bmp now enlarged and copied, apply convolve
  for x := 0 to aBmp.Height - 1 do begin  // Walk scanlines
    O := aBmp.ScanLine[x];      // New Target (Original)
    T := tBufr.ScanLine[x];     //old x-1  (Top)
    C := tBufr.ScanLine[x+1];   //old x    (Center)
    B := tBufr.ScanLine[x+2];   //old x+1  (Bottom)
  // Now do the main piece
    for y := 1 to (tBufr.Width - 2) do begin  // Walk pixels
      O[y-1].rgbtRed := Set255(
          ((T[y-1].rgbtRed*ray[0]) +
          (T[y].rgbtRed*ray[1]) + (T[y+1].rgbtRed*ray[2]) +
          (C[y-1].rgbtRed*ray[3]) +
          (C[y].rgbtRed*ray[4]) + (C[y+1].rgbtRed*ray[5])+
          (B[y-1].rgbtRed*ray[6]) +
          (B[y].rgbtRed*ray[7]) + (B[y+1].rgbtRed*ray[8])) div z
          );
      O[y-1].rgbtBlue := Set255(
          ((T[y-1].rgbtBlue*ray[0]) +
          (T[y].rgbtBlue*ray[1]) + (T[y+1].rgbtBlue*ray[2]) +
          (C[y-1].rgbtBlue*ray[3]) +
          (C[y].rgbtBlue*ray[4]) + (C[y+1].rgbtBlue*ray[5])+
          (B[y-1].rgbtBlue*ray[6]) +
          (B[y].rgbtBlue*ray[7]) + (B[y+1].rgbtBlue*ray[8])) div z
          );
      O[y-1].rgbtGreen := Set255(
          ((T[y-1].rgbtGreen*ray[0]) +
          (T[y].rgbtGreen*ray[1]) + (T[y+1].rgbtGreen*ray[2]) +
          (C[y-1].rgbtGreen*ray[3]) +
          (C[y].rgbtGreen*ray[4]) + (C[y+1].rgbtGreen*ray[5])+
          (B[y-1].rgbtGreen*ray[6]) +
          (B[y].rgbtGreen*ray[7]) + (B[y+1].rgbtGreen*ray[8])) div z
          );
    end;
  end;
  tBufr.Free;
end;

{The Ignore (basic) version of a 3 x 3 convolution.

 The 3 x 3 convolve uses the eight surrounding pixels as part of the
 calculation.  But, for the pixels on the edges, there is nothing to use
 for the top row values.  In other words, the leftmost pixel in the 3rd
 row, or scanline, has no pixels on its left to use in the calculations.
 This version just ignores the outermost edge of the image, and doesn't
 alter those pixels at all.  Repeated applications of filters will
 eventually cause a pronounced 'border' effect, as those pixels never
 change but all others do. However, this version is simpler, and the
 logic is easier to follow.  It's the fastest of the three in this
 application, and works great if the 'borders' are not an issue. }
procedure TForm1.ConvolveI(ray : array of integer; z : word; aBmp : TBitmap);
var
  O, T, C, B : pRGBArray;  // Scanlines
  x, y : integer;
  tBufr : TBitmap; // temp bitmap
begin
  tBufr := TBitmap.Create;
  CopyMe(tBufr,aBmp);
  for x := 1 to aBmp.Height - 2 do begin  // Walk scanlines
    O := aBmp.ScanLine[x];      // New Target (Original)
    T := tBufr.ScanLine[x-1];     //old x-1  (Top)
    C := tBufr.ScanLine[x];   //old x    (Center)
    B := tBufr.ScanLine[x+1];   //old x+1  (Bottom)
  // Now do the main piece
    for y := 1 to (tBufr.Width - 2) do begin  // Walk pixels
      O[y].rgbtRed := Set255(
          ((T[y-1].rgbtRed*ray[0]) +
          (T[y].rgbtRed*ray[1]) + (T[y+1].rgbtRed*ray[2]) +
          (C[y-1].rgbtRed*ray[3]) +
          (C[y].rgbtRed*ray[4]) + (C[y+1].rgbtRed*ray[5])+
          (B[y-1].rgbtRed*ray[6]) +
          (B[y].rgbtRed*ray[7]) + (B[y+1].rgbtRed*ray[8])) div z
          );
      O[y].rgbtBlue := Set255(
          ((T[y-1].rgbtBlue*ray[0]) +
          (T[y].rgbtBlue*ray[1]) + (T[y+1].rgbtBlue*ray[2]) +
          (C[y-1].rgbtBlue*ray[3]) +
          (C[y].rgbtBlue*ray[4]) + (C[y+1].rgbtBlue*ray[5])+
          (B[y-1].rgbtBlue*ray[6]) +
          (B[y].rgbtBlue*ray[7]) + (B[y+1].rgbtBlue*ray[8])) div z
          );
      O[y].rgbtGreen := Set255(
          ((T[y-1].rgbtGreen*ray[0]) +
          (T[y].rgbtGreen*ray[1]) + (T[y+1].rgbtGreen*ray[2]) +
          (C[y-1].rgbtGreen*ray[3]) +
          (C[y].rgbtGreen*ray[4]) + (C[y+1].rgbtGreen*ray[5])+
          (B[y-1].rgbtGreen*ray[6]) +
          (B[y].rgbtGreen*ray[7]) + (B[y+1].rgbtGreen*ray[8])) div z
          );
    end;
  end;
  tBufr.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  x,y : integer;
begin
  OriginalBMP := TBitmap.Create; // Create holding bitmap for 'reset'
  for y := 0 to 2 do      // Set stringgrid to a laplace filter
    for x := 0 to 2 do
      StringGrid1.Cells[y,x] := '-1';
  StringGrid1.Cells[1,1] := '8';
  OpenPictureDialog1.InitialDir:=ExtractFilePath(Application.ExeName);
end;

{Open an image, and store it in an internal bitmap}
procedure TForm1.Button1Click(Sender: TObject);
begin
  if OpenPictureDialog1.Execute
  then
   begin
    Image1.Picture.LoadFromFile(OpenPictureDialog1.FileName);
    CopyMe(OriginalBMP,Image1.Picture.Graphic);
    Button2.Enabled := TRUE;
    Button3.Enabled := TRUE;
    ComboBox1.Enabled := TRUE;
  end;
end;

{This applies the filter settings to the image}
procedure TForm1.Button2Click(Sender: TObject);
var
  ray : array [0..8] of integer;  // Filter settings array
  z : word;                       // Divisor
  OrigBMP : TBitmap;              // Bitmap for temporary use
begin
  Screen.Cursor := crHourGlass;  // Let user know we're busy...
  if CheckBox1.Checked then  // Reset Image to original ?
    Image1.Picture.Assign(OriginalBMP);
  OrigBMP := TBitmap.Create;  // Copy image to 24-bit bitmap
  CopyMe(OrigBMP,Image1.Picture.Graphic);
  ray[0] := StrToInt(StringGrid1.Cells[0,0]);  // Set filter values
  ray[1] := StrToInt(StringGrid1.Cells[1,0]);  //  from string grid.
  ray[2] := StrToInt(StringGrid1.Cells[2,0]);
  ray[3] := StrToInt(StringGrid1.Cells[0,1]);
  ray[4] := StrToInt(StringGrid1.Cells[1,1]);
  ray[5] := StrToInt(StringGrid1.Cells[2,1]);
  ray[6] := StrToInt(StringGrid1.Cells[0,2]);
  ray[7] := StrToInt(StringGrid1.Cells[1,2]);
  ray[8] := StrToInt(StringGrid1.Cells[2,2]);
  z := StrToInt(Edit1.Text);  //   Set divisor value from edit1
  if z = 0 then z := 1;       //   Prevent divide by zero
  case rgEdge.ItemIndex of
    0 : ConvolveM(ray,z,OrigBMP);
    1 : ConvolveE(ray,z,OrigBMP);
    2 : ConvolveI(ray,z,OrigBMP);
  end;
  Image1.Picture.Assign(OrigBMP);  //  Assign filtered image to Image1
  OrigBMP.Free;                    // Done with temp bitmap
  Image1.Refresh;
  Screen.Cursor := crDefault;      // Let user know we're done
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  OriginalBMP.Free;  // Free the bitmap created at startup
end;

{This 'resets' the image, by assigning the bmp to Image1}
procedure TForm1.Button3Click(Sender: TObject);
begin
 Image1.Picture.Assign(OriginalBMP);
 Image1.Refresh;
end;

{This populates the stringgrid with array values, for visual confirmation}
procedure TForm1.SetGrid(ray : array of integer);
begin
  StringGrid1.Cells[0,0] := IntToStr(ray[0]);
  StringGrid1.Cells[1,0] := IntToStr(ray[1]);
  StringGrid1.Cells[2,0] := IntToStr(ray[2]);
  StringGrid1.Cells[0,1] := IntToStr(ray[3]);
  StringGrid1.Cells[1,1] := IntToStr(ray[4]);
  StringGrid1.Cells[2,1] := IntToStr(ray[5]);
  StringGrid1.Cells[0,2] := IntToStr(ray[6]);
  StringGrid1.Cells[1,2] := IntToStr(ray[7]);
  StringGrid1.Cells[2,2] := IntToStr(ray[8]);
end;

{When a combobox selection is made, fill the array with the filter
 values, and set the divisor value.  Then update the stringgrid,
 and finally just do a button click to apply the filter.}
procedure TForm1.ComboBox1Change(Sender: TObject);
var
  z : integer;
  ray : array [0..8] of integer;
begin
  z := 1;  // just to avoid compiler warnings!
  case ComboBox1.ItemIndex of
    0 : begin // Laplace
      ray[0] := -1; ray[1] := -1; ray[2] := -1;
      ray[3] := -1; ray[4] :=  8; ray[5] := -1;
      ray[6] := -1; ray[7] := -1; ray[8] := -1;
      z := 1;
      end;
    1 : begin  // Hipass
      ray[0] := -1; ray[1] := -1; ray[2] := -1;
      ray[3] := -1; ray[4] :=  9; ray[5] := -1;
      ray[6] := -1; ray[7] := -1; ray[8] := -1;
      z := 1;
      end;
    2 : begin  // Find Edges (top down)
      ray[0] :=  1; ray[1] :=  1; ray[2] :=  1;
      ray[3] :=  1; ray[4] := -2; ray[5] :=  1;
      ray[6] := -1; ray[7] := -1; ray[8] := -1;
      z := 1;
      end;
    3 : begin  // Sharpen
      ray[0] := -1; ray[1] := -1; ray[2] := -1;
      ray[3] := -1; ray[4] := 16; ray[5] := -1;
      ray[6] := -1; ray[7] := -1; ray[8] := -1;
      z := 8;
      end;
    4 : begin  // Edge Enhance
      ray[0] :=  0; ray[1] := -1; ray[2] :=  0;
      ray[3] := -1; ray[4] :=  5; ray[5] := -1;
      ray[6] :=  0; ray[7] := -1; ray[8] :=  0;
      z := 1;
      end;
    5 : begin  // Color Emboss (Sorta)
      ray[0] :=  1; ray[1] :=  0; ray[2] :=  1;
      ray[3] :=  0; ray[4] :=  0; ray[5] :=  0;
      ray[6] :=  1; ray[7] :=  0; ray[8] := -2;
      z := 1;
      end;
    6 : begin  // Soften
      ray[0] :=  2; ray[1] :=  2; ray[2] :=  2;
      ray[3] :=  2; ray[4] :=  0; ray[5] :=  2;
      ray[6] :=  2; ray[7] :=  2; ray[8] :=  2;
      z := 16;
      end;
    7 : begin  // Blur
      ray[0] :=  3; ray[1] :=  3; ray[2] :=  3;
      ray[3] :=  3; ray[4] :=  8; ray[5] :=  3;
      ray[6] :=  3; ray[7] :=  3; ray[8] :=  3;
      z := 32;
      end;
  end;
  SetGrid(ray);
  Edit1.Text := IntToStr(z);
  Button2.Click; // This applies the filter.  A little extra overhead.
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  AboutBox.ShowModal;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Application.Terminate;
end;

end.
