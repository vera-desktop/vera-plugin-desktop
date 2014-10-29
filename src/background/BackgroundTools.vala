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

	public struct BackgroundInfo {
		int x;
		int y;
		int src_w;
		int src_h;
		int dest_w;
		int dest_h;
	}	

	public class BackgroundTools : Object {
		/**
		 * Ever wanted to crop a wallpaper?
		*/
		
		public static BackgroundInfo? get_background_info(BackgroundMode mode, Gdk.Rectangle geometry, Gdk.Pixbuf? pixbuf) {
			/**
			 * Returns an appropriate BackgroundInfo object with the
			 * right values for the given wallpaper.
			*/
			
			if (mode == BackgroundMode.COLOR)
				return null;
			
			BackgroundInfo infos = BackgroundInfo();
			
			if (mode == BackgroundMode.SCREEN) {
				infos.x = -geometry.x;
				infos.y = -geometry.y;
			} else {
				infos.x = 0;
				infos.y = 0;
			}
						
			infos.dest_w = geometry.width;
			infos.dest_h = geometry.height;
			infos.src_w = pixbuf.get_width();
			infos.src_h = pixbuf.get_height();
			
			return infos;
			
		}
			
		
		public static void color(Cairo.Context cx, Gdk.RGBA color) {
			/**
			 * Fills with the given color the supplied Cairo.Context.
			*/
			
			cx.set_source_rgb(
				color.red,
				color.green,
				color.blue
			);
			cx.paint();
			
		}
		
		public static void tile(BackgroundInfo infos, Cairo.Context cx, Gdk.Pixbuf pixbuf) {
			/**
			 * Tiles the given pixbuf in the context.
			*/
			
			/*
			 * Cairo Patterns have a neat way to do tiling,
			 * but we need to have the surface image-sized,
			 * which will be then a no-go when we'll put the thing
			 * as the _XROOTPMAP_ID.
			 * 
			 * So we do tiling the hard way.
			 * There aren't problems when painting outside the bounds
			 * of our subsurface as cairo will not make changes there.
			*/
			
			int tile_w = 0, tile_h;
			
			while (tile_w < infos.dest_w) {
				
				tile_h = 0;
				
				while (tile_h < infos.dest_h) {
					Gdk.cairo_set_source_pixbuf(cx, pixbuf, tile_w, tile_h);
					cx.paint();
					
					tile_h += infos.src_h;
				}
				
				tile_w += infos.src_w;
				
			}
			
		}
		
		public static void stretch(BackgroundInfo infos, Cairo.Context cx, Gdk.Pixbuf pixbuf) {
			/**
			 * Stretches the given pixbuf in the context
			*/
			
			Gdk.cairo_set_source_pixbuf(
				cx,
				(
					(!(infos.dest_w == infos.src_w && infos.dest_h == infos.src_h)) ?
					pixbuf.scale_simple(infos.dest_w, infos.dest_h, Gdk.InterpType.BILINEAR) :
					pixbuf
				),
				infos.x,
				infos.y
			);
			cx.paint();
			
		}

	}
	
}
