 
/**
 * Padre's Win32 Launcher Evil Experiment in C
 */
#include <windows.h>
 
/**
 *
 */
LRESULT CALLBACK WndProc(
	HWND   hWnd,
	UINT   msg,
	WPARAM wParam,
	LPARAM lParam ) {
 
	switch( msg ) {
	case WM_PAINT: {
		PAINTSTRUCT ps;
		HDC hDC = BeginPaint( hWnd, &ps );
		TextOut(hDC, 10, 10, "ADP GmbH", 8 );
		EndPaint( hWnd, &ps );
	}
	break;

	case WM_DESTROY:
	  PostQuitMessage(0);
	break;

	default:
	  return DefWindowProc( hWnd, msg, wParam, lParam);
	} 
	return 0;
}
 
/**
 *
 */
int WINAPI WinMain( 
	HINSTANCE hInstance, 
	HINSTANCE hPrevInstance, 
	LPSTR lpCmdLine, 
	int nCmdShow) {
 
	WNDCLASSEX wce;

	wce.cbSize        = sizeof(wce);
	wce.style         = CS_VREDRAW | CS_HREDRAW; 
	wce.lpfnWndProc   = (WNDPROC) WndProc; 
	wce.cbClsExtra    = 0; 
	wce.cbWndExtra    = 0; 
	wce.hInstance     = hInstance; 
	wce.hIcon         = LoadIcon((HINSTANCE) NULL, IDI_APPLICATION); 
	wce.hCursor       = LoadCursor((HINSTANCE) NULL, IDC_ARROW); 
	wce.hbrBackground = (HBRUSH) GetStockObject(WHITE_BRUSH); 
	wce.lpszMenuName  = 0;
	wce.lpszClassName = "ADPWinClass",
	wce.hIconSm       = 0;

	if (!RegisterClassEx(&wce)) return 0; 

	LoadLibrary("shell32");

	HINSTANCE instance;
	ShellExecute(
		NULL,
		"open",
		"wperl.exe",
		"c:\\strawberry\\perl\\bin\\padre",
		NULL,
		SW_SHOWMAXIMIZED
	);
	// HWND hWnd = CreateWindowEx(
	// 0,                      // Ex Styles
	// "ADPWinClass",
	// "ADP GmbH",
	 // WS_OVERLAPPEDWINDOW,
	 // CW_USEDEFAULT,  // x
	 // CW_USEDEFAULT,  // y
	 // CW_USEDEFAULT,  // Height
	 // CW_USEDEFAULT,  // Width
	 // NULL,           // Parent Window
	 // NULL,           // Menu, or windows id if child
	 // hInstance,      // 
	 // NULL            // Pointer to window specific data
	// );

	// ShowWindow( hWnd, nCmdShow );

	// MSG msg;
	// int r;
	// while ((r = GetMessage(&msg, NULL, 0, 0 )) != 0) { 
		// if (r == -1) {
			// // Error!
		// }
		// else {
			// TranslateMessage(&msg); 
			// DispatchMessage(&msg); 
		// }
	// } 

	// The application's return value
	return 0;
}
