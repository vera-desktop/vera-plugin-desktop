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

public class VeraColor : Object {

	private static Settings settings;
	private static Gtk.CssProvider provider;
	
	private static void on_vera_color_enabled_changed() {
		/**
		 * Fired when the 'vera-color-enabled' property has been changed.
		*/
		
		message("enabled changed!");
		
		if (settings.get_boolean("vera-color-enabled")) {
			message("Enabling");
			Gtk.StyleContext.add_provider_for_screen(
				Gdk.Screen.get_default(),
				provider,
				Gtk.STYLE_PROVIDER_PRIORITY_SETTINGS
			);
			
			on_vera_color_changed();
		} else {
			message("Disabling");
			Gtk.StyleContext.remove_provider_for_screen(
				Gdk.Screen.get_default(),
				provider
			);
		}
		
	}
	
	private static void on_vera_color_changed() {
		/**
		 * Fired when the 'vera-color' property has been changed.
		*/
		
		if (!settings.get_boolean("vera-color-enabled"))
			return;
		
		message("Loading");
		provider.load_from_data(
			"@define-color vera-color %s;".printf(settings.get_string("vera-color")),
			-1
		);
		
		Gtk.StyleContext.reset_widgets(Gdk.Screen.get_default());
		
	}
	
	[CCode (cname = "gtk_module_init")]
	public static void gtk_module_init(int argc, string[] argv) {
		/**
		 * Initializes the module.
		*/
		
		provider = new Gtk.CssProvider();
		
		settings = new Settings("org.semplicelinux.vera.desktop");
		settings.changed["vera-color-enabled"].connect(on_vera_color_enabled_changed);
		settings.changed["vera-color"].connect(on_vera_color_changed);
		
		on_vera_color_enabled_changed();
		
	}

}
