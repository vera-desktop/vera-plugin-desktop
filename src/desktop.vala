/*
 * vera-plugin-desktop - desktop plugin for vera
 * Copyright (C) 2014  Eugenio "g7" Paolantonio and the Semplice Project
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Authors:
 *     Eugenio "g7" Paolantonio <me@medesimo.eu>
*/

using Vera;

namespace DesktopPlugin {
    
    extern void set_x_property(X.Display display, X.Window window, X.Atom atom, X.Pixmap pixmap);

    public class Plugin : Peas.ExtensionBase, VeraPlugin {

	public Display display;

	public Settings settings;
	private DesktopWindow[] window_list = new DesktopWindow[0];
	
	private X.Pixmap? xpixmap = null;
	
	private int monitor_number;
	private int realized_backgrounds = 0;
	
	private bool tutorial_enabled;
	
	private void on_settings_changed(string key) {
	    /**
	     * Fired when the settings of vera-desktop have been changed.
	     * Currently we handle only the wallpaper so we'll invoke
	     * set_wallpaper().
	    */
	    
	    debug("changed setting %s", key);
	    
	    this.update_background();
	}

        private void update_background() {
	    /**
	     * Sets the background.
	     * Currently this method is pretty crowded up,
	     * but it does work nonetheless.
	    */
	    
	    Gdk.Screen scr = this.window_list[0].get_screen();
	    Gdk.Rectangle geometry;
	    int screen_num = scr.get_number();
	    Gdk.Window root = scr.get_root_window();
	    //Gdk.Window window = this.window_list[0].get_window();
	    Gdk.Window window;
	    Gdk.Display rootdisplay = root.get_display();
	    weak X.Display xdisplay = Gdk.X11Display.get_xdisplay(rootdisplay);
	    message("X screen number: %s", screen_num.to_string());
	    weak X.Window xrootwindow = xdisplay.root_window(screen_num);
	    Gdk.Pixbuf pixbuf = null;
	    weak Gdk.RGBA background_color;

	    Cairo.Context cx;
	    Cairo.Pattern pattern;
	    Cairo.XlibSurface bg;
	    
	    weak X.Screen xscreen = X.Screen.get_screen(xdisplay, screen_num);
	    
	    string path;
	    string[] backgrounds = this.settings.get_strv("image-path");
	    BackgroundMode type = (BackgroundMode)this.settings.get_enum("background-mode");
	    string color = this.settings.get_string("background-color");
	    
	    if (this.xpixmap != null)
		X.free_pixmap(xdisplay, this.xpixmap);
	    
	    this.xpixmap = X.CreatePixmap(
		xdisplay,
		xrootwindow,
		scr.get_width(),
		scr.get_height(),
		xscreen.default_depth_of_screen()
	    );
	    
	    bg = new Cairo.XlibSurface(
		xdisplay,
		(int)this.xpixmap,
		Gdk.X11Visual.get_xvisual(scr.get_system_visual()),
		scr.get_width(),
		scr.get_height()
	    );
	    
	    
	    /* Solid color, we do not need to loop through the monitors */
	    if (type == BackgroundMode.COLOR) {
		
		/* FIXME: Memory leak when switching from a wallpaper? */
		
		background_color = Gdk.RGBA();
		if (!background_color.parse(color)) {
		    /* Color has not been parsed correctly */
		    warning("Unable to parse background color, skipping...");
		    return;
		}
		
		cx = new Cairo.Context(bg);
		
		/*
		Gdk.cairo_set_source_rgba(cx, background_color);
		cx.rectangle(0, 0, scr.get_width(), scr.get_height());
		cx.fill();
		cx.paint();
		*/
		
		
		cx.set_source_rgb(
		    background_color.red,
		    background_color.green,
		    background_color.blue
		);
		cx.paint();

		/* Create background pattern */
		pattern = new Cairo.Pattern.for_surface(bg);
		    
		/*
		 * Set the created pattern in the window, so that the user
		 * actually sees a background :)
		*/
		foreach (DesktopWindow desktop_window in this.window_list) {
		    window = desktop_window.desktop_background.get_window();
		    window.set_background_pattern(pattern);
		}
		
		if (pixbuf != null)
		    pixbuf = null;
	    } else {
		
		int src_w, src_h, dest_w, dest_h, x, y;

		for (int i = 0; i < this.window_list.length; i++) {
		    
		    window = this.window_list[i].desktop_background.get_window();
		    
		    /*
		     * We should now select the background to paint.
		     * The 'image-path' configuration property in the
		     * gsettings schema is a string array, that contains
		     * (in the correct order) the image to set for every
		     * monitor.
		     * When a monitor doesn't have its specified wallpaper,
		     * we will fallback to the first.
		     * 
		     * Another exception is when the background-mode is
		     * SCREEN: we will pick only the first wallpaper.
		    */
		    
		    if (i < backgrounds.length && type != BackgroundMode.SCREEN) {
			path = backgrounds[i];
		    } else {
			path = backgrounds[0];
		    }
		    
		    /*
		     * We need to set a background image (and an eventual color,
		     * if we have alpha)
		    */
		    
		    scr.get_monitor_geometry(i, out geometry);
		    
		    if (!(type == BackgroundMode.SCREEN && i > 0)) {
			/* If the mode is SCREEN and this isn't the first
			 * monitor, we already have the pixbuf... */
			
			pixbuf = new Gdk.Pixbuf.from_file(path);
		    }


		    message("Monitor " + i.to_string());
		    message("x: " + geometry.x.to_string());
		    message("y: " + geometry.y.to_string());

		    x = 0;
		    y = 0;
		    src_w = pixbuf.get_width();
		    src_h = pixbuf.get_height();
		    dest_w = geometry.width;
		    dest_h = geometry.height;
		    		    
		    if (type == BackgroundMode.SCREEN) {
			x = -geometry.x;
			y = -geometry.y;
		    }
		    
		    /* 
		     * Create a subsurface for the main XlibSurface.
		     * Things we paint here will also go to the main Surface
		     * (bg), that will be applied as _XROOTPMAP_ID.
		     * 
		     * We will apply this subsurface to individual monitors.
		    */
		    Cairo.Surface pbg = new Cairo.Surface.for_rectangle(
			bg,
			geometry.x,
			geometry.y,
			dest_w,
			dest_h
		    );
		    
		    cx = new Cairo.Context(pbg);
		    
		    /*
		     * We should now determine if we need to paint also
		     * the color before the pixbuf.
		     * We need to do that when:
		     *  - The image has alpha (transparent parts)
		     *  - BackgroundMode.CENTER
		     *  - BackgroundMode.FIT
		    */
		    
		    if (pixbuf.has_alpha || type == BackgroundMode.CENTER || type == BackgroundMode.FIT) {
			background_color = Gdk.RGBA();
			if (!background_color.parse(color)) {
			    /* Color has not been parsed correctly */
			    warning("Unable to parse background color, skipping...");
			    return;
			}
			Gdk.cairo_set_source_rgba(cx, background_color);
			cx.rectangle(0, 0, dest_w, dest_h);
			cx.fill();
		    }
		    
		    
		    switch (type) {
			/* Tile */
			case BackgroundMode.TILE:
			    /*
			     * Cairo Patterns have a neat way to do tiling,
			     * but we need to have the surface image-sized,
			     * which will be then a no-go when we'll put
			     * the thing as the _XROOTPMAP_ID.
			     * 
			     * So we do tiling the hard way.
			     * There aren't problems when painting outside
			     * the bounds of our subsurface, as cairo
			     * will not make changes there.
			    */
			    int tile_w = 0, tile_h;
			    
			    while (tile_w < geometry.width) {
				
				tile_h = 0;
				while (tile_h < geometry.height) {
				    Gdk.cairo_set_source_pixbuf(cx, pixbuf, tile_w, tile_h);
				    cx.paint();
				    
				    tile_h += src_h;
				}

				tile_w += src_w;				
				
			    }
			    
			    
			    break;
			/* Stretch */
			case BackgroundMode.STRETCH:
			    
			    message("Monitor " + i.to_string());
			    message("dest_w: " + dest_w.to_string());
			    message("dest_h: " + dest_h.to_string());
			    if (!(dest_w == src_w && dest_h == src_h)) {
				pixbuf = pixbuf.scale_simple(dest_w, dest_h, Gdk.InterpType.BILINEAR);
			    }
			    		    
			    break;
			/* Screen */
			case BackgroundMode.SCREEN:
			
			    if (type == BackgroundMode.SCREEN && i > 0)
				break;
			
			    int screen_width = scr.get_width();
			    int screen_height = scr.get_height();
			    
			    if (!(screen_width == src_w && screen_height == src_h)) {
				pixbuf = pixbuf.scale_simple(screen_width, screen_height, Gdk.InterpType.BILINEAR);
			    }
			    
			    break;
			    
			/* Fit and crop */
			case BackgroundMode.FIT:
			case BackgroundMode.CROP:

			    if (dest_w != src_w || dest_h != src_h) {
				double w_ratio = (float)dest_w / src_w;
				double h_ratio = (float)dest_h / src_h;
				double ratio;
				
				if (type == BackgroundMode.FIT) {
				    ratio = double.min(w_ratio, h_ratio);
				} else {
				    ratio = double.max(w_ratio, h_ratio);
				}
				
				if (ratio != 1.0) {
				    				    
				    src_w = ((int)Math.lround(src_w * ratio));
				    src_h = ((int)Math.lround(src_h * ratio));
				    
				    pixbuf = pixbuf.scale_simple(
					src_w,
					src_h,
					Gdk.InterpType.BILINEAR
				    );
				}
				
				x = (dest_w - src_w) / 2;
				y = (dest_h - src_h) / 2;
			    }
			    
			    break;
			/* Center */
			case BackgroundMode.CENTER:
			    x = (dest_w - src_w) / 2;
			    y = (dest_h - src_h) / 2;
			    break;
			    
		    }
		    
		    if (type != BackgroundMode.TILE)
			Gdk.cairo_set_source_pixbuf(cx, pixbuf, x, y);
		    
		    cx.paint();
		    		    
		    /* Create background pattern */
		    pattern = new Cairo.Pattern.for_surface(pbg);
		    
		    /*
		     * Set the created pattern in the window, so that the user
		     * actually sees a background :)
		    */
		    window.set_background_pattern(pattern);
		    		    
		}
		
	    }
		        
	    /*
	     * Now we need to set the root map on X.
	     * This is needed because when we lack of true transparency
	     * (i.e. we do not have a composite WM active) many applications
	     * (such as tint2, xchat, many terminals, etc) rely on
	     * the _XROOTPMAP_ID atom to create a fake transparency.
	     * 
	     * The specification talk also about the ESETROOT_PMAP_ID property,
	     * but as we are a permanent (hopefully) client, we aren't going
	     * to set it.
	     * The PCManFM guys did the same (and I use this space to thank
	     * them, most code in this source file is inspired by PCManFM's
	     * desktop.c).
	    */
	    
	    xdisplay.grab_server();
	    
	    X.Atom atm = xdisplay.intern_atom("_XROOTPMAP_ID", false);
	    /*
	     * I'm sorry.
	     * Yes, I'm serious.
	     * 
	     * set_x_property() is nothing but an external C function
	     * located in workarounds/xsetproperty.c.
	     * 
	     * Unfortunately, Vala's X.Display.change_property(), does not
	     * work as it should, and we end up with nothing set as
	     * _XROOTPMAP_ID in the best case, and with a fucked X in the
	     * worst (bad Pixmap and some applications that rely on that
	     * property may crash, it happened to me with xchat).
	     * 
	     * I hope to use a Vala equivalent when possible, in the mean
	     * time, please accept this workaround.
	    */
	    set_x_property(xdisplay, xrootwindow, atm, this.xpixmap);

	    //X.SetWindowBackgroundPixmap(xdisplay, xrootwindow, (int)xpixmap);
	    X.ClearWindow(xdisplay, xrootwindow);
	    xdisplay.flush();
	    xdisplay.ungrab_server();
	    
        }
	
	private void on_desktopbackground_realized(Gtk.Widget desktop_background) {
	    /**
	     * We use this method to track down the realized DesktopBackgrounds.
	     * We will draw the background once all the DesktopBackgrounds are realized.
	    */
	    
	    this.realized_backgrounds++;
	    
	    if (this.realized_backgrounds == this.monitor_number) {
		/* We can draw the background */
		this.update_background();
	    }
	}

	private void populate_screens() {
	    /**
	     * This is the method that will create and position the DesktopWindows
	     * on every monitor of the computer.
	    */

	    Gdk.Screen screen = Gdk.Screen.get_default();
	    Gdk.Rectangle rectangle;
	    DesktopWindow window;
	    
	    /* Is the tutorial enabled? */
	    this.tutorial_enabled = this.settings.get_boolean("show-tutorial");
	    
	    /* Set monitor number */
	    this.monitor_number = screen.get_n_monitors();

	    for (int i = 0; i < this.monitor_number; i++) {
		/* Loop through the monitors found */

		/* Get Rectangle of the monitor */
		screen.get_monitor_geometry(i, out rectangle);
		
		/* Create window */
		window = new DesktopWindow(rectangle, this.settings, this.display, i);
		this.window_list += window;
		
		window.desktop_background.realize.connect(this.on_desktopbackground_realized);
		window.show_all();
		
		/* If the tutorial is enabled, we need to connect things up */
		if (this.tutorial_enabled)
		    window.connect_for_tutorial();

	    }
	    
	    /*
	     * We now do something only on the first window:
	     *  - We will 'present' it, so it becomes fully focused
	     *    and ready to listen to keystrokes
	     *  - We will show the Tutorial if the configuration says so.
	    */
	    
	    if (this.tutorial_enabled) {
		/* Yes, we need to show tutorial. */
		this.window_list[0].show_tutorial();
		
		/*
		 * As we run the tutorial only on the first monitor, we need
		 * to share our Tutorial object with the other ones...
		*/
		for (int i=1; i < this.window_list.length; i++) {
		    this.window_list[i].tutorial = this.window_list[0].tutorial;
		}
	    }
	    
	    this.window_list[0].present();
	}

	public void init(Display display) {
	    /**
	     * Initializes the plugin.
	    */
	    
	    try {
		this.display = display;
		    
		this.settings = new Settings("org.semplicelinux.vera.desktop");

		this.settings.changed.connect(this.on_settings_changed);

	    } catch (Error ex) {
		error("Unable to load plugin settings.");
	    }
	    
	    /* Styling */
	    Gtk.CssProvider css_provider = new Gtk.CssProvider();
	    css_provider.load_from_data(@"
		#tutorial { background: transparent; }
		.tutorial-page { background: transparent; }",
		-1
	    );
	    
	    Gtk.StyleContext.add_provider_for_screen(
		Gdk.Screen.get_default(),
		css_provider,
		Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
	    );
	}

	public void startup(StartupPhase phase) {
	    /**
	     * Startups the plugin.
	    */

	    if (phase == StartupPhase.DESKTOP || phase == StartupPhase.SESSION) {
		
		this.populate_screens();

	    }

	}

	public void shutdown() {
	    /**
	     * Shutdown.
	    */
	    
	    foreach (Gtk.Window window in this.window_list) {
		window.destroy();
	    }
	    
	}

    }
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
    Peas.ObjectModule objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(VeraPlugin), typeof(DesktopPlugin.Plugin));
}
