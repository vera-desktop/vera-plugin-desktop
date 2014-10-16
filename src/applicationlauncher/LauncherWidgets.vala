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
    
    public class PageButton : Gtk.RadioButton {
    
	public PageButton(Gtk.RadioButton? radio_group_member, int page_number) {
	    
	    Object();
	    
	    this.group = radio_group_member;
	    ((Gtk.ToggleButton)this).draw_indicator = false;
	    
	    this.set_label(page_number.to_string());
	    
	}
    }

    public class LauncherPages : Gtk.Box {
	
	/**
	 * The pages of the launcher.
	*/
	
	private PageButton first_page = null;
	private int count = 0;
	
	public signal void page_changed(int new_page);
	
	public LauncherPages() {
	    
	    Object(orientation: Gtk.Orientation.HORIZONTAL);
	    
	    /* Add first page */
	    this.update_page_number(1);
	    
	    this.halign = Gtk.Align.CENTER;
	    this.valign = Gtk.Align.CENTER;
	    
	}
	
	private void on_button_toggled(PageButton button, int page) {
	    
	    this.page_changed(page);
	    
	}
	
	public void update_page_number(int new_page) {
	    /**
	     * Creates/Removes buttons.
	    */
	    
	    PageButton button;
	    int current;
	    
	    while (this.count < new_page) {
		this.count++;
		
		button = new PageButton(this.first_page, this.count);
		current = this.count; 
		button.toggled.connect(
		    (button) => {
			this.page_changed(current);
		    }
		);
		button.show();
		this.pack_start(button, false, false, 5);
		
		if (this.first_page == null) {
		    /* This is the first page, save it */
		    this.first_page = button;
		}
	    }
	    
	}
	
    }
    
}
