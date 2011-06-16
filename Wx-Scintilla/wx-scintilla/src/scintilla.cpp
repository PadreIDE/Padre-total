////////////////////////////////////////////////////////////////////////////
// Name:        stc.cpp
// Purpose:     A wxWidgets implementation of Scintilla.  This class is the
//              one meant to be used directly by wx applications.  It does not
//              derive directly from the Scintilla classes, but instead
//              delegates most things to the real Scintilla class.
//              This allows the use of Scintilla without polluting the
//              namespace with all the classes and identifiers from Scintilla.
//
// Author:      Robin Dunn
//
// Created:     13-Jan-2000
// RCS-ID:      $Id: stc.cpp 54251 2008-06-15 22:20:32Z RD $
// Copyright:   (c) 2000 by Total Control Software
// Licence:     wxWindows license
/////////////////////////////////////////////////////////////////////////////

#include <ctype.h>

#include "wx/wx.h"
#include "wx/tokenzr.h"
#include "wx/mstream.h"
#include "wx/image.h"
#include "wx/file.h"

#include "WxScintilla.h"
#include "ScintillaWX.h"

//----------------------------------------------------------------------

const wxChar* wxSTCNameStr = wxT("stcwindow");

#ifdef MAKELONG
#undef MAKELONG
#endif

#define MAKELONG(a, b) ((a) | ((b) << 16))


static long wxColourAsLong(const wxColour& co) {
    return (((long)co.Blue()  << 16) |
            ((long)co.Green() <<  8) |
            ((long)co.Red()));
}

static wxColour wxColourFromLong(long c) {
    wxColour clr;
    clr.Set((unsigned char)(c & 0xff),
            (unsigned char)((c >> 8) & 0xff),
            (unsigned char)((c >> 16) & 0xff));
    return clr;
}


static wxColour wxColourFromSpec(const wxString& spec) {
    // spec should be a colour name or "#RRGGBB"
    if (spec.GetChar(0) == wxT('#')) {

        long red, green, blue;
        red = green = blue = 0;
        spec.Mid(1,2).ToLong(&red,   16);
        spec.Mid(3,2).ToLong(&green, 16);
        spec.Mid(5,2).ToLong(&blue,  16);
        return wxColour((unsigned char)red,
                        (unsigned char)green,
                        (unsigned char)blue);
    }
    else
        return wxColour(spec);
}

//----------------------------------------------------------------------

DEFINE_EVENT_TYPE( wxEVT_STC_CHANGE )
DEFINE_EVENT_TYPE( wxEVT_STC_STYLENEEDED )
DEFINE_EVENT_TYPE( wxEVT_STC_CHARADDED )
DEFINE_EVENT_TYPE( wxEVT_STC_SAVEPOINTREACHED )
DEFINE_EVENT_TYPE( wxEVT_STC_SAVEPOINTLEFT )
DEFINE_EVENT_TYPE( wxEVT_STC_ROMODIFYATTEMPT )
DEFINE_EVENT_TYPE( wxEVT_STC_KEY )
DEFINE_EVENT_TYPE( wxEVT_STC_DOUBLECLICK )
DEFINE_EVENT_TYPE( wxEVT_STC_UPDATEUI )
DEFINE_EVENT_TYPE( wxEVT_STC_MODIFIED )
DEFINE_EVENT_TYPE( wxEVT_STC_MACRORECORD )
DEFINE_EVENT_TYPE( wxEVT_STC_MARGINCLICK )
DEFINE_EVENT_TYPE( wxEVT_STC_NEEDSHOWN )
DEFINE_EVENT_TYPE( wxEVT_STC_PAINTED )
DEFINE_EVENT_TYPE( wxEVT_STC_USERLISTSELECTION )
DEFINE_EVENT_TYPE( wxEVT_STC_URIDROPPED )
DEFINE_EVENT_TYPE( wxEVT_STC_DWELLSTART )
DEFINE_EVENT_TYPE( wxEVT_STC_DWELLEND )
DEFINE_EVENT_TYPE( wxEVT_STC_START_DRAG )
DEFINE_EVENT_TYPE( wxEVT_STC_DRAG_OVER )
DEFINE_EVENT_TYPE( wxEVT_STC_DO_DROP )
DEFINE_EVENT_TYPE( wxEVT_STC_ZOOM )
DEFINE_EVENT_TYPE( wxEVT_STC_HOTSPOT_CLICK )
DEFINE_EVENT_TYPE( wxEVT_STC_HOTSPOT_DCLICK )
DEFINE_EVENT_TYPE( wxEVT_STC_CALLTIP_CLICK )
DEFINE_EVENT_TYPE( wxEVT_STC_AUTOCOMP_SELECTION )



BEGIN_EVENT_TABLE(wxScintillaTextCtrl, wxControl)
    EVT_PAINT                   (wxScintillaTextCtrl::OnPaint)
    EVT_SCROLLWIN               (wxScintillaTextCtrl::OnScrollWin)
    EVT_SCROLL                  (wxScintillaTextCtrl::OnScroll)
    EVT_SIZE                    (wxScintillaTextCtrl::OnSize)
    EVT_LEFT_DOWN               (wxScintillaTextCtrl::OnMouseLeftDown)
    // Let Scintilla see the double click as a second click
    EVT_LEFT_DCLICK             (wxScintillaTextCtrl::OnMouseLeftDown)
    EVT_MOTION                  (wxScintillaTextCtrl::OnMouseMove)
    EVT_LEFT_UP                 (wxScintillaTextCtrl::OnMouseLeftUp)
#if defined(__WXGTK__) || defined(__WXMAC__)
    EVT_RIGHT_UP                (wxScintillaTextCtrl::OnMouseRightUp)
#else
    EVT_CONTEXT_MENU            (wxScintillaTextCtrl::OnContextMenu)
#endif
    EVT_MOUSEWHEEL              (wxScintillaTextCtrl::OnMouseWheel)
    EVT_MIDDLE_UP               (wxScintillaTextCtrl::OnMouseMiddleUp)
    EVT_CHAR                    (wxScintillaTextCtrl::OnChar)
    EVT_KEY_DOWN                (wxScintillaTextCtrl::OnKeyDown)
    EVT_KILL_FOCUS              (wxScintillaTextCtrl::OnLoseFocus)
    EVT_SET_FOCUS               (wxScintillaTextCtrl::OnGainFocus)
    EVT_SYS_COLOUR_CHANGED      (wxScintillaTextCtrl::OnSysColourChanged)
    EVT_ERASE_BACKGROUND        (wxScintillaTextCtrl::OnEraseBackground)
    EVT_MENU_RANGE              (10, 16, wxScintillaTextCtrl::OnMenu)
    EVT_LISTBOX_DCLICK          (wxID_ANY, wxScintillaTextCtrl::OnListBox)
END_EVENT_TABLE()


IMPLEMENT_CLASS(wxScintillaTextCtrl, wxControl)
IMPLEMENT_DYNAMIC_CLASS(wxScintillaTextEvent, wxCommandEvent)

#ifdef LINK_LEXERS
// forces the linking of the lexer modules
int Scintilla_LinkLexers();
#endif

//----------------------------------------------------------------------
// Constructor and Destructor

wxScintillaTextCtrl::wxScintillaTextCtrl(wxWindow *parent,
                                   wxWindowID id,
                                   const wxPoint& pos,
                                   const wxSize& size,
                                   long style,
                                   const wxString& name)
{
    m_swx = NULL;
    Create(parent, id, pos, size, style, name);
}


bool wxScintillaTextCtrl::Create(wxWindow *parent,
                              wxWindowID id,
                              const wxPoint& pos,
                              const wxSize& size,
                              long style,
                              const wxString& name)
{
#ifdef __WXMAC__
    style |= wxVSCROLL | wxHSCROLL;
#endif
    if (!wxControl::Create(parent, id, pos, size,
                           style | wxWANTS_CHARS | wxCLIP_CHILDREN,
                           wxDefaultValidator, name))
        return false;

#ifdef LINK_LEXERS
    Scintilla_LinkLexers();
#endif
    m_swx = new ScintillaWX(this);
    m_stopWatch.Start();
    m_lastKeyDownConsumed = false;
    m_vScrollBar = NULL;
    m_hScrollBar = NULL;
#if wxUSE_UNICODE
    // Put Scintilla into unicode (UTF-8) mode
    SetCodePage(wxSTC_CP_UTF8);
#endif

    SetInitialSize(size);

    // Reduces flicker on GTK+/X11
    SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    return true;
}


wxScintillaTextCtrl::~wxScintillaTextCtrl() {
    delete m_swx;
}


//----------------------------------------------------------------------

long wxScintillaTextCtrl::SendMsg(int msg, long wp, long lp) {

    return m_swx->WndProc(msg, wp, lp);
}

//----------------------------------------------------------------------

// Set the vertical scrollbar to use instead of the ont that's built-in.
void wxScintillaTextCtrl::SetVScrollBar(wxScrollBar* bar)  {
    m_vScrollBar = bar;
    if (bar != NULL) {
        // ensure that the built-in scrollbar is not visible
        SetScrollbar(wxVERTICAL, 0, 0, 0);
    }
}


// Set the horizontal scrollbar to use instead of the ont that's built-in.
void wxScintillaTextCtrl::SetHScrollBar(wxScrollBar* bar)  {
    m_hScrollBar = bar;
    if (bar != NULL) {
        // ensure that the built-in scrollbar is not visible
        SetScrollbar(wxHORIZONTAL, 0, 0, 0);
    }
}

//----------------------------------------------------------------------
// BEGIN generated section.  The following code is automatically generated
//       by gen_iface.py from the contents of Scintilla.iface.  Do not edit
//       this file.  Edit stc.cpp.in or gen_iface.py instead and regenerate.


// Add text to the document at current position.
void wxScintillaTextCtrl::AddText(const wxString& text) {
                    wxWX2MBbuf buf = (wxWX2MBbuf)wx2stc(text);
                    SendMsg(2001, strlen(buf), (wxIntPtr)(const char*)buf);
}

// Add array of cells to document.
void wxScintillaTextCtrl::AddStyledText(const wxMemoryBuffer& data) {
                          SendMsg(2002, data.GetDataLen(), (wxIntPtr)data.GetData());
}

// Insert string at a position.
void wxScintillaTextCtrl::InsertText(int pos, const wxString& text) {
    SendMsg(2003, pos, (wxIntPtr)(const char*)wx2stc(text));
}

// Delete all text in the document.
void wxScintillaTextCtrl::ClearAll() {
    SendMsg(2004, 0, 0);
}

// Set all style bytes to 0, remove all folding information.
void wxScintillaTextCtrl::ClearDocumentStyle() {
    SendMsg(2005, 0, 0);
}

// Returns the number of characters in the document.
int wxScintillaTextCtrl::GetLength() {
    return SendMsg(2006, 0, 0);
}

// Returns the character byte at the position.
int wxScintillaTextCtrl::GetCharAt(int pos) {
         return (unsigned char)SendMsg(2007, pos, 0);
}

// Returns the position of the caret.
int wxScintillaTextCtrl::GetCurrentPos() {
    return SendMsg(2008, 0, 0);
}

// Returns the position of the opposite end of the selection to the caret.
int wxScintillaTextCtrl::GetAnchor() {
    return SendMsg(2009, 0, 0);
}

// Returns the style byte at the position.
int wxScintillaTextCtrl::GetStyleAt(int pos) {
         return (unsigned char)SendMsg(2010, pos, 0);
}

// Redoes the next action on the undo history.
void wxScintillaTextCtrl::Redo() {
    SendMsg(2011, 0, 0);
}

// Choose between collecting actions into the undo
// history and discarding them.
void wxScintillaTextCtrl::SetUndoCollection(bool collectUndo) {
    SendMsg(2012, collectUndo, 0);
}

// Select all the text in the document.
void wxScintillaTextCtrl::SelectAll() {
    SendMsg(2013, 0, 0);
}

// Remember the current position in the undo history as the position
// at which the document was saved.
void wxScintillaTextCtrl::SetSavePoint() {
    SendMsg(2014, 0, 0);
}

// Retrieve a buffer of cells.
wxMemoryBuffer wxScintillaTextCtrl::GetStyledText(int startPos, int endPos) {
        wxMemoryBuffer buf;
        if (endPos < startPos) {
            int temp = startPos;
            startPos = endPos;
            endPos = temp;
        }
        int len = endPos - startPos;
        if (!len) return buf;
        TextRange tr;
        tr.lpstrText = (char*)buf.GetWriteBuf(len*2+1);
        tr.chrg.cpMin = startPos;
        tr.chrg.cpMax = endPos;
        len = SendMsg(2015, 0, (wxIntPtr)&tr);
        buf.UngetWriteBuf(len);
        return buf;
}

// Are there any redoable actions in the undo history?
bool wxScintillaTextCtrl::CanRedo() {
    return SendMsg(2016, 0, 0) != 0;
}

// Retrieve the line number at which a particular marker is located.
int wxScintillaTextCtrl::MarkerLineFromHandle(int handle) {
    return SendMsg(2017, handle, 0);
}

// Delete a marker.
void wxScintillaTextCtrl::MarkerDeleteHandle(int handle) {
    SendMsg(2018, handle, 0);
}

// Is undo history being collected?
bool wxScintillaTextCtrl::GetUndoCollection() {
    return SendMsg(2019, 0, 0) != 0;
}

// Are white space characters currently visible?
// Returns one of SCWS_* constants.
int wxScintillaTextCtrl::GetViewWhiteSpace() {
    return SendMsg(2020, 0, 0);
}

// Make white space characters invisible, always visible or visible outside indentation.
void wxScintillaTextCtrl::SetViewWhiteSpace(int viewWS) {
    SendMsg(2021, viewWS, 0);
}

// Find the position from a point within the window.
int wxScintillaTextCtrl::PositionFromPoint(wxPoint pt) {
        return SendMsg(2022, pt.x, pt.y);
}

// Find the position from a point within the window but return
// INVALID_POSITION if not close to text.
int wxScintillaTextCtrl::PositionFromPointClose(int x, int y) {
    return SendMsg(2023, x, y);
}

// Set caret to start of a line and ensure it is visible.
void wxScintillaTextCtrl::GotoLine(int line) {
    SendMsg(2024, line, 0);
}

// Set caret to a position and ensure it is visible.
void wxScintillaTextCtrl::GotoPos(int pos) {
    SendMsg(2025, pos, 0);
}

// Set the selection anchor to a position. The anchor is the opposite
// end of the selection from the caret.
void wxScintillaTextCtrl::SetAnchor(int posAnchor) {
    SendMsg(2026, posAnchor, 0);
}

// Retrieve the text of the line containing the caret.
// Returns the index of the caret on the line.
wxString wxScintillaTextCtrl::GetCurLine(int* linePos) {
        int len = LineLength(GetCurrentLine());
        if (!len) {
            if (linePos)  *linePos = 0;
            return wxEmptyString;
        }

        wxMemoryBuffer mbuf(len+1);
        char* buf = (char*)mbuf.GetWriteBuf(len+1);

        int pos = SendMsg(2027, len+1, (wxIntPtr)buf);
        mbuf.UngetWriteBuf(len);
        mbuf.AppendByte(0);
        if (linePos)  *linePos = pos;
        return stc2wx(buf);
}

// Retrieve the position of the last correctly styled character.
int wxScintillaTextCtrl::GetEndStyled() {
    return SendMsg(2028, 0, 0);
}

// Convert all line endings in the document to one mode.
void wxScintillaTextCtrl::ConvertEOLs(int eolMode) {
    SendMsg(2029, eolMode, 0);
}

// Retrieve the current end of line mode - one of CRLF, CR, or LF.
int wxScintillaTextCtrl::GetEOLMode() {
    return SendMsg(2030, 0, 0);
}

// Set the current end of line mode.
void wxScintillaTextCtrl::SetEOLMode(int eolMode) {
    SendMsg(2031, eolMode, 0);
}

// Set the current styling position to pos and the styling mask to mask.
// The styling mask can be used to protect some bits in each styling byte from modification.
void wxScintillaTextCtrl::StartStyling(int pos, int mask) {
    SendMsg(2032, pos, mask);
}

// Change style from current styling position for length characters to a style
// and move the current styling position to after this newly styled segment.
void wxScintillaTextCtrl::SetStyling(int length, int style) {
    SendMsg(2033, length, style);
}

// Is drawing done first into a buffer or direct to the screen?
bool wxScintillaTextCtrl::GetBufferedDraw() {
    return SendMsg(2034, 0, 0) != 0;
}

// If drawing is buffered then each line of text is drawn into a bitmap buffer
// before drawing it to the screen to avoid flicker.
void wxScintillaTextCtrl::SetBufferedDraw(bool buffered) {
    SendMsg(2035, buffered, 0);
}

// Change the visible size of a tab to be a multiple of the width of a space character.
void wxScintillaTextCtrl::SetTabWidth(int tabWidth) {
    SendMsg(2036, tabWidth, 0);
}

// Retrieve the visible size of a tab.
int wxScintillaTextCtrl::GetTabWidth() {
    return SendMsg(2121, 0, 0);
}

// Set the code page used to interpret the bytes of the document as characters.
void wxScintillaTextCtrl::SetCodePage(int codePage) {
#if wxUSE_UNICODE
    wxASSERT_MSG(codePage == wxSTC_CP_UTF8,
                 wxT("Only wxSTC_CP_UTF8 may be used when wxUSE_UNICODE is on."));
#else
    wxASSERT_MSG(codePage != wxSTC_CP_UTF8,
                 wxT("wxSTC_CP_UTF8 may not be used when wxUSE_UNICODE is off."));
#endif
    SendMsg(2037, codePage);
}

// Set the symbol used for a particular marker number,
// and optionally the fore and background colours.
void wxScintillaTextCtrl::MarkerDefine(int markerNumber, int markerSymbol,
                const wxColour& foreground,
                const wxColour& background) {

                SendMsg(2040, markerNumber, markerSymbol);
                if (foreground.Ok())
                    MarkerSetForeground(markerNumber, foreground);
                if (background.Ok())
                    MarkerSetBackground(markerNumber, background);
}

// Set the foreground colour used for a particular marker number.
void wxScintillaTextCtrl::MarkerSetForeground(int markerNumber, const wxColour& fore) {
    SendMsg(2041, markerNumber, wxColourAsLong(fore));
}

// Set the background colour used for a particular marker number.
void wxScintillaTextCtrl::MarkerSetBackground(int markerNumber, const wxColour& back) {
    SendMsg(2042, markerNumber, wxColourAsLong(back));
}

// Add a marker to a line, returning an ID which can be used to find or delete the marker.
int wxScintillaTextCtrl::MarkerAdd(int line, int markerNumber) {
    return SendMsg(2043, line, markerNumber);
}

// Delete a marker from a line.
void wxScintillaTextCtrl::MarkerDelete(int line, int markerNumber) {
    SendMsg(2044, line, markerNumber);
}

// Delete all markers with a particular number from all lines.
void wxScintillaTextCtrl::MarkerDeleteAll(int markerNumber) {
    SendMsg(2045, markerNumber, 0);
}

// Get a bit mask of all the markers set on a line.
int wxScintillaTextCtrl::MarkerGet(int line) {
    return SendMsg(2046, line, 0);
}

// Find the next line after lineStart that includes a marker in mask.
int wxScintillaTextCtrl::MarkerNext(int lineStart, int markerMask) {
    return SendMsg(2047, lineStart, markerMask);
}

// Find the previous line before lineStart that includes a marker in mask.
int wxScintillaTextCtrl::MarkerPrevious(int lineStart, int markerMask) {
    return SendMsg(2048, lineStart, markerMask);
}

// Define a marker from a bitmap
void wxScintillaTextCtrl::MarkerDefineBitmap(int markerNumber, const wxBitmap& bmp) {
        // convert bmp to a xpm in a string
        wxMemoryOutputStream strm;
        wxImage img = bmp.ConvertToImage();
        if (img.HasAlpha())
            img.ConvertAlphaToMask();
        img.SaveFile(strm, wxBITMAP_TYPE_XPM);
        size_t len = strm.GetSize();
        char* buff = new char[len+1];
        strm.CopyTo(buff, len);
        buff[len] = 0;
        SendMsg(2049, markerNumber, (wxIntPtr)buff);
        delete [] buff;

}

// Add a set of markers to a line.
void wxScintillaTextCtrl::MarkerAddSet(int line, int set) {
    SendMsg(2466, line, set);
}

// Set the alpha used for a marker that is drawn in the text area, not the margin.
void wxScintillaTextCtrl::MarkerSetAlpha(int markerNumber, int alpha) {
    SendMsg(2476, markerNumber, alpha);
}

// Set a margin to be either numeric or symbolic.
void wxScintillaTextCtrl::SetMarginType(int margin, int marginType) {
    SendMsg(2240, margin, marginType);
}

// Retrieve the type of a margin.
int wxScintillaTextCtrl::GetMarginType(int margin) {
    return SendMsg(2241, margin, 0);
}

// Set the width of a margin to a width expressed in pixels.
void wxScintillaTextCtrl::SetMarginWidth(int margin, int pixelWidth) {
    SendMsg(2242, margin, pixelWidth);
}

// Retrieve the width of a margin in pixels.
int wxScintillaTextCtrl::GetMarginWidth(int margin) {
    return SendMsg(2243, margin, 0);
}

// Set a mask that determines which markers are displayed in a margin.
void wxScintillaTextCtrl::SetMarginMask(int margin, int mask) {
    SendMsg(2244, margin, mask);
}

// Retrieve the marker mask of a margin.
int wxScintillaTextCtrl::GetMarginMask(int margin) {
    return SendMsg(2245, margin, 0);
}

// Make a margin sensitive or insensitive to mouse clicks.
void wxScintillaTextCtrl::SetMarginSensitive(int margin, bool sensitive) {
    SendMsg(2246, margin, sensitive);
}

// Retrieve the mouse click sensitivity of a margin.
bool wxScintillaTextCtrl::GetMarginSensitive(int margin) {
    return SendMsg(2247, margin, 0) != 0;
}

// Clear all the styles and make equivalent to the global default style.
void wxScintillaTextCtrl::StyleClearAll() {
    SendMsg(2050, 0, 0);
}

// Set the foreground colour of a style.
void wxScintillaTextCtrl::StyleSetForeground(int style, const wxColour& fore) {
    SendMsg(2051, style, wxColourAsLong(fore));
}

// Set the background colour of a style.
void wxScintillaTextCtrl::StyleSetBackground(int style, const wxColour& back) {
    SendMsg(2052, style, wxColourAsLong(back));
}

// Set a style to be bold or not.
void wxScintillaTextCtrl::StyleSetBold(int style, bool bold) {
    SendMsg(2053, style, bold);
}

// Set a style to be italic or not.
void wxScintillaTextCtrl::StyleSetItalic(int style, bool italic) {
    SendMsg(2054, style, italic);
}

// Set the size of characters of a style.
void wxScintillaTextCtrl::StyleSetSize(int style, int sizePoints) {
    SendMsg(2055, style, sizePoints);
}

// Set the font of a style.
void wxScintillaTextCtrl::StyleSetFaceName(int style, const wxString& fontName) {
    SendMsg(2056, style, (wxIntPtr)(const char*)wx2stc(fontName));
}

// Set a style to have its end of line filled or not.
void wxScintillaTextCtrl::StyleSetEOLFilled(int style, bool filled) {
    SendMsg(2057, style, filled);
}

// Reset the default style to its state at startup
void wxScintillaTextCtrl::StyleResetDefault() {
    SendMsg(2058, 0, 0);
}

// Set a style to be underlined or not.
void wxScintillaTextCtrl::StyleSetUnderline(int style, bool underline) {
    SendMsg(2059, style, underline);
}

// Set a style to be mixed case, or to force upper or lower case.
void wxScintillaTextCtrl::StyleSetCase(int style, int caseForce) {
    SendMsg(2060, style, caseForce);
}

// Set a style to be a hotspot or not.
void wxScintillaTextCtrl::StyleSetHotSpot(int style, bool hotspot) {
    SendMsg(2409, style, hotspot);
}

// Set the foreground colour of the selection and whether to use this setting.
void wxScintillaTextCtrl::SetSelForeground(bool useSetting, const wxColour& fore) {
    SendMsg(2067, useSetting, wxColourAsLong(fore));
}

// Set the background colour of the selection and whether to use this setting.
void wxScintillaTextCtrl::SetSelBackground(bool useSetting, const wxColour& back) {
    SendMsg(2068, useSetting, wxColourAsLong(back));
}

// Get the alpha of the selection.
int wxScintillaTextCtrl::GetSelAlpha() {
    return SendMsg(2477, 0, 0);
}

// Set the alpha of the selection.
void wxScintillaTextCtrl::SetSelAlpha(int alpha) {
    SendMsg(2478, alpha, 0);
}

// Set the foreground colour of the caret.
void wxScintillaTextCtrl::SetCaretForeground(const wxColour& fore) {
    SendMsg(2069, wxColourAsLong(fore), 0);
}

// When key+modifier combination km is pressed perform msg.
void wxScintillaTextCtrl::CmdKeyAssign(int key, int modifiers, int cmd) {
         SendMsg(2070, MAKELONG(key, modifiers), cmd);
}

// When key+modifier combination km is pressed do nothing.
void wxScintillaTextCtrl::CmdKeyClear(int key, int modifiers) {
         SendMsg(2071, MAKELONG(key, modifiers));
}

// Drop all key mappings.
void wxScintillaTextCtrl::CmdKeyClearAll() {
    SendMsg(2072, 0, 0);
}

// Set the styles for a segment of the document.
void wxScintillaTextCtrl::SetStyleBytes(int length, char* styleBytes) {
        SendMsg(2073, length, (wxIntPtr)styleBytes);
}

// Set a style to be visible or not.
void wxScintillaTextCtrl::StyleSetVisible(int style, bool visible) {
    SendMsg(2074, style, visible);
}

// Get the time in milliseconds that the caret is on and off.
int wxScintillaTextCtrl::GetCaretPeriod() {
    return SendMsg(2075, 0, 0);
}

// Get the time in milliseconds that the caret is on and off. 0 = steady on.
void wxScintillaTextCtrl::SetCaretPeriod(int periodMilliseconds) {
    SendMsg(2076, periodMilliseconds, 0);
}

// Set the set of characters making up words for when moving or selecting by word.
// First sets deaults like SetCharsDefault.
void wxScintillaTextCtrl::SetWordChars(const wxString& characters) {
    SendMsg(2077, 0, (wxIntPtr)(const char*)wx2stc(characters));
}

// Start a sequence of actions that is undone and redone as a unit.
// May be nested.
void wxScintillaTextCtrl::BeginUndoAction() {
    SendMsg(2078, 0, 0);
}

// End a sequence of actions that is undone and redone as a unit.
void wxScintillaTextCtrl::EndUndoAction() {
    SendMsg(2079, 0, 0);
}

// Set an indicator to plain, squiggle or TT.
void wxScintillaTextCtrl::IndicatorSetStyle(int indic, int style) {
    SendMsg(2080, indic, style);
}

// Retrieve the style of an indicator.
int wxScintillaTextCtrl::IndicatorGetStyle(int indic) {
    return SendMsg(2081, indic, 0);
}

// Set the foreground colour of an indicator.
void wxScintillaTextCtrl::IndicatorSetForeground(int indic, const wxColour& fore) {
    SendMsg(2082, indic, wxColourAsLong(fore));
}

// Retrieve the foreground colour of an indicator.
wxColour wxScintillaTextCtrl::IndicatorGetForeground(int indic) {
    long c = SendMsg(2083, indic, 0);
    return wxColourFromLong(c);
}

// Set the foreground colour of all whitespace and whether to use this setting.
void wxScintillaTextCtrl::SetWhitespaceForeground(bool useSetting, const wxColour& fore) {
    SendMsg(2084, useSetting, wxColourAsLong(fore));
}

// Set the background colour of all whitespace and whether to use this setting.
void wxScintillaTextCtrl::SetWhitespaceBackground(bool useSetting, const wxColour& back) {
    SendMsg(2085, useSetting, wxColourAsLong(back));
}

// Divide each styling byte into lexical class bits (default: 5) and indicator
// bits (default: 3). If a lexer requires more than 32 lexical states, then this
// is used to expand the possible states.
void wxScintillaTextCtrl::SetStyleBits(int bits) {
    SendMsg(2090, bits, 0);
}

// Retrieve number of bits in style bytes used to hold the lexical state.
int wxScintillaTextCtrl::GetStyleBits() {
    return SendMsg(2091, 0, 0);
}

// Used to hold extra styling information for each line.
void wxScintillaTextCtrl::SetLineState(int line, int state) {
    SendMsg(2092, line, state);
}

// Retrieve the extra styling information for a line.
int wxScintillaTextCtrl::GetLineState(int line) {
    return SendMsg(2093, line, 0);
}

// Retrieve the last line number that has line state.
int wxScintillaTextCtrl::GetMaxLineState() {
    return SendMsg(2094, 0, 0);
}

// Is the background of the line containing the caret in a different colour?
bool wxScintillaTextCtrl::GetCaretLineVisible() {
    return SendMsg(2095, 0, 0) != 0;
}

// Display the background of the line containing the caret in a different colour.
void wxScintillaTextCtrl::SetCaretLineVisible(bool show) {
    SendMsg(2096, show, 0);
}

// Get the colour of the background of the line containing the caret.
wxColour wxScintillaTextCtrl::GetCaretLineBackground() {
    long c = SendMsg(2097, 0, 0);
    return wxColourFromLong(c);
}

// Set the colour of the background of the line containing the caret.
void wxScintillaTextCtrl::SetCaretLineBackground(const wxColour& back) {
    SendMsg(2098, wxColourAsLong(back), 0);
}

// Set a style to be changeable or not (read only).
// Experimental feature, currently buggy.
void wxScintillaTextCtrl::StyleSetChangeable(int style, bool changeable) {
    SendMsg(2099, style, changeable);
}

// Display a auto-completion list.
// The lenEntered parameter indicates how many characters before
// the caret should be used to provide context.
void wxScintillaTextCtrl::AutoCompShow(int lenEntered, const wxString& itemList) {
    SendMsg(2100, lenEntered, (wxIntPtr)(const char*)wx2stc(itemList));
}

// Remove the auto-completion list from the screen.
void wxScintillaTextCtrl::AutoCompCancel() {
    SendMsg(2101, 0, 0);
}

// Is there an auto-completion list visible?
bool wxScintillaTextCtrl::AutoCompActive() {
    return SendMsg(2102, 0, 0) != 0;
}

// Retrieve the position of the caret when the auto-completion list was displayed.
int wxScintillaTextCtrl::AutoCompPosStart() {
    return SendMsg(2103, 0, 0);
}

// User has selected an item so remove the list and insert the selection.
void wxScintillaTextCtrl::AutoCompComplete() {
    SendMsg(2104, 0, 0);
}

// Define a set of character that when typed cancel the auto-completion list.
void wxScintillaTextCtrl::AutoCompStops(const wxString& characterSet) {
    SendMsg(2105, 0, (wxIntPtr)(const char*)wx2stc(characterSet));
}

// Change the separator character in the string setting up an auto-completion list.
// Default is space but can be changed if items contain space.
void wxScintillaTextCtrl::AutoCompSetSeparator(int separatorCharacter) {
    SendMsg(2106, separatorCharacter, 0);
}

// Retrieve the auto-completion list separator character.
int wxScintillaTextCtrl::AutoCompGetSeparator() {
    return SendMsg(2107, 0, 0);
}

// Select the item in the auto-completion list that starts with a string.
void wxScintillaTextCtrl::AutoCompSelect(const wxString& text) {
    SendMsg(2108, 0, (wxIntPtr)(const char*)wx2stc(text));
}

// Should the auto-completion list be cancelled if the user backspaces to a
// position before where the box was created.
void wxScintillaTextCtrl::AutoCompSetCancelAtStart(bool cancel) {
    SendMsg(2110, cancel, 0);
}

// Retrieve whether auto-completion cancelled by backspacing before start.
bool wxScintillaTextCtrl::AutoCompGetCancelAtStart() {
    return SendMsg(2111, 0, 0) != 0;
}

// Define a set of characters that when typed will cause the autocompletion to
// choose the selected item.
void wxScintillaTextCtrl::AutoCompSetFillUps(const wxString& characterSet) {
    SendMsg(2112, 0, (wxIntPtr)(const char*)wx2stc(characterSet));
}

// Should a single item auto-completion list automatically choose the item.
void wxScintillaTextCtrl::AutoCompSetChooseSingle(bool chooseSingle) {
    SendMsg(2113, chooseSingle, 0);
}

// Retrieve whether a single item auto-completion list automatically choose the item.
bool wxScintillaTextCtrl::AutoCompGetChooseSingle() {
    return SendMsg(2114, 0, 0) != 0;
}

// Set whether case is significant when performing auto-completion searches.
void wxScintillaTextCtrl::AutoCompSetIgnoreCase(bool ignoreCase) {
    SendMsg(2115, ignoreCase, 0);
}

// Retrieve state of ignore case flag.
bool wxScintillaTextCtrl::AutoCompGetIgnoreCase() {
    return SendMsg(2116, 0, 0) != 0;
}

// Display a list of strings and send notification when user chooses one.
void wxScintillaTextCtrl::UserListShow(int listType, const wxString& itemList) {
    SendMsg(2117, listType, (wxIntPtr)(const char*)wx2stc(itemList));
}

// Set whether or not autocompletion is hidden automatically when nothing matches.
void wxScintillaTextCtrl::AutoCompSetAutoHide(bool autoHide) {
    SendMsg(2118, autoHide, 0);
}

// Retrieve whether or not autocompletion is hidden automatically when nothing matches.
bool wxScintillaTextCtrl::AutoCompGetAutoHide() {
    return SendMsg(2119, 0, 0) != 0;
}

// Set whether or not autocompletion deletes any word characters
// after the inserted text upon completion.
void wxScintillaTextCtrl::AutoCompSetDropRestOfWord(bool dropRestOfWord) {
    SendMsg(2270, dropRestOfWord, 0);
}

// Retrieve whether or not autocompletion deletes any word characters
// after the inserted text upon completion.
bool wxScintillaTextCtrl::AutoCompGetDropRestOfWord() {
    return SendMsg(2271, 0, 0) != 0;
}

// Register an image for use in autocompletion lists.
void wxScintillaTextCtrl::RegisterImage(int type, const wxBitmap& bmp) {
        // convert bmp to a xpm in a string
        wxMemoryOutputStream strm;
        wxImage img = bmp.ConvertToImage();
        if (img.HasAlpha())
            img.ConvertAlphaToMask();
        img.SaveFile(strm, wxBITMAP_TYPE_XPM);
        size_t len = strm.GetSize();
        char* buff = new char[len+1];
        strm.CopyTo(buff, len);
        buff[len] = 0;
        SendMsg(2405, type, (wxIntPtr)buff);
        delete [] buff;

}

// Clear all the registered images.
void wxScintillaTextCtrl::ClearRegisteredImages() {
    SendMsg(2408, 0, 0);
}

// Retrieve the auto-completion list type-separator character.
int wxScintillaTextCtrl::AutoCompGetTypeSeparator() {
    return SendMsg(2285, 0, 0);
}

// Change the type-separator character in the string setting up an auto-completion list.
// Default is '?' but can be changed if items contain '?'.
void wxScintillaTextCtrl::AutoCompSetTypeSeparator(int separatorCharacter) {
    SendMsg(2286, separatorCharacter, 0);
}

// Set the maximum width, in characters, of auto-completion and user lists.
// Set to 0 to autosize to fit longest item, which is the default.
void wxScintillaTextCtrl::AutoCompSetMaxWidth(int characterCount) {
    SendMsg(2208, characterCount, 0);
}

// Get the maximum width, in characters, of auto-completion and user lists.
int wxScintillaTextCtrl::AutoCompGetMaxWidth() {
    return SendMsg(2209, 0, 0);
}

// Set the maximum height, in rows, of auto-completion and user lists.
// The default is 5 rows.
void wxScintillaTextCtrl::AutoCompSetMaxHeight(int rowCount) {
    SendMsg(2210, rowCount, 0);
}

// Set the maximum height, in rows, of auto-completion and user lists.
int wxScintillaTextCtrl::AutoCompGetMaxHeight() {
    return SendMsg(2211, 0, 0);
}

// Set the number of spaces used for one level of indentation.
void wxScintillaTextCtrl::SetIndent(int indentSize) {
    SendMsg(2122, indentSize, 0);
}

// Retrieve indentation size.
int wxScintillaTextCtrl::GetIndent() {
    return SendMsg(2123, 0, 0);
}

// Indentation will only use space characters if useTabs is false, otherwise
// it will use a combination of tabs and spaces.
void wxScintillaTextCtrl::SetUseTabs(bool useTabs) {
    SendMsg(2124, useTabs, 0);
}

// Retrieve whether tabs will be used in indentation.
bool wxScintillaTextCtrl::GetUseTabs() {
    return SendMsg(2125, 0, 0) != 0;
}

// Change the indentation of a line to a number of columns.
void wxScintillaTextCtrl::SetLineIndentation(int line, int indentSize) {
    SendMsg(2126, line, indentSize);
}

// Retrieve the number of columns that a line is indented.
int wxScintillaTextCtrl::GetLineIndentation(int line) {
    return SendMsg(2127, line, 0);
}

// Retrieve the position before the first non indentation character on a line.
int wxScintillaTextCtrl::GetLineIndentPosition(int line) {
    return SendMsg(2128, line, 0);
}

// Retrieve the column number of a position, taking tab width into account.
int wxScintillaTextCtrl::GetColumn(int pos) {
    return SendMsg(2129, pos, 0);
}

// Show or hide the horizontal scroll bar.
void wxScintillaTextCtrl::SetUseHorizontalScrollBar(bool show) {
    SendMsg(2130, show, 0);
}

// Is the horizontal scroll bar visible?
bool wxScintillaTextCtrl::GetUseHorizontalScrollBar() {
    return SendMsg(2131, 0, 0) != 0;
}

// Show or hide indentation guides.
void wxScintillaTextCtrl::SetIndentationGuides(bool show) {
    SendMsg(2132, show, 0);
}

// Are the indentation guides visible?
bool wxScintillaTextCtrl::GetIndentationGuides() {
    return SendMsg(2133, 0, 0) != 0;
}

// Set the highlighted indentation guide column.
// 0 = no highlighted guide.
void wxScintillaTextCtrl::SetHighlightGuide(int column) {
    SendMsg(2134, column, 0);
}

// Get the highlighted indentation guide column.
int wxScintillaTextCtrl::GetHighlightGuide() {
    return SendMsg(2135, 0, 0);
}

// Get the position after the last visible characters on a line.
int wxScintillaTextCtrl::GetLineEndPosition(int line) {
    return SendMsg(2136, line, 0);
}

// Get the code page used to interpret the bytes of the document as characters.
int wxScintillaTextCtrl::GetCodePage() {
    return SendMsg(2137, 0, 0);
}

// Get the foreground colour of the caret.
wxColour wxScintillaTextCtrl::GetCaretForeground() {
    long c = SendMsg(2138, 0, 0);
    return wxColourFromLong(c);
}

// In read-only mode?
bool wxScintillaTextCtrl::GetReadOnly() {
    return SendMsg(2140, 0, 0) != 0;
}

// Sets the position of the caret.
void wxScintillaTextCtrl::SetCurrentPos(int pos) {
    SendMsg(2141, pos, 0);
}

// Sets the position that starts the selection - this becomes the anchor.
void wxScintillaTextCtrl::SetSelectionStart(int pos) {
    SendMsg(2142, pos, 0);
}

// Returns the position at the start of the selection.
int wxScintillaTextCtrl::GetSelectionStart() {
    return SendMsg(2143, 0, 0);
}

// Sets the position that ends the selection - this becomes the currentPosition.
void wxScintillaTextCtrl::SetSelectionEnd(int pos) {
    SendMsg(2144, pos, 0);
}

// Returns the position at the end of the selection.
int wxScintillaTextCtrl::GetSelectionEnd() {
    return SendMsg(2145, 0, 0);
}

// Sets the print magnification added to the point size of each style for printing.
void wxScintillaTextCtrl::SetPrintMagnification(int magnification) {
    SendMsg(2146, magnification, 0);
}

// Returns the print magnification.
int wxScintillaTextCtrl::GetPrintMagnification() {
    return SendMsg(2147, 0, 0);
}

// Modify colours when printing for clearer printed text.
void wxScintillaTextCtrl::SetPrintColourMode(int mode) {
    SendMsg(2148, mode, 0);
}

// Returns the print colour mode.
int wxScintillaTextCtrl::GetPrintColourMode() {
    return SendMsg(2149, 0, 0);
}

// Find some text in the document.
int wxScintillaTextCtrl::FindText(int minPos, int maxPos,
               const wxString& text,
               int flags) {
            TextToFind  ft;
            ft.chrg.cpMin = minPos;
            ft.chrg.cpMax = maxPos;
            wxWX2MBbuf buf = (wxWX2MBbuf)wx2stc(text);
            ft.lpstrText = (char*)(const char*)buf;

            return SendMsg(2150, flags, (wxIntPtr)&ft);
}

// On Windows, will draw the document into a display context such as a printer.
 int wxScintillaTextCtrl::FormatRange(bool   doDraw,
                int    startPos,
                int    endPos,
                wxDC*  draw,
                wxDC*  target,
                wxRect renderRect,
                wxRect pageRect) {
             RangeToFormat fr;

             if (endPos < startPos) {
                 int temp = startPos;
                 startPos = endPos;
                 endPos = temp;
             }
             fr.hdc = draw;
             fr.hdcTarget = target;
             fr.rc.top = renderRect.GetTop();
             fr.rc.left = renderRect.GetLeft();
             fr.rc.right = renderRect.GetRight();
             fr.rc.bottom = renderRect.GetBottom();
             fr.rcPage.top = pageRect.GetTop();
             fr.rcPage.left = pageRect.GetLeft();
             fr.rcPage.right = pageRect.GetRight();
             fr.rcPage.bottom = pageRect.GetBottom();
             fr.chrg.cpMin = startPos;
             fr.chrg.cpMax = endPos;

             return SendMsg(2151, doDraw, (wxIntPtr)&fr);
}

// Retrieve the display line at the top of the display.
int wxScintillaTextCtrl::GetFirstVisibleLine() {
    return SendMsg(2152, 0, 0);
}

// Retrieve the contents of a line.
wxString wxScintillaTextCtrl::GetLine(int line) {
         int len = LineLength(line);
         if (!len) return wxEmptyString;

         wxMemoryBuffer mbuf(len+1);
         char* buf = (char*)mbuf.GetWriteBuf(len+1);
         SendMsg(2153, line, (wxIntPtr)buf);
         mbuf.UngetWriteBuf(len);
         mbuf.AppendByte(0);
         return stc2wx(buf);
}

// Returns the number of lines in the document. There is always at least one.
int wxScintillaTextCtrl::GetLineCount() {
    return SendMsg(2154, 0, 0);
}

// Sets the size in pixels of the left margin.
void wxScintillaTextCtrl::SetMarginLeft(int pixelWidth) {
    SendMsg(2155, 0, pixelWidth);
}

// Returns the size in pixels of the left margin.
int wxScintillaTextCtrl::GetMarginLeft() {
    return SendMsg(2156, 0, 0);
}

// Sets the size in pixels of the right margin.
void wxScintillaTextCtrl::SetMarginRight(int pixelWidth) {
    SendMsg(2157, 0, pixelWidth);
}

// Returns the size in pixels of the right margin.
int wxScintillaTextCtrl::GetMarginRight() {
    return SendMsg(2158, 0, 0);
}

// Is the document different from when it was last saved?
bool wxScintillaTextCtrl::GetModify() {
    return SendMsg(2159, 0, 0) != 0;
}

// Select a range of text.
void wxScintillaTextCtrl::SetSelection(int start, int end) {
    SendMsg(2160, start, end);
}

// Retrieve the selected text.
wxString wxScintillaTextCtrl::GetSelectedText() {
         int   start;
         int   end;

         GetSelection(&start, &end);
         int   len  = end - start;
         if (!len) return wxEmptyString;

         wxMemoryBuffer mbuf(len+2);
         char* buf = (char*)mbuf.GetWriteBuf(len+1);
         SendMsg(2161, 0, (wxIntPtr)buf);
         mbuf.UngetWriteBuf(len);
         mbuf.AppendByte(0);
         return stc2wx(buf);
}

// Retrieve a range of text.
wxString wxScintillaTextCtrl::GetTextRange(int startPos, int endPos) {
         if (endPos < startPos) {
             int temp = startPos;
             startPos = endPos;
             endPos = temp;
         }
         int   len  = endPos - startPos;
         if (!len) return wxEmptyString;
         wxMemoryBuffer mbuf(len+1);
         char* buf = (char*)mbuf.GetWriteBuf(len);
         TextRange tr;
         tr.lpstrText = buf;
         tr.chrg.cpMin = startPos;
         tr.chrg.cpMax = endPos;
         SendMsg(2162, 0, (wxIntPtr)&tr);
         mbuf.UngetWriteBuf(len);
         mbuf.AppendByte(0);
         return stc2wx(buf);
}

// Draw the selection in normal style or with selection highlighted.
void wxScintillaTextCtrl::HideSelection(bool normal) {
    SendMsg(2163, normal, 0);
}

// Retrieve the line containing a position.
int wxScintillaTextCtrl::LineFromPosition(int pos) {
    return SendMsg(2166, pos, 0);
}

// Retrieve the position at the start of a line.
int wxScintillaTextCtrl::PositionFromLine(int line) {
    return SendMsg(2167, line, 0);
}

// Scroll horizontally and vertically.
void wxScintillaTextCtrl::LineScroll(int columns, int lines) {
    SendMsg(2168, columns, lines);
}

// Ensure the caret is visible.
void wxScintillaTextCtrl::EnsureCaretVisible() {
    SendMsg(2169, 0, 0);
}

// Replace the selected text with the argument text.
void wxScintillaTextCtrl::ReplaceSelection(const wxString& text) {
    SendMsg(2170, 0, (wxIntPtr)(const char*)wx2stc(text));
}

// Set to read only or read write.
void wxScintillaTextCtrl::SetReadOnly(bool readOnly) {
    SendMsg(2171, readOnly, 0);
}

// Will a paste succeed?
bool wxScintillaTextCtrl::CanPaste() {
    return SendMsg(2173, 0, 0) != 0;
}

// Are there any undoable actions in the undo history?
bool wxScintillaTextCtrl::CanUndo() {
    return SendMsg(2174, 0, 0) != 0;
}

// Delete the undo history.
void wxScintillaTextCtrl::EmptyUndoBuffer() {
    SendMsg(2175, 0, 0);
}

// Undo one action in the undo history.
void wxScintillaTextCtrl::Undo() {
    SendMsg(2176, 0, 0);
}

// Cut the selection to the clipboard.
void wxScintillaTextCtrl::Cut() {
    SendMsg(2177, 0, 0);
}

// Copy the selection to the clipboard.
void wxScintillaTextCtrl::Copy() {
    SendMsg(2178, 0, 0);
}

// Paste the contents of the clipboard into the document replacing the selection.
void wxScintillaTextCtrl::Paste() {
    SendMsg(2179, 0, 0);
}

// Clear the selection.
void wxScintillaTextCtrl::Clear() {
    SendMsg(2180, 0, 0);
}

// Replace the contents of the document with the argument text.
void wxScintillaTextCtrl::SetText(const wxString& text) {
    SendMsg(2181, 0, (wxIntPtr)(const char*)wx2stc(text));
}

// Retrieve all the text in the document.
wxString wxScintillaTextCtrl::GetText() {
         int len  = GetTextLength();
         wxMemoryBuffer mbuf(len+1);   // leave room for the null...
         char* buf = (char*)mbuf.GetWriteBuf(len+1);
         SendMsg(2182, len+1, (wxIntPtr)buf);
         mbuf.UngetWriteBuf(len);
         mbuf.AppendByte(0);
         return stc2wx(buf);
}

// Retrieve the number of characters in the document.
int wxScintillaTextCtrl::GetTextLength() {
    return SendMsg(2183, 0, 0);
}

// Set to overtype (true) or insert mode.
void wxScintillaTextCtrl::SetOvertype(bool overtype) {
    SendMsg(2186, overtype, 0);
}

// Returns true if overtype mode is active otherwise false is returned.
bool wxScintillaTextCtrl::GetOvertype() {
    return SendMsg(2187, 0, 0) != 0;
}

// Set the width of the insert mode caret.
void wxScintillaTextCtrl::SetCaretWidth(int pixelWidth) {
    SendMsg(2188, pixelWidth, 0);
}

// Returns the width of the insert mode caret.
int wxScintillaTextCtrl::GetCaretWidth() {
    return SendMsg(2189, 0, 0);
}

// Sets the position that starts the target which is used for updating the
// document without affecting the scroll position.
void wxScintillaTextCtrl::SetTargetStart(int pos) {
    SendMsg(2190, pos, 0);
}

// Get the position that starts the target.
int wxScintillaTextCtrl::GetTargetStart() {
    return SendMsg(2191, 0, 0);
}

// Sets the position that ends the target which is used for updating the
// document without affecting the scroll position.
void wxScintillaTextCtrl::SetTargetEnd(int pos) {
    SendMsg(2192, pos, 0);
}

// Get the position that ends the target.
int wxScintillaTextCtrl::GetTargetEnd() {
    return SendMsg(2193, 0, 0);
}

// Replace the target text with the argument text.
// Text is counted so it can contain NULs.
// Returns the length of the replacement text.

     int wxScintillaTextCtrl::ReplaceTarget(const wxString& text) {
         wxWX2MBbuf buf = (wxWX2MBbuf)wx2stc(text);
         return SendMsg(2194, strlen(buf), (wxIntPtr)(const char*)buf);
}

// Replace the target text with the argument text after \d processing.
// Text is counted so it can contain NULs.
// Looks for \d where d is between 1 and 9 and replaces these with the strings
// matched in the last search operation which were surrounded by \( and \).
// Returns the length of the replacement text including any change
// caused by processing the \d patterns.

     int wxScintillaTextCtrl::ReplaceTargetRE(const wxString& text) {
         wxWX2MBbuf buf = (wxWX2MBbuf)wx2stc(text);
         return SendMsg(2195, strlen(buf), (wxIntPtr)(const char*)buf);
}

// Search for a counted string in the target and set the target to the found
// range. Text is counted so it can contain NULs.
// Returns length of range or -1 for failure in which case target is not moved.

     int wxScintillaTextCtrl::SearchInTarget(const wxString& text) {
         wxWX2MBbuf buf = (wxWX2MBbuf)wx2stc(text);
         return SendMsg(2197, strlen(buf), (wxIntPtr)(const char*)buf);
}

// Set the search flags used by SearchInTarget.
void wxScintillaTextCtrl::SetSearchFlags(int flags) {
    SendMsg(2198, flags, 0);
}

// Get the search flags used by SearchInTarget.
int wxScintillaTextCtrl::GetSearchFlags() {
    return SendMsg(2199, 0, 0);
}

// Show a call tip containing a definition near position pos.
void wxScintillaTextCtrl::CallTipShow(int pos, const wxString& definition) {
    SendMsg(2200, pos, (wxIntPtr)(const char*)wx2stc(definition));
}

// Remove the call tip from the screen.
void wxScintillaTextCtrl::CallTipCancel() {
    SendMsg(2201, 0, 0);
}

// Is there an active call tip?
bool wxScintillaTextCtrl::CallTipActive() {
    return SendMsg(2202, 0, 0) != 0;
}

// Retrieve the position where the caret was before displaying the call tip.
int wxScintillaTextCtrl::CallTipPosAtStart() {
    return SendMsg(2203, 0, 0);
}

// Highlight a segment of the definition.
void wxScintillaTextCtrl::CallTipSetHighlight(int start, int end) {
    SendMsg(2204, start, end);
}

// Set the background colour for the call tip.
void wxScintillaTextCtrl::CallTipSetBackground(const wxColour& back) {
    SendMsg(2205, wxColourAsLong(back), 0);
}

// Set the foreground colour for the call tip.
void wxScintillaTextCtrl::CallTipSetForeground(const wxColour& fore) {
    SendMsg(2206, wxColourAsLong(fore), 0);
}

// Set the foreground colour for the highlighted part of the call tip.
void wxScintillaTextCtrl::CallTipSetForegroundHighlight(const wxColour& fore) {
    SendMsg(2207, wxColourAsLong(fore), 0);
}

// Enable use of STYLE_CALLTIP and set call tip tab size in pixels.
void wxScintillaTextCtrl::CallTipUseStyle(int tabSize) {
    SendMsg(2212, tabSize, 0);
}

// Find the display line of a document line taking hidden lines into account.
int wxScintillaTextCtrl::VisibleFromDocLine(int line) {
    return SendMsg(2220, line, 0);
}

// Find the document line of a display line taking hidden lines into account.
int wxScintillaTextCtrl::DocLineFromVisible(int lineDisplay) {
    return SendMsg(2221, lineDisplay, 0);
}

// The number of display lines needed to wrap a document line
int wxScintillaTextCtrl::WrapCount(int line) {
    return SendMsg(2235, line, 0);
}

// Set the fold level of a line.
// This encodes an integer level along with flags indicating whether the
// line is a header and whether it is effectively white space.
void wxScintillaTextCtrl::SetFoldLevel(int line, int level) {
    SendMsg(2222, line, level);
}

// Retrieve the fold level of a line.
int wxScintillaTextCtrl::GetFoldLevel(int line) {
    return SendMsg(2223, line, 0);
}

// Find the last child line of a header line.
int wxScintillaTextCtrl::GetLastChild(int line, int level) {
    return SendMsg(2224, line, level);
}

// Find the parent line of a child line.
int wxScintillaTextCtrl::GetFoldParent(int line) {
    return SendMsg(2225, line, 0);
}

// Make a range of lines visible.
void wxScintillaTextCtrl::ShowLines(int lineStart, int lineEnd) {
    SendMsg(2226, lineStart, lineEnd);
}

// Make a range of lines invisible.
void wxScintillaTextCtrl::HideLines(int lineStart, int lineEnd) {
    SendMsg(2227, lineStart, lineEnd);
}

// Is a line visible?
bool wxScintillaTextCtrl::GetLineVisible(int line) {
    return SendMsg(2228, line, 0) != 0;
}

// Show the children of a header line.
void wxScintillaTextCtrl::SetFoldExpanded(int line, bool expanded) {
    SendMsg(2229, line, expanded);
}

// Is a header line expanded?
bool wxScintillaTextCtrl::GetFoldExpanded(int line) {
    return SendMsg(2230, line, 0) != 0;
}

// Switch a header line between expanded and contracted.
void wxScintillaTextCtrl::ToggleFold(int line) {
    SendMsg(2231, line, 0);
}

// Ensure a particular line is visible by expanding any header line hiding it.
void wxScintillaTextCtrl::EnsureVisible(int line) {
    SendMsg(2232, line, 0);
}

// Set some style options for folding.
void wxScintillaTextCtrl::SetFoldFlags(int flags) {
    SendMsg(2233, flags, 0);
}

// Ensure a particular line is visible by expanding any header line hiding it.
// Use the currently set visibility policy to determine which range to display.
void wxScintillaTextCtrl::EnsureVisibleEnforcePolicy(int line) {
    SendMsg(2234, line, 0);
}

// Sets whether a tab pressed when caret is within indentation indents.
void wxScintillaTextCtrl::SetTabIndents(bool tabIndents) {
    SendMsg(2260, tabIndents, 0);
}

// Does a tab pressed when caret is within indentation indent?
bool wxScintillaTextCtrl::GetTabIndents() {
    return SendMsg(2261, 0, 0) != 0;
}

// Sets whether a backspace pressed when caret is within indentation unindents.
void wxScintillaTextCtrl::SetBackSpaceUnIndents(bool bsUnIndents) {
    SendMsg(2262, bsUnIndents, 0);
}

// Does a backspace pressed when caret is within indentation unindent?
bool wxScintillaTextCtrl::GetBackSpaceUnIndents() {
    return SendMsg(2263, 0, 0) != 0;
}

// Sets the time the mouse must sit still to generate a mouse dwell event.
void wxScintillaTextCtrl::SetMouseDwellTime(int periodMilliseconds) {
    SendMsg(2264, periodMilliseconds, 0);
}

// Retrieve the time the mouse must sit still to generate a mouse dwell event.
int wxScintillaTextCtrl::GetMouseDwellTime() {
    return SendMsg(2265, 0, 0);
}

// Get position of start of word.
int wxScintillaTextCtrl::WordStartPosition(int pos, bool onlyWordCharacters) {
    return SendMsg(2266, pos, onlyWordCharacters);
}

// Get position of end of word.
int wxScintillaTextCtrl::WordEndPosition(int pos, bool onlyWordCharacters) {
    return SendMsg(2267, pos, onlyWordCharacters);
}

// Sets whether text is word wrapped.
void wxScintillaTextCtrl::SetWrapMode(int mode) {
    SendMsg(2268, mode, 0);
}

// Retrieve whether text is word wrapped.
int wxScintillaTextCtrl::GetWrapMode() {
    return SendMsg(2269, 0, 0);
}

// Set the display mode of visual flags for wrapped lines.
void wxScintillaTextCtrl::SetWrapVisualFlags(int wrapVisualFlags) {
    SendMsg(2460, wrapVisualFlags, 0);
}

// Retrive the display mode of visual flags for wrapped lines.
int wxScintillaTextCtrl::GetWrapVisualFlags() {
    return SendMsg(2461, 0, 0);
}

// Set the location of visual flags for wrapped lines.
void wxScintillaTextCtrl::SetWrapVisualFlagsLocation(int wrapVisualFlagsLocation) {
    SendMsg(2462, wrapVisualFlagsLocation, 0);
}

// Retrive the location of visual flags for wrapped lines.
int wxScintillaTextCtrl::GetWrapVisualFlagsLocation() {
    return SendMsg(2463, 0, 0);
}

// Set the start indent for wrapped lines.
void wxScintillaTextCtrl::SetWrapStartIndent(int indent) {
    SendMsg(2464, indent, 0);
}

// Retrive the start indent for wrapped lines.
int wxScintillaTextCtrl::GetWrapStartIndent() {
    return SendMsg(2465, 0, 0);
}

// Sets the degree of caching of layout information.
void wxScintillaTextCtrl::SetLayoutCache(int mode) {
    SendMsg(2272, mode, 0);
}

// Retrieve the degree of caching of layout information.
int wxScintillaTextCtrl::GetLayoutCache() {
    return SendMsg(2273, 0, 0);
}

// Sets the document width assumed for scrolling.
void wxScintillaTextCtrl::SetScrollWidth(int pixelWidth) {
    SendMsg(2274, pixelWidth, 0);
}

// Retrieve the document width assumed for scrolling.
int wxScintillaTextCtrl::GetScrollWidth() {
    return SendMsg(2275, 0, 0);
}

// Measure the pixel width of some text in a particular style.
// NUL terminated text argument.
// Does not handle tab or control characters.
int wxScintillaTextCtrl::TextWidth(int style, const wxString& text) {
    return SendMsg(2276, style, (wxIntPtr)(const char*)wx2stc(text));
}

// Sets the scroll range so that maximum scroll position has
// the last line at the bottom of the view (default).
// Setting this to false allows scrolling one page below the last line.
void wxScintillaTextCtrl::SetEndAtLastLine(bool endAtLastLine) {
    SendMsg(2277, endAtLastLine, 0);
}

// Retrieve whether the maximum scroll position has the last
// line at the bottom of the view.
bool wxScintillaTextCtrl::GetEndAtLastLine() {
    return SendMsg(2278, 0, 0) != 0;
}

// Retrieve the height of a particular line of text in pixels.
int wxScintillaTextCtrl::TextHeight(int line) {
    return SendMsg(2279, line, 0);
}

// Show or hide the vertical scroll bar.
void wxScintillaTextCtrl::SetUseVerticalScrollBar(bool show) {
    SendMsg(2280, show, 0);
}

// Is the vertical scroll bar visible?
bool wxScintillaTextCtrl::GetUseVerticalScrollBar() {
    return SendMsg(2281, 0, 0) != 0;
}

// Append a string to the end of the document without changing the selection.
void wxScintillaTextCtrl::AppendText(const wxString& text) {
                    wxWX2MBbuf buf = (wxWX2MBbuf)wx2stc(text);
                    SendMsg(2282, strlen(buf), (wxIntPtr)(const char*)buf);
}

// Is drawing done in two phases with backgrounds drawn before foregrounds?
bool wxScintillaTextCtrl::GetTwoPhaseDraw() {
    return SendMsg(2283, 0, 0) != 0;
}

// In twoPhaseDraw mode, drawing is performed in two phases, first the background
// and then the foreground. This avoids chopping off characters that overlap the next run.
void wxScintillaTextCtrl::SetTwoPhaseDraw(bool twoPhase) {
    SendMsg(2284, twoPhase, 0);
}

// Make the target range start and end be the same as the selection range start and end.
void wxScintillaTextCtrl::TargetFromSelection() {
    SendMsg(2287, 0, 0);
}

// Join the lines in the target.
void wxScintillaTextCtrl::LinesJoin() {
    SendMsg(2288, 0, 0);
}

// Split the lines in the target into lines that are less wide than pixelWidth
// where possible.
void wxScintillaTextCtrl::LinesSplit(int pixelWidth) {
    SendMsg(2289, pixelWidth, 0);
}

// Set the colours used as a chequerboard pattern in the fold margin
void wxScintillaTextCtrl::SetFoldMarginColour(bool useSetting, const wxColour& back) {
    SendMsg(2290, useSetting, wxColourAsLong(back));
}
void wxScintillaTextCtrl::SetFoldMarginHiColour(bool useSetting, const wxColour& fore) {
    SendMsg(2291, useSetting, wxColourAsLong(fore));
}

// Move caret down one line.
void wxScintillaTextCtrl::LineDown() {
    SendMsg(2300, 0, 0);
}

// Move caret down one line extending selection to new caret position.
void wxScintillaTextCtrl::LineDownExtend() {
    SendMsg(2301, 0, 0);
}

// Move caret up one line.
void wxScintillaTextCtrl::LineUp() {
    SendMsg(2302, 0, 0);
}

// Move caret up one line extending selection to new caret position.
void wxScintillaTextCtrl::LineUpExtend() {
    SendMsg(2303, 0, 0);
}

// Move caret left one character.
void wxScintillaTextCtrl::CharLeft() {
    SendMsg(2304, 0, 0);
}

// Move caret left one character extending selection to new caret position.
void wxScintillaTextCtrl::CharLeftExtend() {
    SendMsg(2305, 0, 0);
}

// Move caret right one character.
void wxScintillaTextCtrl::CharRight() {
    SendMsg(2306, 0, 0);
}

// Move caret right one character extending selection to new caret position.
void wxScintillaTextCtrl::CharRightExtend() {
    SendMsg(2307, 0, 0);
}

// Move caret left one word.
void wxScintillaTextCtrl::WordLeft() {
    SendMsg(2308, 0, 0);
}

// Move caret left one word extending selection to new caret position.
void wxScintillaTextCtrl::WordLeftExtend() {
    SendMsg(2309, 0, 0);
}

// Move caret right one word.
void wxScintillaTextCtrl::WordRight() {
    SendMsg(2310, 0, 0);
}

// Move caret right one word extending selection to new caret position.
void wxScintillaTextCtrl::WordRightExtend() {
    SendMsg(2311, 0, 0);
}

// Move caret to first position on line.
void wxScintillaTextCtrl::Home() {
    SendMsg(2312, 0, 0);
}

// Move caret to first position on line extending selection to new caret position.
void wxScintillaTextCtrl::HomeExtend() {
    SendMsg(2313, 0, 0);
}

// Move caret to last position on line.
void wxScintillaTextCtrl::LineEnd() {
    SendMsg(2314, 0, 0);
}

// Move caret to last position on line extending selection to new caret position.
void wxScintillaTextCtrl::LineEndExtend() {
    SendMsg(2315, 0, 0);
}

// Move caret to first position in document.
void wxScintillaTextCtrl::DocumentStart() {
    SendMsg(2316, 0, 0);
}

// Move caret to first position in document extending selection to new caret position.
void wxScintillaTextCtrl::DocumentStartExtend() {
    SendMsg(2317, 0, 0);
}

// Move caret to last position in document.
void wxScintillaTextCtrl::DocumentEnd() {
    SendMsg(2318, 0, 0);
}

// Move caret to last position in document extending selection to new caret position.
void wxScintillaTextCtrl::DocumentEndExtend() {
    SendMsg(2319, 0, 0);
}

// Move caret one page up.
void wxScintillaTextCtrl::PageUp() {
    SendMsg(2320, 0, 0);
}

// Move caret one page up extending selection to new caret position.
void wxScintillaTextCtrl::PageUpExtend() {
    SendMsg(2321, 0, 0);
}

// Move caret one page down.
void wxScintillaTextCtrl::PageDown() {
    SendMsg(2322, 0, 0);
}

// Move caret one page down extending selection to new caret position.
void wxScintillaTextCtrl::PageDownExtend() {
    SendMsg(2323, 0, 0);
}

// Switch from insert to overtype mode or the reverse.
void wxScintillaTextCtrl::EditToggleOvertype() {
    SendMsg(2324, 0, 0);
}

// Cancel any modes such as call tip or auto-completion list display.
void wxScintillaTextCtrl::Cancel() {
    SendMsg(2325, 0, 0);
}

// Delete the selection or if no selection, the character before the caret.
void wxScintillaTextCtrl::DeleteBack() {
    SendMsg(2326, 0, 0);
}

// If selection is empty or all on one line replace the selection with a tab character.
// If more than one line selected, indent the lines.
void wxScintillaTextCtrl::Tab() {
    SendMsg(2327, 0, 0);
}

// Dedent the selected lines.
void wxScintillaTextCtrl::BackTab() {
    SendMsg(2328, 0, 0);
}

// Insert a new line, may use a CRLF, CR or LF depending on EOL mode.
void wxScintillaTextCtrl::NewLine() {
    SendMsg(2329, 0, 0);
}

// Insert a Form Feed character.
void wxScintillaTextCtrl::FormFeed() {
    SendMsg(2330, 0, 0);
}

// Move caret to before first visible character on line.
// If already there move to first character on line.
void wxScintillaTextCtrl::VCHome() {
    SendMsg(2331, 0, 0);
}

// Like VCHome but extending selection to new caret position.
void wxScintillaTextCtrl::VCHomeExtend() {
    SendMsg(2332, 0, 0);
}

// Magnify the displayed text by increasing the sizes by 1 point.
void wxScintillaTextCtrl::ZoomIn() {
    SendMsg(2333, 0, 0);
}

// Make the displayed text smaller by decreasing the sizes by 1 point.
void wxScintillaTextCtrl::ZoomOut() {
    SendMsg(2334, 0, 0);
}

// Delete the word to the left of the caret.
void wxScintillaTextCtrl::DelWordLeft() {
    SendMsg(2335, 0, 0);
}

// Delete the word to the right of the caret.
void wxScintillaTextCtrl::DelWordRight() {
    SendMsg(2336, 0, 0);
}

// Cut the line containing the caret.
void wxScintillaTextCtrl::LineCut() {
    SendMsg(2337, 0, 0);
}

// Delete the line containing the caret.
void wxScintillaTextCtrl::LineDelete() {
    SendMsg(2338, 0, 0);
}

// Switch the current line with the previous.
void wxScintillaTextCtrl::LineTranspose() {
    SendMsg(2339, 0, 0);
}

// Duplicate the current line.
void wxScintillaTextCtrl::LineDuplicate() {
    SendMsg(2404, 0, 0);
}

// Transform the selection to lower case.
void wxScintillaTextCtrl::LowerCase() {
    SendMsg(2340, 0, 0);
}

// Transform the selection to upper case.
void wxScintillaTextCtrl::UpperCase() {
    SendMsg(2341, 0, 0);
}

// Scroll the document down, keeping the caret visible.
void wxScintillaTextCtrl::LineScrollDown() {
    SendMsg(2342, 0, 0);
}

// Scroll the document up, keeping the caret visible.
void wxScintillaTextCtrl::LineScrollUp() {
    SendMsg(2343, 0, 0);
}

// Delete the selection or if no selection, the character before the caret.
// Will not delete the character before at the start of a line.
void wxScintillaTextCtrl::DeleteBackNotLine() {
    SendMsg(2344, 0, 0);
}

// Move caret to first position on display line.
void wxScintillaTextCtrl::HomeDisplay() {
    SendMsg(2345, 0, 0);
}

// Move caret to first position on display line extending selection to
// new caret position.
void wxScintillaTextCtrl::HomeDisplayExtend() {
    SendMsg(2346, 0, 0);
}

// Move caret to last position on display line.
void wxScintillaTextCtrl::LineEndDisplay() {
    SendMsg(2347, 0, 0);
}

// Move caret to last position on display line extending selection to new
// caret position.
void wxScintillaTextCtrl::LineEndDisplayExtend() {
    SendMsg(2348, 0, 0);
}

// These are like their namesakes Home(Extend)?, LineEnd(Extend)?, VCHome(Extend)?
// except they behave differently when word-wrap is enabled:
// They go first to the start / end of the display line, like (Home|LineEnd)Display
// The difference is that, the cursor is already at the point, it goes on to the start
// or end of the document line, as appropriate for (Home|LineEnd|VCHome)(Extend)?.
void wxScintillaTextCtrl::HomeWrap() {
    SendMsg(2349, 0, 0);
}
void wxScintillaTextCtrl::HomeWrapExtend() {
    SendMsg(2450, 0, 0);
}
void wxScintillaTextCtrl::LineEndWrap() {
    SendMsg(2451, 0, 0);
}
void wxScintillaTextCtrl::LineEndWrapExtend() {
    SendMsg(2452, 0, 0);
}
void wxScintillaTextCtrl::VCHomeWrap() {
    SendMsg(2453, 0, 0);
}
void wxScintillaTextCtrl::VCHomeWrapExtend() {
    SendMsg(2454, 0, 0);
}

// Copy the line containing the caret.
void wxScintillaTextCtrl::LineCopy() {
    SendMsg(2455, 0, 0);
}

// Move the caret inside current view if it's not there already.
void wxScintillaTextCtrl::MoveCaretInsideView() {
    SendMsg(2401, 0, 0);
}

// How many characters are on a line, not including end of line characters?
int wxScintillaTextCtrl::LineLength(int line) {
    return SendMsg(2350, line, 0);
}

// Highlight the characters at two positions.
void wxScintillaTextCtrl::BraceHighlight(int pos1, int pos2) {
    SendMsg(2351, pos1, pos2);
}

// Highlight the character at a position indicating there is no matching brace.
void wxScintillaTextCtrl::BraceBadLight(int pos) {
    SendMsg(2352, pos, 0);
}

// Find the position of a matching brace or INVALID_POSITION if no match.
int wxScintillaTextCtrl::BraceMatch(int pos) {
    return SendMsg(2353, pos, 0);
}

// Are the end of line characters visible?
bool wxScintillaTextCtrl::GetViewEOL() {
    return SendMsg(2355, 0, 0) != 0;
}

// Make the end of line characters visible or invisible.
void wxScintillaTextCtrl::SetViewEOL(bool visible) {
    SendMsg(2356, visible, 0);
}

// Retrieve a pointer to the document object.
void* wxScintillaTextCtrl::GetDocPointer() {
         return (void*)SendMsg(2357);
}

// Change the document object used.
void wxScintillaTextCtrl::SetDocPointer(void* docPointer) {
         SendMsg(2358, 0, (wxIntPtr)docPointer);
}

// Set which document modification events are sent to the container.
void wxScintillaTextCtrl::SetModEventMask(int mask) {
    SendMsg(2359, mask, 0);
}

// Retrieve the column number which text should be kept within.
int wxScintillaTextCtrl::GetEdgeColumn() {
    return SendMsg(2360, 0, 0);
}

// Set the column number of the edge.
// If text goes past the edge then it is highlighted.
void wxScintillaTextCtrl::SetEdgeColumn(int column) {
    SendMsg(2361, column, 0);
}

// Retrieve the edge highlight mode.
int wxScintillaTextCtrl::GetEdgeMode() {
    return SendMsg(2362, 0, 0);
}

// The edge may be displayed by a line (EDGE_LINE) or by highlighting text that
// goes beyond it (EDGE_BACKGROUND) or not displayed at all (EDGE_NONE).
void wxScintillaTextCtrl::SetEdgeMode(int mode) {
    SendMsg(2363, mode, 0);
}

// Retrieve the colour used in edge indication.
wxColour wxScintillaTextCtrl::GetEdgeColour() {
    long c = SendMsg(2364, 0, 0);
    return wxColourFromLong(c);
}

// Change the colour used in edge indication.
void wxScintillaTextCtrl::SetEdgeColour(const wxColour& edgeColour) {
    SendMsg(2365, wxColourAsLong(edgeColour), 0);
}

// Sets the current caret position to be the search anchor.
void wxScintillaTextCtrl::SearchAnchor() {
    SendMsg(2366, 0, 0);
}

// Find some text starting at the search anchor.
// Does not ensure the selection is visible.
int wxScintillaTextCtrl::SearchNext(int flags, const wxString& text) {
    return SendMsg(2367, flags, (wxIntPtr)(const char*)wx2stc(text));
}

// Find some text starting at the search anchor and moving backwards.
// Does not ensure the selection is visible.
int wxScintillaTextCtrl::SearchPrev(int flags, const wxString& text) {
    return SendMsg(2368, flags, (wxIntPtr)(const char*)wx2stc(text));
}

// Retrieves the number of lines completely visible.
int wxScintillaTextCtrl::LinesOnScreen() {
    return SendMsg(2370, 0, 0);
}

// Set whether a pop up menu is displayed automatically when the user presses
// the wrong mouse button.
void wxScintillaTextCtrl::UsePopUp(bool allowPopUp) {
    SendMsg(2371, allowPopUp, 0);
}

// Is the selection rectangular? The alternative is the more common stream selection.
bool wxScintillaTextCtrl::SelectionIsRectangle() {
    return SendMsg(2372, 0, 0) != 0;
}

// Set the zoom level. This number of points is added to the size of all fonts.
// It may be positive to magnify or negative to reduce.
void wxScintillaTextCtrl::SetZoom(int zoom) {
    SendMsg(2373, zoom, 0);
}

// Retrieve the zoom level.
int wxScintillaTextCtrl::GetZoom() {
    return SendMsg(2374, 0, 0);
}

// Create a new document object.
// Starts with reference count of 1 and not selected into editor.
void* wxScintillaTextCtrl::CreateDocument() {
         return (void*)SendMsg(2375);
}

// Extend life of document.
void wxScintillaTextCtrl::AddRefDocument(void* docPointer) {
         SendMsg(2376, 0, (wxIntPtr)docPointer);
}

// Release a reference to the document, deleting document if it fades to black.
void wxScintillaTextCtrl::ReleaseDocument(void* docPointer) {
         SendMsg(2377, 0, (wxIntPtr)docPointer);
}

// Get which document modification events are sent to the container.
int wxScintillaTextCtrl::GetModEventMask() {
    return SendMsg(2378, 0, 0);
}

// Change internal focus flag.
void wxScintillaTextCtrl::SetSTCFocus(bool focus) {
    SendMsg(2380, focus, 0);
}

// Get internal focus flag.
bool wxScintillaTextCtrl::GetSTCFocus() {
    return SendMsg(2381, 0, 0) != 0;
}

// Change error status - 0 = OK.
void wxScintillaTextCtrl::SetStatus(int statusCode) {
    SendMsg(2382, statusCode, 0);
}

// Get error status.
int wxScintillaTextCtrl::GetStatus() {
    return SendMsg(2383, 0, 0);
}

// Set whether the mouse is captured when its button is pressed.
void wxScintillaTextCtrl::SetMouseDownCaptures(bool captures) {
    SendMsg(2384, captures, 0);
}

// Get whether mouse gets captured.
bool wxScintillaTextCtrl::GetMouseDownCaptures() {
    return SendMsg(2385, 0, 0) != 0;
}

// Sets the cursor to one of the SC_CURSOR* values.
void wxScintillaTextCtrl::SetSTCCursor(int cursorType) {
    SendMsg(2386, cursorType, 0);
}

// Get cursor type.
int wxScintillaTextCtrl::GetSTCCursor() {
    return SendMsg(2387, 0, 0);
}

// Change the way control characters are displayed:
// If symbol is < 32, keep the drawn way, else, use the given character.
void wxScintillaTextCtrl::SetControlCharSymbol(int symbol) {
    SendMsg(2388, symbol, 0);
}

// Get the way control characters are displayed.
int wxScintillaTextCtrl::GetControlCharSymbol() {
    return SendMsg(2389, 0, 0);
}

// Move to the previous change in capitalisation.
void wxScintillaTextCtrl::WordPartLeft() {
    SendMsg(2390, 0, 0);
}

// Move to the previous change in capitalisation extending selection
// to new caret position.
void wxScintillaTextCtrl::WordPartLeftExtend() {
    SendMsg(2391, 0, 0);
}

// Move to the change next in capitalisation.
void wxScintillaTextCtrl::WordPartRight() {
    SendMsg(2392, 0, 0);
}

// Move to the next change in capitalisation extending selection
// to new caret position.
void wxScintillaTextCtrl::WordPartRightExtend() {
    SendMsg(2393, 0, 0);
}

// Set the way the display area is determined when a particular line
// is to be moved to by Find, FindNext, GotoLine, etc.
void wxScintillaTextCtrl::SetVisiblePolicy(int visiblePolicy, int visibleSlop) {
    SendMsg(2394, visiblePolicy, visibleSlop);
}

// Delete back from the current position to the start of the line.
void wxScintillaTextCtrl::DelLineLeft() {
    SendMsg(2395, 0, 0);
}

// Delete forwards from the current position to the end of the line.
void wxScintillaTextCtrl::DelLineRight() {
    SendMsg(2396, 0, 0);
}

// Get and Set the xOffset (ie, horizonal scroll position).
void wxScintillaTextCtrl::SetXOffset(int newOffset) {
    SendMsg(2397, newOffset, 0);
}
int wxScintillaTextCtrl::GetXOffset() {
    return SendMsg(2398, 0, 0);
}

// Set the last x chosen value to be the caret x position.
void wxScintillaTextCtrl::ChooseCaretX() {
    SendMsg(2399, 0, 0);
}

// Set the way the caret is kept visible when going sideway.
// The exclusion zone is given in pixels.
void wxScintillaTextCtrl::SetXCaretPolicy(int caretPolicy, int caretSlop) {
    SendMsg(2402, caretPolicy, caretSlop);
}

// Set the way the line the caret is on is kept visible.
// The exclusion zone is given in lines.
void wxScintillaTextCtrl::SetYCaretPolicy(int caretPolicy, int caretSlop) {
    SendMsg(2403, caretPolicy, caretSlop);
}

// Set printing to line wrapped (SC_WRAP_WORD) or not line wrapped (SC_WRAP_NONE).
void wxScintillaTextCtrl::SetPrintWrapMode(int mode) {
    SendMsg(2406, mode, 0);
}

// Is printing line wrapped?
int wxScintillaTextCtrl::GetPrintWrapMode() {
    return SendMsg(2407, 0, 0);
}

// Set a fore colour for active hotspots.
void wxScintillaTextCtrl::SetHotspotActiveForeground(bool useSetting, const wxColour& fore) {
    SendMsg(2410, useSetting, wxColourAsLong(fore));
}

// Set a back colour for active hotspots.
void wxScintillaTextCtrl::SetHotspotActiveBackground(bool useSetting, const wxColour& back) {
    SendMsg(2411, useSetting, wxColourAsLong(back));
}

// Enable / Disable underlining active hotspots.
void wxScintillaTextCtrl::SetHotspotActiveUnderline(bool underline) {
    SendMsg(2412, underline, 0);
}

// Limit hotspots to single line so hotspots on two lines don't merge.
void wxScintillaTextCtrl::SetHotspotSingleLine(bool singleLine) {
    SendMsg(2421, singleLine, 0);
}

// Move caret between paragraphs (delimited by empty lines).
void wxScintillaTextCtrl::ParaDown() {
    SendMsg(2413, 0, 0);
}
void wxScintillaTextCtrl::ParaDownExtend() {
    SendMsg(2414, 0, 0);
}
void wxScintillaTextCtrl::ParaUp() {
    SendMsg(2415, 0, 0);
}
void wxScintillaTextCtrl::ParaUpExtend() {
    SendMsg(2416, 0, 0);
}

// Given a valid document position, return the previous position taking code
// page into account. Returns 0 if passed 0.
int wxScintillaTextCtrl::PositionBefore(int pos) {
    return SendMsg(2417, pos, 0);
}

// Given a valid document position, return the next position taking code
// page into account. Maximum value returned is the last position in the document.
int wxScintillaTextCtrl::PositionAfter(int pos) {
    return SendMsg(2418, pos, 0);
}

// Copy a range of text to the clipboard. Positions are clipped into the document.
void wxScintillaTextCtrl::CopyRange(int start, int end) {
    SendMsg(2419, start, end);
}

// Copy argument text to the clipboard.
void wxScintillaTextCtrl::CopyText(int length, const wxString& text) {
    SendMsg(2420, length, (wxIntPtr)(const char*)wx2stc(text));
}

// Set the selection mode to stream (SC_SEL_STREAM) or rectangular (SC_SEL_RECTANGLE) or
// by lines (SC_SEL_LINES).
void wxScintillaTextCtrl::SetSelectionMode(int mode) {
    SendMsg(2422, mode, 0);
}

// Get the mode of the current selection.
int wxScintillaTextCtrl::GetSelectionMode() {
    return SendMsg(2423, 0, 0);
}

// Retrieve the position of the start of the selection at the given line (INVALID_POSITION if no selection on this line).
int wxScintillaTextCtrl::GetLineSelStartPosition(int line) {
    return SendMsg(2424, line, 0);
}

// Retrieve the position of the end of the selection at the given line (INVALID_POSITION if no selection on this line).
int wxScintillaTextCtrl::GetLineSelEndPosition(int line) {
    return SendMsg(2425, line, 0);
}

// Move caret down one line, extending rectangular selection to new caret position.
void wxScintillaTextCtrl::LineDownRectExtend() {
    SendMsg(2426, 0, 0);
}

// Move caret up one line, extending rectangular selection to new caret position.
void wxScintillaTextCtrl::LineUpRectExtend() {
    SendMsg(2427, 0, 0);
}

// Move caret left one character, extending rectangular selection to new caret position.
void wxScintillaTextCtrl::CharLeftRectExtend() {
    SendMsg(2428, 0, 0);
}

// Move caret right one character, extending rectangular selection to new caret position.
void wxScintillaTextCtrl::CharRightRectExtend() {
    SendMsg(2429, 0, 0);
}

// Move caret to first position on line, extending rectangular selection to new caret position.
void wxScintillaTextCtrl::HomeRectExtend() {
    SendMsg(2430, 0, 0);
}

// Move caret to before first visible character on line.
// If already there move to first character on line.
// In either case, extend rectangular selection to new caret position.
void wxScintillaTextCtrl::VCHomeRectExtend() {
    SendMsg(2431, 0, 0);
}

// Move caret to last position on line, extending rectangular selection to new caret position.
void wxScintillaTextCtrl::LineEndRectExtend() {
    SendMsg(2432, 0, 0);
}

// Move caret one page up, extending rectangular selection to new caret position.
void wxScintillaTextCtrl::PageUpRectExtend() {
    SendMsg(2433, 0, 0);
}

// Move caret one page down, extending rectangular selection to new caret position.
void wxScintillaTextCtrl::PageDownRectExtend() {
    SendMsg(2434, 0, 0);
}

// Move caret to top of page, or one page up if already at top of page.
void wxScintillaTextCtrl::StutteredPageUp() {
    SendMsg(2435, 0, 0);
}

// Move caret to top of page, or one page up if already at top of page, extending selection to new caret position.
void wxScintillaTextCtrl::StutteredPageUpExtend() {
    SendMsg(2436, 0, 0);
}

// Move caret to bottom of page, or one page down if already at bottom of page.
void wxScintillaTextCtrl::StutteredPageDown() {
    SendMsg(2437, 0, 0);
}

// Move caret to bottom of page, or one page down if already at bottom of page, extending selection to new caret position.
void wxScintillaTextCtrl::StutteredPageDownExtend() {
    SendMsg(2438, 0, 0);
}

// Move caret left one word, position cursor at end of word.
void wxScintillaTextCtrl::WordLeftEnd() {
    SendMsg(2439, 0, 0);
}

// Move caret left one word, position cursor at end of word, extending selection to new caret position.
void wxScintillaTextCtrl::WordLeftEndExtend() {
    SendMsg(2440, 0, 0);
}

// Move caret right one word, position cursor at end of word.
void wxScintillaTextCtrl::WordRightEnd() {
    SendMsg(2441, 0, 0);
}

// Move caret right one word, position cursor at end of word, extending selection to new caret position.
void wxScintillaTextCtrl::WordRightEndExtend() {
    SendMsg(2442, 0, 0);
}

// Set the set of characters making up whitespace for when moving or selecting by word.
// Should be called after SetWordChars.
void wxScintillaTextCtrl::SetWhitespaceChars(const wxString& characters) {
    SendMsg(2443, 0, (wxIntPtr)(const char*)wx2stc(characters));
}

// Reset the set of characters for whitespace and word characters to the defaults.
void wxScintillaTextCtrl::SetCharsDefault() {
    SendMsg(2444, 0, 0);
}

// Get currently selected item position in the auto-completion list
int wxScintillaTextCtrl::AutoCompGetCurrent() {
    return SendMsg(2445, 0, 0);
}

// Enlarge the document to a particular size of text bytes.
void wxScintillaTextCtrl::Allocate(int bytes) {
    SendMsg(2446, bytes, 0);
}

// Find the position of a column on a line taking into account tabs and
// multi-byte characters. If beyond end of line, return line end position.
int wxScintillaTextCtrl::FindColumn(int line, int column) {
    return SendMsg(2456, line, column);
}

// Can the caret preferred x position only be changed by explicit movement commands?
bool wxScintillaTextCtrl::GetCaretSticky() {
    return SendMsg(2457, 0, 0) != 0;
}

// Stop the caret preferred x position changing when the user types.
void wxScintillaTextCtrl::SetCaretSticky(bool useCaretStickyBehaviour) {
    SendMsg(2458, useCaretStickyBehaviour, 0);
}

// Switch between sticky and non-sticky: meant to be bound to a key.
void wxScintillaTextCtrl::ToggleCaretSticky() {
    SendMsg(2459, 0, 0);
}

// Enable/Disable convert-on-paste for line endings
void wxScintillaTextCtrl::SetPasteConvertEndings(bool convert) {
    SendMsg(2467, convert, 0);
}

// Get convert-on-paste setting
bool wxScintillaTextCtrl::GetPasteConvertEndings() {
    return SendMsg(2468, 0, 0) != 0;
}

// Duplicate the selection. If selection empty duplicate the line containing the caret.
void wxScintillaTextCtrl::SelectionDuplicate() {
    SendMsg(2469, 0, 0);
}

// Set background alpha of the caret line.
void wxScintillaTextCtrl::SetCaretLineBackAlpha(int alpha) {
    SendMsg(2470, alpha, 0);
}

// Get the background alpha of the caret line.
int wxScintillaTextCtrl::GetCaretLineBackAlpha() {
    return SendMsg(2471, 0, 0);
}

// Start notifying the container of all key presses and commands.
void wxScintillaTextCtrl::StartRecord() {
    SendMsg(3001, 0, 0);
}

// Stop notifying the container of all key presses and commands.
void wxScintillaTextCtrl::StopRecord() {
    SendMsg(3002, 0, 0);
}

// Set the lexing language of the document.
void wxScintillaTextCtrl::SetLexer(int lexer) {
    SendMsg(4001, lexer, 0);
}

// Retrieve the lexing language of the document.
int wxScintillaTextCtrl::GetLexer() {
    return SendMsg(4002, 0, 0);
}

// Colourise a segment of the document using the current lexing language.
void wxScintillaTextCtrl::Colourise(int start, int end) {
    SendMsg(4003, start, end);
}

// Set up a value that may be used by a lexer for some optional feature.
void wxScintillaTextCtrl::SetProperty(const wxString& key, const wxString& value) {
    SendMsg(4004, (wxIntPtr)(const char*)wx2stc(key), (wxIntPtr)(const char*)wx2stc(value));
}

// Set up the key words used by the lexer.
void wxScintillaTextCtrl::SetKeyWords(int keywordSet, const wxString& keyWords) {
    SendMsg(4005, keywordSet, (wxIntPtr)(const char*)wx2stc(keyWords));
}

// Set the lexing language of the document based on string name.
void wxScintillaTextCtrl::SetLexerLanguage(const wxString& language) {
    SendMsg(4006, 0, (wxIntPtr)(const char*)wx2stc(language));
}

// Retrieve a 'property' value previously set with SetProperty.
wxString wxScintillaTextCtrl::GetProperty(const wxString& key) {
         int len = SendMsg(SCI_GETPROPERTY, (wxIntPtr)(const char*)wx2stc(key), (long)NULL);
         if (!len) return wxEmptyString;

         wxMemoryBuffer mbuf(len+1);
         char* buf = (char*)mbuf.GetWriteBuf(len+1);
         SendMsg(4008, (wxIntPtr)(const char*)wx2stc(key), (wxIntPtr)buf);
         mbuf.UngetWriteBuf(len);
         mbuf.AppendByte(0);
         return stc2wx(buf);
}

// Retrieve a 'property' value previously set with SetProperty,
// with '$()' variable replacement on returned buffer.
wxString wxScintillaTextCtrl::GetPropertyExpanded(const wxString& key) {
         int len = SendMsg(SCI_GETPROPERTYEXPANDED, (wxIntPtr)(const char*)wx2stc(key), (long)NULL);
         if (!len) return wxEmptyString;

         wxMemoryBuffer mbuf(len+1);
         char* buf = (char*)mbuf.GetWriteBuf(len+1);
         SendMsg(4009, (wxIntPtr)(const char*)wx2stc(key), (wxIntPtr)buf);
         mbuf.UngetWriteBuf(len);
         mbuf.AppendByte(0);
         return stc2wx(buf);
}

// Retrieve a 'property' value previously set with SetProperty,
// interpreted as an int AFTER any '$()' variable replacement.
int wxScintillaTextCtrl::GetPropertyInt(const wxString& key) {
    return SendMsg(4010, (wxIntPtr)(const char*)wx2stc(key), 0);
}

// Retrieve the number of bits the current lexer needs for styling.
int wxScintillaTextCtrl::GetStyleBitsNeeded() {
    return SendMsg(4011, 0, 0);
}

// END of generated section
//----------------------------------------------------------------------


// Returns the line number of the line with the caret.
int wxScintillaTextCtrl::GetCurrentLine() {
    int line = LineFromPosition(GetCurrentPos());
    return line;
}


// Extract style settings from a spec-string which is composed of one or
// more of the following comma separated elements:
//
//      bold                    turns on bold
//      italic                  turns on italics
//      fore:[name or #RRGGBB]  sets the foreground colour
//      back:[name or #RRGGBB]  sets the background colour
//      face:[facename]         sets the font face name to use
//      size:[num]              sets the font size in points
//      eol                     turns on eol filling
//      underline               turns on underlining
//
void wxScintillaTextCtrl::StyleSetSpec(int styleNum, const wxString& spec) {

    wxStringTokenizer tkz(spec, wxT(","));
    while (tkz.HasMoreTokens()) {
        wxString token = tkz.GetNextToken();

        wxString option = token.BeforeFirst(':');
        wxString val = token.AfterFirst(':');

        if (option == wxT("bold"))
            StyleSetBold(styleNum, true);

        else if (option == wxT("italic"))
            StyleSetItalic(styleNum, true);

        else if (option == wxT("underline"))
            StyleSetUnderline(styleNum, true);

        else if (option == wxT("eol"))
            StyleSetEOLFilled(styleNum, true);

        else if (option == wxT("size")) {
            long points;
            if (val.ToLong(&points))
                StyleSetSize(styleNum, points);
        }

        else if (option == wxT("face"))
            StyleSetFaceName(styleNum, val);

        else if (option == wxT("fore"))
            StyleSetForeground(styleNum, wxColourFromSpec(val));

        else if (option == wxT("back"))
            StyleSetBackground(styleNum, wxColourFromSpec(val));
    }
}


// Set style size, face, bold, italic, and underline attributes from
// a wxFont's attributes.
void wxScintillaTextCtrl::StyleSetFont(int styleNum, wxFont& font) {
#ifdef __WXGTK__
    // Ensure that the native font is initialized
    int x, y;
    GetTextExtent(wxT("X"), &x, &y, NULL, NULL, &font);
#endif
    int            size     = font.GetPointSize();
    wxString       faceName = font.GetFaceName();
    bool           bold     = font.GetWeight() == wxBOLD;
    bool           italic   = font.GetStyle() != wxNORMAL;
    bool           under    = font.GetUnderlined();
    wxFontEncoding encoding = font.GetEncoding();

    StyleSetFontAttr(styleNum, size, faceName, bold, italic, under, encoding);
}

// Set all font style attributes at once.
void wxScintillaTextCtrl::StyleSetFontAttr(int styleNum, int size,
                                        const wxString& faceName,
                                        bool bold, bool italic,
                                        bool underline,
                                        wxFontEncoding encoding) {
    StyleSetSize(styleNum, size);
    StyleSetFaceName(styleNum, faceName);
    StyleSetBold(styleNum, bold);
    StyleSetItalic(styleNum, italic);
    StyleSetUnderline(styleNum, underline);
    StyleSetFontEncoding(styleNum, encoding);
}


// Set the character set of the font in a style.  Converts the Scintilla
// character set values to a wxFontEncoding.
void wxScintillaTextCtrl::StyleSetCharacterSet(int style, int characterSet)
{
    wxFontEncoding encoding;

    // Translate the Scintilla characterSet to a wxFontEncoding
    switch (characterSet) {
        default:
        case wxSTC_CHARSET_ANSI:
        case wxSTC_CHARSET_DEFAULT:
            encoding = wxFONTENCODING_DEFAULT;
            break;

        case wxSTC_CHARSET_BALTIC:
            encoding = wxFONTENCODING_ISO8859_13;
            break;

        case wxSTC_CHARSET_CHINESEBIG5:
            encoding = wxFONTENCODING_CP950;
            break;

        case wxSTC_CHARSET_EASTEUROPE:
            encoding = wxFONTENCODING_ISO8859_2;
            break;

        case wxSTC_CHARSET_GB2312:
            encoding = wxFONTENCODING_CP936;
            break;

        case wxSTC_CHARSET_GREEK:
            encoding = wxFONTENCODING_ISO8859_7;
            break;

        case wxSTC_CHARSET_HANGUL:
            encoding = wxFONTENCODING_CP949;
            break;

        case wxSTC_CHARSET_MAC:
            encoding = wxFONTENCODING_DEFAULT;
            break;

        case wxSTC_CHARSET_OEM:
            encoding = wxFONTENCODING_DEFAULT;
            break;

        case wxSTC_CHARSET_RUSSIAN:
            encoding = wxFONTENCODING_KOI8;
            break;

        case wxSTC_CHARSET_SHIFTJIS:
            encoding = wxFONTENCODING_CP932;
            break;

        case wxSTC_CHARSET_SYMBOL:
            encoding = wxFONTENCODING_DEFAULT;
            break;

        case wxSTC_CHARSET_TURKISH:
            encoding = wxFONTENCODING_ISO8859_9;
            break;

        case wxSTC_CHARSET_JOHAB:
            encoding = wxFONTENCODING_DEFAULT;
            break;

        case wxSTC_CHARSET_HEBREW:
            encoding = wxFONTENCODING_ISO8859_8;
            break;

        case wxSTC_CHARSET_ARABIC:
            encoding = wxFONTENCODING_ISO8859_6;
            break;

        case wxSTC_CHARSET_VIETNAMESE:
            encoding = wxFONTENCODING_DEFAULT;
            break;

        case wxSTC_CHARSET_THAI:
            encoding = wxFONTENCODING_ISO8859_11;
            break;

        case wxSTC_CHARSET_CYRILLIC:
            encoding = wxFONTENCODING_ISO8859_5;
            break;

        case wxSTC_CHARSET_8859_15:
            encoding = wxFONTENCODING_ISO8859_15;;
            break;
    }

    // We just have Scintilla track the wxFontEncoding for us.  It gets used
    // in Font::Create in PlatWX.cpp.  We add one to the value so that the
    // effective wxFONENCODING_DEFAULT == SC_SHARSET_DEFAULT and so when
    // Scintilla internally uses SC_CHARSET_DEFAULT we will translate it back
    // to wxFONENCODING_DEFAULT in Font::Create.
    SendMsg(SCI_STYLESETCHARACTERSET, style, encoding+1);
}


// Set the font encoding to be used by a style.
void wxScintillaTextCtrl::StyleSetFontEncoding(int style, wxFontEncoding encoding)
{
    SendMsg(SCI_STYLESETCHARACTERSET, style, encoding+1);
}


// Perform one of the operations defined by the wxSTC_CMD_* constants.
void wxScintillaTextCtrl::CmdKeyExecute(int cmd) {
    SendMsg(cmd);
}


// Set the left and right margin in the edit area, measured in pixels.
void wxScintillaTextCtrl::SetMargins(int left, int right) {
    SetMarginLeft(left);
    SetMarginRight(right);
}


// Retrieve the start and end positions of the current selection.
void wxScintillaTextCtrl::GetSelection(int* startPos, int* endPos) {
    if (startPos != NULL)
        *startPos = SendMsg(SCI_GETSELECTIONSTART);
    if (endPos != NULL)
        *endPos = SendMsg(SCI_GETSELECTIONEND);
}


// Retrieve the point in the window where a position is displayed.
wxPoint wxScintillaTextCtrl::PointFromPosition(int pos) {
    int x = SendMsg(SCI_POINTXFROMPOSITION, 0, pos);
    int y = SendMsg(SCI_POINTYFROMPOSITION, 0, pos);
    return wxPoint(x, y);
}

// Scroll enough to make the given line visible
void wxScintillaTextCtrl::ScrollToLine(int line) {
    m_swx->DoScrollToLine(line);
}


// Scroll enough to make the given column visible
void wxScintillaTextCtrl::ScrollToColumn(int column) {
    m_swx->DoScrollToColumn(column);
}


bool wxScintillaTextCtrl::SaveFile(const wxString& filename)
{
    wxFile file(filename, wxFile::write);

    if (!file.IsOpened())
        return false;

    bool success = file.Write(GetText(), *wxConvCurrent);

    if (success)
        SetSavePoint();

    return success;
}

bool wxScintillaTextCtrl::LoadFile(const wxString& filename)
{
    bool success = false;
    wxFile file(filename, wxFile::read);

    if (file.IsOpened())
    {
        wxString contents;
        // get the file size (assume it is not huge file...)
        ssize_t len = (ssize_t)file.Length();

        if (len > 0)
        {
#if wxUSE_UNICODE
            wxMemoryBuffer buffer(len+1);
            success = (file.Read(buffer.GetData(), len) == len);
            if (success) {
                ((char*)buffer.GetData())[len] = 0;
                contents = wxString(buffer, *wxConvCurrent, len);
            }
#else
            wxString buffer;
            success = (file.Read(wxStringBuffer(buffer, len), len) == len);
            contents = buffer;
#endif
        }
        else
        {
            if (len == 0)
                success = true;  // empty file is ok
            else
                success = false; // len == wxInvalidOffset
        }

        if (success)
        {
            SetText(contents);
            EmptyUndoBuffer();
            SetSavePoint();
        }
    }

    return success;
}


#if wxUSE_DRAG_AND_DROP
wxDragResult wxScintillaTextCtrl::DoDragOver(wxCoord x, wxCoord y, wxDragResult def) {
        return m_swx->DoDragOver(x, y, def);
}


bool wxScintillaTextCtrl::DoDropText(long x, long y, const wxString& data) {
    return m_swx->DoDropText(x, y, data);
}
#endif


void wxScintillaTextCtrl::SetUseAntiAliasing(bool useAA) {
    m_swx->SetUseAntiAliasing(useAA);
}

bool wxScintillaTextCtrl::GetUseAntiAliasing() {
    return m_swx->GetUseAntiAliasing();
}





void wxScintillaTextCtrl::AddTextRaw(const char* text)
{
    SendMsg(SCI_ADDTEXT, strlen(text), (wxIntPtr)text);
}

void wxScintillaTextCtrl::InsertTextRaw(int pos, const char* text)
{
    SendMsg(SCI_INSERTTEXT, pos, (wxIntPtr)text);
}

wxCharBuffer wxScintillaTextCtrl::GetCurLineRaw(int* linePos)
{
    int len = LineLength(GetCurrentLine());
    if (!len) {
        if (linePos)  *linePos = 0;
        wxCharBuffer empty;
        return empty;
    }

    wxCharBuffer buf(len);
    int pos = SendMsg(SCI_GETCURLINE, len, (wxIntPtr)buf.data());
    if (linePos)  *linePos = pos;
    return buf;
}

wxCharBuffer wxScintillaTextCtrl::GetLineRaw(int line)
{
    int len = LineLength(line);
    if (!len) {
        wxCharBuffer empty;
        return empty;
    }

    wxCharBuffer buf(len);
    SendMsg(SCI_GETLINE, line, (wxIntPtr)buf.data());
    return buf;
}

wxCharBuffer wxScintillaTextCtrl::GetSelectedTextRaw()
{
    int   start;
    int   end;

    GetSelection(&start, &end);
    int   len  = end - start;
    if (!len) {
        wxCharBuffer empty;
        return empty;
    }

    wxCharBuffer buf(len);
    SendMsg(SCI_GETSELTEXT, 0, (wxIntPtr)buf.data());
    return buf;
}

wxCharBuffer wxScintillaTextCtrl::GetTextRangeRaw(int startPos, int endPos)
{
    if (endPos < startPos) {
        int temp = startPos;
        startPos = endPos;
        endPos = temp;
    }
    int len  = endPos - startPos;
    if (!len) {
        wxCharBuffer empty;
        return empty;
    }

    wxCharBuffer buf(len);
    TextRange tr;
    tr.lpstrText = buf.data();
    tr.chrg.cpMin = startPos;
    tr.chrg.cpMax = endPos;
    SendMsg(SCI_GETTEXTRANGE, 0, (wxIntPtr)&tr);
    return buf;
}

void wxScintillaTextCtrl::SetTextRaw(const char* text)
{
    SendMsg(SCI_SETTEXT, 0, (wxIntPtr)text);
}

wxCharBuffer wxScintillaTextCtrl::GetTextRaw()
{
    int len  = GetTextLength();
    wxCharBuffer buf(len);
    SendMsg(SCI_GETTEXT, len+1, (wxIntPtr)buf.data());
    return buf;
}

void wxScintillaTextCtrl::AppendTextRaw(const char* text)
{
    SendMsg(SCI_APPENDTEXT, strlen(text), (wxIntPtr)text);
}





//----------------------------------------------------------------------
// Event handlers

void wxScintillaTextCtrl::OnPaint(wxPaintEvent& WXUNUSED(evt)) {
    wxPaintDC dc(this);
    m_swx->DoPaint(&dc, GetUpdateRegion().GetBox());
}

void wxScintillaTextCtrl::OnScrollWin(wxScrollWinEvent& evt) {
    if (evt.GetOrientation() == wxHORIZONTAL)
        m_swx->DoHScroll(evt.GetEventType(), evt.GetPosition());
    else
        m_swx->DoVScroll(evt.GetEventType(), evt.GetPosition());
}

void wxScintillaTextCtrl::OnScroll(wxScrollEvent& evt) {
    wxScrollBar* sb = wxDynamicCast(evt.GetEventObject(), wxScrollBar);
    if (sb) {
        if (sb->IsVertical())
            m_swx->DoVScroll(evt.GetEventType(), evt.GetPosition());
        else
            m_swx->DoHScroll(evt.GetEventType(), evt.GetPosition());
    }
}

void wxScintillaTextCtrl::OnSize(wxSizeEvent& WXUNUSED(evt)) {
    if (m_swx) {
        wxSize sz = GetClientSize();
        m_swx->DoSize(sz.x, sz.y);
    }
}

void wxScintillaTextCtrl::OnMouseLeftDown(wxMouseEvent& evt) {
    SetFocus();
    wxPoint pt = evt.GetPosition();
    m_swx->DoLeftButtonDown(Point(pt.x, pt.y), m_stopWatch.Time(),
                      evt.ShiftDown(), evt.ControlDown(), evt.AltDown());
}

void wxScintillaTextCtrl::OnMouseMove(wxMouseEvent& evt) {
    wxPoint pt = evt.GetPosition();
    m_swx->DoLeftButtonMove(Point(pt.x, pt.y));
}

void wxScintillaTextCtrl::OnMouseLeftUp(wxMouseEvent& evt) {
    wxPoint pt = evt.GetPosition();
    m_swx->DoLeftButtonUp(Point(pt.x, pt.y), m_stopWatch.Time(),
                      evt.ControlDown());
}


void wxScintillaTextCtrl::OnMouseRightUp(wxMouseEvent& evt) {
    wxPoint pt = evt.GetPosition();
    m_swx->DoContextMenu(Point(pt.x, pt.y));
}


void wxScintillaTextCtrl::OnMouseMiddleUp(wxMouseEvent& evt) {
    wxPoint pt = evt.GetPosition();
    m_swx->DoMiddleButtonUp(Point(pt.x, pt.y));
}

void wxScintillaTextCtrl::OnContextMenu(wxContextMenuEvent& evt) {
    wxPoint pt = evt.GetPosition();
    ScreenToClient(&pt.x, &pt.y);
    /*
      Show context menu at event point if it's within the window,
      or at caret location if not
    */
    wxHitTest ht = this->HitTest(pt);
    if (ht != wxHT_WINDOW_INSIDE) {
        pt = this->PointFromPosition(this->GetCurrentPos());
    }
    m_swx->DoContextMenu(Point(pt.x, pt.y));
}


void wxScintillaTextCtrl::OnMouseWheel(wxMouseEvent& evt) {
    m_swx->DoMouseWheel(evt.GetWheelRotation(),
                        evt.GetWheelDelta(),
                        evt.GetLinesPerAction(),
                        evt.ControlDown(),
                        evt.IsPageScroll());
}


void wxScintillaTextCtrl::OnChar(wxKeyEvent& evt) {
    // On (some?) non-US PC keyboards the AltGr key is required to enter some
    // common characters.  It comes to us as both Alt and Ctrl down so we need
    // to let the char through in that case, otherwise if only ctrl or only
    // alt let's skip it.
    bool ctrl = evt.ControlDown();
#ifdef __WXMAC__
    // On the Mac the Alt key is just a modifier key (like Shift) so we need
    // to allow the char events to be processed when Alt is pressed.
    // TODO:  Should we check MetaDown instead in this case?
    bool alt = false;
#else
    bool alt  = evt.AltDown();
#endif
    bool skip = ((ctrl || alt) && ! (ctrl && alt));

    if (!m_lastKeyDownConsumed && !skip) {
#if wxUSE_UNICODE
        int key = evt.GetUnicodeKey();
        bool keyOk = true;

        // if the unicode key code is not really a unicode character (it may
        // be a function key or etc., the platforms appear to always give us a
        // small value in this case) then fallback to the ascii key code but
        // don't do anything for function keys or etc.
        if (key <= 127) {
            key = evt.GetKeyCode();
            keyOk = (key <= 127);
        }
        if (keyOk) {
            m_swx->DoAddChar(key);
            return;
        }
#else
        int key = evt.GetKeyCode();
        if (key <= WXK_START || key > WXK_COMMAND) {
            m_swx->DoAddChar(key);
            return;
        }
#endif
    }

    evt.Skip();
}


void wxScintillaTextCtrl::OnKeyDown(wxKeyEvent& evt) {
    int processed = m_swx->DoKeyDown(evt, &m_lastKeyDownConsumed);
    if (!processed && !m_lastKeyDownConsumed)
        evt.Skip();
}


void wxScintillaTextCtrl::OnLoseFocus(wxFocusEvent& evt) {
    m_swx->DoLoseFocus();
    evt.Skip();
}


void wxScintillaTextCtrl::OnGainFocus(wxFocusEvent& evt) {
    m_swx->DoGainFocus();
    evt.Skip();
}


void wxScintillaTextCtrl::OnSysColourChanged(wxSysColourChangedEvent& WXUNUSED(evt)) {
    m_swx->DoSysColourChange();
}


void wxScintillaTextCtrl::OnEraseBackground(wxEraseEvent& WXUNUSED(evt)) {
    // do nothing to help avoid flashing
}



void wxScintillaTextCtrl::OnMenu(wxCommandEvent& evt) {
    m_swx->DoCommand(evt.GetId());
}


void wxScintillaTextCtrl::OnListBox(wxCommandEvent& WXUNUSED(evt)) {
    m_swx->DoOnListBox();
}


void wxScintillaTextCtrl::OnIdle(wxIdleEvent& evt) {
    m_swx->DoOnIdle(evt);
}


wxSize wxScintillaTextCtrl::DoGetBestSize() const
{
    // What would be the best size for a wxSTC?
    // Just give a reasonable minimum until something else can be figured out.
    return wxSize(200,100);
}


//----------------------------------------------------------------------
// Turn notifications from Scintilla into events


void wxScintillaTextCtrl::NotifyChange() {
    wxScintillaTextEvent evt(wxEVT_STC_CHANGE, GetId());
    evt.SetEventObject(this);
    GetEventHandler()->ProcessEvent(evt);
}


static void SetEventText(wxScintillaTextEvent& evt, const char* text,
                         size_t length) {
    if(!text) return;

    evt.SetText(stc2wx(text, length));
}


void wxScintillaTextCtrl::NotifyParent(SCNotification* _scn) {
    SCNotification& scn = *_scn;
    wxScintillaTextEvent evt(0, GetId());

    evt.SetEventObject(this);
    evt.SetPosition(scn.position);
    evt.SetKey(scn.ch);
    evt.SetModifiers(scn.modifiers);

    switch (scn.nmhdr.code) {
    case SCN_STYLENEEDED:
        evt.SetEventType(wxEVT_STC_STYLENEEDED);
        break;

    case SCN_CHARADDED:
        evt.SetEventType(wxEVT_STC_CHARADDED);
        break;

    case SCN_SAVEPOINTREACHED:
        evt.SetEventType(wxEVT_STC_SAVEPOINTREACHED);
        break;

    case SCN_SAVEPOINTLEFT:
        evt.SetEventType(wxEVT_STC_SAVEPOINTLEFT);
        break;

    case SCN_MODIFYATTEMPTRO:
        evt.SetEventType(wxEVT_STC_ROMODIFYATTEMPT);
        break;

    case SCN_KEY:
        evt.SetEventType(wxEVT_STC_KEY);
        break;

    case SCN_DOUBLECLICK:
        evt.SetEventType(wxEVT_STC_DOUBLECLICK);
        break;

    case SCN_UPDATEUI:
        evt.SetEventType(wxEVT_STC_UPDATEUI);
        break;

    case SCN_MODIFIED:
        evt.SetEventType(wxEVT_STC_MODIFIED);
        evt.SetModificationType(scn.modificationType);
        SetEventText(evt, scn.text, scn.length);
        evt.SetLength(scn.length);
        evt.SetLinesAdded(scn.linesAdded);
        evt.SetLine(scn.line);
        evt.SetFoldLevelNow(scn.foldLevelNow);
        evt.SetFoldLevelPrev(scn.foldLevelPrev);
        break;

    case SCN_MACRORECORD:
        evt.SetEventType(wxEVT_STC_MACRORECORD);
        evt.SetMessage(scn.message);
        evt.SetWParam(scn.wParam);
        evt.SetLParam(scn.lParam);
        break;

    case SCN_MARGINCLICK:
        evt.SetEventType(wxEVT_STC_MARGINCLICK);
        evt.SetMargin(scn.margin);
        break;

    case SCN_NEEDSHOWN:
        evt.SetEventType(wxEVT_STC_NEEDSHOWN);
        evt.SetLength(scn.length);
        break;

    case SCN_PAINTED:
        evt.SetEventType(wxEVT_STC_PAINTED);
        break;

    case SCN_AUTOCSELECTION:
        evt.SetEventType(wxEVT_STC_AUTOCOMP_SELECTION);
        evt.SetListType(scn.listType);
        SetEventText(evt, scn.text, strlen(scn.text));
        evt.SetPosition(scn.lParam);
        break;

    case SCN_USERLISTSELECTION:
        evt.SetEventType(wxEVT_STC_USERLISTSELECTION);
        evt.SetListType(scn.listType);
        SetEventText(evt, scn.text, strlen(scn.text));
        evt.SetPosition(scn.lParam);
        break;

    case SCN_URIDROPPED:
        evt.SetEventType(wxEVT_STC_URIDROPPED);
        SetEventText(evt, scn.text, strlen(scn.text));
        break;

    case SCN_DWELLSTART:
        evt.SetEventType(wxEVT_STC_DWELLSTART);
        evt.SetX(scn.x);
        evt.SetY(scn.y);
        break;

    case SCN_DWELLEND:
        evt.SetEventType(wxEVT_STC_DWELLEND);
        evt.SetX(scn.x);
        evt.SetY(scn.y);
        break;

    case SCN_ZOOM:
        evt.SetEventType(wxEVT_STC_ZOOM);
        break;

    case SCN_HOTSPOTCLICK:
        evt.SetEventType(wxEVT_STC_HOTSPOT_CLICK);
        break;

    case SCN_HOTSPOTDOUBLECLICK:
        evt.SetEventType(wxEVT_STC_HOTSPOT_DCLICK);
        break;

    case SCN_CALLTIPCLICK:
        evt.SetEventType(wxEVT_STC_CALLTIP_CLICK);
        break;

    default:
        return;
    }

    GetEventHandler()->ProcessEvent(evt);
}


//----------------------------------------------------------------------
//----------------------------------------------------------------------
//----------------------------------------------------------------------

wxScintillaTextEvent::wxScintillaTextEvent(wxEventType commandType, int id)
    : wxCommandEvent(commandType, id)
{
    m_position = 0;
    m_key = 0;
    m_modifiers = 0;
    m_modificationType = 0;
    m_length = 0;
    m_linesAdded = 0;
    m_line = 0;
    m_foldLevelNow = 0;
    m_foldLevelPrev = 0;
    m_margin = 0;
    m_message = 0;
    m_wParam = 0;
    m_lParam = 0;
    m_listType = 0;
    m_x = 0;
    m_y = 0;
    m_dragAllowMove = false;
#if wxUSE_DRAG_AND_DROP
    m_dragResult = wxDragNone;
#endif
}

bool wxScintillaTextEvent::GetShift() const { return (m_modifiers & SCI_SHIFT) != 0; }
bool wxScintillaTextEvent::GetControl() const { return (m_modifiers & SCI_CTRL) != 0; }
bool wxScintillaTextEvent::GetAlt() const { return (m_modifiers & SCI_ALT) != 0; }


wxScintillaTextEvent::wxScintillaTextEvent(const wxScintillaTextEvent& event):
  wxCommandEvent(event)
{
    m_position =      event.m_position;
    m_key =           event.m_key;
    m_modifiers =     event.m_modifiers;
    m_modificationType = event.m_modificationType;
    m_text =          event.m_text;
    m_length =        event.m_length;
    m_linesAdded =    event.m_linesAdded;
    m_line =          event.m_line;
    m_foldLevelNow =  event.m_foldLevelNow;
    m_foldLevelPrev = event.m_foldLevelPrev;

    m_margin =        event.m_margin;

    m_message =       event.m_message;
    m_wParam =        event.m_wParam;
    m_lParam =        event.m_lParam;

    m_listType =     event.m_listType;
    m_x =            event.m_x;
    m_y =            event.m_y;

    m_dragText =     event.m_dragText;
    m_dragAllowMove =event.m_dragAllowMove;
#if wxUSE_DRAG_AND_DROP
    m_dragResult =   event.m_dragResult;
#endif
}

//----------------------------------------------------------------------
//----------------------------------------------------------------------









