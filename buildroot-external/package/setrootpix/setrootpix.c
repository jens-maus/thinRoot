/*
 * setrootpix.c
 *
 * Set a solid-color root background using a 1x1 pixmap (tiled by the X server),
 * and publish _XROOTPMAP_ID + ESETROOT_PMAP_ID hints. Uses RetainPermanent so
 * the pixmap survives after this helper exits.
 *
 * Build:
 *   cc -O2 -Wall -Wextra -o setrootpix setrootpix.c -lX11
 *
 * Usage:
 *   ./setrootpix "#32436B"
 */

#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <stdio.h>
#include <stdlib.h>

static int alloc_color(Display *dpy, Colormap cmap, const char *spec, XColor *out)
{
    if (!XParseColor(dpy, cmap, spec, out)) {
        return 0;
    }
    if (!XAllocColor(dpy, cmap, out)) {
        return 0;
    }
    return 1;
}

int main(int argc, char **argv)
{
    const char *color = (argc >= 2) ? argv[1] : "#32436B";

    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) {
        fprintf(stderr, "setrootpix: cannot open display\n");
        return 1;
    }

    const int scr = DefaultScreen(dpy);
    Window root = RootWindow(dpy, scr);
    Colormap cmap = DefaultColormap(dpy, scr);

    /* Ensure server retains resources after this client exits (critical). */
    XSetCloseDownMode(dpy, RetainPermanent);

    XColor col;
    if (!alloc_color(dpy, cmap, color, &col)) {
        fprintf(stderr, "setrootpix: cannot parse/alloc color '%s'\n", color);
        XCloseDisplay(dpy);
        return 2;
    }

    /* 1x1 pixmap; the server will tile it across the root window. */
    Pixmap pm = XCreatePixmap(dpy, root, 1, 1, DefaultDepth(dpy, scr));
    if (!pm) {
        fprintf(stderr, "setrootpix: XCreatePixmap failed\n");
        XCloseDisplay(dpy);
        return 3;
    }

    GC gc = XCreateGC(dpy, pm, 0, NULL);
    if (!gc) {
        fprintf(stderr, "setrootpix: XCreateGC failed\n");
        XFreePixmap(dpy, pm);
        XCloseDisplay(dpy);
        return 4;
    }

    XSetForeground(dpy, gc, col.pixel);
    XFillRectangle(dpy, pm, gc, 0, 0, 1, 1);
    XFreeGC(dpy, gc);

    /* Apply background pixmap and force redraw. */
    XSetWindowBackgroundPixmap(dpy, root, pm);
    XClearWindow(dpy, root);

    /* Publish well-known background pixmap hints. */
    Atom a_root = XInternAtom(dpy, "_XROOTPMAP_ID", False);
    Atom a_eset = XInternAtom(dpy, "ESETROOT_PMAP_ID", False);

    /* Note: properties are 32-bit items; Pixmap is an XID, safe to store as unsigned long. */
    unsigned long pm_id = (unsigned long)pm;

    XChangeProperty(dpy, root, a_root, XA_PIXMAP, 32, PropModeReplace,
                    (unsigned char *)&pm_id, 1);
    XChangeProperty(dpy, root, a_eset, XA_PIXMAP, 32, PropModeReplace,
                    (unsigned char *)&pm_id, 1);

    XFlush(dpy);
    XCloseDisplay(dpy);
    return 0;
}
