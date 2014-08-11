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
    
    enum BackgroundMode {
        COLOR = 1,
        TILE = 2,
        STRETCH = 3,
        SCREEN = 4,
        FIT = 5,
        CROP = 6,
        CENTER = 7;
    }
        

	public class DesktopBackground : Gtk.EventBox {

		/**
		 * The DesktopBackground widget. This is the main part of
		 * DesktopPlugin.
		 */
         
        private XlibDisplay xlib_display;
        
        private int monitor_number;

        private DesktopWindow parent_window;

        private bool painted = false;

        private Settings settings;

        private weak Gdk.RGBA background_color;
        private weak Gdk.Pixbuf pixbuf;
        
        public signal void menu_shown ();
        
        public static Gdk.RGBA get_dominant_color(Gdk.Pixbuf pixbuf) {
            /**
             * Given a GdkPixbuf, this static method will return the
             * dominant color found in the image.
             * 
             * Method based on GetDominantColorOfImage() in linuxdeepin /
             * go_lib @ GitHub, committed by fasheng. Thank you!
             * https://github.com/linuxdeepin/go-lib/blob/master/gdkpixbuf/gdk_pixbuf_utils.c
            */
            
            weak uint8[] pixels = pixbuf.get_pixels_with_length();
            
            int64 sum_r = 0;
            int64 sum_g = 0;
            int64 sum_b = 0;
            int64 count = 0;
            int skip = pixbuf.get_n_channels();
            
            for (int i = 0; i < pixels.length; i += skip) {
                if (skip == 4 && pixels[i+3] < 125) {
                    continue;
                }
                
                sum_r += pixels[i];
                sum_g += pixels[i+1];
                sum_b += pixels[i+2];
                count++;
            }
            
            message((sum_r / count).to_string());
            message((sum_g / count).to_string());
            message((sum_b / count).to_string());
            
            Gdk.RGBA result = Gdk.RGBA();
            int64 red = sum_r / count;
            int64 green = sum_g / count;
            int64 blue = sum_b / count;
            /* Better way to do this? */
            result.parse("#%lli%lli%lli".printf(red, green, blue));
            
            return result;
            
        }

        private bool on_button_pressed(Gdk.EventButton evnt) {
            
            message("Button pressed!");
            
            if (evnt.button == Gdk.BUTTON_PRIMARY) {
                /* If primary button (usually left), we need to regain focus */
                this.parent_window.set_focus(this);
            } else {
                /* Otherwise, forward the event to the root window (if we are on X) */
                
                if (evnt.button == Gdk.BUTTON_SECONDARY) {
                    /* That's probably the WM menu */
                    this.menu_shown();
                }
                
                this.xlib_display.send_to_root_window(evnt);
            }

            return true;
        }

		public DesktopBackground(DesktopWindow parent_window, Settings settings, int monitor_number) {
            /**
             * Constructs the DesktopBackground.
             */

            Object();
            
            /* Monitor number */
            this.monitor_number = monitor_number;
            
            /* Make child window invisible */
            this.visible_window = false;
            
            /* Events */
            this.add_events(
                Gdk.EventMask.BUTTON_PRESS_MASK |
                Gdk.EventMask.BUTTON_RELEASE_MASK |
                Gdk.EventMask.KEY_PRESS_MASK |
                Gdk.EventMask.KEY_RELEASE_MASK |
                Gdk.EventMask.ENTER_NOTIFY_MASK |
                Gdk.EventMask.LEAVE_NOTIFY_MASK
            );
            this.can_focus = true;

            this.parent_window = parent_window;
            
            /* Xlibdisplay? */
            this.xlib_display = (XlibDisplay)this.parent_window.display;

            this.background_color = new Gdk.RGBA();

            this.settings = settings;


            this.set_app_paintable(true);

            this.button_press_event.connect(this.on_button_pressed);


		}

	}

}
