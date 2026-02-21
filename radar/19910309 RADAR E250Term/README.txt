1-19-98
=======
The E250Term program was a package developed for KSNP in Coffey County, KS.  It was originally intended to be an SCA-delivered system, like E300DB, but in the end they decided that they would rather have a dial-up system.

The ARCHITECTURE
================
The Server end (the E250 radar) is controlled by a software program that Peter James wrote (see the E250 subdirectory).  It places the VGA card in 640x480 mode, and assigns the colormap so that a white bit plane sits on top of a black/grn/yel/red double plane.

The Server is a small TSR (terminate-and-stay-resident) program that, once loaded, installs an ISR (interrupt service routine) on one of the serial ports, initializes the modem for auto-answer, and then terminates (and stays resident).

Once a call comes in, the server queries for a serial number from the client (terminal).  The call is logged.

If the serial number has already been used this cycle, the call terminates immediately, and an **ACCESSED DENIED** message is added to the log.

Otherwise, the radar parameters are then read off the screen (bit plane 2?).  The parameter glyphs are matched to digits in the character generator table, and the glyphs are decoded into range, gain, and tilt values.

Next, the screen is grabbed and transferred to an intermediate buffer.

Finally, the parameters are transmitted, then the screen is compressed line-by-line and transmitted.

I have somehow misplaced the final release of the source code.  The
final release included logging on the server end, and access control.