/*
 * setrootpix.c
 *
 * Sets a solid-color root background using a 1x1 pixmap (tiled by the X server),
 * and publishes background pixmap hints:
 *   - _XROOTPMAP_ID
 *   - ESETROOT_PMAP_ID
 *   - _XSETROOT_ID
 *
 * Uses RetainPermanent so the pixmap survives after this helper exits.
 *
 * Build:
 *   ${TARGET_CC} -O2 -Wall -Wextra -o setrootpix setrootpix.c -lX11
 *
 * Usage:
 *   ./setrootpix "#32436B"
 */

#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <stdint.h>
#include <stdio.h>

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

static void set_pixmap_property(Display *dpy, Window root, Atom prop, Pixmap pm)
{
    /* XIDs are 32-bit; store as 32-bit item for XChangeProperty format=32. */
    uint32_t id = (uint32_t)pm;

    XChangeProperty(dpy, root, prop, XA_PIXMAP, 32, PropModeReplace,
                    (unsigned char *)&id, 1);
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

    /* Critical: keep resources (pixmap) after this client exits. */
    XSetCloseDownMode(dpy, RetainPermanent);

    XColor col;
    if (!alloc_color(dpy, cmap, color, &col)) {
        fprintf(stderr, "setrootpix: cannot parse/alloc color '%s'\n", color);
        XCloseDisplay(dpy);
        return 2;
    }

    /* 1x1 pixmap; will be tiled across the root window. */
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

    /* Apply pixmap as root background and repaint. */
    XSetWindowBackgroundPixmap(dpy, root, pm);
    XClearWindow(dpy, root);

    /* Publish hints used by compositors / pseudo-transparency clients. */
    Atom a_root  = XInternAtom(dpy, "_XROOTPMAP_ID", False);
    Atom a_eset  = XInternAtom(dpy, "ESETROOT_PMAP_ID", False);
    Atom a_xset  = XInternAtom(dpy, "_XSETROOT_ID", False);

    set_pixmap_property(dpy, root, a_root, pm);
    set_pixmap_property(dpy, root, a_eset, pm);
    set_pixmap_property(dpy, root, a_xset, pm);

    XFlush(dpy);
    XCloseDisplay(dpy);
    return 0;
}
