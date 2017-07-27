//
//  Copyright (C) 2011-2015 Eidete Developers
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Eidete.Widgets {
    public class SelectionArea : Granite.Widgets.CompositedWindow {
        private int[,] pos;
        public bool discrete;
        public bool not_visible;

        public int x;
        public int y;
        public int w;
        public int h;

        public SelectionArea () {
            this.stick ();
            this.resizable = true;
            this.set_has_resize_grip (false);
            this.set_default_geometry (640, 480);
            this.events = Gdk.EventMask.BUTTON_MOTION_MASK | Gdk.EventMask.BUTTON1_MOTION_MASK |
                    Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK;
            this.skip_taskbar_hint = true;
            this.skip_pager_hint = true;
            this.not_visible = false;

            this.button_press_event.connect ((e) => {
                Gdk.WindowEdge [] dir = {Gdk.WindowEdge.NORTH_WEST,
                        Gdk.WindowEdge.NORTH,Gdk.WindowEdge.NORTH_EAST,
                        Gdk.WindowEdge.EAST,Gdk.WindowEdge.SOUTH_EAST,Gdk.WindowEdge.SOUTH,
                        Gdk.WindowEdge.SOUTH_WEST,Gdk.WindowEdge.WEST};

                for (var i = 0; i < 8; i++) {
                    if (in_quad (pos[i,0] - 12, pos[i,1] - 10, 24, 24, (int) e.x, (int) e.y)) {
                        this.begin_resize_drag (dir[i], (int) e.button, (int) e.x_root, (int) e.y_root, e.time);

                        return false;
                    }
                }

                this.begin_move_drag ((int) e.button, (int) e.x_root, (int) e.y_root, e.time);

                return false;
            });

            this.configure_event.connect ((e) => {
                var scale = get_scale_factor ();
                var screen_width = Gdk.Screen.width () * scale;
                var screen_height = Gdk.Screen.height () * scale;

                var e_x = e.x * scale;
                var e_y= e.y * scale;
                var e_width = e.width * scale;
                var e_height = e.height * scale;

                // check if coordinates are out of the screen and check
                // if coordinate + width/height is out of the screen, then
                // adjust coordinates to keep width and height (and aspect
                // ratio) intact

                if (e_x < 0 || e_x > screen_width) {
                    x = 0;
                } else if (e_x + e_width > screen_width && e_width < screen_width) {
                    x = screen_width - e_width;
                } else {
                    x = e_x;
                }

                if (e_y < 0) {
                    y = 0;
                } else if (e_y + e_height >= screen_height && e_height < screen_height) {
                    y = screen_height - e_height - 1;
                } else {
                    y = e_y;
                }

                // just in case an edge is still outside of the screen
                // we'll modify the width/height if thats the case

                if (x + e_width > screen_width) {
                    w = screen_width - x;
                } else {
                    w = e_width;
                }

                if (y + e_height > screen_height) {
                    h = screen_height - y;
                } else {
                    h = e_height;
                }

                geometry_changed (x, y, w, h);

                return false;
            });

            this.destroy.connect (() => {
                this.not_visible = true;
            });
        }

        private bool in_quad (int qx, int qy, int qh, int qw, int x, int y) {
            return ((x > qx) && (x < (qx + qw)) && (y > qy) && (y < qy + qh));
        }

        public override bool draw (Cairo.Context ctx) {
            int w = this.get_allocated_width ();
            int h = this.get_allocated_height ();
            int r = 16;

            if (!discrete) {
                pos = { { 1, 1 },           // upper left
                        { w / 2, 1 },       // upper midpoint
                        { w - 1, 1 },       // upper right
                        { w - 1, h / 2 },   // right midpoint
                        { w - 1, h - 1 },   // lower right
                        { w / 2, h - 1 },   // lower midpoint
                        { 1, h - 1 },       // lower left
                        { 1, h / 2 } };     // left midpoint

                ctx.rectangle (0, 0, w, h);
                ctx.set_source_rgba (0.1, 0.1, 0.1, 0.2);
                ctx.fill ();

                for (var i = 0; i < 8; i++) {
                    ctx.arc (pos[i,0], pos[i,1], r, 0.0, 2 * 3.14);
                    ctx.set_source_rgb (0.7, 0.7, 0.7);
                    ctx.fill ();
                }

                ctx.rectangle (0, 0, w, h);
                ctx.set_source_rgb (1.0, 1.0, 1.0);
                ctx.set_line_width (1.0);
                ctx.stroke ();
            } else {
                ctx.rectangle (0, 0, w, h);
                ctx.set_source_rgb (0.8, 0.0, 0.0);
                ctx.set_line_width (3.0);
                ctx.stroke ();
            }

            return base.draw (ctx);
        }

        public signal void geometry_changed (int x, int y, int width, int height);

        public void to_discrete () {
            if (!this.is_composited ()) {
                this.destroy ();

                return;
            }

            this.discrete = true;
            this.set_keep_above (true);
            this.queue_draw ();
            this.resize (w + 6, h + 6);
            this.move (x - 2, y - 2);
            this.deletable = false;
            this.type_hint = Gdk.WindowTypeHint.SPLASHSCREEN;
            this.accept_focus = false;

            this.realize ();

            Cairo.RectangleInt rect = { 0, 0, 1, 1 };
            this.get_window ().input_shape_combine_region (new Cairo.Region.rectangle (rect), 0, 0);

            this.enter_notify_event.connect (() => {
                this.get_window ().input_shape_combine_region (new Cairo.Region.rectangle (rect), 0, 0);

                return true;
            });
        }
    }
}
