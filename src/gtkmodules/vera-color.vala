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

public class VeraColor : Gtk.CssProvider {

	private Settings settings;
	
	private void on_vera_color_changed() {
		
		this.load_from_data(
			"@define-color vera-color %s;".printf(this.settings.get_string("vera-color")),
			-1
		);
		
	}
	
	public VeraColor() {
		/**
		 * Initializes the module.
		*/
		
		Object();
		
		this.settings = new Settings("org.semplicelinux.vera.desktop");
		this.settings.changed["vera-color"].connect(this.on_vera_color_changed);
				
		Gtk.StyleContext.add_provider_for_screen(
			Gdk.Screen.get_default(),
			this,
			Gtk.STYLE_PROVIDER_PRIORITY_SETTINGS
		);
		
		this.on_vera_color_changed();
		
	}

}

public void gtk_module_init (int argc, string[] argv) {
	message("Module init");
	
	new VeraColor();
}
